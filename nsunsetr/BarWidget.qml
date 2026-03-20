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
  readonly property bool iconOnly: main ? main.iconOnlyInBar : false
  readonly property string iconName: {
    if (!main || !main.available)
      return "alert-circle";
    if (!main.serviceActive)
      return "moon-off";
    if (main.period === "day")
      return "sun-high";
    if (main.period === "night")
      return "moon-stars";
    if (main.period === "sunset")
      return "sunset";
    if (main.period === "sunrise")
      return "sun-low";
    return "sun-moon";
  }
  readonly property color accentColor: {
    if (!main || !main.available)
      return Color.mError;
    if (!main.serviceActive)
      return Color.mOnSurfaceVariant;
    if (main.period === "day")
      return Color.mPrimary;
    if (main.period === "night")
      return "#90caf9";
    if (main.period === "sunset")
      return "#ffb74d";
    if (main.period === "sunrise")
      return "#f48fb1";
    return "#ffcc80";
  }
  readonly property color hoverTextColor: "#000000"
  readonly property color baseTextColor: Color.mOnSurfaceVariant
  readonly property real infoChipWidth: Math.round(84 * Style.uiScaleRatio)
  readonly property string chipText: {
    if (!main)
      return "--";
    if (main.showLabelInBar)
      return String(main.activeShortLabel || "--");
    if (main.currentTemp > 0)
      return Math.round(main.currentTemp) + "K";
    if (main.targetTemp > 0)
      return Math.round(main.targetTemp) + "K";
    return "--";
  }
  readonly property string tooltipText: {
    if (!main)
      return "Sunsetr unavailable";
    if (!main.available)
      return main.lastError ? ("Sunsetr unavailable\n" + main.lastError) : "Sunsetr unavailable";
    var lines = [];
    lines.push("Preset: " + String(main.activePresetLabel || "Default"));
    if (main.manualOverride)
      lines.push("Scheduled: " + String(main.scheduledPresetLabel || "Default"));
    lines.push("State: " + (main.serviceActive ? "Running" : "Stopped") + " | " + String(main.period || "unknown"));
    if (main.currentTemp > 0)
      lines.push("Current: " + Math.round(main.currentTemp) + "K @ " + Number(main.currentGamma).toFixed(1) + "%");
    else if (main.targetTemp > 0)
      lines.push("Target: " + Math.round(main.targetTemp) + "K @ " + Number(main.targetGamma).toFixed(1) + "%");
    lines.push("Next: " + String(main.nextScheduledTime || "--:--") + " -> " + String(main.nextScheduledLabel || "Default"));
    lines.push("Right click: toggle bar details");
    lines.push("Middle click: apply auto preset");
    return lines.join("\n");
  }

  implicitWidth: iconOnly ? Style.capsuleHeight : row.implicitWidth + (Style.marginM * 2)
  implicitHeight: Style.capsuleHeight

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: mouse.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: !main ? Style.capsuleBorderColor : (main.available ? Qt.alpha(root.accentColor, 0.22) : Qt.alpha(Color.mError, 0.22))
    border.width: Style.capsuleBorderWidth
    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        icon: root.iconName
        applyUiScale: false
        pointSize: Style.fontSizeM
        color: mouse.containsMouse ? root.hoverTextColor : root.accentColor
      }

      Rectangle {
        visible: !root.iconOnly
        radius: Style.radiusM
        color: mouse.containsMouse ? Qt.alpha("#ffffff", 0.70) : Qt.alpha(root.accentColor, 0.12)
        border.color: mouse.containsMouse ? Qt.alpha(root.hoverTextColor, 0.16) : Qt.alpha(root.accentColor, 0.22)
        border.width: 1
        Layout.preferredHeight: Math.max(Style.capsuleHeight - 10, 18)
        Layout.preferredWidth: Math.max(root.infoChipWidth, chipLabel.implicitWidth + Style.marginM * 2)

        NText {
          id: chipLabel
          anchors.centerIn: parent
          text: root.chipText
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
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouseEvent) {
      if (!main)
        return;
      if (mouseEvent.button === Qt.MiddleButton) {
        main.applyAuto();
      } else if (mouseEvent.button === Qt.RightButton) {
        main.toggleIconOnlyInBar();
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
