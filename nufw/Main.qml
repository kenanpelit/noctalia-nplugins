import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property bool actionBusy: false
  property bool available: false
  property bool readable: false
  property string status: "unknown"
  property string loggingLevel: "n/a"
  property string incomingPolicy: "n/a"
  property string outgoingPolicy: "n/a"
  property string routedPolicy: "n/a"
  property int ruleCount: 0
  property string rulesPreview: ""
  property string lastError: ""
  property string lastAction: ""

  readonly property string stateScript: String(Qt.resolvedUrl("scripts/state.sh")).replace(/^file:\/\//, "")
  readonly property string actionScript: String(Qt.resolvedUrl("scripts/action.sh")).replace(/^file:\/\//, "")
  readonly property int watchdogInterval: {
    var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.watchdogInterval, 10) : NaN;
    return (isNaN(candidate) || candidate < 5000) ? 12000 : candidate;
  }
  readonly property bool enabled: status === "active"

  function refresh() {
    if (!stateProcess.running)
      stateProcess.running = true;
  }

  function applyState(text) {
    var raw = String(text || "").trim();
    if (!raw)
      return;
    try {
      var data = JSON.parse(raw);
      available = !!data.available;
      readable = !!data.readable;
      status = String(data.status || "unknown");
      loggingLevel = String(data.loggingLevel || "n/a");
      incomingPolicy = String(data.incomingPolicy || "n/a");
      outgoingPolicy = String(data.outgoingPolicy || "n/a");
      routedPolicy = String(data.routedPolicy || "n/a");
      ruleCount = Number(data.ruleCount);
      if (isNaN(ruleCount))
        ruleCount = 0;
      rulesPreview = String(data.rulesPreview || "");
      lastError = String(data.error || "");
    } catch (err) {
      lastError = "Failed to parse firewall state";
    }
  }

  function runAction(args, label) {
    if (actionBusy || !args || args.length === 0)
      return;
    actionBusy = true;
    lastError = "";
    lastAction = label || "Working...";
    actionProcess.command = ["sh", actionScript].concat(args);
    actionProcess.running = true;
  }

  function openPanelUi() {
    if (!pluginApi)
      return;
    pluginApi.withCurrentScreen(function(screen) {
      pluginApi.togglePanel(screen, null);
    });
  }

  function openSettingsUi() {
    if (!pluginApi)
      return;
    pluginApi.withCurrentScreen(function(screen) {
      BarService.openPluginSettings(screen, pluginApi.manifest);
    });
  }

  function toggleFirewall() { runAction(["toggle"], enabled ? "Disabling firewall" : "Enabling firewall"); }
  function enableFirewall() { runAction(["enable"], "Enabling firewall"); }
  function disableFirewall() { runAction(["disable"], "Disabling firewall"); }
  function reloadFirewall() { runAction(["reload"], "Reloading firewall"); }

  Component.onCompleted: refresh()
  onPluginApiChanged: refresh()

  Process {
    id: stateProcess
    command: ["sh", root.stateScript]
    stdout: StdioCollector {
      onStreamFinished: root.applyState(this.text || "")
    }
    stderr: StdioCollector { id: stateStderr }
    onExited: function(code) {
      if (code !== 0 && !root.lastError)
        root.lastError = (stateStderr.text || "Failed to read firewall state").trim();
    }
  }

  Process {
    id: actionProcess
    stdout: StdioCollector { id: actionStdout }
    stderr: StdioCollector { id: actionStderr }
    onExited: function(code) {
      root.actionBusy = false;
      if (code !== 0) {
        root.lastError = (actionStderr.text || actionStdout.text || "Firewall action failed").trim();
      } else {
        var out = String(actionStdout.text || "").trim();
        if (out)
          root.lastAction = out;
        root.refresh();
      }
    }
  }

  Timer {
    interval: root.watchdogInterval
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "plugin:nufw"

    function togglePanel() { root.openPanelUi(); }
    function toggle() { root.openPanelUi(); }
    function panel() { root.openPanelUi(); }
    function refresh() { root.refresh(); }
    function toggleFirewall() { root.toggleFirewall(); }
    function enable() { root.enableFirewall(); }
    function disable() { root.disableFirewall(); }
    function reload() { root.reloadFirewall(); }
    function openSettings() { root.openSettingsUi(); }
  }
}
