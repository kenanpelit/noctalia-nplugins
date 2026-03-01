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
  readonly property int activeTodos: main ? main.activeTodoCount : 0
  readonly property int notesCount: main ? main.noteCount : 0
  readonly property bool hasWork: activeTodos > 0 || notesCount > 0
  readonly property color accentColor: hasWork ? Color.mPrimary : Color.mOnSurface
  readonly property real contentWidth: Style.capsuleHeight
  readonly property real contentHeight: Style.capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusL
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: hasWork ? Qt.alpha(Color.mPrimary, 0.22) : Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Rectangle {
      anchors.centerIn: parent
      visible: hasWork
      width: 8
      height: 8
      radius: 4
      color: Color.mPrimary
      anchors.horizontalCenterOffset: 10
      anchors.verticalCenterOffset: -10
    }

    NIcon {
      anchors.centerIn: parent
      icon: "notes"
      applyUiScale: false
      pointSize: Style.fontSizeM
      color: mouseArea.containsMouse ? Color.mOnHover : accentColor
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      if (pluginApi) {
        pluginApi.openPanel(root.screen);
      }
    }
  }
}
