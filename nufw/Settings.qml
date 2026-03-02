import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property string watchdogText: "12000"

  Component.onCompleted: syncFromSettings()
  onPluginApiChanged: syncFromSettings()

  function syncFromSettings() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    var value = pluginApi.pluginSettings.watchdogInterval;
    watchdogText = value === undefined ? "12000" : String(value);
  }

  function save() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    var parsed = parseInt(watchdogText, 10);
    if (isNaN(parsed) || parsed < 5000)
      parsed = 12000;
    pluginApi.pluginSettings.watchdogInterval = parsed;
    pluginApi.saveSettings();
    watchdogText = String(parsed);
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginL

    NText {
      text: "NUFW Settings"
      font.pointSize: Style.fontSizeL * Style.uiScaleRatio
      font.weight: Font.Bold
    }

    NText {
      text: "Refresh cadence for reading UFW state. Lower values update faster but probe the firewall more often."
      wrapMode: Text.Wrap
      color: Color.mOnSurfaceVariant
      Layout.fillWidth: true
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      TextField {
        Layout.fillWidth: true
        text: root.watchdogText
        placeholderText: "12000"
        inputMethodHints: Qt.ImhDigitsOnly
        onTextChanged: root.watchdogText = text
      }

      NButton {
        text: "Save"
        icon: "device-floppy"
        onClicked: root.save()
      }
    }
  }
}
