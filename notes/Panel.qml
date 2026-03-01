import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var main: pluginApi ? pluginApi.mainInstance : null
  readonly property var geometryPlaceholder: panelFrame
  readonly property bool allowAttach: true

  property real contentPreferredWidth: 940 * Style.uiScaleRatio
  property real contentPreferredHeight: 640 * Style.uiScaleRatio

  property int currentTabIndex: 0
  property string selectedNoteId: ""
  property string draftTitle: ""
  property string draftBody: ""

  function summaryValue(name) {
    var summary = main ? main.summary() : null;
    return summary && summary[name] !== undefined ? summary[name] : 0;
  }

  function notesList() {
    return main ? main.notesData : [];
  }

  function todosList() {
    return main ? main.todosData : [];
  }

  function refreshEditorFromSelection() {
    if (!main) {
      draftTitle = "";
      draftBody = "";
      return;
    }

    if (!selectedNoteId) {
      draftTitle = "";
      draftBody = "";
      return;
    }

    var note = main.noteById(selectedNoteId);
    if (!note) {
      selectedNoteId = "";
      draftTitle = "";
      draftBody = "";
      return;
    }

    draftTitle = note.title;
    draftBody = note.body;
  }

  function startNewNote() {
    selectedNoteId = "";
    draftTitle = "";
    draftBody = "";
  }

  function selectNote(noteId) {
    selectedNoteId = String(noteId || "");
    refreshEditorFromSelection();
  }

  function saveEditorNote() {
    if (!main)
      return;
    selectedNoteId = main.upsertNote(selectedNoteId, draftTitle, draftBody);
    refreshEditorFromSelection();
  }

  function deleteEditorNote() {
    if (!main || !selectedNoteId)
      return;
    main.deleteNote(selectedNoteId);
    startNewNote();
  }

  function priorityLabel(priority) {
    var key = String(priority || "medium");
    if (key === "high") return "High";
    if (key === "low") return "Low";
    return "Medium";
  }

  function priorityColor(priority) {
    var key = String(priority || "medium");
    if (key === "high") return "#ef5350";
    if (key === "low") return "#90a4ae";
    return "#42a5f5";
  }

  Component.onCompleted: startNewNote()
  onMainChanged: startNewNote()

  Rectangle {
    id: panelFrame
    anchors.fill: parent
    radius: Style.radiusL
    color: Color.mSurface
    border.color: Qt.alpha(Color.mOutline, 0.18)
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        Rectangle {
          Layout.preferredWidth: 44
          Layout.preferredHeight: 44
          radius: 22
          color: Qt.alpha(Color.mPrimary, 0.12)
          border.color: Qt.alpha(Color.mPrimary, 0.2)
          border.width: 1

          NIcon {
            anchors.centerIn: parent
            icon: "file-text"
            pointSize: Style.fontSizeL
            color: Color.mPrimary
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          NText {
            text: "Notes Hub"
            pointSize: Style.fontSizeL
            font.weight: Font.Bold
            color: Color.mOnSurface
          }

          NText {
            text: "One workspace for scratchpad capture, durable notes, and actionable todos."
            pointSize: Style.fontSizeXS
            color: Color.mSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Style.marginS
        rowSpacing: Style.marginS

        Repeater {
          model: [
            { label: "Active Tasks", value: root.summaryValue("activeTodos") },
            { label: "Notes", value: root.summaryValue("notes") },
            { label: "Scratchpad", value: root.summaryValue("scratchpadChars") + " chars" }
          ]

          delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            radius: Style.radiusM
            color: Qt.alpha(Color.mPrimary, 0.08)
            border.color: Qt.alpha(Color.mPrimary, 0.14)
            border.width: 1
            implicitHeight: summaryCol.implicitHeight + (Style.marginM * 2)

            ColumnLayout {
              id: summaryCol
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: 2

              NText { text: modelData.label; pointSize: Style.fontSizeXS; color: Color.mSecondary }
              NText { text: String(modelData.value); pointSize: Style.fontSizeL; font.weight: Font.Medium; color: Color.mOnSurface }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        Repeater {
          model: ["Scratchpad", "Notes", "Todos"]

          delegate: NButton {
            required property string modelData
            required property int index
            Layout.fillWidth: true
            text: modelData
            backgroundColor: root.currentTabIndex === index ? Qt.alpha(Color.mPrimary, 0.14) : Qt.alpha(Color.mSurfaceVariant, 0.42)
            textColor: root.currentTabIndex === index ? Color.mPrimary : Color.mOnSurface
            onClicked: root.currentTabIndex = index
          }
        }
      }

      StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: root.currentTabIndex

        Rectangle {
          radius: Style.radiusM
          color: Qt.alpha(Color.mSurfaceVariant, 0.36)
          border.color: Qt.alpha(Color.mOutline, 0.1)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              NText {
                Layout.fillWidth: true
                text: "Fast capture"
                pointSize: Style.fontSizeM
                font.weight: Font.Medium
                color: Color.mOnSurface
              }

              NButton {
                text: "Save as Note"
                icon: "plus"
                enabled: !!main && scratchpadEditor.text.trim() !== ""
                onClicked: {
                  if (main) {
                    root.selectedNoteId = main.quickCapture(scratchpadEditor.text);
                    root.refreshEditorFromSelection();
                  }
                }
              }

              NButton {
                text: "Clear"
                icon: "eraser"
                enabled: !!main && scratchpadEditor.text !== ""
                onClicked: {
                  scratchpadEditor.text = "";
                  if (main) main.setScratchpad("");
                }
              }
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: Style.radiusS
              color: Color.mSurface
              border.color: Qt.alpha(Color.mOutline, 0.12)
              border.width: 1

              ScrollView {
                anchors.fill: parent
                anchors.margins: 1
                clip: true

                TextArea {
                  id: scratchpadEditor
                  text: main ? main.scratchpadText : ""
                  wrapMode: TextEdit.Wrap
                  selectByMouse: true
                  padding: Style.marginM
                  placeholderText: "Jot anything here. It autosaves and can be promoted into a note later."
                  color: Color.mOnSurface
                  background: null
                  onTextChanged: scratchpadSaveTimer.restart()
                }
              }
            }
          }

          Timer {
            id: scratchpadSaveTimer
            interval: main ? main.autosaveDelay : 700
            running: false
            repeat: false
            onTriggered: {
              if (main && scratchpadEditor.text !== main.scratchpadText) {
                main.setScratchpad(scratchpadEditor.text);
              }
            }
          }
        }

        RowLayout {
          spacing: Style.marginM

          Rectangle {
            Layout.preferredWidth: 300 * Style.uiScaleRatio
            Layout.fillHeight: true
            radius: Style.radiusM
            color: Qt.alpha(Color.mSurfaceVariant, 0.36)
            border.color: Qt.alpha(Color.mOutline, 0.1)
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: Style.marginM

              RowLayout {
                Layout.fillWidth: true

                NText {
                  Layout.fillWidth: true
                  text: "Notes"
                  pointSize: Style.fontSizeM
                  font.weight: Font.Medium
                  color: Color.mOnSurface
                }

                NButton {
                  text: "New"
                  icon: "plus"
                  onClicked: root.startNewNote()
                }
              }

              ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                  id: notesView
                  model: root.notesList()
                  spacing: Style.marginS

                  delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width - 6
                    radius: Style.radiusS
                    color: root.selectedNoteId === modelData.id ? Qt.alpha(Color.mPrimary, 0.1) : Color.mSurface
                    border.color: root.selectedNoteId === modelData.id ? Qt.alpha(Color.mPrimary, 0.24) : Qt.alpha(Color.mOutline, 0.08)
                    border.width: 1
                    implicitHeight: noteCol.implicitHeight + (Style.marginM * 2)

                    ColumnLayout {
                      id: noteCol
                      anchors.fill: parent
                      anchors.margins: Style.marginM
                      spacing: Style.marginXS

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginXS

                        NText {
                          Layout.fillWidth: true
                          text: modelData.title
                          pointSize: Style.fontSizeS
                          font.weight: Font.Medium
                          color: Color.mOnSurface
                          elide: Text.ElideRight
                        }

                        NIcon {
                          visible: !!modelData.pinned
                          icon: "pinned"
                          pointSize: Style.fontSizeXS
                          color: Color.mPrimary
                        }
                      }

                      NText {
                        text: String(modelData.body || "").split("\n").join(" ")
                        pointSize: Style.fontSizeXS
                        color: Color.mSecondary
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        Layout.fillWidth: true
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.selectNote(modelData.id)
                    }
                  }
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Style.radiusM
            color: Qt.alpha(Color.mSurfaceVariant, 0.36)
            border.color: Qt.alpha(Color.mOutline, 0.1)
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: Style.marginM

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NText {
                  Layout.fillWidth: true
                  text: root.selectedNoteId ? "Edit note" : "New note"
                  pointSize: Style.fontSizeM
                  font.weight: Font.Medium
                  color: Color.mOnSurface
                }

                NButton {
                  text: root.selectedNoteId && main && main.noteById(root.selectedNoteId) && main.noteById(root.selectedNoteId).pinned ? "Unpin" : "Pin"
                  icon: "pinned"
                  enabled: !!main && !!root.selectedNoteId
                  onClicked: {
                    if (main && root.selectedNoteId) {
                      main.toggleNotePinned(root.selectedNoteId);
                    }
                  }
                }

                NButton {
                  text: "Delete"
                  icon: "trash"
                  enabled: !!root.selectedNoteId
                  onClicked: root.deleteEditorNote()
                }

                NButton {
                  text: "Save"
                  icon: "device-floppy"
                  enabled: !!main
                  onClicked: root.saveEditorNote()
                }
              }

              TextField {
                id: noteTitleField
                Layout.fillWidth: true
                text: root.draftTitle
                placeholderText: "Title"
                onTextChanged: root.draftTitle = text
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.radiusS
                color: Color.mSurface
                border.color: Qt.alpha(Color.mOutline, 0.12)
                border.width: 1

                ScrollView {
                  anchors.fill: parent
                  anchors.margins: 1
                  clip: true

                  TextArea {
                    id: noteBodyField
                    text: root.draftBody
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    padding: Style.marginM
                    placeholderText: "Long-form notes, drafts, meeting notes, or reference snippets."
                    color: Color.mOnSurface
                    background: null
                    onTextChanged: root.draftBody = text
                  }
                }
              }
            }
          }
        }

        Rectangle {
          radius: Style.radiusM
          color: Qt.alpha(Color.mSurfaceVariant, 0.36)
          border.color: Qt.alpha(Color.mOutline, 0.1)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              TextField {
                id: todoInput
                Layout.fillWidth: true
                placeholderText: "Add a task"
                onAccepted: addTodoButton.clicked()
              }

              ComboBox {
                id: priorityBox
                model: ["High", "Medium", "Low"]
                currentIndex: 1
                Layout.preferredWidth: 140 * Style.uiScaleRatio
              }

              NButton {
                id: addTodoButton
                text: "Add"
                icon: "plus"
                enabled: !!main && todoInput.text.trim() !== ""
                onClicked: {
                  if (main) {
                    var priority = priorityBox.currentIndex === 0 ? "high" : (priorityBox.currentIndex === 2 ? "low" : "medium");
                    main.addTodo(todoInput.text, priority);
                    todoInput.text = "";
                    priorityBox.currentIndex = 1;
                  }
                }
              }
            }

            ScrollView {
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true

              ListView {
                id: todoView
                model: root.todosList()
                spacing: Style.marginS

                delegate: Rectangle {
                  required property var modelData
                  width: ListView.view.width - 6
                  radius: Style.radiusS
                  color: Color.mSurface
                  border.color: Qt.alpha(Color.mOutline, 0.08)
                  border.width: 1
                  implicitHeight: todoRow.implicitHeight + (Style.marginM * 2)

                  RowLayout {
                    id: todoRow
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginS

                    CheckBox {
                      checked: !!modelData.done
                      onToggled: {
                        if (main) main.setTodoDone(modelData.id, checked);
                      }
                    }

                    NText {
                      Layout.fillWidth: true
                      text: modelData.text
                      pointSize: Style.fontSizeS
                      color: modelData.done ? Color.mSecondary : Color.mOnSurface
                      font.strikeout: !!modelData.done
                      wrapMode: Text.WordWrap
                    }

                    Rectangle {
                      radius: 10
                      color: Qt.alpha(root.priorityColor(modelData.priority), 0.16)
                      border.color: Qt.alpha(root.priorityColor(modelData.priority), 0.28)
                      border.width: 1
                      implicitWidth: priorityText.implicitWidth + (Style.marginS * 2)
                      implicitHeight: priorityText.implicitHeight + Style.marginXS

                      NText {
                        id: priorityText
                        anchors.centerIn: parent
                        text: root.priorityLabel(modelData.priority)
                        pointSize: Style.fontSizeXS
                        color: root.priorityColor(modelData.priority)
                      }
                    }

                    NButton {
                      text: "Cycle"
                      enabled: !!main
                      onClicked: {
                        if (main) main.cycleTodoPriority(modelData.id);
                      }
                    }

                    NButton {
                      text: "Delete"
                      icon: "trash"
                      enabled: !!main
                      onClicked: {
                        if (main) main.deleteTodo(modelData.id);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
