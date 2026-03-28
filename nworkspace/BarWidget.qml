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
  readonly property real pillHeight: Style.capsuleHeight
  readonly property real pillRadius: Style.radiusL
  readonly property real previewDotSize: Math.max(6, Math.round(Style.marginS * 0.75))
  property var selectedWorkspace: null

  implicitWidth: container.implicitWidth
  implicitHeight: container.implicitHeight

  function tooltipFor(workspace) {
    var lines = [];
    lines.push(workspace.label);
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
    var base = main && main.compact ? 44 : 54;
    var extra = Math.max(0, String(workspace.label || "").length - 1) * (main && main.compact ? 6 : 8);
    if (main && main.showOutputName)
      extra += 18;
    if (main && main.showWindowCount && workspace.windowCount > 0)
      extra += 16;
    if (main && main.showPreviewDots && workspace.previewTokens.length > 0)
      extra += workspace.previewTokens.length * (previewDotSize + 3);
    return Math.max(base, Math.round((base + extra) * Style.uiScaleRatio));
  }

  RowLayout {
    id: container
    spacing: Style.marginXS

    Repeater {
      model: root.rows

      delegate: Rectangle {
        required property var modelData
        readonly property var workspace: modelData

        Layout.preferredWidth: root.pillWidth(workspace)
        Layout.preferredHeight: root.pillHeight
        radius: root.pillRadius
        color: {
          if (mouseArea.containsMouse)
            return Color.mHover;
          if (workspace.isFocused)
            return Qt.alpha(Color.mPrimary, 0.92);
          if (workspace.isUrgent)
            return Qt.alpha(Color.mError, 0.85);
          if (workspace.windowCount > 0)
            return Qt.alpha(Color.mSurfaceVariant, 0.88);
          return Qt.alpha(Color.mSurfaceVariant, 0.42);
        }
        border.color: workspace.isFocused
                        ? Qt.alpha(Color.mPrimary, 0.35)
                        : Qt.alpha(workspace.isUrgent ? Color.mError : Color.mOutline, 0.18)
        border.width: Style.capsuleBorderWidth

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: main && main.compact ? Style.marginS : Style.marginM
          anchors.rightMargin: main && main.compact ? Style.marginS : Style.marginM
          spacing: Style.marginXS

          Rectangle {
            visible: main && main.showOutputName
            Layout.preferredWidth: Math.max(12, Math.round(Style.fontSizeXS * 1.6))
            Layout.preferredHeight: Math.max(12, Math.round(Style.fontSizeXS * 1.6))
            radius: width / 2
            color: Qt.alpha(workspace.isFocused ? Color.mOnPrimary : Color.mPrimary, workspace.isFocused ? 0.18 : 0.14)

            NText {
              anchors.centerIn: parent
              text: String(workspace.output || "?").substring(0, 1).toUpperCase()
              pointSize: Style.fontSizeXXS
              font.weight: Font.Bold
              color: workspace.isFocused ? Color.mOnPrimary : Color.mPrimary
            }
          }

          NText {
            Layout.fillWidth: true
            text: workspace.label
            pointSize: main && main.compact ? Style.fontSizeXS : Style.barFontSize
            font.weight: workspace.isFocused ? Font.Bold : Font.Medium
            color: {
              if (mouseArea.containsMouse)
                return "#000000";
              if (workspace.isFocused)
                return Color.mOnPrimary;
              if (workspace.isUrgent)
                return Color.mOnError;
              return Color.mOnSurface;
            }
            elide: Text.ElideRight
          }

          RowLayout {
            visible: main && main.showPreviewDots && workspace.previewTokens.length > 0
            spacing: 3

            Repeater {
              model: workspace.previewTokens
              delegate: Rectangle {
                required property var modelData
                Layout.preferredWidth: root.previewDotSize
                Layout.preferredHeight: root.previewDotSize
                radius: width / 2
                color: workspace.isFocused ? Qt.alpha(Color.mOnPrimary, 0.85) : Qt.alpha(Color.mPrimary, 0.65)

                NText {
                  anchors.centerIn: parent
                  text: String(modelData || "")
                  pointSize: Style.fontSizeXXS * 0.82
                  font.weight: Font.Bold
                  color: workspace.isFocused ? Color.mPrimary : Color.mOnPrimary
                }
              }
            }
          }

          Rectangle {
            visible: main && main.showWindowCount && workspace.windowCount > 0
            radius: height / 2
            color: workspace.isFocused ? Qt.alpha(Color.mOnPrimary, 0.18) : Qt.alpha(Color.mPrimary, 0.14)
            border.color: workspace.isFocused ? Qt.alpha(Color.mOnPrimary, 0.18) : Qt.alpha(Color.mPrimary, 0.18)
            border.width: 1
            implicitHeight: Math.max(18, Math.round((main && main.compact ? 18 : 20) * Style.uiScaleRatio))
            implicitWidth: countText.implicitWidth + Style.marginM

            NText {
              id: countText
              anchors.centerIn: parent
              text: String(workspace.windowCount)
              pointSize: Style.fontSizeXXS
              font.weight: Font.Bold
              color: workspace.isFocused ? Color.mOnPrimary : Color.mPrimary
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
