import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var pluginApi: null
  property string currentClipboard: ""
  property string clipboardKind: "empty"
  property var itemsData: []
  property string lastError: ""
  property string lastAction: ""
  property bool actionBusy: false
  property bool clipboardAvailable: false

  readonly property int clipCount: itemsData.length
  readonly property int pinnedCount: {
    var count = 0;
    for (var i = 0; i < itemsData.length; ++i) {
      if (itemsData[i].pinned)
        count += 1;
    }
    return count;
  }
  readonly property bool hasTextClipboard: clipboardKind === "text" && String(currentClipboard || "").trim() !== ""
  readonly property int pollInterval: {
    var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.pollInterval, 10) : NaN;
    return (isNaN(candidate) || candidate < 1000) ? 2500 : candidate;
  }
  readonly property int maxItems: {
    var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.maxItems, 10) : NaN;
    return (isNaN(candidate) || candidate < 3) ? 12 : candidate;
  }

  function nowIso() {
    return new Date().toISOString();
  }

  function buildPreview(text) {
    var clean = String(text || "").replace(/\s+/g, " ").trim();
    if (clean.length > 92)
      return clean.substring(0, 92) + "…";
    return clean;
  }

  function normalizeItem(item) {
    var text = String(item && item.text !== undefined ? item.text : "").trim();
    return {
      id: String(item && item.id ? item.id : Date.now()),
      text: text,
      preview: buildPreview(text),
      pinned: !!(item && item.pinned),
      updatedAt: String(item && item.updatedAt ? item.updatedAt : nowIso())
    };
  }

  function sortItems(list) {
    list.sort(function(a, b) {
      if (a.pinned !== b.pinned)
        return a.pinned ? -1 : 1;
      return new Date(b.updatedAt) - new Date(a.updatedAt);
    });
    return list;
  }

  function assignItems(items) {
    var next = [];
    for (var i = 0; i < items.length; ++i) {
      var normalized = normalizeItem(items[i]);
      if (normalized.text)
        next.push(normalized);
    }
    itemsData = sortItems(next);
  }

  function persist() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    pluginApi.pluginSettings.items = itemsData.slice();
    pluginApi.pluginSettings.pollInterval = pollInterval;
    pluginApi.pluginSettings.maxItems = maxItems;
    pluginApi.pluginSettings.count = clipCount;
    pluginApi.pluginSettings.pinnedCount = pinnedCount;
    pluginApi.saveSettings();
  }

  function ensureSettings() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    var settings = pluginApi.pluginSettings;
    var dirty = false;
    if (!Array.isArray(settings.items)) {
      settings.items = [];
      dirty = true;
    }
    if (settings.pollInterval === undefined) {
      settings.pollInterval = 2500;
      dirty = true;
    }
    if (settings.maxItems === undefined) {
      settings.maxItems = 12;
      dirty = true;
    }
    assignItems(settings.items);
    if (dirty)
      persist();
  }

  function trimItems(list) {
    if (list.length <= maxItems)
      return list;
    return list.slice(0, maxItems);
  }

  function addClipText(text, pinned) {
    var clean = String(text || "").trim();
    if (!clean)
      return "";
    var next = [];
    var existingId = "";
    for (var i = 0; i < itemsData.length; ++i) {
      var item = itemsData[i];
      if (item.text === clean) {
        existingId = item.id;
        next.push({
          id: item.id,
          text: clean,
          preview: buildPreview(clean),
          pinned: pinned ? true : !!item.pinned,
          updatedAt: nowIso()
        });
      } else {
        next.push(item);
      }
    }
    if (!existingId) {
      existingId = String(Date.now());
      next.unshift({
        id: existingId,
        text: clean,
        preview: buildPreview(clean),
        pinned: !!pinned,
        updatedAt: nowIso()
      });
    }
    assignItems(trimItems(next));
    persist();
    lastAction = pinned ? "Pinned current clipboard" : "Saved current clipboard";
    return existingId;
  }

  function saveCurrent() {
    if (!hasTextClipboard)
      return "";
    return addClipText(currentClipboard, false);
  }

  function pinCurrent() {
    if (!hasTextClipboard)
      return "";
    return addClipText(currentClipboard, true);
  }

  function removeItem(itemId) {
    var key = String(itemId || "");
    var next = [];
    for (var i = 0; i < itemsData.length; ++i) {
      if (itemsData[i].id !== key)
        next.push(itemsData[i]);
    }
    assignItems(next);
    persist();
    lastAction = "Removed saved clip";
  }

  function togglePinned(itemId) {
    var key = String(itemId || "");
    var next = [];
    for (var i = 0; i < itemsData.length; ++i) {
      var item = itemsData[i];
      if (item.id === key) {
        next.push({
          id: item.id,
          text: item.text,
          preview: buildPreview(item.text),
          pinned: !item.pinned,
          updatedAt: nowIso()
        });
      } else {
        next.push(item);
      }
    }
    assignItems(next);
    persist();
    lastAction = "Updated pin state";
  }

  function copyText(text) {
    var clean = String(text || "");
    if (!clean || actionBusy || !clipboardAvailable)
      return;
    actionBusy = true;
    lastError = "";
    actionProcess.command = [
      "sh", "-lc", 'printf "%s" "$1" | wl-copy',
      "nclipper-copy", clean
    ];
    actionProcess.running = true;
  }

  function openPanel() {
    if (!pluginApi)
      return;
    pluginApi.withCurrentScreen(function(screen) {
      pluginApi.togglePanel(screen);
    });
  }

  function refreshClipboard() {
    if (!clipboardAvailable || clipboardProcess.running)
      return;
    clipboardProcess.running = true;
  }

  function applyClipboardPayload(text) {
    var raw = String(text || "");
    var lines = raw.split("\n");
    var marker = lines.length > 0 ? String(lines.shift() || "").trim() : "__EMPTY__";
    var body = lines.join("\n");
    body = body.replace(/\r/g, "");
    body = body.replace(/\n$/, "");

    if (marker === "__TEXT__") {
      clipboardKind = "text";
      currentClipboard = body;
      return;
    }
    if (marker === "__IMAGE__") {
      clipboardKind = "image";
      currentClipboard = "";
      return;
    }
    if (marker === "__EMPTY__") {
      clipboardKind = "empty";
      currentClipboard = "";
      return;
    }

    clipboardKind = body.trim() ? "text" : "empty";
    currentClipboard = body;
  }

  Component.onCompleted: {
    ensureSettings();
    checkProcess.running = true;
  }

  onPluginApiChanged: ensureSettings()

  Process {
    id: checkProcess
    command: ["sh", "-lc", "command -v wl-paste >/dev/null 2>&1 && command -v wl-copy >/dev/null 2>&1"]
    stderr: StdioCollector { id: checkStderr }
    onExited: function(code) {
      root.clipboardAvailable = (code === 0);
      if (root.clipboardAvailable) {
        root.refreshClipboard();
      } else {
        root.lastError = (checkStderr.text || "wl-paste / wl-copy not available").trim();
      }
    }
  }

  Process {
    id: clipboardProcess
    command: [
      "sh", "-lc",
      'if wl-paste --list-types 2>/dev/null | grep -q "^text/"; then printf "__TEXT__\\n"; wl-paste --no-newline --type text 2>/dev/null || true; elif wl-paste --list-types 2>/dev/null | grep -q "^image/"; then printf "__IMAGE__\\n"; else printf "__EMPTY__\\n"; fi'
    ]
    stdout: StdioCollector {
      onStreamFinished: root.applyClipboardPayload(this.text || "")
    }
  }

  Process {
    id: actionProcess
    stdout: StdioCollector { id: actionStdout }
    stderr: StdioCollector { id: actionStderr }
    onExited: function(code) {
      root.actionBusy = false;
      if (code !== 0) {
        root.lastError = (actionStderr.text || "Clipboard action failed").trim();
      } else {
        root.lastAction = "Copied clip to clipboard";
        root.refreshClipboard();
      }
    }
  }

  Timer {
    interval: root.pollInterval
    running: root.clipboardAvailable
    repeat: true
    onTriggered: root.refreshClipboard()
  }

  IpcHandler {
    target: "plugin:nclipper"

    function togglePanel() { root.openPanel(); }
    function refresh() { root.refreshClipboard(); }
    function saveCurrent() { root.saveCurrent(); }
    function pinCurrent() { root.pinCurrent(); }
    function copyItem(text: string) { root.copyText(text); }
    function removeItem(itemId: string) { root.removeItem(itemId); }
    function togglePinned(itemId: string) { root.togglePinned(itemId); }
  }
}
