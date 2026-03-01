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
  property real contentPreferredHeight: Math.round(640 * Style.uiScaleRatio)

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
        spacing: Style.marginM

        Rectangle {
          Layout.fillWidth: true
          color: Color.mSurfaceVariant
          radius: Style.radiusL
          border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.12)
          border.width: 1
          implicitHeight: heroColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: heroColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginM

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                NText {
                  text: "NSystem"
                  font.pointSize: Style.fontSizeL * Style.uiScaleRatio
                  font.weight: Font.Bold
                }

                NText {
                  text: main ? ("CPU " + main.cpuUsage + "% • RAM " + main.memPercent + "% • Disk " + main.diskPercent + "%") : "Reading live system state..."
                  color: Color.mOnSurfaceVariant
                  pointSize: Style.fontSizeS * Style.uiScaleRatio
                  wrapMode: Text.Wrap
                }
              }

              NButton {
                text: "Refresh"
                icon: "refresh"
                enabled: !!main && !main.actionBusy
                onClicked: main.refresh()
              }
            }

            GridLayout {
              Layout.fillWidth: true
              columns: 2
              columnSpacing: Style.marginS
              rowSpacing: Style.marginS

              Repeater {
                model: [
                  { title: "CPU", value: main ? (main.cpuUsage + "%") : "--" },
                  { title: "Memory", value: main ? (main.memUsedGiB.toFixed(1) + " / " + main.memTotalGiB.toFixed(1) + " GiB") : "--" },
                  { title: "Disk", value: main ? (main.diskUsedGiB.toFixed(1) + " / " + main.diskTotalGiB.toFixed(1) + " GiB") : "--" },
                  { title: "Load", value: main ? main.load1.toFixed(2) : "--" },
                  { title: "Temp", value: main ? (main.tempC >= 0 ? (main.tempC.toFixed(1) + "°C") : "Unavailable") : "--" },
                  { title: "Uptime", value: main ? main.uptime : "--" }
                ]

                Rectangle {
                  Layout.fillWidth: true
                  color: Qt.alpha(Color.mSurface, 0.32)
                  radius: Style.radiusM
                  border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.08)
                  border.width: 1
                  implicitHeight: statColumn.implicitHeight + (Style.marginS * 2)

                  ColumnLayout {
                    id: statColumn
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: 2

                    NText {
                      text: modelData.title
                      color: Color.mOnSurfaceVariant
                      pointSize: Style.fontSizeS * Style.uiScaleRatio
                    }

                    NText {
                      text: modelData.value
                      font.weight: Font.DemiBold
                      wrapMode: Text.Wrap
                    }
                  }
                }
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
          implicitHeight: processColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: processColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NText {
              text: "Top Process"
              font.weight: Font.DemiBold
            }

            NText {
              text: main ? (main.topProcessName + " • " + main.topProcessCpu.toFixed(1) + "% CPU") : "Checking..."
              wrapMode: Text.Wrap
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          color: Color.mSurfaceVariant
          radius: Style.radiusL
          border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.12)
          border.width: 1
          implicitHeight: actionsColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: actionsColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NText {
              text: "Quick Tools"
              font.weight: Font.DemiBold
            }

            GridLayout {
              Layout.fillWidth: true
              columns: 3
              columnSpacing: Style.marginS
              rowSpacing: Style.marginS

              NButton {
                Layout.fillWidth: true
                text: "btop"
                icon: "chart-bar"
                enabled: !!main && !main.actionBusy
                onClicked: main.openBtop()
              }

              NButton {
                Layout.fillWidth: true
                text: "htop"
                icon: "activity"
                enabled: !!main && !main.actionBusy
                onClicked: main.openHtop()
              }

              NButton {
                Layout.fillWidth: true
                text: "top"
                icon: "terminal-2"
                enabled: !!main && !main.actionBusy
                onClicked: main.openTop()
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
          implicitHeight: footerColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: footerColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NText {
              visible: !!(main && main.lastAction)
              text: main ? ("Last action: " + main.lastAction) : ""
              color: Color.mPrimary
              wrapMode: Text.Wrap
            }

            NText {
              visible: !!(main && main.lastError)
              text: main ? main.lastError : ""
              color: Color.mError
              wrapMode: Text.Wrap
            }
          }
        }
      }
    }
  }
}
