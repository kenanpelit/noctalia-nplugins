import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property var ipMonitorService: pluginApi?.mainInstance?.ipMonitorService || null

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string iconColorKey: cfg.iconColor ?? defaults.iconColor
  readonly property string successIconKey: cfg.successIcon ?? defaults.successIcon ?? "network"
  readonly property string errorIconKey: cfg.errorIcon ?? defaults.errorIcon ?? "alert-circle"
  readonly property string loadingIconKey: cfg.loadingIcon ?? defaults.loadingIcon ?? "loader"
  // Read IP state from service (service is the source of truth)
  readonly property string currentIp: ipMonitorService?.currentIp ?? "n/a"
  readonly property var ipData: ipMonitorService?.ipData ?? null
  readonly property string fetchState: ipMonitorService?.fetchState ?? "idle"

  readonly property string currentIcon: {
    if (fetchState === "loading") return loadingIconKey;
    if (fetchState === "error") return errorIconKey;
    return successIconKey;
  }

  readonly property color accentColor: {
    if (fetchState === "error")
      return Color.mError;
    if (fetchState === "success")
      return Color.resolveColorKey(iconColorKey);
    return Color.mOnSurfaceVariant;
  }
  readonly property color hoverTextColor: "#000000"
  readonly property color borderColor: {
    if (fetchState === "error")
      return Qt.alpha(Color.mError, 0.22);
    if (fetchState === "success")
      return Qt.alpha(root.accentColor, 0.22);
    return Style.capsuleBorderColor;
  }

  implicitWidth: Style.capsuleHeight
  implicitHeight: Style.capsuleHeight

  onIpMonitorServiceChanged: {
    Logger.d("Nip", "BarWidget ipMonitorService changed:", ipMonitorService !== null);
  }
  
  onCurrentIpChanged: {
    Logger.d("Nip", "BarWidget currentIp changed to:", currentIp);
  }
  
  Component.onCompleted: {
    Logger.d("Nip", "BarWidget completed refresh");
  }

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: root.borderColor
    border.width: Style.capsuleBorderWidth
    Behavior on color { ColorAnimation { duration: 150 } }

    NIcon {
      anchors.centerIn: parent
      icon: root.currentIcon
      applyUiScale: false
      pointSize: Style.fontSizeM
      color: mouseArea.containsMouse ? root.hoverTextColor : root.accentColor
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
        return;
      }
      if (pluginApi) {
        pluginApi.openPanel(root.screen, root);
      }
    }

    onEntered: {
      var lines = [];
      lines.push("Left click: Open panel");
      lines.push("Right click: Menu");
      lines.push("");
      lines.push("IP: " + root.currentIp);
      if (root.fetchState === "success" && root.ipData) {
        var data = root.ipData;
        if (data.city || data.country) {
          var parts = [];
          if (data.city) parts.push(data.city);
          if (data.country) parts.push(data.country);
          lines.push(parts.join(", "));
        }
      }
      TooltipService.show(root, lines.join("\n"), BarService.getTooltipDirection(root.screen?.name));
    }

    onExited: TooltipService.hide()
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": "Copy IP",
        "action": "copy",
        "icon": "copy"
      },
      {
        "label": "Refresh IP",
        "action": "refresh",
        "icon": "refresh"
      },
      {
        "label": pluginApi?.tr("menu.settings"),
        "action": "settings",
        "icon": "settings"
      },
    ]

    onTriggered: function (action) {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "copy") {
        if (currentIp && currentIp !== "n/a") {
          Quickshell.execDetached(["sh", "-c", `printf '%s' '${currentIp}' | wl-copy`]);
          ToastService.showNotice("IP copied to clipboard: " + currentIp);
          Logger.d("Nip", "Copied IP to clipboard:", currentIp);
        } else {
          ToastService.showNotice("No IP to copy");
        }
      } else if (action === "refresh") {
        ipMonitorService.fetchIp();
      } else if (action === "settings") {
        BarService.openPluginSettings(root.screen, pluginApi.manifest);
      }
    }
  }
}
