import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property string pollIntervalText: "2500"
  property string maxItemsText: "12"

  Component.onCompleted: syncFromSettings()
  onPluginApiChanged: syncFromSettings()

  function syncFromSettings() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    pollIntervalText = String(pluginApi.pluginSettings.pollInterval === undefined ? 2500 : pluginApi.pluginSettings.pollInterval);
    maxItemsText = String(pluginApi.pluginSettings.maxItems === undefined ? 12 : pluginApi.pluginSettings.maxItems);
  }

  function save() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    var poll = parseInt(pollIntervalText, 10);
    var max = parseInt(maxItemsText, 10);
    if (isNaN(poll) || poll < 1000)
      poll = 2500;
    if (isNaN(max) || max < 3)
      max = 12;
    pluginApi.pluginSettings.pollInterval = poll;
    pluginApi.pluginSettings.maxItems = max;
    pluginApi.saveSettings();
    pollIntervalText = String(poll);
    maxItemsText = String(max);
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginL

    NText {
      text: "NClipper Settings"
      font.pointSize: Style.fontSizeL * Style.uiScaleRatio
      font.weight: Font.Bold
    }

    NText {
      text: "Tune how often the clipboard is sampled and how many saved snippets are retained."
      wrapMode: Text.Wrap
      color: Color.mOnSurfaceVariant
      Layout.fillWidth: true
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NText { text: "Poll (ms)"; Layout.preferredWidth: 90 * Style.uiScaleRatio }
      TextField { Layout.fillWidth: true; text: root.pollIntervalText; inputMethodHints: Qt.ImhDigitsOnly; onTextChanged: root.pollIntervalText = text }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NText { text: "Max items"; Layout.preferredWidth: 90 * Style.uiScaleRatio }
      TextField { Layout.fillWidth: true; text: root.maxItemsText; inputMethodHints: Qt.ImhDigitsOnly; onTextChanged: root.maxItemsText = text }
    }

    NButton {
      text: "Save"
      icon: "device-floppy"
      onClicked: root.save()
    }
  }
}
