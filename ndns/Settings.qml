import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property string oscCommand: "osc-mullvad"
    property string watchdogText: "30000"

    Component.onCompleted: syncFromSettings()
    onPluginApiChanged: syncFromSettings()

    function syncFromSettings() {
        var settings = pluginApi?.pluginSettings || ({});
        var defaults = pluginApi?.manifest?.metadata?.defaultSettings || ({});
        var parsed = parseInt(settings.watchdogInterval ?? defaults.watchdogInterval ?? 30000, 10);
        oscCommand = String(settings.oscCommand ?? defaults.oscCommand ?? "osc-mullvad");
        watchdogText = (isNaN(parsed) || parsed < 10000) ? "30000" : String(parsed);
    }

    spacing: Style.marginL

    NLabel {
        label: "NDNS"
        description: "Panel control and backend command settings."
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Backend Command"
        description: "Executable used for Mullvad / Blocky switching."
        placeholderText: "osc-mullvad"
        text: root.oscCommand
        onTextChanged: root.oscCommand = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Refresh Interval (ms)"
        description: "Background state polling cadence. Higher values reduce backend churn."
        placeholderText: "30000"
        text: root.watchdogText
        onTextChanged: root.watchdogText = text
    }

    RowLayout {
        spacing: Style.marginM

        NButton {
            text: "Toggle Panel"
            onClicked: {
                if (pluginApi && pluginApi.withCurrentScreen) {
                    pluginApi.withCurrentScreen(function(screen) {
                        pluginApi.togglePanel(screen, null);
                    });
                }
            }
        }

        NButton {
            text: "Sync / Repair"
            onClicked: {
                if (pluginApi && pluginApi.mainInstance) {
                    pluginApi.mainInstance.runAction("repair");
                }
            }
        }

        NButton {
            text: "Save"
            icon: "device-floppy"
            onClicked: root.saveSettings()
        }
    }

    function saveSettings() {
        if (!pluginApi) {
            return;
        }

        var parsed = parseInt(root.watchdogText, 10);
        if (isNaN(parsed) || parsed < 10000) {
            parsed = 30000;
        }

        pluginApi.pluginSettings.oscCommand = root.oscCommand || "osc-mullvad";
        pluginApi.pluginSettings.watchdogInterval = parsed;
        pluginApi.saveSettings();
        root.watchdogText = String(parsed);

        if (pluginApi.withCurrentScreen) {
            pluginApi.withCurrentScreen(function(screen) {
                pluginApi.closePanel(screen);
            });
        }
    }
}
