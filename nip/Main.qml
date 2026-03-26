import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  Item {
    id: service

    property var ipData: null
    property string currentIp: "n/a"
    property string fetchState: "idle"
    property int lastFetchTime: 0
    property string lastError: ""
    property int refreshTrigger: 0

    readonly property var cfg: root.pluginApi?.pluginSettings || ({})
    readonly property var defaults: root.pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property int refreshInterval: cfg.refreshInterval ?? defaults.refreshInterval ?? 300
    readonly property string stateScript: String(Qt.resolvedUrl("scripts/state.sh")).replace(/^file:\/\//, "")

    function nonEmptyString(value) {
      if (value === undefined || value === null)
        return "";

      var text = String(value).trim();
      return text === "undefined" || text === "null" ? "" : text;
    }

    function firstString(values) {
      for (var i = 0; i < values.length; ++i) {
        var text = nonEmptyString(values[i]);
        if (text)
          return text;
      }

      return "";
    }

    function coordinatesString(data) {
      var loc = nonEmptyString(data.loc);
      if (loc)
        return loc;

      var latitude = firstString([data.latitude, data.lat]);
      var longitude = firstString([data.longitude, data.lon]);
      if (latitude && longitude)
        return latitude + "," + longitude;

      return "";
    }

    function sourceId(data) {
      if (data.mullvad_exit_ip !== undefined || data.mullvad_exit_ip_hostname !== undefined)
        return "mullvad";
      if (data.connection !== undefined && data.success !== undefined)
        return "ipwhois";
      if (data.country_name !== undefined || data.network !== undefined)
        return "ipapi";
      if (data.asn_org !== undefined || data.time_zone !== undefined)
        return "ifconfig";
      if (data.readme !== undefined || data.bogon !== undefined)
        return "ipinfo";
      return "unknown";
    }

    function normalizePayload(data) {
      if (!data || typeof data !== "object")
        throw new Error("Backend returned invalid JSON");
      if (data.success === false)
        throw new Error(firstString([data.message, data.error]) || "IP provider error");

      var connection = data.connection && typeof data.connection === "object" ? data.connection : null;
      var timezone = data.timezone;
      if (timezone && typeof timezone === "object")
        timezone = firstString([timezone.id, timezone.timezone, timezone.name, timezone.abbr]);

      var vpnConnected = data.mullvad_exit_ip === true;
      var organization = vpnConnected
        ? "Mullvad"
        : firstString([
            data.org,
            data.organization,
            data.asn_org,
            connection ? connection.org : "",
            connection ? connection.isp : "",
            data.isp
          ]);

      return {
        ip: firstString([data.ip, data.address]),
        city: firstString([data.city]),
        country: firstString([data.country_name, data.country]),
        region: firstString([data.region, data.region_name]),
        timezone: firstString([timezone, data.time_zone]),
        postal: firstString([data.postal, data.zip_code, data.zip]),
        loc: coordinatesString(data),
        org: organization,
        hostname: firstString([
          data.hostname,
          data.mullvad_exit_ip_hostname,
          connection ? connection.hostname : "",
          connection ? connection.domain : ""
        ]),
        vpnConnected: vpnConnected,
        relay: firstString([data.mullvad_exit_ip_hostname]),
        protocol: firstString([data.mullvad_server_type]),
        source: sourceId(data)
      };
    }

    function applyState(rawText) {
      var payload = String(rawText === undefined || rawText === null ? "" : rawText).trim();
      if (!payload)
        throw new Error("Empty status response");

      var normalized = normalizePayload(JSON.parse(payload));
      if (!normalized.ip)
        throw new Error("No IP field in response");

      service.ipData = normalized;
      service.currentIp = normalized.ip;
      service.fetchState = "success";
      service.lastFetchTime = Date.now();
      service.lastError = "";
      Logger.d("Nip", "Service IP fetched successfully:", service.currentIp, "source:", normalized.source);
    }

    function fetchIp() {
      if (!stateProcess.running) {
        Logger.d("Nip", "Service starting stateProcess");
        stateProcess.running = true;
      } else {
        Logger.d("Nip", "Service fetch already in progress");
      }
    }

    function triggerRefresh() {
      Logger.d("Nip", "Service triggerRefresh() called");
      refreshTrigger++;
      fetchIp();
    }

    Component.onCompleted: {
      Logger.i("Nip", "Service initialized, first time fetching IP.");
      Qt.callLater(() => fetchIp());
    }

    Process {
      id: stateProcess
      command: ["bash", service.stateScript]
      stdout: StdioCollector {
        onStreamFinished: {
          try {
            service.applyState(this.text || "");
          } catch (error) {
            service.currentIp = "n/a";
            service.ipData = null;
            service.fetchState = "error";
            service.lastError = String(error && error.message ? error.message : error);
            Logger.e("Nip", "Service parse error:", service.lastError);
          }
        }
      }
      stderr: StdioCollector { id: stateStderr }

      onStarted: {
        service.fetchState = "loading";
        service.lastError = "";
        Logger.d("Nip", "Service fetching IP info...");
      }

      onExited: function(exitCode) {
        if (exitCode !== 0) {
          service.currentIp = "n/a";
          service.ipData = null;
          service.fetchState = "error";
          service.lastError = String(stateStderr.text || "Failed to fetch public IP details").trim();
          Logger.e("Nip", "Service backend failed:", exitCode, service.lastError);
        } else if (service.fetchState !== "success") {
          service.currentIp = "n/a";
          service.ipData = null;
          service.fetchState = "error";
          if (!service.lastError)
            service.lastError = "Invalid backend response";
        }
      }
    }

    Timer {
      interval: service.refreshInterval * 1000
      running: interval > 0
      repeat: true
      onTriggered: service.fetchIp()
    }
  }

  property alias ipMonitorService: service

  IpcHandler {
    target: "plugin:nip"

    function refreshIp() {
      Logger.i("Nip", "IPC refreshIp() called");
      service.triggerRefresh();
      ToastService.showNotice("Refreshing IP info...");
    }

    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(screen => {
          pluginApi.openPanel(screen);
        });
      }
    }
  }
}
