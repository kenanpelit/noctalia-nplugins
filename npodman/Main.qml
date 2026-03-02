import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    function withCurrentScreenOrPrimary(callback) {
        if (!callback)
            return;

        if (pluginApi && pluginApi.withCurrentScreen) {
            pluginApi.withCurrentScreen(callback);
            return;
        }

        if (Quickshell.screens.length > 0)
            callback(Quickshell.screens[0]);
    }

    function openPanelUi() {
        withCurrentScreenOrPrimary(function(screen) {
            if (pluginApi && pluginApi.openPanel)
                pluginApi.openPanel(screen, null);
        });
    }

    function closePanelUi() {
        withCurrentScreenOrPrimary(function(screen) {
            if (pluginApi && pluginApi.closePanel)
                pluginApi.closePanel(screen);
        });
    }

    function togglePanelUi() {
        withCurrentScreenOrPrimary(function(screen) {
            if (pluginApi && pluginApi.togglePanel)
                pluginApi.togglePanel(screen, null);
        });
    }

    function openSettingsUi() {
        withCurrentScreenOrPrimary(function(screen) {
            if (pluginApi && pluginApi.manifest)
                BarService.openPluginSettings(screen, pluginApi.manifest);
        });
    }

    IpcHandler {
        target: "plugin:npodman"

        function openPanel() {
            root.openPanelUi();
        }

        function closePanel() {
            root.closePanelUi();
        }

        function togglePanel() {
            root.togglePanelUi();
        }

        function toggle() {
            root.togglePanelUi();
        }

        function panel() {
            root.togglePanelUi();
        }

        function openSettings() {
            root.openSettingsUi();
        }
    }
}
