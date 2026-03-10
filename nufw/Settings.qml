import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property string watchdogText: "120000"
  property bool allowPrivilegedReads: true

  Component.onCompleted: syncFromSettings()
  onPluginApiChanged: syncFromSettings()

  function syncFromSettings() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    var value = pluginApi.pluginSettings.watchdogInterval;
    var parsed = parseInt(value, 10);
    watchdogText = (isNaN(parsed) || parsed < 120000) ? "120000" : String(parsed);
    allowPrivilegedReads = pluginApi.pluginSettings.allowPrivilegedReads === undefined
      ? true
      : !!pluginApi.pluginSettings.allowPrivilegedReads;
  }

  function save() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    var parsed = parseInt(watchdogText, 10);
    if (isNaN(parsed) || parsed < 120000)
      parsed = 120000;
    pluginApi.pluginSettings.watchdogInterval = parsed;
    pluginApi.pluginSettings.allowPrivilegedReads = allowPrivilegedReads;
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

    CheckBox {
      text: "Allow privileged reads (`sudo -n` fallback)"
      checked: root.allowPrivilegedReads
      onToggled: root.allowPrivilegedReads = checked
    }

    NText {
      text: "Keep this off unless plain `ufw status` is unreadable. Enabling it can generate sudo journal noise."
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
        placeholderText: "120000"
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
