import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var pluginApi: null
  property bool actionBusy: false
  property int cpuUsage: 0
  property int memPercent: 0
  property real memUsedGiB: 0
  property real memTotalGiB: 0
  property int diskPercent: 0
  property real diskUsedGiB: 0
  property real diskTotalGiB: 0
  property real load1: 0
  property string uptime: "--"
  property real tempC: -1
  property string topProcessName: "idle"
  property real topProcessCpu: 0
  property string lastError: ""
  property string lastAction: ""

  readonly property string stateScript: String(Qt.resolvedUrl("scripts/state.sh")).replace(/^file:\/\//, "")
  readonly property int watchdogInterval: {
    var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.watchdogInterval, 10) : NaN;
    return (isNaN(candidate) || candidate < 1500) ? 4000 : candidate;
  }
  readonly property string btopCommand: pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.btopCommand ? String(pluginApi.pluginSettings.btopCommand) : "kitty --class btop -e btop"
  readonly property string htopCommand: pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.htopCommand ? String(pluginApi.pluginSettings.htopCommand) : "kitty --class htop -e htop"
  readonly property string topCommand: pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.topCommand ? String(pluginApi.pluginSettings.topCommand) : "kitty --class top -e top"

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
      cpuUsage = Number(data.cpuUsage) || 0;
      memPercent = Number(data.memPercent) || 0;
      memUsedGiB = Number(data.memUsedGiB) || 0;
      memTotalGiB = Number(data.memTotalGiB) || 0;
      diskPercent = Number(data.diskPercent) || 0;
      diskUsedGiB = Number(data.diskUsedGiB) || 0;
      diskTotalGiB = Number(data.diskTotalGiB) || 0;
      load1 = Number(data.load1) || 0;
      uptime = String(data.uptime || "--");
      tempC = data.tempC === null || data.tempC === undefined ? -1 : Number(data.tempC);
      if (isNaN(tempC))
        tempC = -1;
      topProcessName = String(data.topProcessName || "idle");
      topProcessCpu = Number(data.topProcessCpu) || 0;
      if (!lastError || lastError.indexOf("Failed to read") === 0)
        lastError = "";
    } catch (err) {
      lastError = "Failed to parse system state";
    }
  }

  function openPanel() {
    if (!pluginApi)
      return;
    pluginApi.withCurrentScreen(function(screen) {
      pluginApi.togglePanel(screen);
    });
  }

  function runCommand(command, label) {
    if (actionBusy || !command)
      return;
    actionBusy = true;
    lastError = "";
    lastAction = label || "Running...";
    actionProcess.command = ["sh", "-lc", String(command)];
    actionProcess.running = true;
  }

  function openBtop() { runCommand(btopCommand, "Open btop"); }
  function openHtop() { runCommand(htopCommand, "Open htop"); }
  function openTop() { runCommand(topCommand, "Open top"); }

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
      if (code !== 0)
        root.lastError = (stateStderr.text || "Failed to read system state").trim();
    }
  }

  Process {
    id: actionProcess
    stdout: StdioCollector { id: actionStdout }
    stderr: StdioCollector { id: actionStderr }
    onExited: function(code) {
      root.actionBusy = false;
      if (code !== 0) {
        root.lastError = (actionStderr.text || "Action failed").trim();
      } else {
        var out = String(actionStdout.text || "").trim();
        if (out)
          root.lastAction = out;
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
    target: "plugin:nsystem"

    function togglePanel() { root.openPanel(); }
    function refresh() { root.refresh(); }
    function openBtop() { root.openBtop(); }
    function openHtop() { root.openHtop(); }
    function openTop() { root.openTop(); }
  }
}
