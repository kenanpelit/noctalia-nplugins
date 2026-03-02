import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

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
  readonly property string tooltipText: {
    var lines = [];
    lines.push("Active tasks: " + activeTodos);
    lines.push("Notes: " + notesCount);
    if (main && String(main.scratchpadText || "").trim())
      lines.push("Scratchpad: active");
    return lines.join("\n");
  }

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusL
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: hasWork ? Qt.alpha(Color.mPrimary, 0.22) : Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

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

    onEntered: {
      if (root.tooltipText)
        TooltipService.show(root, root.tooltipText, BarService.getTooltipDirection(root.screen?.name));
    }

    onExited: TooltipService.hide()
  }
}
