import QtQuick
import QtQuick.Layouts
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
  readonly property string detailText: {
    if (!main)
      return "--";
    if (main.batteryAvailable && main.batteryPercent >= 0)
      return main.batteryPercent + "%";
    if (main.onAc)
      return "AC";
    if (main.onBattery)
      return "BAT";
    return "--";
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
  readonly property color hoverTextColor: "#000000"
  readonly property color baseTextColor: Color.mOnSurfaceVariant
  readonly property real statusChipWidth: Math.round(48 * Style.uiScaleRatio)

  implicitWidth: row.implicitWidth + (Style.marginM * 2)
  implicitHeight: Style.capsuleHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusL
    color: mouse.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Qt.alpha(root.accentColor, 0.22)
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        icon: root.iconName
        applyUiScale: false
        color: mouse.containsMouse ? root.hoverTextColor : root.accentColor
      }

      Rectangle {
        radius: Style.radiusM
        color: mouse.containsMouse ? Qt.alpha("#ffffff", 0.70) : Qt.alpha(root.accentColor, 0.12)
        border.color: mouse.containsMouse ? Qt.alpha(root.hoverTextColor, 0.16) : Qt.alpha(root.accentColor, 0.22)
        border.width: 1
        Layout.preferredHeight: Math.max(Style.capsuleHeight - 10, 18)
        Layout.preferredWidth: root.statusChipWidth

        NText {
          anchors.centerIn: parent
          text: root.detailText
          pointSize: Style.barFontSize
          font.weight: Font.Medium
          color: mouse.containsMouse ? root.hoverTextColor : root.baseTextColor
        }
      }
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
