import QtQuick
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
  readonly property string iconName: {
    if (!main || !main.available)
      return "alert-circle";
    if (main.status === "active")
      return "shield-check";
    if (main.status === "inactive")
      return "shield-x";
    return "shield";
  }
  readonly property color accentColor: {
    if (!main || !main.available)
      return Color.mError;
    if (main.status === "active")
      return Color.mPrimary;
    if (main.status === "inactive")
      return Color.mOnSurfaceVariant;
    return Color.mOnSurface;
  }
  readonly property color hoverTextColor: "#000000"
  readonly property string tooltipText: {
    if (!main)
      return "Firewall unavailable";
    if (!main.available)
      return main.lastError ? ("UFW unavailable\n" + main.lastError) : "UFW unavailable";
    var lines = [];
    lines.push("Firewall: " + String(main.status || "unknown"));
    lines.push("Rules: " + main.ruleCount);
    lines.push("Logging: " + String(main.loggingLevel || "n/a"));
    lines.push("In " + String(main.incomingPolicy || "n/a") + " / Out " + String(main.outgoingPolicy || "n/a"));
    return lines.join("\n");
  }

  implicitWidth: Math.round((Style.capsuleHeight + Style.marginS) * 1.15)
  implicitHeight: Style.capsuleHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusL
    color: mouse.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Qt.alpha(root.accentColor, 0.22)
    border.width: Style.capsuleBorderWidth

    NIcon {
      anchors.centerIn: parent
      icon: root.iconName
      applyUiScale: false
      color: mouse.containsMouse ? root.hoverTextColor : root.accentColor
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
    onEntered: {
      if (root.tooltipText)
        TooltipService.show(root, root.tooltipText, BarService.getTooltipDirection(root.screen?.name));
    }
    onExited: TooltipService.hide()
  }
}
