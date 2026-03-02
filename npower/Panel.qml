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

  property real contentPreferredWidth: Math.round(440 * Style.uiScaleRatio)
  property real contentPreferredHeight: mainLayout.implicitHeight + (Style.marginL * 2)

  function profileIsActive(mode) {
    return !!(main && main.profile === mode);
  }

  function actionBackground(mode) {
    if (profileIsActive(mode))
      return Qt.alpha(Color.mPrimary, 0.16);
    if (mode === "cycle")
      return Qt.alpha(Color.mSurfaceVariant, 0.75);
    return Qt.alpha(Color.mSurfaceVariant, 0.48);
  }

  function actionTextColor(mode) {
    return profileIsActive(mode) ? Color.mPrimary : Color.mOnSurface;
  }

  function sessionBackground(kind) {
    if (kind === "lock-suspend")
      return Qt.alpha(Color.mPrimary, 0.10);
    return Qt.alpha(Color.mSurfaceVariant, 0.48);
  }

  function sourceBadgeText() {
    if (!main)
      return "Idle";
    if (main.onAc)
      return "AC";
    if (main.onBattery)
      return "Battery";
    return "Unknown";
  }

  function sourceBadgeColor() {
    if (!main)
      return Qt.alpha(Color.mSurfaceVariant, 0.85);
    if (main.onAc)
      return Qt.alpha(Color.mPrimary, 0.16);
    if (main.onBattery)
      return Qt.alpha(Color.mSecondary, 0.14);
    return Qt.alpha(Color.mSurfaceVariant, 0.85);
  }

  function sourceBadgeTextColor() {
    if (main && main.onAc)
      return Color.mPrimary;
    if (main && main.onBattery)
      return Color.mSecondary;
    return Color.mOnSurface;
  }

  Rectangle {
    id: panelFrame
    anchors.fill: parent
    color: Color.mSurface
    radius: Style.radiusL
    border.color: Qt.alpha(Color.mOutline, 0.2)
    border.width: 1

    ColumnLayout {
      id: mainLayout
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
                icon: main && main.onAc ? "plug-connected" : "battery"
                pointSize: Style.fontSizeL
                color: Color.mPrimary
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              NText {
                text: "NPower"
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
              }

              NText {
                text: {
                  if (!main)
                    return "Reading current power state...";
                  var battery = main.batteryAvailable && main.batteryPercent >= 0 ? (main.batteryPercent + "%") : "No battery";
                  return main.profile + " • " + battery;
                }
                pointSize: Style.fontSizeXS
                color: Color.mSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }

            Rectangle {
              Layout.alignment: Qt.AlignTop
              radius: height / 2
              color: root.sourceBadgeColor()
              border.color: Qt.alpha(Color.mOutline, 0.12)
              border.width: 1
              implicitHeight: badgeText.implicitHeight + (Style.marginS * 2)
              implicitWidth: badgeText.implicitWidth + (Style.marginM * 2)

              NText {
                id: badgeText
                anchors.centerIn: parent
                text: root.sourceBadgeText()
                pointSize: Style.fontSizeXS
                font.weight: Font.Medium
                color: root.sourceBadgeTextColor()
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            radius: Style.radiusM
            color: Qt.alpha(Color.mSurface, 0.9)
            border.color: Qt.alpha(Color.mOutline, 0.12)
            border.width: 1
            implicitHeight: liveLayout.implicitHeight + (Style.marginM * 2)

            RowLayout {
              id: liveLayout
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: Style.marginM

              Rectangle {
                Layout.preferredWidth: 4
                Layout.fillHeight: true
                radius: 2
                color: main && main.autoProfileLocked
                       ? Color.mPrimary
                       : Qt.alpha(Color.mOutline, 0.35)
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                NText {
                  text: main ? main.profile : "Checking..."
                  pointSize: Style.fontSizeM
                  font.weight: Font.Medium
                  color: Color.mOnSurface
                }

                NText {
                  text: main
                        ? (main.batteryAvailable && main.batteryPercent >= 0
                           ? (main.batteryPercent + "% • " + main.batteryStatus)
                           : "Desktop / no battery detected")
                        : "Reading battery state..."
                  pointSize: Style.fontSizeXS
                  color: Color.mOnSurfaceVariant
                  wrapMode: Text.WordWrap
                  Layout.fillWidth: true
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            Rectangle {
              Layout.fillWidth: true
              radius: Style.radiusS
              color: Qt.alpha(Color.mSurfaceVariant, 0.62)
              implicitHeight: profileChipText.implicitHeight + (Style.marginS * 2)

              NText {
                id: profileChipText
                anchors.centerIn: parent
                text: "Auto " + (main && main.autoProfileLocked ? "Locked" : (main && main.pppTimerActive ? "Active" : "Manual"))
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                font.weight: Font.Medium
              }
            }

            Rectangle {
              Layout.fillWidth: true
              radius: Style.radiusS
              color: Qt.alpha(Color.mSurfaceVariant, 0.62)
              implicitHeight: idleChipText.implicitHeight + (Style.marginS * 2)

              NText {
                id: idleChipText
                anchors.centerIn: parent
                text: "Stasis " + (main && main.stasisActive ? "On" : "Off")
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                font.weight: Font.Medium
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        visible: main ? main.lastError !== "" : false
        color: Qt.alpha(Color.mError, 0.1)
        radius: Style.radiusS
        border.color: Qt.alpha(Color.mError, 0.3)
        border.width: 1
        implicitHeight: errorText.implicitHeight + Style.marginM

        NText {
          id: errorText
          anchors.fill: parent
          anchors.margins: Style.marginS
          text: main ? main.lastError : ""
          color: Color.mError
          pointSize: Style.fontSizeS
          wrapMode: Text.WordWrap
        }
      }

      NText {
        Layout.fillWidth: true
        text: "Power Controls"
        pointSize: Style.fontSizeS
        font.weight: Font.Medium
        color: Color.mSecondary
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          NButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            text: "Saver"
            icon: "battery-1"
            backgroundColor: root.actionBackground("power-saver")
            textColor: root.actionTextColor("power-saver")
            enabled: !!main && !main.actionBusy
            onClicked: main.setProfile("power-saver")
          }

          NButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            text: "Balanced"
            icon: "adjustments"
            backgroundColor: root.actionBackground("balanced")
            textColor: root.actionTextColor("balanced")
            enabled: !!main && !main.actionBusy
            onClicked: main.setProfile("balanced")
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          NButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            text: "Boost"
            icon: "bolt"
            backgroundColor: root.actionBackground("performance")
            textColor: root.actionTextColor("performance")
            enabled: !!main && !main.actionBusy
            onClicked: main.setProfile("performance")
          }

          NButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            text: "Cycle"
            icon: "arrows-shuffle"
            backgroundColor: root.actionBackground("cycle")
            textColor: Color.mOnSurface
            enabled: !!main && !main.actionBusy
            onClicked: main.cycleProfile()
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          NButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            text: main && main.autoProfileLocked ? "Unlock Auto" : "Lock Auto"
            icon: main && main.autoProfileLocked ? "lock-open" : "lock"
            backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
            textColor: Color.mOnSurface
            enabled: !!main && !main.actionBusy
            onClicked: main.toggleAutoProfileLock()
          }

          NButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            text: "Idle Toggle"
            icon: "hourglass"
            backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
            textColor: Color.mOnSurface
            enabled: !!main && !main.actionBusy && main.idleCommandAvailable
            onClicked: main.toggleIdleInhibit()
          }
        }
      }

      NText {
        Layout.fillWidth: true
        text: "Session Actions"
        pointSize: Style.fontSizeS
        font.weight: Font.Medium
        color: Color.mSecondary
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          NButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            text: "Lock"
            icon: "lock"
            backgroundColor: root.sessionBackground("lock")
            textColor: Color.mOnSurface
            enabled: !!main && !main.actionBusy
            onClicked: main.lockSession()
          }

          NButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            text: "Suspend"
            icon: "moon"
            backgroundColor: root.sessionBackground("suspend")
            textColor: Color.mOnSurface
            enabled: !!main && !main.actionBusy
            onClicked: main.suspendSession()
          }
        }

        NButton {
          Layout.fillWidth: true
          text: "Lock + Suspend"
          icon: "lock-pause"
          backgroundColor: root.sessionBackground("lock-suspend")
          textColor: Color.mPrimary
          enabled: !!main && !main.actionBusy
          onClicked: main.lockAndSuspend()
        }
      }

      Rectangle {
        Layout.fillWidth: true
        color: Qt.alpha(Color.mSurfaceVariant, 0.42)
        radius: Style.radiusL
        border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.10)
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
        }
      }
    }
  }
}
