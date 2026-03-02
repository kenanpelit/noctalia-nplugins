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

  property real contentPreferredWidth: 920 * Style.uiScaleRatio
  property real contentPreferredHeight: 640 * Style.uiScaleRatio

  property int currentTabIndex: 0
  property string selectedNoteId: ""
  property string draftTitle: ""
  property string draftBody: ""

  function summaryValue(name) {
    var summary = main ? main.summary() : null;
    return summary && summary[name] !== undefined ? summary[name] : 0;
  }

  function notesList() { return main ? main.notesData : []; }
  function todosList() { return main ? main.todosData : []; }

  function refreshEditorFromSelection() {
    if (!main || !selectedNoteId) {
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
    color: Color.mSurface
    radius: Style.radiusL
    border.color: Qt.alpha(Color.mOutline, 0.2)
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      Rectangle {
        Layout.fillWidth: true
        color: Qt.alpha(Color.mPrimary, 0.08)
        radius: Style.radiusL
        border.color: Qt.alpha(Color.mPrimary, 0.16)
        border.width: 1
        implicitHeight: heroLayout.implicitHeight + (Style.marginM * 2)

        ColumnLayout {
          id: heroLayout
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            Rectangle {
              Layout.preferredWidth: Math.round(42 * Style.uiScaleRatio)
              Layout.preferredHeight: Math.round(42 * Style.uiScaleRatio)
              radius: width / 2
              color: Qt.alpha(Color.mPrimary, 0.14)
              border.color: Qt.alpha(Color.mPrimary, 0.22)
              border.width: 1

              NIcon {
                anchors.centerIn: parent
                icon: "notes"
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
                font.weight: Style.fontWeightBold
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

            Rectangle {
              Layout.alignment: Qt.AlignTop
              radius: height / 2
              color: Qt.alpha(Color.mPrimary, 0.14)
              border.color: Qt.alpha(Color.mOutline, 0.12)
              border.width: 1
              implicitHeight: badgeText.implicitHeight + (Style.marginS * 2)
              implicitWidth: badgeText.implicitWidth + (Style.marginM * 2)

              NText {
                id: badgeText
                anchors.centerIn: parent
                text: root.currentTabIndex === 0 ? "Scratchpad" : (root.currentTabIndex === 1 ? "Notes" : "Tasks")
                pointSize: Style.fontSizeXS
                font.weight: Font.Medium
                color: Color.mPrimary
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            Repeater {
              model: [
                { label: "Active Tasks", value: root.summaryValue("activeTodos"), tabIndex: 2 },
                { label: "Notes", value: root.summaryValue("notes"), tabIndex: 1 },
                { label: "Scratchpad", value: root.summaryValue("scratchpadChars") + " chars", tabIndex: 0 }
              ]

              delegate: Rectangle {
                required property var modelData
                readonly property bool isActive: root.currentTabIndex === modelData.tabIndex
                Layout.fillWidth: true
                radius: Style.radiusM
                color: isActive ? Qt.alpha(Color.mPrimary, 0.16) : Qt.alpha(Color.mSurfaceVariant, 0.48)
                border.color: isActive ? Qt.alpha(Color.mPrimary, 0.28) : Qt.alpha(Color.mOutline, 0.10)
                border.width: 1
                implicitHeight: summaryCol.implicitHeight + (Style.marginM * 2)

                ColumnLayout {
                  id: summaryCol
                  anchors.fill: parent
                  anchors.margins: Style.marginM
                  spacing: 2

                  NText {
                    text: modelData.label
                    pointSize: Style.fontSizeXS
                    color: isActive ? Color.mPrimary : Color.mSecondary
                  }

                  NText {
                    text: String(modelData.value)
                    pointSize: Style.fontSizeL
                    font.weight: Font.Medium
                    color: isActive ? Color.mPrimary : Color.mOnSurface
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.currentTabIndex = modelData.tabIndex
                }
              }
            }
          }
        }
      }

      StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: root.currentTabIndex

        Rectangle {
          radius: Style.radiusL
          color: Qt.alpha(Color.mSurfaceVariant, 0.42)
          border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.10)
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
                text: "Fast Capture"
                pointSize: Style.fontSizeM
                font.weight: Font.Medium
                color: Color.mOnSurface
              }

              NButton {
                text: "Save as Note"
                icon: "note"
                backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
                textColor: Color.mOnSurface
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
                icon: "backspace"
                backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
                textColor: Color.mOnSurface
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
              radius: Style.radiusM
              color: Qt.alpha(Color.mSurface, 0.9)
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
              if (main && scratchpadEditor.text !== main.scratchpadText)
                main.setScratchpad(scratchpadEditor.text);
            }
          }
        }

        RowLayout {
          spacing: Style.marginM

          Rectangle {
            Layout.preferredWidth: 300 * Style.uiScaleRatio
            Layout.fillHeight: true
            radius: Style.radiusL
            color: Qt.alpha(Color.mSurfaceVariant, 0.42)
            border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.10)
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
                  icon: "note"
                  backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
                  textColor: Color.mOnSurface
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
                    color: root.selectedNoteId === modelData.id ? Qt.alpha(Color.mPrimary, 0.10) : Qt.alpha(Color.mSurface, 0.9)
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

                        Rectangle {
                          visible: !!modelData.pinned
                          radius: Style.radiusS
                          color: Qt.alpha(Color.mPrimary, 0.12)
                          implicitWidth: pinIcon.implicitWidth + (Style.marginXS * 2)
                          implicitHeight: pinIcon.implicitHeight + (Style.marginXS * 2)

                          NIcon {
                            id: pinIcon
                            anchors.centerIn: parent
                            icon: "pin"
                            pointSize: Style.fontSizeXS
                            color: Color.mPrimary
                          }
                        }
                      }

                      NText {
                        text: modelData.body.replace(/\n/g, " ")
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
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
            radius: Style.radiusL
            color: Qt.alpha(Color.mSurfaceVariant, 0.42)
            border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.10)
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: Style.marginM

              TextField {
                Layout.fillWidth: true
                placeholderText: "Title"
                text: root.draftTitle
                onTextChanged: root.draftTitle = text
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.radiusM
                color: Qt.alpha(Color.mSurface, 0.9)
                border.color: Qt.alpha(Color.mOutline, 0.12)
                border.width: 1

                ScrollView {
                  anchors.fill: parent
                  anchors.margins: 1
                  clip: true

                  TextArea {
                    text: root.draftBody
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    padding: Style.marginM
                    placeholderText: "Write your note..."
                    color: Color.mOnSurface
                    background: null
                    onTextChanged: root.draftBody = text
                  }
                }
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NButton {
                  Layout.fillWidth: true
                  text: root.selectedNoteId ? "Save" : "Create"
                  icon: "device-floppy"
                  backgroundColor: Qt.alpha(Color.mPrimary, 0.14)
                  textColor: Color.mPrimary
                  enabled: !!main
                  onClicked: root.saveEditorNote()
                }

                NButton {
                  Layout.fillWidth: true
                  text: root.selectedNoteId && main && main.noteById(root.selectedNoteId) && main.noteById(root.selectedNoteId).pinned ? "Unpin" : "Pin"
                  icon: "pin"
                  backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
                  textColor: Color.mOnSurface
                  enabled: !!main && !!root.selectedNoteId
                  onClicked: if (main && root.selectedNoteId) main.togglePin(root.selectedNoteId)
                }

                NButton {
                  Layout.fillWidth: true
                  text: "Delete"
                  icon: "trash"
                  backgroundColor: Qt.alpha(Color.mError, 0.10)
                  textColor: Color.mError
                  enabled: !!main && !!root.selectedNoteId
                  onClicked: root.deleteEditorNote()
                }
              }
            }
          }
        }

        Rectangle {
          radius: Style.radiusL
          color: Qt.alpha(Color.mSurfaceVariant, 0.42)
          border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.10)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NText {
              text: "Active Tasks"
              pointSize: Style.fontSizeM
              font.weight: Font.Medium
              color: Color.mOnSurface
            }

            ScrollView {
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true

              ColumnLayout {
                width: parent.width
                spacing: Style.marginS

                Repeater {
                  model: root.todosList()

                  delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    radius: Style.radiusS
                    color: Qt.alpha(Color.mSurface, 0.9)
                    border.color: Qt.alpha(Color.mOutline, 0.08)
                    border.width: 1
                    implicitHeight: todoCol.implicitHeight + (Style.marginM * 2)

                    ColumnLayout {
                      id: todoCol
                      anchors.fill: parent
                      anchors.margins: Style.marginM
                      spacing: Style.marginS

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        CheckBox {
                          checked: !!modelData.done
                          onToggled: if (main) main.toggleTodo(modelData.id)
                        }

                        NText {
                          Layout.fillWidth: true
                          text: modelData.text
                          wrapMode: Text.WordWrap
                          color: modelData.done ? Color.mOnSurfaceVariant : Color.mOnSurface
                          font.strikeout: !!modelData.done
                        }

                        Rectangle {
                          radius: Style.radiusS
                          color: Qt.alpha(root.priorityColor(modelData.priority), 0.12)
                          border.color: Qt.alpha(root.priorityColor(modelData.priority), 0.22)
                          border.width: 1
                          implicitWidth: priorityText.implicitWidth + (Style.marginS * 2)
                          implicitHeight: priorityText.implicitHeight + (Style.marginXS * 2)

                          NText {
                            id: priorityText
                            anchors.centerIn: parent
                            text: root.priorityLabel(modelData.priority)
                            pointSize: Style.fontSizeXS
                            color: root.priorityColor(modelData.priority)
                          }
                        }
                      }

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NButton {
                          Layout.fillWidth: true
                          text: "Priority"
                          icon: "flag"
                          backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
                          textColor: Color.mOnSurface
                          onClicked: if (main) main.cycleTodoPriority(modelData.id)
                        }

                        NButton {
                          Layout.fillWidth: true
                          text: "Remove"
                          icon: "trash"
                          backgroundColor: Qt.alpha(Color.mError, 0.10)
                          textColor: Color.mError
                          onClicked: if (main) main.removeTodo(modelData.id)
                        }
                      }
                    }
                  }
                }

                NText {
                  visible: root.todosList().length === 0
                  text: "No active tasks yet."
                  color: Color.mOnSurfaceVariant
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              TextField {
                id: todoInput
                Layout.fillWidth: true
                placeholderText: "Add a task"
                onAccepted: addTodoButton.clicked()
              }

              NButton {
                id: addTodoButton
                text: "Add"
                icon: "plus"
                backgroundColor: Qt.alpha(Color.mPrimary, 0.14)
                textColor: Color.mPrimary
                enabled: !!main && todoInput.text.trim() !== ""
                onClicked: {
                  if (!main)
                    return;
                  main.addTodo(todoInput.text, "medium");
                  todoInput.text = "";
                }
              }
            }
          }
        }
      }
    }
  }
}
