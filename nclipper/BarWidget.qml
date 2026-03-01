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
  readonly property bool hasClipboard: main ? String(main.currentClipboard || "").trim() !== "" : false
  readonly property string countText: main && main.clipCount > 0 ? String(main.clipCount) : ""
  readonly property color accentColor: hasClipboard ? Color.mPrimary : Color.mOnSurface

  implicitWidth: row.implicitWidth + (Style.marginM * 2)
  implicitHeight: Style.capsuleHeight

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: mouse.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Qt.alpha(root.accentColor, 0.24)
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        icon: "clipboard-text"
        color: mouse.containsMouse ? Color.mOnHover : root.accentColor
        pointSize: Style.fontSizeS
      }

      NText {
        visible: root.countText !== ""
        text: root.countText
        color: mouse.containsMouse ? Color.mOnHover : Color.mOnSurface
        pointSize: Style.barFontSize
        font.weight: Font.Medium
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
      if (mouseEvent.button === Qt.RightButton)
        main.saveCurrent();
      else if (pluginApi)
        pluginApi.openPanel(root.screen, root);
    }
  }
}
