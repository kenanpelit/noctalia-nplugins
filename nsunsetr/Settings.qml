import QtQuick
import QtQuick.Controls
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

    NText {
      text: "NSunsetr Settings"
      font.pointSize: Style.fontSizeL * Style.uiScaleRatio
      font.weight: Font.Bold
    }

    NText {
      text: "Tune how often the plugin refreshes and how much each quick action changes color temperature or gamma."
      wrapMode: Text.Wrap
      color: Color.mOnSurfaceVariant
      Layout.fillWidth: true
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      ColumnLayout {
        Layout.fillWidth: true

        NText {
          text: "Refresh interval (ms)"
          color: Color.mOnSurface
        }

        TextField {
          Layout.fillWidth: true
          text: root.watchdogText
          placeholderText: "20000"
          inputMethodHints: Qt.ImhDigitsOnly
          onTextChanged: root.watchdogText = text
        }
      }

      ColumnLayout {
        Layout.fillWidth: true

        NText {
          text: "Temp step (K)"
          color: Color.mOnSurface
        }

        TextField {
          Layout.fillWidth: true
          text: root.tempStepText
          placeholderText: "150"
          inputMethodHints: Qt.ImhDigitsOnly
          onTextChanged: root.tempStepText = text
        }
      }

      ColumnLayout {
        Layout.fillWidth: true

        NText {
          text: "Gamma step (%)"
          color: Color.mOnSurface
        }

        TextField {
          Layout.fillWidth: true
          text: root.gammaStepText
          placeholderText: "2"
          inputMethodHints: Qt.ImhDigitsOnly
          onTextChanged: root.gammaStepText = text
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      Switch {
        checked: root.showLabelInBar
        onToggled: root.showLabelInBar = checked
      }

      NText {
        text: "Show preset label in the bar instead of live Kelvin"
        color: Color.mOnSurface
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      Switch {
        checked: root.iconOnlyInBar
        onToggled: root.iconOnlyInBar = checked
      }

      NText {
        text: "Start the bar widget in icon-only mode"
        color: Color.mOnSurface
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }
    }

    NButton {
      text: "Save"
      icon: "device-floppy"
      onClicked: root.save()
    }
  }
}
