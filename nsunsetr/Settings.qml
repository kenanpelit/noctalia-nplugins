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
  }

  function save() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;

    pluginApi.pluginSettings.watchdogInterval = watchdogInterval;
    pluginApi.pluginSettings.tempStep = tempStep;
    pluginApi.pluginSettings.gammaStep = gammaStep;
    pluginApi.pluginSettings.showLabelInBar = showLabelInBar;
    pluginApi.saveSettings();
    if (pluginApi.mainInstance)
      pluginApi.mainInstance.syncPluginSettings();
  }

  spacing: Style.marginM

  NLabel {
    Layout.fillWidth: true
    label: "NSunsetr"
    description: "Simple controls for refresh cadence, quick-action step sizes, and what the expanded bar chip shows."
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
    description: "When you expand the bar widget with a double-click, show the preset label instead of live Kelvin."
  }

  CheckBox {
    checked: root.showLabelInBar
    text: "Show preset label in bar"
    onToggled: root.showLabelInBar = checked
  }

  NLabel {
    Layout.fillWidth: true
    label: "Bar Behavior"
    description: "The widget starts as icon-only by default. Double-click the widget to show or hide the value chip."
  }

  NButton {
    Layout.fillWidth: true
    text: "Save"
    icon: "device-floppy"
    onClicked: root.save()
  }
}
