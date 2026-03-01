import QtQuick
import Quickshell
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen
  property var pluginApi: null
  readonly property var main: pluginApi ? pluginApi.mainInstance : null

  icon: main && main.isRecording ? "camera-video" : "camera"
  tooltipText: main ? main.buildTooltip() : "NCapture"

  onClicked: {
    if (pluginApi) {
      pluginApi.togglePanel(screen, this);
    }
  }
}
