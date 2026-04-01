import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  property var pluginApi: null
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string valueLabelMode: "index+name"
  property string valueCharacterCount: "3"
  property bool valueHideEmpty: false
  property bool valueFollowFocusedOutput: true
  property bool valueShowOutputName: false
  property bool valueShowWindowCount: true
  property bool valueShowPreviewDots: true
  property string valueMaxPreviewDots: "4"
  property bool valueCompact: false

  Component.onCompleted: syncFromSettings()
  onPluginApiChanged: syncFromSettings()

  function settingValue(key, fallback) {
    var value = pluginApi?.pluginSettings?.[key];
    if (value === undefined)
      value = defaults[key];
    if (value === undefined)
      value = fallback;
    return value;
  }

  function syncFromSettings() {
    valueLabelMode = String(settingValue("labelMode", "index+name"));
    valueCharacterCount = String(settingValue("characterCount", 3));
    valueHideEmpty = !!settingValue("hideEmpty", false);
    valueFollowFocusedOutput = !!settingValue("followFocusedOutput", true);
    valueShowOutputName = !!settingValue("showOutputName", false);
    valueShowWindowCount = !!settingValue("showWindowCount", true);
    valueShowPreviewDots = !!settingValue("showPreviewDots", true);
    valueMaxPreviewDots = String(settingValue("maxPreviewDots", 4));
    valueCompact = !!settingValue("compact", false);
  }

  function saveSettings() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;

    var charCount = parseInt(valueCharacterCount, 10);
    if (isNaN(charCount))
      charCount = 3;
    charCount = Math.max(1, Math.min(8, charCount));

    var maxDots = parseInt(valueMaxPreviewDots, 10);
    if (isNaN(maxDots))
      maxDots = 4;
    maxDots = Math.max(1, Math.min(6, maxDots));

    pluginApi.pluginSettings.labelMode = valueLabelMode;
    pluginApi.pluginSettings.characterCount = charCount;
    pluginApi.pluginSettings.hideEmpty = valueHideEmpty;
    pluginApi.pluginSettings.followFocusedOutput = valueFollowFocusedOutput;
    pluginApi.pluginSettings.showOutputName = valueShowOutputName;
    pluginApi.pluginSettings.showWindowCount = valueShowWindowCount;
    pluginApi.pluginSettings.showPreviewDots = valueShowPreviewDots;
    pluginApi.pluginSettings.maxPreviewDots = maxDots;
    pluginApi.pluginSettings.compact = valueCompact;
    pluginApi.saveSettings();

    if (pluginApi.mainInstance && pluginApi.mainInstance.refresh)
      pluginApi.mainInstance.refresh();
  }

  NText {
    text: "NWorkspace Settings"
    pointSize: Style.fontSizeL * Style.uiScaleRatio
    font.weight: Font.Bold
  }

  NText {
    text: "These settings apply globally to the plugin. Use them to tune density, output behaviour, and how much context appears in the bar."
    wrapMode: Text.WordWrap
    color: Color.mOnSurfaceVariant
    Layout.fillWidth: true
  }

  NComboBox {
    label: "Label mode"
    description: "How each workspace pill should be labeled in the bar."
    model: [
      { "key": "index", "name": "Index" },
      { "key": "name", "name": "Name" },
      { "key": "index+name", "name": "Index + Name" }
    ]
    currentKey: valueLabelMode
    onSelected: key => {
      valueLabelMode = key;
      saveSettings();
    }
    minimumWidth: 220
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Name length"
    description: "How many characters from the workspace name should appear in the bar."
    text: valueCharacterCount
    placeholderText: "3"
    inputMethodHints: Qt.ImhDigitsOnly
    onTextChanged: valueCharacterCount = text
    onEditingFinished: saveSettings()
  }

  NToggle {
    label: "Hide empty workspaces"
    description: "Keep the bar tighter by removing empty workspaces unless they are focused."
    checked: valueHideEmpty
    onToggled: checked => {
      valueHideEmpty = checked;
      saveSettings();
    }
  }

  NToggle {
    label: "Follow focused output"
    description: "Show workspaces from the monitor that currently has focus instead of the bar's own output."
    checked: valueFollowFocusedOutput
    onToggled: checked => {
      valueFollowFocusedOutput = checked;
      saveSettings();
    }
  }

  NToggle {
    label: "Show output badge"
    description: "Add a compact output marker to each workspace pill."
    checked: valueShowOutputName
    onToggled: checked => {
      valueShowOutputName = checked;
      saveSettings();
    }
  }

  NToggle {
    label: "Show window counts"
    description: "Display how many windows are open inside each workspace."
    checked: valueShowWindowCount
    onToggled: checked => {
      valueShowWindowCount = checked;
      saveSettings();
    }
  }

  NToggle {
    label: "Show preview dots"
    description: "Render tiny app hints for the first few unique windows in each workspace."
    checked: valueShowPreviewDots
    onToggled: checked => {
      valueShowPreviewDots = checked;
      saveSettings();
    }
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Preview dots"
    description: "Maximum number of unique app markers shown inside each workspace pill."
    text: valueMaxPreviewDots
    placeholderText: "4"
    inputMethodHints: Qt.ImhDigitsOnly
    enabled: valueShowPreviewDots
    onTextChanged: valueMaxPreviewDots = text
    onEditingFinished: saveSettings()
  }

  NToggle {
    label: "Compact mode"
    description: "Reduce pill padding for denser bars."
    checked: valueCompact
    onToggled: checked => {
      valueCompact = checked;
      saveSettings();
    }
  }

  NButton {
    text: "Save Settings"
    icon: "device-floppy"
    Layout.alignment: Qt.AlignLeft
    onClicked: saveSettings()
  }
}
