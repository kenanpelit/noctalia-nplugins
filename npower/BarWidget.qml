import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property var main: pluginApi ? pluginApi.mainInstance : null
  readonly property string iconName: {
    if (!main)
      return "plug-connected";
    if (main.onAc)
      return main.profile === "performance" ? "bolt" : "plug-connected";
    if (!main.batteryAvailable)
      return "battery";
    if (main.batteryLevel <= 15)
      return "battery-1";
    if (main.batteryLevel <= 35)
      return "battery-2";
    if (main.batteryLevel <= 60)
      return "battery-3";
    if (main.batteryLevel <= 85)
      return "battery-4";
    return "battery";
  }
  readonly property color accentColor: {
    if (!main)
      return Color.mOnSurface;
    if (main.profile === "performance")
      return "#ef5350";
    if (main.profile === "power-saver")
      return "#42a5f5";
    if (main.onAc)
      return Color.mPrimary;
    if (main.batteryLevel <= 20)
      return Color.mError;
    return Color.mOnSurface;
  }

  implicitWidth: Style.capsuleHeight
  implicitHeight: Style.capsuleHeight

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: mouse.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Qt.alpha(root.accentColor, 0.24)
    border.width: Style.capsuleBorderWidth

    NIcon {
      anchors.centerIn: parent
      icon: root.iconName
      color: mouse.containsMouse ? Color.mOnHover : root.accentColor
      pointSize: Style.fontSizeS
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouseEvent) {
      if (!main)
        return;
      if (mouseEvent.button === Qt.RightButton) {
        main.cycleProfile();
      } else if (pluginApi) {
        pluginApi.openPanel(root.screen, root);
      }
    }
  }
}
