import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var pluginApi: null
  property bool actionBusy: false
  property string powerSource: "unknown"
  property bool batteryAvailable: false
  property int batteryPercent: -1
  property string batteryStatus: "unknown"
  property string profile: "unknown"
  property bool pppTimerActive: false
  property bool autoProfileLocked: false
  property bool stasisActive: false
  property bool idleCommandAvailable: false
  property string lastError: ""
  property string lastAction: ""

  readonly property string stateScript: String(Qt.resolvedUrl("scripts/state.sh")).replace(/^file:\/\//, "")
  readonly property string actionScript: String(Qt.resolvedUrl("scripts/action.sh")).replace(/^file:\/\//, "")
  readonly property int watchdogInterval: {
    var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.watchdogInterval, 10) : NaN;
    return (isNaN(candidate) || candidate < 5000) ? 15000 : candidate;
  }
  readonly property bool onAc: powerSource === "ac"
  readonly property bool onBattery: powerSource === "battery"
  readonly property int batteryLevel: batteryPercent < 0 ? 0 : batteryPercent

  function refresh() {
    if (!stateProcess.running) {
      stateProcess.running = true;
    }
  }

  function applyState(text) {
    var raw = String(text || "").trim();
    if (!raw)
      return;
    try {
      var data = JSON.parse(raw);
      powerSource = String(data.powerSource || "unknown");
      batteryAvailable = !!data.batteryAvailable;
      batteryPercent = Number(data.batteryPercent);
      if (isNaN(batteryPercent))
        batteryPercent = -1;
      batteryStatus = String(data.batteryStatus || "unknown");
      profile = String(data.profile || "unknown");
      pppTimerActive = !!data.pppTimerActive;
      autoProfileLocked = !!data.autoProfileLocked;
      stasisActive = !!data.stasisActive;
      idleCommandAvailable = !!data.idleCommandAvailable;
      if (!lastError || lastError.indexOf("Failed to read") === 0)
        lastError = "";
    } catch (err) {
      lastError = "Failed to parse state";
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

  function openPanel() {
    if (!pluginApi)
      return;
    pluginApi.withCurrentScreen(function(screen) {
      pluginApi.togglePanel(screen);
    });
  }

  function setProfile(mode) { runAction(["set-profile", mode], "Profile → " + mode); }
  function cycleProfile() { runAction(["cycle-profile"], "Cycle profile"); }
  function toggleAutoProfileLock() { runAction(["toggle-lock"], autoProfileLocked ? "Auto profile unlocked" : "Auto profile locked"); }
  function toggleIdleInhibit() { runAction(["idle-toggle"], "Toggle idle inhibit"); }
  function lockSession() { runAction(["lock"], "Lock session"); }
  function suspendSession() { runAction(["suspend"], "Suspend"); }
  function lockAndSuspend() { runAction(["lock-and-suspend"], "Lock and suspend"); }

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
      if (code !== 0) {
        root.lastError = (stateStderr.text || "Failed to read power state").trim();
      }
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
    target: "plugin:npower"

    function togglePanel() { root.openPanel(); }
    function refresh() { root.refresh(); }
    function cycleProfile() { root.cycleProfile(); }
    function setProfile(mode: string) { root.setProfile(mode); }
    function toggleLock() { root.toggleAutoProfileLock(); }
    function toggleIdleInhibit() { root.toggleIdleInhibit(); }
    function lock() { root.lockSession(); }
    function suspend() { root.suspendSession(); }
    function lockAndSuspend() { root.lockAndSuspend(); }
  }
}
