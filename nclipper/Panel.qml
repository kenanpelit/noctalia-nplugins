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

  property real contentPreferredWidth: Math.round(560 * Style.uiScaleRatio)
  property real contentPreferredHeight: Math.round(680 * Style.uiScaleRatio)

  Rectangle {
    id: panelFrame
    anchors.fill: parent
    color: "transparent"

    Flickable {
      anchors.fill: parent
      contentWidth: width
      contentHeight: contentColumn.implicitHeight + (Style.marginL * 2)
      clip: true

      ColumnLayout {
        id: contentColumn
        x: Style.marginL
        y: Style.marginL
        width: parent.width - (Style.marginL * 2)
        spacing: Style.marginL

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            NText {
              text: "NClipper"
              font.pointSize: Style.fontSizeL * Style.uiScaleRatio
              font.weight: Font.Bold
            }

            NText {
              text: main ? (main.clipCount + " saved | " + main.pinnedCount + " pinned") : "Checking clipboard state..."
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeS * Style.uiScaleRatio
            }
          }

          NButton {
            text: "Refresh"
            icon: "refresh"
            enabled: !!main && !main.actionBusy
            onClicked: main.refreshClipboard()
          }
        }

        Rectangle {
          Layout.fillWidth: true
          color: Color.mSurfaceVariant
          radius: Style.radiusL
          border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.12)
          border.width: 1
          implicitHeight: clipboardColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: clipboardColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NText {
              text: "Current Clipboard"
              font.weight: Font.DemiBold
            }

            Rectangle {
              Layout.fillWidth: true
              color: Qt.alpha(Color.mSurface, 0.35)
              radius: Style.radiusM
              implicitHeight: previewText.implicitHeight + (Style.marginM * 2)

              NText {
                id: previewText
                anchors.fill: parent
                anchors.margins: Style.marginM
                text: main && String(main.currentClipboard || "").trim() !== "" ? main.currentClipboard : "Clipboard is empty or non-text right now."
                wrapMode: Text.Wrap
                color: main && String(main.currentClipboard || "").trim() !== "" ? Color.mOnSurface : Color.mOnSurfaceVariant
              }
            }

            GridLayout {
              Layout.fillWidth: true
              columns: 3
              columnSpacing: Style.marginS
              rowSpacing: Style.marginS

              NButton { Layout.fillWidth: true; text: "Save Clip"; icon: "device-floppy"; enabled: !!main && !main.actionBusy && main.currentClipboard.trim() !== ""; onClicked: main.saveCurrent() }
              NButton { Layout.fillWidth: true; text: "Pin Current"; icon: "pin"; enabled: !!main && !main.actionBusy && main.currentClipboard.trim() !== ""; onClicked: main.pinCurrent() }
              NButton { Layout.fillWidth: true; text: "Copy Again"; icon: "copy"; enabled: !!main && !main.actionBusy && main.currentClipboard.trim() !== ""; onClicked: main.copyText(main.currentClipboard) }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          color: Color.mSurfaceVariant
          radius: Style.radiusL
          border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.12)
          border.width: 1
          implicitHeight: savedColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: savedColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NText {
              text: "Saved Clips"
              font.weight: Font.DemiBold
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              Repeater {
                model: main ? main.itemsData : []

                Rectangle {
                  Layout.fillWidth: true
                  color: Qt.alpha(Color.mSurface, 0.35)
                  radius: Style.radiusM
                  border.color: modelData.pinned ? Qt.alpha(Color.mPrimary, 0.28) : Qt.alpha(Color.mOnSurfaceVariant, 0.08)
                  border.width: 1
                  implicitHeight: itemColumn.implicitHeight + (Style.marginM * 2)

                  ColumnLayout {
                    id: itemColumn
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginS

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: Style.marginS

                      NText {
                        text: modelData.preview
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        font.weight: modelData.pinned ? Font.DemiBold : Font.Normal
                      }

                      NText {
                        visible: modelData.pinned
                        text: "Pinned"
                        color: Color.mPrimary
                        pointSize: Style.fontSizeS * Style.uiScaleRatio
                      }
                    }

                    NText {
                      text: modelData.text.length + " chars"
                      color: Color.mOnSurfaceVariant
                      pointSize: Style.fontSizeS * Style.uiScaleRatio
                    }

                    GridLayout {
                      Layout.fillWidth: true
                      columns: 3
                      columnSpacing: Style.marginS
                      rowSpacing: Style.marginS

                      NButton { Layout.fillWidth: true; text: "Copy"; icon: "copy"; enabled: !!main && !main.actionBusy; onClicked: main.copyText(modelData.text) }
                      NButton { Layout.fillWidth: true; text: modelData.pinned ? "Unpin" : "Pin"; icon: modelData.pinned ? "pin-off" : "pin"; enabled: !!main && !main.actionBusy; onClicked: main.togglePinned(modelData.id) }
                      NButton { Layout.fillWidth: true; text: "Remove"; icon: "trash"; enabled: !!main && !main.actionBusy; onClicked: main.removeItem(modelData.id) }
                    }
                  }
                }
              }

              NText {
                visible: !!main && main.itemsData.length === 0
                text: "No saved clips yet. Save or pin the current clipboard to start building a reusable set."
                color: Color.mOnSurfaceVariant
                wrapMode: Text.Wrap
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          color: Color.mSurfaceVariant
          radius: Style.radiusL
          border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.12)
          border.width: 1
          implicitHeight: statusColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: statusColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NText { text: "Status"; font.weight: Font.DemiBold }
            NText { text: main && main.lastAction ? ("Last action: " + main.lastAction) : "Ready"; color: main && main.lastAction ? Color.mPrimary : Color.mOnSurfaceVariant; wrapMode: Text.Wrap }
            NText { visible: !!(main && main.lastError); text: main ? main.lastError : ""; color: Color.mError; wrapMode: Text.Wrap }
          }
        }
      }
    }
  }
}
