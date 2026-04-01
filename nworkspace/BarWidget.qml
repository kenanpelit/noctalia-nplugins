import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Compositor
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property var main: pluginApi ? pluginApi.mainInstance : null
  readonly property var rows: main ? main.visibleRowsForScreen(screen?.name || "") : []
  readonly property real capsuleHeight: Style.capsuleHeight
  readonly property real horizontalPadding: Style.marginS
  readonly property real spacingBetweenPills: Style.marginXS
  readonly property real visualPillHeight: Style.toOdd(Math.max(14, capsuleHeight * (main && main.compact ? 0.62 : 0.74)))
  readonly property real visualPillRadius: Style.radiusM
  readonly property real previewDotSize: Math.max(5, Math.round(Style.marginS * 0.65))
  property var selectedWorkspace: null

  implicitWidth: workspaceBackground.implicitWidth
  implicitHeight: workspaceBackground.implicitHeight

  function tooltipFor(workspace) {
    var lines = [];
    lines.push(workspace.fullLabel || workspace.label);
    lines.push("Output: " + (workspace.output || "Unknown"));
    lines.push("Windows: " + workspace.windowCount);
    if (workspace.isFocused)
      lines.push("Focused workspace");
    else if (workspace.isActive)
      lines.push("Visible on monitor");
    if (workspace.isUrgent)
      lines.push("Urgent activity");
    if (workspace.windows && workspace.windows.length > 0) {
      lines.push("");
      for (var i = 0; i < workspace.windows.length; ++i) {
        var win = workspace.windows[i];
        var title = String(win.title || "").trim();
        var app = CompositorService.getCleanAppName(win.appId, title);
        lines.push("• " + app + (title ? " — " + title : ""));
      }
    }
    return lines.join("\n");
  }

  function pillWidth(workspace) {
    var dimension = visualPillHeight;
    var active = !!workspace.isFocused || !!workspace.isActive;
    var showsIndex = showIndexLabel(workspace);
    var showsName = showNameLabel(workspace);
    var base = active ? dimension * 1.28 : dimension * 0.92;
    var extra = 0;
    if (showsIndex)
      extra += dimension * 0.95;
    if (showsName)
      extra += Math.max(dimension * 0.86, String(workspace.shortName || "").length * (dimension * (showsIndex ? 0.34 : 0.42)));
    if (showsIndex && showsName)
      extra += dimension * 0.22;
    if (main && main.showOutputName)
      extra += dimension * 0.85;
    if (main && main.showWindowCount && workspace.windowCount > 0)
      extra += dimension * 0.95;
    if (main && main.showPreviewDots && workspace.previewTokens.length > 0)
      extra += workspace.previewTokens.length * (previewDotSize + 2);
    return Style.toOdd(Math.max(base, Math.round(base + extra)));
  }

  function showIndexLabel(workspace) {
    if (!main)
      return true;
    if (main.labelMode === "name")
      return !workspace.shortName;
    return true;
  }

  function showNameLabel(workspace) {
    if (!main)
      return !!workspace.shortName;
    if (main.labelMode === "index")
      return false;
    return !!workspace.shortName;
  }

  function pillColor(workspace, hovered) {
    if (hovered)
      return Color.mHover;
    if (workspace.isFocused)
      return Color.mPrimary;
    if (workspace.isUrgent)
      return Color.mError;
    if (workspace.windowCount > 0)
      return Color.mSecondary;
    return Qt.alpha(Color.mSecondary, 0.30);
  }

  function pillTextColor(workspace, hovered) {
    if (hovered)
      return Color.mOnHover;
    if (workspace.isFocused)
      return Color.mOnPrimary;
    if (workspace.isUrgent)
      return Color.mOnError;
    if (workspace.windowCount > 0)
      return Color.mOnSecondary;
    return Color.mOnSecondary;
  }

  function accentChipColor(workspace, hovered) {
    return Qt.alpha(pillTextColor(workspace, hovered), workspace.isFocused ? 0.22 : 0.15);
  }

  function secondaryTextColor(workspace, hovered) {
    return Qt.alpha(pillTextColor(workspace, hovered), workspace.isFocused ? 0.96 : 0.78);
  }

  Rectangle {
    id: workspaceBackground
    implicitWidth: pillRow.implicitWidth + horizontalPadding * 2
    implicitHeight: capsuleHeight
    width: implicitWidth
    height: implicitHeight
    radius: Style.radiusM
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Row {
      id: pillRow
      anchors.left: parent.left
      anchors.leftMargin: horizontalPadding
      anchors.verticalCenter: parent.verticalCenter
      spacing: spacingBetweenPills

      Repeater {
        model: root.rows

        delegate: Item {
          required property var modelData
          readonly property var workspace: modelData
          width: root.pillWidth(workspace)
          height: root.capsuleHeight

          Rectangle {
            id: pill
            width: parent.width
            height: root.visualPillHeight
            anchors.centerIn: parent
            radius: root.visualPillRadius
            color: root.pillColor(workspace, mouseArea.containsMouse)

            Row {
              anchors.centerIn: parent
              spacing: 2

              Rectangle {
                visible: main && main.showOutputName
                width: Math.max(10, Math.round(root.visualPillHeight * 0.58))
                height: width
                radius: width / 2
                color: Qt.alpha(root.pillTextColor(workspace, mouseArea.containsMouse), 0.18)

                NText {
                  anchors.centerIn: parent
                  text: String(workspace.output || "?").substring(0, 1).toUpperCase()
                  pointSize: root.visualPillHeight * 0.25
                  applyUiScale: false
                  font.weight: Font.Bold
                  color: root.pillTextColor(workspace, mouseArea.containsMouse)
                }
              }

              Rectangle {
                visible: root.showIndexLabel(workspace)
                anchors.verticalCenter: parent.verticalCenter
                radius: height / 2
                color: root.accentChipColor(workspace, mouseArea.containsMouse)
                border.color: Qt.alpha(root.pillTextColor(workspace, mouseArea.containsMouse), workspace.isFocused ? 0.12 : 0.06)
                border.width: 1
                implicitHeight: Math.max(14, Math.round(root.visualPillHeight * (root.showNameLabel(workspace) ? 0.60 : 0.68)))
                implicitWidth: indexText.implicitWidth + (root.showNameLabel(workspace) ? Style.marginS : Style.marginM)

                NText {
                  id: indexText
                  anchors.centerIn: parent
                  text: workspace.indexLabel
                  family: Settings.data.ui.fontFixed
                  pointSize: root.visualPillHeight * (root.showNameLabel(workspace) ? 0.30 : 0.36)
                  applyUiScale: false
                  font.weight: Font.Bold
                  color: root.pillTextColor(workspace, mouseArea.containsMouse)
                }
              }

              Rectangle {
                visible: root.showIndexLabel(workspace) && root.showNameLabel(workspace)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(4, Math.round(root.previewDotSize * 0.72))
                height: width
                radius: width / 2
                color: Qt.alpha(root.pillTextColor(workspace, mouseArea.containsMouse), 0.28)
              }

              NText {
                visible: root.showNameLabel(workspace)
                anchors.verticalCenter: parent.verticalCenter
                text: workspace.shortName
                pointSize: root.visualPillHeight * (root.showIndexLabel(workspace) ? 0.32 : 0.42)
                applyUiScale: false
                font.weight: workspace.isFocused ? Font.DemiBold : Font.Medium
                color: root.showIndexLabel(workspace)
                       ? root.secondaryTextColor(workspace, mouseArea.containsMouse)
                       : root.pillTextColor(workspace, mouseArea.containsMouse)
              }

              Row {
                visible: main && main.showPreviewDots && workspace.previewTokens.length > 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Repeater {
                  model: workspace.previewTokens
                  delegate: Rectangle {
                    required property var modelData
                    width: root.previewDotSize
                    height: root.previewDotSize
                    radius: width / 2
                    color: Qt.alpha(root.pillTextColor(workspace, mouseArea.containsMouse), 0.82)

                    NText {
                      anchors.centerIn: parent
                      text: String(modelData || "")
                      pointSize: root.previewDotSize * 0.52
                      applyUiScale: false
                      font.weight: Font.Bold
                      color: root.pillColor(workspace, mouseArea.containsMouse)
                    }
                  }
                }
              }

              Rectangle {
                visible: main && main.showWindowCount && workspace.windowCount > 0
                anchors.verticalCenter: parent.verticalCenter
                radius: height / 2
                color: Qt.alpha(root.pillTextColor(workspace, mouseArea.containsMouse), 0.16)
                implicitHeight: Math.max(14, Math.round(root.visualPillHeight * 0.62))
                implicitWidth: countText.implicitWidth + Style.marginS

                NText {
                  id: countText
                  anchors.centerIn: parent
                  text: String(workspace.windowCount)
                  pointSize: root.visualPillHeight * 0.26
                  applyUiScale: false
                  font.weight: Font.Bold
                  color: root.pillTextColor(workspace, mouseArea.containsMouse)
                }
              }
            }
          }

          MouseArea {
            id: mouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: function(mouse) {
              if (mouse.button === Qt.RightButton) {
                root.selectedWorkspace = workspace;
                PanelService.showContextMenu(contextMenu, parent, root.screen);
                return;
              }
              if (mouse.button === Qt.MiddleButton) {
                if (pluginApi)
                  pluginApi.openPanel(root.screen, parent);
                return;
              }
              CompositorService.switchToWorkspace(workspace);
            }

            onEntered: TooltipService.show(parent, root.tooltipFor(workspace), BarService.getTooltipDirection(root.screen?.name))
            onExited: TooltipService.hide()
          }
        }
      }
    }
  }

  WheelHandler {
    target: null
    enabled: !!main
    onWheel: function(event) {
      if (!main)
        return;
      main.switchWorkspaceByOffset(root.screen?.name || "", event.angleDelta.y > 0 ? -1 : 1);
      event.accepted = true;
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": "Open Workspace Panel",
        "action": "panel",
        "icon": "layout-grid"
      },
      {
        "label": "Focus This Workspace",
        "action": "focus",
        "icon": "arrow-right"
      },
      {
        "label": "Cycle Label Mode",
        "action": "labelMode",
        "icon": "apps"
      },
      {
        "label": (main && main.hideEmpty) ? "Show Empty Workspaces" : "Hide Empty Workspaces",
        "action": "hideEmpty",
        "icon": "filter"
      },
      {
        "label": (main && main.followFocusedOutput) ? "Pin To This Bar Output" : "Follow Focused Output",
        "action": "followOutput",
        "icon": "monitor"
      },
      {
        "label": "Settings",
        "action": "settings",
        "icon": "settings"
      }
    ]

    onTriggered: function(action) {
      contextMenu.close();
      PanelService.closeContextMenu(root.screen);

      if (action === "panel") {
        pluginApi?.openPanel(root.screen, root);
      } else if (action === "focus" && root.selectedWorkspace) {
        CompositorService.switchToWorkspace(root.selectedWorkspace);
      } else if (action === "labelMode" && main) {
        main.cycleLabelMode();
      } else if (action === "hideEmpty" && main) {
        main.setSetting("hideEmpty", !main.hideEmpty);
      } else if (action === "followOutput" && main) {
        main.setSetting("followFocusedOutput", !main.followFocusedOutput);
      } else if (action === "settings" && pluginApi) {
        BarService.openPluginSettings(root.screen, pluginApi.manifest);
      }
    }
  }
}
