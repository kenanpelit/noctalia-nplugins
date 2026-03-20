import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property bool actionBusy: false
  property bool available: false
  property bool helperAvailable: false
  property bool configAvailable: false
  property bool scheduleAvailable: false
  property bool serviceActive: false
  property bool timerActive: false
  property bool running: false
  property string activePreset: "default"
  property string activePresetLabel: "Default"
  property string activeShortLabel: "Default"
  property string scheduledPreset: "default"
  property string scheduledPresetLabel: "Default"
  property string nextScheduledPreset: "default"
  property string nextScheduledLabel: "Default"
  property string nextScheduledTime: "--:--"
  property bool manualOverride: false
  property string period: "unknown"
  property string state: "unknown"
  property real currentTemp: -1
  property real currentGamma: -1
  property real targetTemp: -1
  property real targetGamma: -1
  property real progress: -1
  property var scheduleEntries: []
  property string lastError: ""
  property string lastAction: ""
  property int watchdogInterval: 20000
  property int tempStep: 150
  property int gammaStep: 2
  property bool showLabelInBar: false
  property bool iconOnlyInBar: true

  readonly property string stateScript: String(Qt.resolvedUrl("scripts/state.sh")).replace(/^file:\/\//, "")
  readonly property string actionScript: String(Qt.resolvedUrl("scripts/action.sh")).replace(/^file:\/\//, "")

  function syncPluginSettings() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;

    var settings = pluginApi.pluginSettings;
    var parsedWatchdog = parseInt(settings.watchdogInterval, 10);
    watchdogInterval = (isNaN(parsedWatchdog) || parsedWatchdog < 5000) ? 20000 : parsedWatchdog;

    var parsedTempStep = parseInt(settings.tempStep, 10);
    tempStep = (isNaN(parsedTempStep) || parsedTempStep < 50) ? 150 : parsedTempStep;

    var parsedGammaStep = parseInt(settings.gammaStep, 10);
    gammaStep = (isNaN(parsedGammaStep) || parsedGammaStep < 1) ? 2 : parsedGammaStep;

    showLabelInBar = settings.showLabelInBar === true;
  }

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
      helperAvailable = !!data.helperAvailable;
      configAvailable = !!data.configAvailable;
      scheduleAvailable = !!data.scheduleAvailable;
      serviceActive = !!data.serviceActive;
      timerActive = !!data.timerActive;
      running = !!data.running;
      activePreset = String(data.activePreset || "default");
      activePresetLabel = String(data.activePresetLabel || "Default");
      activeShortLabel = String(data.activeShortLabel || activePresetLabel);
      scheduledPreset = String(data.scheduledPreset || "default");
      scheduledPresetLabel = String(data.scheduledPresetLabel || "Default");
      nextScheduledPreset = String(data.nextScheduledPreset || "default");
      nextScheduledLabel = String(data.nextScheduledLabel || "Default");
      nextScheduledTime = String(data.nextScheduledTime || "--:--");
      manualOverride = !!data.manualOverride;
      period = String(data.period || "unknown");
      state = String(data.state || "unknown");

      var numericCurrentTemp = Number(data.currentTemp);
      currentTemp = isNaN(numericCurrentTemp) ? -1 : numericCurrentTemp;
      var numericCurrentGamma = Number(data.currentGamma);
      currentGamma = isNaN(numericCurrentGamma) ? -1 : numericCurrentGamma;
      var numericTargetTemp = Number(data.targetTemp);
      targetTemp = isNaN(numericTargetTemp) ? -1 : numericTargetTemp;
      var numericTargetGamma = Number(data.targetGamma);
      targetGamma = isNaN(numericTargetGamma) ? -1 : numericTargetGamma;
      var numericProgress = Number(data.progress);
      progress = isNaN(numericProgress) ? -1 : numericProgress;

      scheduleEntries = Array.isArray(data.scheduleEntries) ? data.scheduleEntries : [];
      lastError = String(data.error || "");
    } catch (err) {
      lastError = "Failed to parse sunsetr state";
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
    refresh();
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

  function applyAuto() { runAction(["auto"], "Auto preset"); }
  function applyDefault() { runAction(["default"], "Default preset"); }
  function applyPreset(preset) { runAction(["preset", preset], "Preset -> " + preset); }
  function makeWarmer() { runAction(["warmer", String(tempStep)], "Warmer +" + tempStep + "K"); }
  function makeCooler() { runAction(["cooler", String(tempStep)], "Cooler -" + tempStep + "K"); }
  function raiseGamma() { runAction(["gamma-up", String(gammaStep)], "Gamma +" + gammaStep + "%"); }
  function lowerGamma() { runAction(["gamma-down", String(gammaStep)], "Gamma -" + gammaStep + "%"); }
  function restartService() { runAction(["restart"], "Restart sunsetr"); }
  function toggleIconOnlyInBar() {
    iconOnlyInBar = !iconOnlyInBar;
  }

  Component.onCompleted: {
    syncPluginSettings();
    refresh();
  }
  onPluginApiChanged: {
    syncPluginSettings();
    refresh();
  }

  Process {
    id: stateProcess
    command: ["sh", root.stateScript]
    stdout: StdioCollector {
      onStreamFinished: root.applyState(this.text || "")
    }
    stderr: StdioCollector { id: stateStderr }
    onExited: function(code) {
      if (code !== 0) {
        root.lastError = (stateStderr.text || "Failed to read sunsetr state").trim();
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
        root.lastError = (actionStderr.text || actionStdout.text || "Sunsetr action failed").trim();
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
    target: "plugin:nsunsetr"

    function togglePanel() { root.openPanelUi(); }
    function toggle() { root.openPanelUi(); }
    function panel() { root.openPanelUi(); }
    function refresh() { root.refresh(); }
    function auto() { root.applyAuto(); }
    function resetDefault() { root.applyDefault(); }
    function warmer() { root.makeWarmer(); }
    function cooler() { root.makeCooler(); }
    function gammaUp() { root.raiseGamma(); }
    function gammaDown() { root.lowerGamma(); }
    function restart() { root.restartService(); }
    function setPreset(preset: string) { root.applyPreset(preset); }
    function toggleBarMode() { root.toggleIconOnlyInBar(); }
    function openSettings() { root.openSettingsUi(); }
  }
}
