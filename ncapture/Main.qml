import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  property bool recorderAvailable: false
  property bool screenshotAvailable: false
  property bool isRecording: false
  property bool micActive: false
  property bool camActive: false
  property bool shareActive: false
  property var micApps: []
  property var camApps: []
  property var shareApps: []
  property string lastAction: ""
  property string lastError: ""

  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string recordCommand: cfg.recordCommand || defaults.recordCommand || "gpu-screen-recorder -w portal"
  readonly property string stopCommand: cfg.stopCommand || defaults.stopCommand || "pkill -SIGINT -f 'gpu-screen-recorder'"
  readonly property string regionScreenshotCommand: cfg.regionScreenshotCommand || defaults.regionScreenshotCommand || "grimblast --notify copy area"
  readonly property string screenScreenshotCommand: cfg.screenScreenshotCommand || defaults.screenScreenshotCommand || "grimblast --notify copy output"
  readonly property string windowScreenshotCommand: cfg.windowScreenshotCommand || defaults.windowScreenshotCommand || "grimblast --notify copy active"
  readonly property int pollInterval: {
    var candidate = parseInt(cfg.pollInterval ?? defaults.pollInterval ?? 2000, 10);
    return (isNaN(candidate) || candidate < 500) ? 2000 : candidate;
  }
  readonly property bool anyPrivacyActive: micActive || camActive || shareActive
  readonly property bool anyActive: isRecording || anyPrivacyActive

  function hasNodeLinks(node, links) {
    for (var i = 0; i < links.length; ++i) {
      var link = links[i];
      if (link && (link.source === node || link.target === node))
        return true;
    }
    return false;
  }

  function getAppName(node) {
    return node.properties["application.name"] || node.nickname || node.name || "";
  }

  function isScreenShareNode(node) {
    if (!node || !node.properties)
      return false;
    var mediaClass = node.properties["media.class"] || "";
    if (mediaClass.indexOf("Audio") >= 0 || mediaClass.indexOf("Video") === -1)
      return false;
    var mediaName = String(node.properties["media.name"] || "").toLowerCase();
    return mediaName.match(/^(xdph-streaming|gsr-default|game capture|screen|desktop|display|cast|webrtc|v4l2)/)
           || mediaName.match(/screen-cast|screen-capture|desktop-capture|monitor-capture|window-capture|game-capture/i);
  }

  function updateMicrophoneState(nodes, links) {
    var appNames = [];
    var active = false;
    for (var i = 0; i < nodes.length; ++i) {
      var node = nodes[i];
      if (!node || !node.isStream || !node.audio || node.isSink)
        continue;
      if (!hasNodeLinks(node, links) || !node.properties)
        continue;
      if ((node.properties["media.class"] || "") === "Stream/Input/Audio") {
        if (node.properties["stream.capture.sink"] === "true")
          continue;
        active = true;
        var app = getAppName(node);
        if (app && appNames.indexOf(app) === -1)
          appNames.push(app);
      }
    }
    micActive = active;
    micApps = appNames;
  }

  function updateScreenShareState(nodes, links) {
    var appNames = [];
    var active = false;
    for (var i = 0; i < nodes.length; ++i) {
      var node = nodes[i];
      if (!node || !hasNodeLinks(node, links) || !node.properties)
        continue;
      if (isScreenShareNode(node)) {
        active = true;
        var app = getAppName(node);
        if (app && appNames.indexOf(app) === -1)
          appNames.push(app);
      }
    }
    shareActive = active;
    shareApps = appNames;
  }

  function updatePrivacyState() {
    if (!Pipewire.ready)
      return;
    var nodes = Pipewire.nodes.values || [];
    var links = Pipewire.links.values || [];
    updateMicrophoneState(nodes, links);
    updateScreenShareState(nodes, links);
    if (!cameraDetectionProcess.running)
      cameraDetectionProcess.running = true;
  }

  function refresh() {
    lastError = "";
    if (!availabilityProcess.running)
      availabilityProcess.running = true;
    if (!recordingProcess.running)
      recordingProcess.running = true;
    updatePrivacyState();
  }

  function runShell(command, actionText) {
    if (!command || !String(command).trim())
      return;
    lastError = "";
    lastAction = actionText;
    Quickshell.execDetached(["sh", "-lc", String(command)]);
    stateRefreshTimer.restart();
  }

  function screenshotCommandFor(mode) {
    if (mode === "region")
      return regionScreenshotCommand;
    if (mode === "screen")
      return screenScreenshotCommand;
    if (mode === "window")
      return windowScreenshotCommand;
    return "";
  }

  function takeScreenshot(mode) {
    var command = screenshotCommandFor(mode);
    if (!command) {
      lastError = "No screenshot command configured for " + mode;
      return;
    }
    runShell(command, "Screenshot requested: " + mode);
  }

  function startRecording() {
    if (!recorderAvailable) {
      lastError = "gpu-screen-recorder is not available";
      return;
    }
    if (isRecording)
      return;
    runShell(recordCommand, "Recording start requested");
  }

  function stopRecording() {
    if (!isRecording)
      return;
    runShell(stopCommand, "Recording stop requested");
  }

  function toggleRecording() {
    if (isRecording)
      stopRecording();
    else
      startRecording();
  }

  function buildTooltip() {
    var parts = [];
    parts.push(isRecording ? "Recording active" : "Recorder idle");
    if (micActive)
      parts.push("Mic: " + (micApps.length ? micApps.join(", ") : "active"));
    if (camActive)
      parts.push("Camera: " + (camApps.length ? camApps.join(", ") : "active"));
    if (shareActive)
      parts.push("Share: " + (shareApps.length ? shareApps.join(", ") : "active"));
    return parts.join("\n");
  }

  function statusSummary() {
    if (isRecording)
      return "Recording";
    if (anyPrivacyActive)
      return "Privacy active";
    if (recorderAvailable || screenshotAvailable)
      return "Ready";
    return "Unavailable";
  }

  Component.onCompleted: refresh()

  Timer {
    interval: root.pollInterval
    repeat: true
    running: true
    triggeredOnStart: false
    onTriggered: root.refresh()
  }

  Timer {
    id: stateRefreshTimer
    interval: 700
    repeat: false
    onTriggered: root.refresh()
  }

  PwObjectTracker {
    objects: Pipewire.ready ? Pipewire.nodes.values : []
  }

  Process {
    id: availabilityProcess
    command: ["sh", "-lc", "command -v gpu-screen-recorder >/dev/null 2>&1; rec=$?; (command -v grimblast >/dev/null 2>&1 || command -v grim >/dev/null 2>&1); shot=$?; printf '%s %s' \"$rec\" \"$shot\""]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = String(this.text || "").trim().split(/\s+/);
        root.recorderAvailable = parts.length > 0 && parts[0] === "0";
        root.screenshotAvailable = parts.length > 1 && parts[1] === "0";
      }
    }
  }

  Process {
    id: recordingProcess
    command: ["sh", "-lc", "pgrep -f 'gpu-screen-recorder' >/dev/null 2>&1"]
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: function(exitCode) {
      root.isRecording = exitCode === 0;
    }
  }

  Process {
    id: cameraDetectionProcess
    command: ["sh", "-lc", "for dev in /sys/class/video4linux/video*; do [ -e \"$dev/name\" ] && grep -qv 'Metadata' \"$dev/name\" && dev_name=$(basename \"$dev\") && find /proc/[0-9]*/fd -lname \"/dev/$dev_name\" 2>/dev/null; done | cut -d/ -f3 | xargs -r ps -o comm= -p | sort -u | tr '\n' ',' | sed 's/,$//'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var appsString = String(this.text || "").trim();
        var apps = appsString.length > 0 ? appsString.split(',') : [];
        root.camApps = apps;
        root.camActive = apps.length > 0;
      }
    }
  }

  IpcHandler {
    target: "plugin:ncapture"

    function togglePanel() {
      if (pluginApi && pluginApi.withCurrentScreen) {
        pluginApi.withCurrentScreen(function(screen) {
          pluginApi.togglePanel(screen, null);
        });
      }
    }

    function toggle() { root.toggleRecording(); }
    function start() { root.startRecording(); }
    function stop() { root.stopRecording(); }
    function refresh() { root.refresh(); }
    function screenshotRegion() { root.takeScreenshot("region"); }
    function screenshotScreen() { root.takeScreenshot("screen"); }
    function screenshotWindow() { root.takeScreenshot("window"); }
  }
}
