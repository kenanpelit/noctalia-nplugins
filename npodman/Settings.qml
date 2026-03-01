import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    function resolveRefreshInterval() {
        var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.refreshInterval, 10) : NaN;
        return (isNaN(candidate) || candidate <= 0) ? 60000 : candidate;
    }

    property int refreshInterval: resolveRefreshInterval()

    function saveSettings() {
        if (!pluginApi) {
            return;
        }
        pluginApi.pluginSettings.refreshInterval = root.refreshInterval;
        pluginApi.saveSettings();
    }

    Component.onCompleted: {
        if (pluginApi && pluginApi.pluginSettings) {
            var candidate = parseInt(pluginApi.pluginSettings.refreshInterval, 10);
            if (isNaN(candidate) || candidate <= 0) {
                pluginApi.pluginSettings.refreshInterval = root.refreshInterval;
                pluginApi.saveSettings();
            }
        }
    }

    spacing: Style.marginM

    ListModel {
        id: intervalModel

        ListElement { name: "30 Seconds"; key: "30000" }
        ListElement { name: "60 Seconds"; key: "60000" }
        ListElement { name: "2 Minutes"; key: "120000" }
        ListElement { name: "5 Minutes"; key: "300000" }
    }

    NLabel {
        Layout.fillWidth: true
        label: "Fallback Watchdog"
        description: "NPodman now updates from podman events in real time. This timer is only a low-frequency fallback if the event stream stalls or a change is missed."
    }

    NComboBox {
        Layout.fillWidth: true
        model: intervalModel
        currentKey: String(root.refreshInterval)
        onSelected: root.refreshInterval = parseInt(key)
    }

    NButton {
        Layout.fillWidth: true
        text: "Save"
        icon: "device-floppy"
        onClicked: root.saveSettings()
    }
}
