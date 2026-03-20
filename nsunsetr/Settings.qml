import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property string watchdogText: "20000"
  property string tempStepText: "150"
  property string gammaStepText: "2"
  property bool showLabelInBar: false
  property bool iconOnlyInBar: false

  Component.onCompleted: syncFromSettings()
  onPluginApiChanged: syncFromSettings()

  function syncFromSettings() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    var settings = pluginApi.pluginSettings;
    watchdogText = settings.watchdogInterval === undefined ? "20000" : String(settings.watchdogInterval);
    tempStepText = settings.tempStep === undefined ? "150" : String(settings.tempStep);
    gammaStepText = settings.gammaStep === undefined ? "2" : String(settings.gammaStep);
    showLabelInBar = settings.showLabelInBar === true;
    iconOnlyInBar = settings.iconOnlyInBar === true;
  }

  function save() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;

    var watchdog = parseInt(watchdogText, 10);
    if (isNaN(watchdog) || watchdog < 5000)
      watchdog = 20000;

    var tempStep = parseInt(tempStepText, 10);
    if (isNaN(tempStep) || tempStep < 50)
      tempStep = 150;

    var gammaStep = parseInt(gammaStepText, 10);
    if (isNaN(gammaStep) || gammaStep < 1)
      gammaStep = 2;

    pluginApi.pluginSettings.watchdogInterval = watchdog;
    pluginApi.pluginSettings.tempStep = tempStep;
    pluginApi.pluginSettings.gammaStep = gammaStep;
    pluginApi.pluginSettings.showLabelInBar = showLabelInBar;
    pluginApi.pluginSettings.iconOnlyInBar = iconOnlyInBar;
    pluginApi.saveSettings();

    watchdogText = String(watchdog);
    tempStepText = String(tempStep);
    gammaStepText = String(gammaStep);
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginL

    NLabel {
      Layout.fillWidth: true
      label: "NSunsetr"
      description: "Panel control, bar presentation, and quick action tuning."
    }

    NTextInput {
      Layout.fillWidth: true
      label: "Refresh Interval (ms)"
      description: "Background state polling cadence. Higher values reduce backend churn."
      placeholderText: "20000"
      text: root.watchdogText
      inputMethodHints: Qt.ImhDigitsOnly
      onTextChanged: root.watchdogText = text
    }

    NTextInput {
      Layout.fillWidth: true
      label: "Temperature Step (K)"
      description: "How much each warmer/cooler action changes the current color temperature."
      placeholderText: "150"
      text: root.tempStepText
      inputMethodHints: Qt.ImhDigitsOnly
      onTextChanged: root.tempStepText = text
    }

    NTextInput {
      Layout.fillWidth: true
      label: "Gamma Step (%)"
      description: "How much each gamma action changes the current gamma percentage."
      placeholderText: "2"
      text: root.gammaStepText
      inputMethodHints: Qt.ImhDigitsOnly
      onTextChanged: root.gammaStepText = text
    }

    NToggle {
      label: "Show Preset Label In Bar"
      description: "Use the preset label instead of live Kelvin in the bar chip."
      checked: root.showLabelInBar
      onToggled: checked => root.showLabelInBar = checked
    }

    NToggle {
      label: "Start In Icon-Only Mode"
      description: "Begin with only the bar icon visible. You can also double-click the widget to toggle this live."
      checked: root.iconOnlyInBar
      onToggled: checked => root.iconOnlyInBar = checked
    }

    NButton {
      Layout.fillWidth: true
      text: "Save"
      icon: "device-floppy"
      onClicked: root.save()
    }
  }
}
