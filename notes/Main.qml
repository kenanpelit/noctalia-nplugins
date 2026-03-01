import QtQuick
import Quickshell.Io
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property var notesData: []
  property var todosData: []
  property string scratchpadText: ""
  property bool showCountsInBar: true
  property int autosaveDelay: 700

  readonly property int noteCount: notesData.length
  readonly property int todoCount: todosData.length
  readonly property int activeTodoCount: {
    var count = 0;
    for (var i = 0; i < todosData.length; ++i) {
      if (!todosData[i].done) count += 1;
    }
    return count;
  }

  function nowIso() {
    return new Date().toISOString();
  }

  function normalizePriority(value) {
    var key = String(value || "medium").toLowerCase();
    if (["high", "medium", "low"].indexOf(key) === -1) {
      return "medium";
    }
    return key;
  }

  function priorityRank(value) {
    switch (normalizePriority(value)) {
    case "high":
      return 0;
    case "medium":
      return 1;
    default:
      return 2;
    }
  }

  function cloneNote(note) {
    return {
      id: String(note.id || Date.now()),
      title: String(note.title || ""),
      body: String(note.body !== undefined ? note.body : (note.content !== undefined ? note.content : "")),
      pinned: !!note.pinned,
      updatedAt: String(note.updatedAt || note.modifiedAt || nowIso())
    };
  }

  function cloneTodo(todo) {
    return {
      id: String(todo.id || Date.now()),
      text: String(todo.text || ""),
      done: !!(todo.done !== undefined ? todo.done : todo.completed),
      priority: normalizePriority(todo.priority),
      updatedAt: String(todo.updatedAt || todo.createdAt || nowIso())
    };
  }

  function assignNotes(items) {
    var next = [];
    for (var i = 0; i < items.length; ++i) {
      next.push(cloneNote(items[i]));
    }
    next.sort(function(a, b) {
      if (a.pinned !== b.pinned)
        return a.pinned ? -1 : 1;
      return new Date(b.updatedAt) - new Date(a.updatedAt);
    });
    notesData = next;
  }

  function assignTodos(items) {
    var next = [];
    for (var i = 0; i < items.length; ++i) {
      next.push(cloneTodo(items[i]));
    }
    next.sort(function(a, b) {
      if (a.done !== b.done)
        return a.done ? 1 : -1;
      var priorityDelta = priorityRank(a.priority) - priorityRank(b.priority);
      if (priorityDelta !== 0)
        return priorityDelta;
      return new Date(b.updatedAt) - new Date(a.updatedAt);
    });
    todosData = next;
  }

  function ensureSettings() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;

    var settings = pluginApi.pluginSettings;
    var dirty = false;

    if (!Array.isArray(settings.notes)) {
      settings.notes = [];
      dirty = true;
    }
    if (!Array.isArray(settings.todos)) {
      settings.todos = [];
      dirty = true;
    }
    if (settings.scratchpadContent === undefined) {
      settings.scratchpadContent = "";
      dirty = true;
    }
    if (settings.showCountsInBar === undefined) {
      settings.showCountsInBar = true;
      dirty = true;
    }
    if (settings.autosaveDelay === undefined) {
      settings.autosaveDelay = 700;
      dirty = true;
    }

    assignNotes(settings.notes);
    assignTodos(settings.todos);
    scratchpadText = String(settings.scratchpadContent || "");
    showCountsInBar = !!settings.showCountsInBar;

    var parsedDelay = parseInt(settings.autosaveDelay, 10);
    autosaveDelay = (isNaN(parsedDelay) || parsedDelay < 300) ? 700 : parsedDelay;

    if (dirty) {
      persist();
    } else {
      syncCountersOnly();
    }
  }

  function syncCountersOnly() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;
    pluginApi.pluginSettings.count = noteCount;
    pluginApi.pluginSettings.todoCount = todoCount;
    pluginApi.pluginSettings.activeTodoCount = activeTodoCount;
    pluginApi.saveSettings();
  }

  function persist() {
    if (!pluginApi || !pluginApi.pluginSettings)
      return;

    pluginApi.pluginSettings.notes = notesData.slice();
    pluginApi.pluginSettings.todos = todosData.slice();
    pluginApi.pluginSettings.scratchpadContent = scratchpadText;
    pluginApi.pluginSettings.showCountsInBar = showCountsInBar;
    pluginApi.pluginSettings.autosaveDelay = autosaveDelay;
    pluginApi.pluginSettings.count = noteCount;
    pluginApi.pluginSettings.todoCount = todoCount;
    pluginApi.pluginSettings.activeTodoCount = activeTodoCount;
    pluginApi.saveSettings();
  }

  function noteById(noteId) {
    var key = String(noteId || "");
    for (var i = 0; i < notesData.length; ++i) {
      if (notesData[i].id === key)
        return cloneNote(notesData[i]);
    }
    return null;
  }

  function upsertNote(noteId, title, body) {
    var cleanBody = String(body || "").trim();
    var cleanTitle = String(title || "").trim();
    if (!cleanTitle && cleanBody) {
      cleanTitle = cleanBody.split("\n")[0].substring(0, 48);
    }
    if (!cleanTitle)
      cleanTitle = "Untitled note";

    var next = notesData.slice();
    var targetId = String(noteId || "");
    var found = false;

    for (var i = 0; i < next.length; ++i) {
      if (next[i].id === targetId && targetId !== "") {
        next[i] = {
          id: next[i].id,
          title: cleanTitle,
          body: String(body || ""),
          pinned: !!next[i].pinned,
          updatedAt: nowIso()
        };
        found = true;
        targetId = next[i].id;
        break;
      }
    }

    if (!found) {
      targetId = String(Date.now());
      next.unshift({
        id: targetId,
        title: cleanTitle,
        body: String(body || ""),
        pinned: false,
        updatedAt: nowIso()
      });
    }

    assignNotes(next);
    persist();
    return targetId;
  }

  function deleteNote(noteId) {
    var key = String(noteId || "");
    var next = [];
    for (var i = 0; i < notesData.length; ++i) {
      if (notesData[i].id !== key)
        next.push(notesData[i]);
    }
    assignNotes(next);
    persist();
  }

  function toggleNotePinned(noteId) {
    var key = String(noteId || "");
    var next = notesData.slice();
    for (var i = 0; i < next.length; ++i) {
      if (next[i].id === key) {
        next[i] = {
          id: next[i].id,
          title: next[i].title,
          body: next[i].body,
          pinned: !next[i].pinned,
          updatedAt: nowIso()
        };
        break;
      }
    }
    assignNotes(next);
    persist();
  }

  function addTodo(text, priority) {
    var cleanText = String(text || "").trim();
    if (!cleanText)
      return "";
    var next = todosData.slice();
    var todoId = String(Date.now());
    next.unshift({
      id: todoId,
      text: cleanText,
      done: false,
      priority: normalizePriority(priority),
      updatedAt: nowIso()
    });
    assignTodos(next);
    persist();
    return todoId;
  }

  function setTodoDone(todoId, done) {
    var key = String(todoId || "");
    var next = todosData.slice();
    for (var i = 0; i < next.length; ++i) {
      if (next[i].id === key) {
        next[i] = {
          id: next[i].id,
          text: next[i].text,
          done: !!done,
          priority: next[i].priority,
          updatedAt: nowIso()
        };
        break;
      }
    }
    assignTodos(next);
    persist();
  }

  function cycleTodoPriority(todoId) {
    var key = String(todoId || "");
    var next = todosData.slice();
    for (var i = 0; i < next.length; ++i) {
      if (next[i].id === key) {
        var current = normalizePriority(next[i].priority);
        var nextPriority = current === "high" ? "medium" : (current === "medium" ? "low" : "high");
        next[i] = {
          id: next[i].id,
          text: next[i].text,
          done: !!next[i].done,
          priority: nextPriority,
          updatedAt: nowIso()
        };
        break;
      }
    }
    assignTodos(next);
    persist();
  }

  function deleteTodo(todoId) {
    var key = String(todoId || "");
    var next = [];
    for (var i = 0; i < todosData.length; ++i) {
      if (todosData[i].id !== key)
        next.push(todosData[i]);
    }
    assignTodos(next);
    persist();
  }

  function setScratchpad(text) {
    scratchpadText = String(text || "");
    persist();
  }

  function quickCapture(text) {
    var cleanText = String(text || "").trim();
    if (!cleanText)
      return "";
    return upsertNote("", "", cleanText);
  }

  function setShowCounts(enabled) {
    showCountsInBar = !!enabled;
    persist();
  }

  function summary() {
    return {
      notes: noteCount,
      todos: todoCount,
      activeTodos: activeTodoCount,
      scratchpadChars: scratchpadText.length
    };
  }

  Component.onCompleted: ensureSettings()
  onPluginApiChanged: ensureSettings()

  IpcHandler {
    target: "plugin:notes"

    function togglePanel() {
      if (!pluginApi)
        return;
      pluginApi.withCurrentScreen(function(screen) {
        pluginApi.togglePanel(screen);
      });
    }

    function addTodo(text: string, priority: string) {
      root.addTodo(text, priority);
    }

    function addNote(title: string, body: string) {
      root.upsertNote("", title, body);
    }

    function quickCapture(text: string) {
      root.quickCapture(text);
    }

    function setScratchpad(text: string) {
      root.setScratchpad(text);
    }

    function toggleTodo(id: string) {
      for (var i = 0; i < root.todosData.length; ++i) {
        if (root.todosData[i].id === String(id)) {
          root.setTodoDone(id, !root.todosData[i].done);
          break;
        }
      }
    }

    function removeTodo(id: string) {
      root.deleteTodo(id);
    }
  }
}
