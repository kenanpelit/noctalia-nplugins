import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.Compositor
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property var screen: null
  readonly property var main: pluginApi ? pluginApi.mainInstance : null
  readonly property var groups: main ? main.groupedRowsForScreen(screen?.name || "") : []
  readonly property var summary: main ? main.summaryForScreen(screen?.name || "") : ({ "workspaces": 0, "occupied": 0, "windows": 0 })
  readonly property var geometryPlaceholder: frame
  readonly property bool allowAttach: true

  property real contentPreferredWidth: 900 * Style.uiScaleRatio
  property real contentPreferredHeight: 620 * Style.uiScaleRatio

  Rectangle {
    id: frame
    anchors.fill: parent
    radius: Style.radiusL
    color: Color.mSurface
    border.color: Qt.alpha(Color.mOutline, 0.18)
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      Rectangle {
        Layout.fillWidth: true
        radius: Style.radiusL
        color: Qt.alpha(Color.mPrimary, 0.08)
        border.color: Qt.alpha(Color.mPrimary, 0.18)
        border.width: 1
        implicitHeight: hero.implicitHeight + (Style.marginM * 2)

        ColumnLayout {
          id: hero
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

              NIcon {
                anchors.centerIn: parent
                icon: "layout-grid"
                pointSize: Style.fontSizeL
                color: Color.mPrimary
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              NText {
                text: "NWorkspace"
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
              }

              NText {
                text: "Fast workspace radar with per-output grouping, live window counts, and direct window focus."
                pointSize: Style.fontSizeXS
                color: Color.mSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            Repeater {
              model: [
                { label: "Visible Workspaces", value: summary.workspaces },
                { label: "Occupied", value: summary.occupied },
                { label: "Windows", value: summary.windows }
              ]

              delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                radius: Style.radiusM
                color: Qt.alpha(Color.mSurfaceVariant, 0.52)
                border.color: Qt.alpha(Color.mOutline, 0.10)
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
                    color: Color.mSecondary
                  }

                  NText {
                    text: String(modelData.value)
                    pointSize: Style.fontSizeL
                    font.weight: Font.Medium
                    color: Color.mOnSurface
                  }
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NButton {
              text: main && main.hideEmpty ? "Show Empty" : "Hide Empty"
              icon: "filter"
              outlined: true
              onClicked: main?.setSetting("hideEmpty", !main.hideEmpty)
            }

            NButton {
              text: main && main.followFocusedOutput ? "Following Focused Output" : "Pinned To This Output"
              icon: "monitor"
              outlined: true
              onClicked: main?.setSetting("followFocusedOutput", !main.followFocusedOutput)
            }

            NButton {
              text: "Cycle Label Mode"
              icon: "apps"
              outlined: true
              onClicked: main?.cycleLabelMode()
            }
          }
        }
      }

      ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ColumnLayout {
          width: parent.width
          spacing: Style.marginM

          Repeater {
            model: root.groups

            delegate: Rectangle {
              required property var modelData
              readonly property var group: modelData
              Layout.fillWidth: true
              radius: Style.radiusL
              color: Qt.alpha(Color.mSurfaceVariant, 0.42)
              border.color: group.isFocusedOutput ? Qt.alpha(Color.mPrimary, 0.22) : Qt.alpha(Color.mOutline, 0.10)
              border.width: 1
              implicitHeight: groupColumn.implicitHeight + (Style.marginM * 2)

              ColumnLayout {
                id: groupColumn
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Style.marginS

                  NText {
                    text: group.output
                    pointSize: Style.fontSizeM
                    font.weight: Font.Medium
                    color: group.isFocusedOutput ? Color.mPrimary : Color.mOnSurface
                    Layout.fillWidth: true
                  }

                  Rectangle {
                    radius: height / 2
                    color: Qt.alpha(group.isFocusedOutput ? Color.mPrimary : Color.mOnSurfaceVariant, 0.12)
                    implicitHeight: badgeText.implicitHeight + Style.marginS * 2
                    implicitWidth: badgeText.implicitWidth + Style.marginM * 2

                    NText {
                      id: badgeText
                      anchors.centerIn: parent
                      text: group.items.length + " ws / " + group.totalWindows + " windows"
                      pointSize: Style.fontSizeXXS
                      font.weight: Font.Medium
                      color: group.isFocusedOutput ? Color.mPrimary : Color.mSecondary
                    }
                  }
                }

                Repeater {
                  model: group.items

                  delegate: Rectangle {
                    required property var modelData
                    readonly property var workspace: modelData
                    Layout.fillWidth: true
                    radius: Style.radiusM
                    color: workspace.isFocused ? Qt.alpha(Color.mPrimary, 0.12) : Qt.alpha(Color.mSurface, 0.78)
                    border.color: workspace.isFocused
                                   ? Qt.alpha(Color.mPrimary, 0.24)
                                   : Qt.alpha(workspace.isUrgent ? Color.mError : Color.mOutline, 0.10)
                    border.width: 1
                    implicitHeight: workspaceColumn.implicitHeight + (Style.marginM * 2)

                    ColumnLayout {
                      id: workspaceColumn
                      anchors.fill: parent
                      anchors.margins: Style.marginM
                      spacing: Style.marginS

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        Rectangle {
                          Layout.preferredWidth: Math.round(34 * Style.uiScaleRatio)
                          Layout.preferredHeight: Math.round(34 * Style.uiScaleRatio)
                          radius: Style.radiusM
                          color: Qt.alpha(workspace.isUrgent ? Color.mError : (workspace.isFocused ? Color.mPrimary : Color.mSurfaceVariant), workspace.isFocused ? 0.18 : 0.82)
                          border.color: Qt.alpha(workspace.isUrgent ? Color.mError : (workspace.isFocused ? Color.mPrimary : Color.mOutline), workspace.isFocused ? 0.24 : 0.10)
                          border.width: 1

                          NText {
                            anchors.centerIn: parent
                            text: workspace.indexLabel
                            pointSize: Style.fontSizeS
                            font.family: Settings.data.ui.fontFixed
                            font.weight: Font.Bold
                            color: workspace.isUrgent ? Color.mError : (workspace.isFocused ? Color.mPrimary : Color.mOnSurface)
                          }
                        }

                        ColumnLayout {
                          Layout.fillWidth: true
                          spacing: 1

                          NText {
                            text: workspace.name || ("Workspace " + workspace.indexLabel)
                            pointSize: Style.fontSizeM
                            font.weight: workspace.isFocused ? Font.Bold : Font.Medium
                            color: workspace.isFocused ? Color.mPrimary : Color.mOnSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                          }

                          NText {
                            visible: !!workspace.name
                            text: "Workspace " + workspace.indexLabel
                            pointSize: Style.fontSizeXXS
                            font.weight: Font.Medium
                            color: Color.mSecondary
                          }
                        }

                        Rectangle {
                          visible: workspace.isFocused || workspace.isActive || workspace.isUrgent
                          radius: height / 2
                          color: Qt.alpha(workspace.isUrgent ? Color.mError : Color.mPrimary, 0.12)
                          implicitHeight: stateText.implicitHeight + Style.marginXS * 2
                          implicitWidth: stateText.implicitWidth + Style.marginM * 2

                          NText {
                            id: stateText
                            anchors.centerIn: parent
                            text: workspace.isUrgent ? "Urgent" : (workspace.isFocused ? "Focused" : "Visible")
                            pointSize: Style.fontSizeXXS
                            font.weight: Font.Medium
                            color: workspace.isUrgent ? Color.mError : Color.mPrimary
                          }
                        }

                        Item { Layout.fillWidth: true }

                        NButton {
                          text: "Go"
                          icon: "arrow-right"
                          outlined: true
                          onClicked: CompositorService.switchToWorkspace(workspace)
                        }
                      }

                      NText {
                        text: workspace.windowCount > 0
                                ? workspace.windowCount + " windows"
                                : "No windows"
                        pointSize: Style.fontSizeXS
                        color: Color.mSecondary
                      }

                      Flow {
                        Layout.fillWidth: true
                        spacing: Style.marginXS

                        Repeater {
                          model: workspace.windows

                          delegate: Rectangle {
                            required property var modelData
                            readonly property var windowInfo: modelData
                            radius: Style.radiusM
                            color: windowInfo.isFocused ? Qt.alpha(Color.mPrimary, 0.14) : Qt.alpha(Color.mSurfaceVariant, 0.62)
                            border.color: windowInfo.isFocused ? Qt.alpha(Color.mPrimary, 0.24) : Qt.alpha(Color.mOutline, 0.10)
                            border.width: 1
                            implicitHeight: chipLabel.implicitHeight + Style.marginS * 2
                            implicitWidth: Math.min(chipLabel.implicitWidth + Style.marginL * 2, Math.round(320 * Style.uiScaleRatio))

                            NText {
                              id: chipLabel
                              anchors.centerIn: parent
                              text: {
                                var title = String(windowInfo.title || "").trim();
                                var app = CompositorService.getCleanAppName(windowInfo.appId, title);
                                return title ? (app + " — " + title) : app;
                              }
                              pointSize: Style.fontSizeXS
                              color: windowInfo.isFocused ? Color.mPrimary : Color.mOnSurface
                              elide: Text.ElideRight
                              width: Math.min(implicitWidth, Math.round(280 * Style.uiScaleRatio))
                            }

                            MouseArea {
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: CompositorService.focusWindow(windowInfo)
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
    }
  }
}
