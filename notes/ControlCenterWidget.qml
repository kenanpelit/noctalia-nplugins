import QtQuick
import Quickshell
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen
  property var pluginApi: null
  readonly property var main: pluginApi ? pluginApi.mainInstance : null

  icon: "notes"
  tooltipText: {
    var active = main ? main.activeTodoCount : 0;
    var notes = main ? main.noteCount : 0;
    return "Notes Hub: " + active + " active tasks, " + notes + " notes";
  }

  onClicked: {
    if (pluginApi) {
      pluginApi.togglePanel(screen, this);
    }
  }
}
