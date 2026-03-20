import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property int watchdogInterval: 20000
  property int tempStep: 150
  property int gammaStep: 2
  property bool showLabelInBar: false

  implicitWidth: Math.round(760 * Style.uiScaleRatio)
  implicitHeight: content.implicitHeight + (Style.marginXL * 2)

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

  function saveSettings() {
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

  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.margins: Style.marginXL
    spacing: Style.marginL

    NLabel {
      Layout.fillWidth: true
      label: "NSunsetr"
      description: "Readable controls for bar behavior and color adjustment steps."
    }

    NBox {
      Layout.fillWidth: true
      implicitHeight: barCard.implicitHeight + (Style.marginL * 2)

      ColumnLayout {
        id: barCard
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        NLabel {
          Layout.fillWidth: true
          label: "Bar Behavior"
          description: "The widget starts as icon-only. Double-click the widget to show or hide the value chip."
        }

        CheckBox {
          Layout.fillWidth: true
          checked: root.showLabelInBar
          text: "When expanded, show preset label instead of live Kelvin"
          onToggled: root.showLabelInBar = checked
        }
      }
    }

    NBox {
      Layout.fillWidth: true
      implicitHeight: refreshCard.implicitHeight + (Style.marginL * 2)

      ColumnLayout {
        id: refreshCard
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        NLabel {
          Layout.fillWidth: true
          label: "Refresh Interval"
          description: "Fallback polling cadence for sunsetr state."
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          Slider {
            Layout.fillWidth: true
            from: 5000
            to: 120000
            stepSize: 5000
            value: root.watchdogInterval
            onMoved: root.watchdogInterval = Math.round(value)
            onValueChanged: root.watchdogInterval = Math.round(value)
          }

          Rectangle {
            radius: Style.radiusS
            color: Qt.alpha(Color.mPrimary, 0.12)
            border.color: Qt.alpha(Color.mPrimary, 0.20)
            border.width: 1
            implicitWidth: refreshValue.implicitWidth + (Style.marginM * 2)
            implicitHeight: refreshValue.implicitHeight + (Style.marginS * 2)

            NText {
              id: refreshValue
              anchors.centerIn: parent
              text: Math.round(root.watchdogInterval / 1000) + " s"
              color: Color.mPrimary
              font.weight: Font.Medium
            }
          }
        }
      }
    }

    NBox {
      Layout.fillWidth: true
      implicitHeight: stepsCard.implicitHeight + (Style.marginL * 2)

      ColumnLayout {
        id: stepsCard
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        NLabel {
          Layout.fillWidth: true
          label: "Adjustment Steps"
          description: "Control how much the warmer/cooler and gamma actions change on each click."
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NText {
              text: "Temperature Step"
              color: Color.mOnSurface
              font.weight: Font.Medium
            }

            Slider {
              Layout.fillWidth: true
              from: 50
              to: 1000
              stepSize: 25
              value: root.tempStep
              onMoved: root.tempStep = Math.round(value)
              onValueChanged: root.tempStep = Math.round(value)
            }

            NText {
              text: root.tempStep + " K"
              color: Color.mSecondary
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NText {
              text: "Gamma Step"
              color: Color.mOnSurface
              font.weight: Font.Medium
            }

            Slider {
              Layout.fillWidth: true
              from: 1
              to: 20
              stepSize: 1
              value: root.gammaStep
              onMoved: root.gammaStep = Math.round(value)
              onValueChanged: root.gammaStep = Math.round(value)
            }

            NText {
              text: root.gammaStep + " %"
              color: Color.mSecondary
            }
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.topMargin: Style.marginS
      spacing: Style.marginM

      Item {
        Layout.fillWidth: true
      }

      NButton {
        text: "Save"
        icon: "device-floppy"
        onClicked: root.saveSettings()
      }
    }
  }
}
