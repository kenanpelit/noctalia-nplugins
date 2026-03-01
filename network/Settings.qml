import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property bool showLabelInBar: pluginApi && pluginApi.pluginSettings ? pluginApi.pluginSettings.showLabelInBar !== false : true
  property int watchdogInterval: {
    var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.watchdogInterval, 10) : NaN;
    return (isNaN(candidate) || candidate < 10000) ? 30000 : candidate;
  }
  property int maxVisibleNetworks: {
    var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.maxVisibleNetworks, 10) : NaN;
    return (isNaN(candidate) || candidate < 3) ? 6 : candidate;
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.pluginSettings.showLabelInBar = root.showLabelInBar;
    pluginApi.pluginSettings.watchdogInterval = root.watchdogInterval;
    pluginApi.pluginSettings.maxVisibleNetworks = root.maxVisibleNetworks;
    pluginApi.saveSettings();
    if (pluginApi.mainInstance) {
      pluginApi.mainInstance.queueRefresh();
    }
  }

  spacing: Style.marginM

  NLabel {
    Layout.fillWidth: true
    label: "Bar label"
    description: "Show the current network name and signal directly in the bar widget."
  }

  CheckBox {
    checked: root.showLabelInBar
    text: "Show label in bar"
    onToggled: root.showLabelInBar = checked
  }

  NLabel {
    Layout.fillWidth: true
    label: "Watchdog"
    description: "The plugin reacts to nmcli monitor events immediately. This timer is only a low-frequency fallback if an event is missed."
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    Slider {
      Layout.fillWidth: true
      from: 10000
      to: 120000
      stepSize: 5000
      value: root.watchdogInterval
      onMoved: root.watchdogInterval = Math.round(value)
      onValueChanged: root.watchdogInterval = Math.round(value)
    }

    NText {
      text: Math.round(root.watchdogInterval / 1000) + " s"
      color: Color.mSecondary
      pointSize: Style.fontSizeS
    }
  }

  NLabel {
    Layout.fillWidth: true
    label: "Visible Wi-Fi entries"
    description: "Limit how many nearby SSIDs are shown in the panel."
  }

  SpinBox {
    from: 3
    to: 12
    value: root.maxVisibleNetworks
    onValueChanged: root.maxVisibleNetworks = value
  }

  NButton {
    Layout.fillWidth: true
    text: "Save"
    icon: "device-floppy"
    onClicked: root.saveSettings()
  }
}
