import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.Panels.Settings
import qs.Services.UI
import qs.Widgets
import "." as Local

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

  readonly property string displayIp: ""
  readonly property bool isHot: fetchState === "success"

  // Bar position handling
  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"

  readonly property string currentIcon: {
    if (fetchState === "loading") return loadingIconKey;
    if (fetchState === "error") return errorIconKey;
    return successIconKey;
  }

  readonly property color iconColor: isHot ? Color.resolveColorKey(iconColorKey) : Color.mOnSurfaceVariant

  implicitWidth: pill.width
  implicitHeight: pill.height

  onIpMonitorServiceChanged: {
    Logger.d("Nip", "BarWidget ipMonitorService changed:", ipMonitorService !== null);
  }
  
  onCurrentIpChanged: {
    Logger.d("Nip", "BarWidget currentIp changed to:", currentIp);
  }
  
  Component.onCompleted: {
    Logger.d("Nip", "BarWidget completed refresh");
  }

  BarPill {
    id: pill
    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    icon: root.currentIcon
    text: root.displayIp
    rotateText: isVerticalBar
    forceOpen: false
    forceClose: true
    autoHide: false
    customTextIconColor: root.iconColor

    tooltipText: {
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
      return lines.join("\n");
    }

    onClicked: {
      // Open panel (displays cached IP data)
      if (pluginApi) {
        pluginApi.openPanel(root.screen, root);
      }
    }

    onRightClicked: {
      PanelService.showContextMenu(contextMenu, root, screen);
    }
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

