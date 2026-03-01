import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property string recordCommand: pluginApi?.pluginSettings?.recordCommand
                                 || pluginApi?.manifest?.metadata?.defaultSettings?.recordCommand
                                 || ""
  property string stopCommand: pluginApi?.pluginSettings?.stopCommand
                               || pluginApi?.manifest?.metadata?.defaultSettings?.stopCommand
                               || ""
  property string regionScreenshotCommand: pluginApi?.pluginSettings?.regionScreenshotCommand
                                           || pluginApi?.manifest?.metadata?.defaultSettings?.regionScreenshotCommand
                                           || ""
  property string screenScreenshotCommand: pluginApi?.pluginSettings?.screenScreenshotCommand
                                           || pluginApi?.manifest?.metadata?.defaultSettings?.screenScreenshotCommand
                                           || ""
  property string windowScreenshotCommand: pluginApi?.pluginSettings?.windowScreenshotCommand
                                           || pluginApi?.manifest?.metadata?.defaultSettings?.windowScreenshotCommand
                                           || ""
  property int pollInterval: {
    var candidate = parseInt(pluginApi?.pluginSettings?.pollInterval
                             ?? pluginApi?.manifest?.metadata?.defaultSettings?.pollInterval
                             ?? 2000, 10);
    return (isNaN(candidate) || candidate < 500) ? 2000 : candidate;
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.pluginSettings.recordCommand = root.recordCommand;
    pluginApi.pluginSettings.stopCommand = root.stopCommand;
    pluginApi.pluginSettings.regionScreenshotCommand = root.regionScreenshotCommand;
    pluginApi.pluginSettings.screenScreenshotCommand = root.screenScreenshotCommand;
    pluginApi.pluginSettings.windowScreenshotCommand = root.windowScreenshotCommand;
    pluginApi.pluginSettings.pollInterval = root.pollInterval;
    pluginApi.saveSettings();
    if (pluginApi.mainInstance)
      pluginApi.mainInstance.refresh();
  }

  spacing: Style.marginM

  NLabel {
    Layout.fillWidth: true
    label: "NCapture"
    description: "Configure the backend commands used for screenshots, recording, and background state polling."
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Record Command"
    description: "Shell command used when starting a recording."
    text: root.recordCommand
    onTextChanged: root.recordCommand = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Stop Command"
    description: "Shell command used when stopping an active recording."
    text: root.stopCommand
    onTextChanged: root.stopCommand = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Region Screenshot"
    description: "Command used for a region capture action."
    text: root.regionScreenshotCommand
    onTextChanged: root.regionScreenshotCommand = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Screen Screenshot"
    description: "Command used for the current monitor capture action."
    text: root.screenScreenshotCommand
    onTextChanged: root.screenScreenshotCommand = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Window Screenshot"
    description: "Command used for the active window capture action."
    text: root.windowScreenshotCommand
    onTextChanged: root.windowScreenshotCommand = text
  }

  NLabel {
    Layout.fillWidth: true
    label: "Polling interval"
    description: "How often the plugin refreshes recording and privacy state."
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    Slider {
      Layout.fillWidth: true
      from: 500
      to: 10000
      stepSize: 500
      value: root.pollInterval
      onMoved: root.pollInterval = Math.round(value)
      onValueChanged: root.pollInterval = Math.round(value)
    }

    NText {
      text: Math.round(root.pollInterval) + " ms"
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
