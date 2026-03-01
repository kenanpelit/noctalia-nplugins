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
        spacing: Style.marginL

        RowLayout {
          Layout.fillWidth: true

          NText {
            text: "NPower"
            font.pointSize: Style.fontSizeL * Style.uiScaleRatio
            font.weight: Font.Bold
            Layout.fillWidth: true
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
          columnSpacing: Style.marginM
          rowSpacing: Style.marginM

          Repeater {
            model: [
              { title: "Source", value: main ? (main.onAc ? "AC" : (main.onBattery ? "Battery" : "Unknown")) : "Checking..." },
              { title: "Battery", value: main ? (main.batteryAvailable && main.batteryPercent >= 0 ? (main.batteryPercent + "% | " + main.batteryStatus) : "Unavailable") : "Checking..." },
              { title: "Profile", value: main ? main.profile : "Checking..." },
              { title: "Auto Profile", value: main ? (main.autoProfileLocked ? "Locked" : (main.pppTimerActive ? "Timer active" : "Manual")) : "Checking..." }
            ]

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: cardColumn.implicitHeight + (Style.marginM * 2)
              color: Color.mSurfaceVariant
              radius: Style.radiusL

              ColumnLayout {
                id: cardColumn
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: 4

                NText {
                  text: modelData.title
                  color: Color.mOnSurfaceVariant
                  pointSize: Style.fontSizeS * Style.uiScaleRatio
                }

                NText {
                  text: modelData.value
                  font.weight: Font.DemiBold
                  elide: Text.ElideRight
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          color: Color.mSurfaceVariant
          radius: Style.radiusL
          implicitHeight: profileColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: profileColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NText {
              text: "Power Profile"
              font.weight: Font.DemiBold
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              NButton { Layout.fillWidth: true; text: "Saver"; icon: "battery-1"; enabled: !!main && !main.actionBusy; onClicked: main.setProfile("power-saver") }
              NButton { Layout.fillWidth: true; text: "Balanced"; icon: "adjustments"; enabled: !!main && !main.actionBusy; onClicked: main.setProfile("balanced") }
              NButton { Layout.fillWidth: true; text: "Performance"; icon: "bolt"; enabled: !!main && !main.actionBusy; onClicked: main.setProfile("performance") }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              NButton {
                Layout.fillWidth: true
                text: main && main.autoProfileLocked ? "Unlock Auto Profile" : "Lock Auto Profile"
                icon: main && main.autoProfileLocked ? "lock-open" : "lock"
                enabled: !!main && !main.actionBusy
                onClicked: main.toggleAutoProfileLock()
              }

              NButton {
                Layout.fillWidth: true
                text: "Cycle"
                icon: "arrows-shuffle"
                enabled: !!main && !main.actionBusy
                onClicked: main.cycleProfile()
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          color: Color.mSurfaceVariant
          radius: Style.radiusL
          implicitHeight: sessionColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: sessionColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NText {
              text: "Session & Idle"
              font.weight: Font.DemiBold
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              NButton {
                Layout.fillWidth: true
                text: "Idle Toggle"
                icon: "hourglass"
                enabled: !!main && !main.actionBusy && main.idleCommandAvailable
                onClicked: main.toggleIdleInhibit()
              }

              NButton {
                Layout.fillWidth: true
                text: "Lock"
                icon: "lock"
                enabled: !!main && !main.actionBusy
                onClicked: main.lockSession()
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              NButton {
                Layout.fillWidth: true
                text: "Suspend"
                icon: "moon"
                enabled: !!main && !main.actionBusy
                onClicked: main.suspendSession()
              }

              NButton {
                Layout.fillWidth: true
                text: "Lock & Suspend"
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
          implicitHeight: statusColumn.implicitHeight + (Style.marginM * 2)

          ColumnLayout {
            id: statusColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NText {
              text: "System State"
              font.weight: Font.DemiBold
            }

            NText {
              text: main ? ("ppp-auto-profile.timer: " + (main.pppTimerActive ? "active" : "inactive")) : "ppp-auto-profile.timer: checking"
              color: Color.mOnSurfaceVariant
            }

            NText {
              text: main ? ("stasis.service: " + (main.stasisActive ? "active" : "inactive")) : "stasis.service: checking"
              color: Color.mOnSurfaceVariant
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
