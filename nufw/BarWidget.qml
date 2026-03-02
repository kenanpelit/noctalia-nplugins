import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var main: pluginApi ? pluginApi.mainInstance : null

  readonly property string chipText: {
    if (!main || !main.available)
      return "n/a";
    if (main.status === "active")
      return "On";
    if (main.status === "inactive")
      return "Off";
    return "?";
  }

  function chipBackground() {
    if (!main || !main.available)
      return Qt.alpha(Color.mSurfaceVariant, 0.48);
    if (main.status === "active")
      return Qt.alpha(Color.mPrimary, 0.16);
    return Qt.alpha(Color.mSurfaceVariant, 0.48);
  }

  function chipTextColor() {
    if (hoverArea.containsMouse)
      return "#000000";
    if (main && main.status === "active")
      return Color.mPrimary;
    return Color.mOnSurfaceVariant;
  }

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: hoverArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Qt.alpha(main && main.status === "active" ? Color.mPrimary : Color.mOutline, 0.14)
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.marginM
      anchors.rightMargin: Style.marginS
      spacing: Style.marginS

      NIcon {
        icon: "shield"
        pointSize: Style.fontSizeM
        color: hoverArea.containsMouse
               ? "#000000"
               : (main && main.status === "active" ? Color.mPrimary : Color.mOnSurfaceVariant)
      }

      Rectangle {
        Layout.preferredWidth: Math.round(48 * Style.uiScaleRatio)
        Layout.preferredHeight: Math.round(24 * Style.uiScaleRatio)
        radius: height / 2
        color: hoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.7) : root.chipBackground()
        border.color: hoverArea.containsMouse
                      ? Qt.rgba(0, 0, 0, 0.14)
                      : Qt.alpha(Color.mOutline, 0.1)
        border.width: 1

        NText {
          anchors.centerIn: parent
          text: root.chipText
          pointSize: Style.fontSizeXS
          font.weight: Font.Medium
          color: root.chipTextColor()
        }
      }
    }

    MouseArea {
      id: hoverArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (!pluginApi)
          return;
        if (mouse.button === Qt.RightButton) {
          if (main)
            main.refresh();
          return;
        }
        pluginApi.withCurrentScreen(function(screen) {
          pluginApi.togglePanel(screen, null);
        });
      }
    }
  }
}
