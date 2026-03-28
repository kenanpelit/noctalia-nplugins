import QtQuick
import qs.Services.Compositor
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property var workspaceRows: []
  property var groupedRows: []

  readonly property string labelMode: readStringSetting("labelMode", "index+name")
  readonly property int characterCount: readIntSetting("characterCount", 3, 1, 8)
  readonly property bool hideEmpty: readBoolSetting("hideEmpty", false)
  readonly property bool followFocusedOutput: readBoolSetting("followFocusedOutput", true)
  readonly property bool showOutputName: readBoolSetting("showOutputName", false)
  readonly property bool showWindowCount: readBoolSetting("showWindowCount", true)
  readonly property bool showPreviewDots: readBoolSetting("showPreviewDots", true)
  readonly property int maxPreviewDots: readIntSetting("maxPreviewDots", 4, 1, 6)
  readonly property bool compact: readBoolSetting("compact", false)
  readonly property string focusedOutput: {
    var ws = CompositorService.getCurrentWorkspace();
    return ws && ws.output ? String(ws.output) : "";
  }

  function readStringSetting(key, fallback) {
    var value = pluginApi?.pluginSettings?.[key];
    if (value === undefined || value === null || String(value).trim() === "")
      value = defaults[key];
    if (value === undefined || value === null || String(value).trim() === "")
      value = fallback;
    return String(value);
  }

  function readBoolSetting(key, fallback) {
    var value = pluginApi?.pluginSettings?.[key];
    if (value === undefined)
      value = defaults[key];
    if (value === undefined)
      value = fallback;
    return !!value;
  }

  function readIntSetting(key, fallback, minValue, maxValue) {
    var value = pluginApi?.pluginSettings?.[key];
    if (value === undefined)
      value = defaults[key];
    var parsed = parseInt(value, 10);
    if (isNaN(parsed))
      parsed = fallback;
    parsed = Math.max(minValue, parsed);
    parsed = Math.min(maxValue, parsed);
    return parsed;
  }

  function ensureSettings() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;

    var settings = pluginApi.pluginSettings;
    var dirty = false;

    function assignDefault(key, fallback) {
      if (settings[key] === undefined) {
        settings[key] = defaults[key] !== undefined ? defaults[key] : fallback;
        dirty = true;
      }
    }

    assignDefault("labelMode", "index+name");
    assignDefault("characterCount", 3);
    assignDefault("hideEmpty", false);
    assignDefault("followFocusedOutput", true);
    assignDefault("showOutputName", false);
    assignDefault("showWindowCount", true);
    assignDefault("showPreviewDots", true);
    assignDefault("maxPreviewDots", 4);
    assignDefault("compact", false);

    if (dirty)
      pluginApi.saveSettings();

    scheduleRefresh();
  }

  function setSetting(key, value) {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    pluginApi.pluginSettings[key] = value;
    pluginApi.saveSettings();
    scheduleRefresh();
  }

  function cycleLabelMode() {
    var order = ["index", "name", "index+name"];
    var current = labelMode;
    var index = order.indexOf(current);
    if (index < 0)
      index = 0;
    setSetting("labelMode", order[(index + 1) % order.length]);
  }

  function normalizedOutputName(name) {
    return String(name || "").toLowerCase();
  }

  function visibleRowsForScreen(screenName) {
    if (CompositorService.globalWorkspaces)
      return workspaceRows.slice();

    var target = normalizedOutputName(screenName);
    var focused = normalizedOutputName(focusedOutput);
    var rows = [];

    for (var i = 0; i < workspaceRows.length; ++i) {
      var row = workspaceRows[i];
      if (followFocusedOutput && focused) {
        if (normalizedOutputName(row.output) === focused)
          rows.push(row);
      } else if (!target || normalizedOutputName(row.output) === target) {
        rows.push(row);
      }
    }

    return rows;
  }

  function groupedRowsForScreen(screenName) {
    return groupRows(visibleRowsForScreen(screenName));
  }

  function switchWorkspaceByOffset(screenName, offset) {
    var rows = visibleRowsForScreen(screenName);
    if (rows.length <= 1)
      return;

    var currentIndex = 0;
    for (var i = 0; i < rows.length; ++i) {
      if (rows[i].isFocused) {
        currentIndex = i;
        break;
      }
    }

    var nextIndex = (currentIndex + offset) % rows.length;
    if (nextIndex < 0)
      nextIndex = rows.length - 1;

    CompositorService.switchToWorkspace(rows[nextIndex]);
  }

  function labelFor(workspace) {
    var name = String(workspace.name || "");
    var shortName = name ? name.substring(0, characterCount) : "";
    if (labelMode === "name")
      return shortName || String(workspace.idx);
    if (labelMode === "index")
      return String(workspace.idx);
    if (shortName)
      return String(workspace.idx) + " " + shortName;
    return String(workspace.idx);
  }

  function previewTokens(windows) {
    var tokens = [];
    var seen = {};

    for (var i = 0; i < windows.length; ++i) {
      var win = windows[i];
      var label = String(win.appId || win.title || "").trim();
      if (!label)
        label = "App";
      label = label.split(".").pop();
      label = label.charAt(0).toUpperCase();
      if (seen[label])
        continue;
      seen[label] = true;
      tokens.push(label);
      if (tokens.length >= maxPreviewDots)
        break;
    }

    return tokens;
  }

  function windowsForWorkspace(workspaceId) {
    var items = [];
    var windows = CompositorService.getWindowsForWorkspace(workspaceId);
    for (var i = 0; i < windows.length; ++i) {
      var win = windows[i];
      items.push({
                   id: win.id,
                   title: String(win.title || ""),
                   appId: String(win.appId || ""),
                   output: String(win.output || ""),
                   isFocused: !!win.isFocused,
                   workspaceId: win.workspaceId
                 });
    }
    return items;
  }

  function buildRow(workspace) {
    var windows = windowsForWorkspace(workspace.id);
    return {
      id: workspace.id,
      idx: workspace.idx,
      name: String(workspace.name || ""),
      output: String(workspace.output || ""),
      isFocused: !!workspace.isFocused,
      isActive: !!workspace.isActive,
      isUrgent: !!workspace.isUrgent,
      isOccupied: !!workspace.isOccupied,
      label: labelFor(workspace),
      windowCount: windows.length,
      previewTokens: previewTokens(windows),
      windows: windows
    };
  }

  function groupRows(rows) {
    var bucketMap = {};
    var groups = [];

    for (var i = 0; i < rows.length; ++i) {
      var row = rows[i];
      var key = String(row.output || "Unknown");
      if (!bucketMap[key]) {
        bucketMap[key] = {
          output: key,
          isFocusedOutput: normalizedOutputName(key) === normalizedOutputName(focusedOutput),
          occupiedCount: 0,
          totalWindows: 0,
          items: []
        };
        groups.push(bucketMap[key]);
      }

      bucketMap[key].items.push(row);
      if (row.windowCount > 0)
        bucketMap[key].occupiedCount += 1;
      bucketMap[key].totalWindows += row.windowCount;
    }

    groups.sort(function(a, b) {
      if (a.isFocusedOutput !== b.isFocusedOutput)
        return a.isFocusedOutput ? -1 : 1;
      return String(a.output).localeCompare(String(b.output));
    });

    return groups;
  }

  function summaryForScreen(screenName) {
    var rows = visibleRowsForScreen(screenName);
    var occupied = 0;
    var windows = 0;
    for (var i = 0; i < rows.length; ++i) {
      if (rows[i].windowCount > 0)
        occupied += 1;
      windows += rows[i].windowCount;
    }
    return {
      workspaces: rows.length,
      occupied: occupied,
      windows: windows
    };
  }

  function scheduleRefresh() {
    Qt.callLater(refresh);
  }

  function refresh() {
    var rows = [];

    for (var i = 0; i < CompositorService.workspaces.count; ++i) {
      var workspace = CompositorService.workspaces.get(i);
      if (hideEmpty && !workspace.isOccupied && !workspace.isFocused)
        continue;
      rows.push(buildRow(workspace));
    }

    rows.sort(function(a, b) {
      var outputDelta = String(a.output).localeCompare(String(b.output));
      if (outputDelta !== 0)
        return outputDelta;
      return a.idx - b.idx;
    });

    workspaceRows = rows;
    groupedRows = groupRows(rows);
  }

  Component.onCompleted: ensureSettings()
  onPluginApiChanged: ensureSettings()

  Connections {
    target: CompositorService
    function onWorkspacesChanged() { root.scheduleRefresh(); }
    function onWindowListChanged() { root.scheduleRefresh(); }
    function onActiveWindowChanged() { root.scheduleRefresh(); }
  }
}
