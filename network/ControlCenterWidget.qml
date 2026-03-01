import QtQuick
import Quickshell
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen
  property var pluginApi: null
  readonly property var main: pluginApi ? pluginApi.mainInstance : null

  icon: main && main.activeType === "wifi" ? "router" : "network"
  tooltipText: main
               ? (main.displayName + (main.online ? " | " + String(main.connectivity || "").toUpperCase() : " | OFFLINE"))
               : "Network"

  onClicked: {
    if (pluginApi) {
      pluginApi.togglePanel(screen, this);
    }
  }
}
