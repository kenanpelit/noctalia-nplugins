import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property int watchdogInterval: 20000
  property int tempStep: 150
  property int gammaStep: 2
  property bool showLabelInBar: false
  property bool iconOnlyInBar: false

  Component.onCompleted: syncFromSettings()
  onPluginApiChanged: syncFromSettings()

  function syncFromSettings() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    var settings = pluginApi.pluginSettings;
    var parsedWatchdog = parseInt(settings.watchdogInterval, 10);
    watchdogInterval = (isNaN(parsedWatchdog) || parsedWatchdog < 5000) ? 20000 : parsedWatchdog;
    var parsedTempStep = parseInt(settings.tempStep, 10);
    tempStep = (isNaN(parsedTempStep) || parsedTempStep < 50) ? 150 : parsedTempStep;
    var parsedGammaStep = parseInt(settings.gammaStep, 10);
    gammaStep = (isNaN(parsedGammaStep) || parsedGammaStep < 1) ? 2 : parsedGammaStep;
    showLabelInBar = settings.showLabelInBar === true;
    iconOnlyInBar = settings.iconOnlyInBar === true;
  }

  function save() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;

    pluginApi.pluginSettings.watchdogInterval = watchdogInterval;
    pluginApi.pluginSettings.tempStep = tempStep;
    pluginApi.pluginSettings.gammaStep = gammaStep;
    pluginApi.pluginSettings.showLabelInBar = showLabelInBar;
    pluginApi.pluginSettings.iconOnlyInBar = iconOnlyInBar;
    pluginApi.saveSettings();
    if (pluginApi.mainInstance)
      pluginApi.mainInstance.syncPluginSettings();
  }

  spacing: Style.marginM

  NLabel {
    Layout.fillWidth: true
    label: "NSunsetr"
    description: "Panel control, bar presentation, and quick action tuning."
  }

  NLabel {
    Layout.fillWidth: true
    label: "Refresh Interval"
    description: "Background state polling cadence. Higher values reduce backend churn."
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    Slider {
      Layout.fillWidth: true
      from: 5000
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
    label: "Temperature Step"
    description: "How much each warmer/cooler action changes the current color temperature."
  }

  SpinBox {
    from: 50
    to: 1000
    stepSize: 25
    value: root.tempStep
    onValueChanged: root.tempStep = value
  }

  NLabel {
    Layout.fillWidth: true
    label: "Gamma Step"
    description: "How much each gamma action changes the current gamma percentage."
  }

  SpinBox {
    from: 1
    to: 20
    stepSize: 1
    value: root.gammaStep
    onValueChanged: root.gammaStep = value
  }

  NLabel {
    Layout.fillWidth: true
    label: "Bar Label"
    description: "Use the preset label instead of live Kelvin in the bar chip."
  }

  CheckBox {
    checked: root.showLabelInBar
    text: "Show preset label in bar"
    onToggled: root.showLabelInBar = checked
  }

  NLabel {
    Layout.fillWidth: true
    label: "Icon-Only Start Mode"
    description: "Begin with only the bar icon visible. You can also double-click the widget to toggle this live."
  }

  CheckBox {
    checked: root.iconOnlyInBar
    text: "Start in icon-only mode"
    onToggled: root.iconOnlyInBar = checked
  }

  NButton {
    Layout.fillWidth: true
    text: "Save"
    icon: "device-floppy"
    onClicked: root.save()
  }
}
