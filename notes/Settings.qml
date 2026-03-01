import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property bool showCountsInBar: pluginApi && pluginApi.pluginSettings ? pluginApi.pluginSettings.showCountsInBar !== false : true
  property int autosaveDelay: {
    var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.autosaveDelay, 10) : NaN;
    return (isNaN(candidate) || candidate < 300) ? 700 : candidate;
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.pluginSettings.showCountsInBar = root.showCountsInBar;
    pluginApi.pluginSettings.autosaveDelay = root.autosaveDelay;
    pluginApi.saveSettings();
    if (pluginApi.mainInstance) {
      pluginApi.mainInstance.showCountsInBar = root.showCountsInBar;
      pluginApi.mainInstance.autosaveDelay = root.autosaveDelay;
      pluginApi.mainInstance.persist();
    }
  }

  spacing: Style.marginM

  NLabel {
    Layout.fillWidth: true
    label: "Bar summary"
    description: "Show active task and note counts directly in the bar capsule."
  }

  CheckBox {
    checked: root.showCountsInBar
    text: "Show counts in bar"
    onToggled: root.showCountsInBar = checked
  }

  NLabel {
    Layout.fillWidth: true
    label: "Scratchpad autosave"
    description: "Delay before scratchpad edits are persisted. Lower is more immediate; higher avoids noisy writes."
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    Slider {
      Layout.fillWidth: true
      from: 300
      to: 2000
      stepSize: 100
      value: root.autosaveDelay
      onMoved: root.autosaveDelay = Math.round(value)
      onValueChanged: root.autosaveDelay = Math.round(value)
    }

    NText {
      text: root.autosaveDelay + " ms"
      color: Color.mSecondary
      pointSize: Style.fontSizeS
    }
  }

  NButton {
    Layout.fillWidth: true
    text: "Save"
    icon: "device-floppy"
    onClicked: root.saveSettings()
  }
}
