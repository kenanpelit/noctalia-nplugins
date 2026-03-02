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
    if (!main || !main.available)
      return "alert-circle";
    if (main.status === "active")
      return "shield-check";
    if (main.status === "inactive")
      return "shield-x";
    return "shield";
  }
  readonly property string detailText: {
    if (!main || !main.available)
      return "n/a";
    if (main.status === "active")
      return "On";
    if (main.status === "inactive")
      return "Off";
    return "?";
  }
  readonly property color accentColor: {
    if (!main || !main.available)
      return Color.mError;
    if (main.status === "active")
      return Color.mPrimary;
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
        main.refresh();
      } else if (pluginApi) {
        pluginApi.openPanel(root.screen, root);
      }
    }
  }
}
