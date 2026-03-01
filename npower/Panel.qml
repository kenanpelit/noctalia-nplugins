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

  property real contentPreferredWidth: Math.round(540 * Style.uiScaleRatio)
  property real contentPreferredHeight: Math.round(620 * Style.uiScaleRatio)

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
                  text: "NPower"
                  font.pointSize: Style.fontSizeL * Style.uiScaleRatio
                  font.weight: Font.Bold
                }

                NText {
                  text: {
                    if (!main)
                      return "Reading current power state...";
                    var source = main.onAc ? "AC" : (main.onBattery ? "Battery" : "Unknown");
                    var battery = main.batteryAvailable && main.batteryPercent >= 0 ? (main.batteryPercent + "%") : "No battery";
                    return source + " • " + main.profile + " • " + battery;
                  }
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
                  { title: "Source", value: main ? (main.onAc ? "AC" : (main.onBattery ? "Battery" : "Unknown")) : "Checking..." },
                  { title: "Battery", value: main ? (main.batteryAvailable && main.batteryPercent >= 0 ? (main.batteryPercent + "%") : "Unavailable") : "Checking..." },
                  { title: "Profile", value: main ? main.profile : "Checking..." },
                  { title: "Auto", value: main ? (main.autoProfileLocked ? "Locked" : (main.pppTimerActive ? "Active" : "Manual")) : "Checking..." }
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
          implicitHeight: controlsColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: controlsColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NText {
              text: "Power Controls"
              font.weight: Font.DemiBold
            }

            GridLayout {
              Layout.fillWidth: true
              columns: 2
              columnSpacing: Style.marginS
              rowSpacing: Style.marginS

              NButton {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Saver"
                icon: "battery-1"
                enabled: !!main && !main.actionBusy
                onClicked: main.setProfile("power-saver")
              }

              NButton {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Balanced"
                icon: "adjustments"
                enabled: !!main && !main.actionBusy
                onClicked: main.setProfile("balanced")
              }

              NButton {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Boost"
                icon: "bolt"
                enabled: !!main && !main.actionBusy
                onClicked: main.setProfile("performance")
              }

              NButton {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Cycle"
                icon: "arrows-shuffle"
                enabled: !!main && !main.actionBusy
                onClicked: main.cycleProfile()
              }

              NButton {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: main && main.autoProfileLocked ? "Unlock Auto" : "Lock Auto"
                icon: main && main.autoProfileLocked ? "lock-open" : "lock"
                enabled: !!main && !main.actionBusy
                onClicked: main.toggleAutoProfileLock()
              }

              NButton {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Idle Toggle"
                icon: "hourglass"
                enabled: !!main && !main.actionBusy && main.idleCommandAvailable
                onClicked: main.toggleIdleInhibit()
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
          implicitHeight: sessionColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: sessionColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NText {
              text: "Session Actions"
              font.weight: Font.DemiBold
            }

            GridLayout {
              Layout.fillWidth: true
              columns: 2
              columnSpacing: Style.marginS
              rowSpacing: Style.marginS

              NButton {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Lock"
                icon: "lock"
                enabled: !!main && !main.actionBusy
                onClicked: main.lockSession()
              }

              NButton {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Suspend"
                icon: "moon"
                enabled: !!main && !main.actionBusy
                onClicked: main.suspendSession()
              }

              NButton {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.columnSpan: 2
                text: "Lock + Suspend"
                icon: "lock-pause"
                enabled: !!main && !main.actionBusy
                onClicked: main.lockAndSuspend()
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
          implicitHeight: stateColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: stateColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NText {
              text: "Runtime State"
              font.weight: Font.DemiBold
            }

            NText {
              text: main ? ("ppp-auto-profile.timer: " + (main.pppTimerActive ? "active" : "inactive")) : "ppp-auto-profile.timer: checking"
              color: Color.mOnSurfaceVariant
              wrapMode: Text.Wrap
            }

            NText {
              text: main ? ("stasis.service: " + (main.stasisActive ? "active" : "inactive")) : "stasis.service: checking"
              color: Color.mOnSurfaceVariant
              wrapMode: Text.Wrap
            }

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
