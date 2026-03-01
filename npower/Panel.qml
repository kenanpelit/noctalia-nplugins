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
  readonly property real twoColumnButtonWidth: Math.max(150 * Style.uiScaleRatio, Math.floor((contentColumn.width - Style.marginS) / 2))
  readonly property real threeColumnButtonWidth: Math.max(108 * Style.uiScaleRatio, Math.floor((contentColumn.width - (Style.marginS * 2)) / 3))

  function applyButtonWidth(item, width) {
    if (!item)
      return;
    item.Layout.minimumWidth = width;
    item.Layout.preferredWidth = width;
    item.Layout.maximumWidth = width;
  }

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
              text: "NPower"
              font.pointSize: Style.fontSizeL * Style.uiScaleRatio
              font.weight: Font.Bold
            }

            NText {
              text: main ? ((main.onAc ? "AC power" : (main.onBattery ? "Battery power" : "Unknown source")) + " | " + main.profile) : "Checking current power state..."
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeS * Style.uiScaleRatio
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
              border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.12)
              border.width: 1

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
          border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.12)
          border.width: 1
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

            GridLayout {
              Layout.fillWidth: true
              columns: 3
              columnSpacing: Style.marginS
              rowSpacing: Style.marginS

              NButton {
                text: "Saver"
                icon: "battery-1"
                enabled: !!main && !main.actionBusy
                Component.onCompleted: root.applyButtonWidth(this, root.threeColumnButtonWidth)
                onClicked: main.setProfile("power-saver")
              }

              NButton {
                text: "Balanced"
                icon: "adjustments"
                enabled: !!main && !main.actionBusy
                Component.onCompleted: root.applyButtonWidth(this, root.threeColumnButtonWidth)
                onClicked: main.setProfile("balanced")
              }

              NButton {
                text: "Performance"
                icon: "bolt"
                enabled: !!main && !main.actionBusy
                Component.onCompleted: root.applyButtonWidth(this, root.threeColumnButtonWidth)
                onClicked: main.setProfile("performance")
              }
            }

            GridLayout {
              Layout.fillWidth: true
              columns: 2
              columnSpacing: Style.marginS
              rowSpacing: Style.marginS

              NButton {
                text: main && main.autoProfileLocked ? "Unlock Auto" : "Lock Auto"
                icon: main && main.autoProfileLocked ? "lock-open" : "lock"
                enabled: !!main && !main.actionBusy
                Component.onCompleted: root.applyButtonWidth(this, root.twoColumnButtonWidth)
                onClicked: main.toggleAutoProfileLock()
              }

              NButton {
                text: "Cycle Mode"
                icon: "arrows-shuffle"
                enabled: !!main && !main.actionBusy
                Component.onCompleted: root.applyButtonWidth(this, root.twoColumnButtonWidth)
                onClicked: main.cycleProfile()
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
            spacing: Style.marginM

            NText {
              text: "Session & Idle"
              font.weight: Font.DemiBold
            }

            GridLayout {
              Layout.fillWidth: true
              columns: 2
              columnSpacing: Style.marginS
              rowSpacing: Style.marginS

              NButton {
                text: "Idle Inhibit"
                icon: "hourglass"
                enabled: !!main && !main.actionBusy && main.idleCommandAvailable
                Component.onCompleted: root.applyButtonWidth(this, root.twoColumnButtonWidth)
                onClicked: main.toggleIdleInhibit()
              }

              NButton {
                text: "Lock Screen"
                icon: "lock"
                enabled: !!main && !main.actionBusy
                Component.onCompleted: root.applyButtonWidth(this, root.twoColumnButtonWidth)
                onClicked: main.lockSession()
              }

              NButton {
                text: "Suspend"
                icon: "moon"
                enabled: !!main && !main.actionBusy
                Component.onCompleted: root.applyButtonWidth(this, root.twoColumnButtonWidth)
                onClicked: main.suspendSession()
              }

              NButton {
                text: "Lock & Suspend"
                icon: "lock-pause"
                enabled: !!main && !main.actionBusy
                Component.onCompleted: root.applyButtonWidth(this, root.twoColumnButtonWidth)
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
