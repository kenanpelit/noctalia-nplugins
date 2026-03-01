import QtQuick
import Quickshell.Io
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  property bool nmcliAvailable: false
  property bool actionBusy: false
  property bool wifiEnabled: false
  property string generalState: "unknown"
  property string connectivity: "unknown"
  property string activeDevice: ""
  property string activeType: ""
  property string activeState: ""
  property string activeConnection: ""
  property string activeSsid: ""
  property int activeSignal: -1
  property string ipAddress: ""
  property string gateway: ""
  property var nearbyNetworks: []
  property string lastError: ""

  readonly property bool online: connectivity === "full" || connectivity === "limited"
  readonly property bool fullyOnline: connectivity === "full"
  readonly property bool wifiConnected: activeType === "wifi" && activeConnection !== ""
  readonly property string displayName: wifiConnected
                                        ? (activeSsid || activeConnection)
                                        : (activeConnection || (fullyOnline ? "Online" : (online ? "Limited" : "Offline")))
  readonly property int watchdogInterval: {
    var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.watchdogInterval, 10) : NaN;
    return (isNaN(candidate) || candidate < 10000) ? 30000 : candidate;
  }
  readonly property int maxVisibleNetworks: {
    var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.maxVisibleNetworks, 10) : NaN;
    return (isNaN(candidate) || candidate < 3) ? 6 : candidate;
  }

  function splitFields(text, expectedCount, delimiter) {
    var source = String(text || "").trim();
    var sep = delimiter || ":";
    if (!source || expectedCount <= 0)
      return [];

    var parts = [];
    var rest = source;
    for (var i = 1; i < expectedCount; ++i) {
      var idx = rest.indexOf(sep);
      if (idx === -1) {
        parts.push(rest);
        rest = "";
        break;
      }
      parts.push(rest.slice(0, idx));
      rest = rest.slice(idx + sep.length);
    }
    parts.push(rest);
    while (parts.length < expectedCount)
      parts.push("");
    return parts;
  }

  function normalizeConnection(value) {
    var text = String(value || "").trim();
    return text === "--" ? "" : text;
  }

  function resetState() {
    generalState = "unknown";
    connectivity = "unknown";
    activeDevice = "";
    activeType = "";
    activeState = "";
    activeConnection = "";
    activeSsid = "";
    activeSignal = -1;
    ipAddress = "";
    gateway = "";
    nearbyNetworks = [];
  }

  function queueRefresh() {
    if (nmcliAvailable) {
      debounceTimer.restart();
    }
  }

  function startMonitor() {
    if (nmcliAvailable && !monitorProcess.running) {
      monitorProcess.running = true;
    }
  }

  function refresh() {
    if (!nmcliAvailable || actionBusy) {
      return;
    }
    if (!generalProcess.running) generalProcess.running = true;
    if (!deviceProcess.running) deviceProcess.running = true;
    if (!wifiListProcess.running) wifiListProcess.running = true;
  }

  function refreshPathDetails() {
    if (!activeDevice) {
      gateway = "";
      ipAddress = "";
      return;
    }
    if (routeProcess.running)
      return;
    routeProcess.command = ["nmcli", "-g", "IP4.ADDRESS,IP4.GATEWAY", "device", "show", activeDevice];
    routeProcess.running = true;
  }

  function updatePrimaryDevice(deviceRows) {
    var preferred = null;
    for (var i = 0; i < deviceRows.length; ++i) {
      var row = deviceRows[i];
      var state = String(row.state || "").toLowerCase();
      if (row.connection && (state === "connected" || state === "connecting")) {
        if (!preferred || (preferred.type !== "wifi" && row.type === "wifi")) {
          preferred = row;
        }
      }
    }
    if (!preferred) {
      activeDevice = "";
      activeType = "";
      activeState = "";
      activeConnection = "";
      activeSsid = "";
      activeSignal = -1;
      return;
    }

    activeDevice = preferred.device;
    activeType = preferred.type;
    activeState = preferred.state;
    activeConnection = preferred.connection;
    if (preferred.type !== "wifi") {
      activeSsid = preferred.connection;
      activeSignal = -1;
    }
  }

  function parseGeneral(text) {
    var parts = splitFields(text, 2, ":");
    generalState = parts.length > 0 ? String(parts[0] || "unknown").toLowerCase() : "unknown";
    connectivity = parts.length > 1 ? String(parts[1] || "unknown").toLowerCase() : "unknown";
  }

  function parseDevices(text) {
    var rows = [];
    var lines = String(text || "").trim().split("\n");
    for (var i = 0; i < lines.length; ++i) {
      var line = String(lines[i] || "").trim();
      if (!line)
        continue;
      var parts = splitFields(line, 4, ":");
      rows.push({
        device: String(parts[0] || ""),
        type: String(parts[1] || ""),
        state: String(parts[2] || "").toLowerCase(),
        connection: normalizeConnection(parts[3])
      });
    }
    updatePrimaryDevice(rows);
    refreshPathDetails();
  }

  function parseWifiList(text) {
    var strongestBySsid = {};
    var ordered = [];
    var lines = String(text || "").trim().split("\n");
    for (var i = 0; i < lines.length; ++i) {
      var line = String(lines[i] || "").trim();
      if (!line)
        continue;
      var parts = splitFields(line, 4, ":");
      var inUse = String(parts[0] || "").trim() === "*";
      var signal = parseInt(parts[1], 10);
      var security = String(parts[2] || "Open").trim() || "Open";
      var ssid = String(parts[3] || "").trim();
      if (!ssid)
        continue;
      if (isNaN(signal)) signal = 0;
      var item = { inUse: inUse, ssid: ssid, signal: signal, security: security };
      var existing = strongestBySsid[ssid];
      if (!existing || item.signal > existing.signal || item.inUse) {
        strongestBySsid[ssid] = item;
      }
    }
    for (var key in strongestBySsid) {
      ordered.push(strongestBySsid[key]);
    }
    ordered.sort(function(a, b) {
      if (a.inUse !== b.inUse)
        return a.inUse ? -1 : 1;
      return b.signal - a.signal;
    });
    nearbyNetworks = ordered.slice(0, maxVisibleNetworks);

    if (activeType === "wifi") {
      for (var j = 0; j < ordered.length; ++j) {
        if (ordered[j].inUse || ordered[j].ssid === activeConnection) {
          activeSsid = ordered[j].ssid;
          activeSignal = ordered[j].signal;
          break;
        }
      }
      if (!activeSsid)
        activeSsid = activeConnection;
    }
  }

  function parseRoute(text) {
    var lines = String(text || "").trim().split("\n");
    var rawIp = lines.length > 0 ? String(lines[0] || "").trim() : "";
    var rawGateway = lines.length > 1 ? String(lines[1] || "").trim() : "";
    ipAddress = rawIp.replace(/\/.*/, "");
    gateway = rawGateway;
  }

  function setWifiEnabled(enabled) {
    if (actionBusy)
      return;
    lastError = "";
    actionBusy = true;
    actionProcess.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"];
    actionProcess.running = true;
  }

  function toggleWifi() {
    setWifiEnabled(!wifiEnabled);
  }

  function rescanWifi() {
    if (actionBusy)
      return;
    lastError = "";
    actionBusy = true;
    actionProcess.command = ["nmcli", "device", "wifi", "rescan"];
    actionProcess.running = true;
  }

  function connectWifi(ssid) {
    if (actionBusy || !nmcliAvailable)
      return;
    var target = String(ssid || "").trim();
    if (!target)
      return;
    lastError = "";
    actionBusy = true;
    actionProcess.command = activeDevice
      ? ["nmcli", "device", "wifi", "connect", target, "ifname", activeDevice]
      : ["nmcli", "device", "wifi", "connect", target];
    actionProcess.running = true;
  }

  Component.onCompleted: checkProcess.running = true
  onPluginApiChanged: if (pluginApi) queueRefresh()

  Process {
    id: checkProcess
    command: ["nmcli", "-t", "-f", "RUNNING", "general"]
    stderr: StdioCollector { id: checkStderr }
    onExited: function(code) {
      nmcliAvailable = (code === 0);
      if (nmcliAvailable) {
        lastError = "";
        refresh();
        startMonitor();
      } else {
        resetState();
        lastError = (checkStderr.text || "nmcli not available").trim();
      }
    }
  }

  Process {
    id: generalProcess
    command: ["nmcli", "-t", "-f", "STATE,CONNECTIVITY", "general"]
    stdout: StdioCollector {
      onStreamFinished: root.parseGeneral(this.text || "")
    }
    stderr: StdioCollector { id: generalStderr }
    onExited: function(code) {
      if (code !== 0) {
        lastError = (generalStderr.text || "Failed to read general network state").trim();
      }
    }
  }

  Process {
    id: deviceProcess
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
    stdout: StdioCollector {
      onStreamFinished: root.parseDevices(this.text || "")
    }
    stderr: StdioCollector { id: deviceStderr }
    onExited: function(code) {
      if (code !== 0) {
        lastError = (deviceStderr.text || "Failed to read devices").trim();
      }
    }
  }

  Process {
    id: wifiListProcess
    command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "no"]
    stdout: StdioCollector {
      onStreamFinished: root.parseWifiList(this.text || "")
    }
    stderr: StdioCollector { id: wifiStderr }
    onExited: function(code) {
      if (code === 0) {
        return;
      }
      var errorText = (wifiStderr.text || "").trim();
      if (String(errorText).toLowerCase().indexOf("wifi is disabled") !== -1) {
        nearbyNetworks = [];
      } else if (errorText !== "") {
        lastError = errorText;
      }
    }
  }

  Process {
    id: routeProcess
    stdout: StdioCollector {
      onStreamFinished: root.parseRoute(this.text || "")
    }
  }

  Process {
    id: radioProcess
    command: ["nmcli", "radio", "wifi"]
    stdout: StdioCollector {
      onStreamFinished: {
        var state = String(this.text || "").trim().toLowerCase();
        root.wifiEnabled = state === "enabled";
      }
    }
  }

  Process {
    id: actionProcess
    stderr: StdioCollector { id: actionStderr }
    onExited: function(code) {
      actionBusy = false;
      if (code !== 0) {
        lastError = (actionStderr.text || "Network command failed").trim();
        ToastService.showError(lastError);
      } else {
        lastError = "";
      }
      radioProcess.running = true;
      queueRefresh();
    }
  }

  Process {
    id: monitorProcess
    command: ["nmcli", "monitor"]
    stdout: SplitParser {
      onRead: function(data) {
        if (String(data || "").trim() !== "") {
          root.queueRefresh();
        }
      }
    }
    onRunningChanged: {
      if (!running && root.nmcliAvailable) {
        monitorRestartTimer.restart();
      }
    }
  }

  Timer {
    id: debounceTimer
    interval: 500
    running: false
    repeat: false
    onTriggered: {
      radioProcess.running = true;
      root.refresh();
    }
  }

  Timer {
    id: monitorRestartTimer
    interval: 5000
    running: false
    repeat: false
    onTriggered: root.startMonitor()
  }

  Timer {
    interval: root.watchdogInterval
    running: root.nmcliAvailable
    repeat: true
    onTriggered: {
      radioProcess.running = true;
      root.refresh();
    }
  }

  IpcHandler {
    target: "plugin:network"

    function togglePanel() {
      if (!pluginApi)
        return;
      pluginApi.withCurrentScreen(function(screen) {
        pluginApi.togglePanel(screen);
      });
    }

    function refresh() {
      root.queueRefresh();
    }

    function wifiToggle() {
      root.toggleWifi();
    }

    function wifiEnable() {
      root.setWifiEnabled(true);
    }

    function wifiDisable() {
      root.setWifiEnabled(false);
    }

    function wifiRescan() {
      root.rescanWifi();
    }
  }
}
