import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var main: pluginApi ? pluginApi.mainInstance : null
  readonly property var geometryPlaceholder: panelFrame
  readonly property bool allowAttach: true

  property real contentPreferredWidth: Math.round(480 * Style.uiScaleRatio)
  property real contentPreferredHeight: mainLayout.implicitHeight + (Style.marginL * 2)

  function iconName() {
    if (!main || !main.available)
      return "alert-circle";
    if (!main.serviceActive)
      return "temperature";
    if (main.period === "day")
      return "sun";
    if (main.period === "night")
      return "moon";
    if (main.period === "sunset")
      return "sunset-2";
    if (main.period === "sunrise")
      return "sunrise";
    return "temperature";
  }

  function statusBadgeText() {
    if (!main || !main.available)
      return "Unavailable";
    if (!main.serviceActive)
      return "Stopped";
    if (main.manualOverride)
      return "Manual";
    return "Scheduled";
  }

  function statusBadgeColor() {
    if (!main || !main.available)
      return Qt.alpha(Color.mError, 0.12);
    if (!main.serviceActive)
      return Qt.alpha(Color.mSurfaceVariant, 0.82);
    if (main.manualOverride)
      return Qt.alpha("#ffb74d", 0.18);
    return Qt.alpha(Color.mPrimary, 0.16);
  }

  function statusBadgeTextColor() {
    if (!main || !main.available)
      return Color.mError;
    if (!main.serviceActive)
      return Color.mOnSurface;
    if (main.manualOverride)
      return "#e65100";
    return Color.mPrimary;
  }

  function tempLabel(value) {
    return value > 0 ? Math.round(value) + "K" : "--";
  }

  function gammaLabel(value) {
    return value > 0 ? Number(value).toFixed(1) + "%" : "--";
  }

  function actionIsActive(actionId) {
    if (!main)
      return false;

    switch (actionId) {
    case "auto":
      return !main.manualOverride && main.activePreset === main.scheduledPreset;
    case "default":
      return main.activePreset === "default";
    case "refresh":
      return false;
    case "restart":
      return false;
    default:
      return false;
    }
  }

  function actionBackground(actionId) {
    if (root.actionIsActive(actionId))
      return Qt.alpha(Color.mPrimary, 0.16);
    if (actionId === "refresh" || actionId === "restart")
      return Qt.alpha(Color.mPrimary, 0.12);
    return Qt.alpha(Color.mSurfaceVariant, 0.48);
  }

  function actionTextColor(actionId) {
    if (root.actionIsActive(actionId))
      return Color.mPrimary;
    if (actionId === "refresh" || actionId === "restart")
      return Color.mPrimary;
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
                icon: root.iconName()
                pointSize: Style.fontSizeL
                color: Color.mPrimary
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              NText {
                text: "NSunsetr"
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
              }

              NText {
                text: !main
                      ? "Reading sunsetr state..."
                      : (String(main.activePresetLabel || "Default") + " • " + root.tempLabel(main.currentTemp > 0 ? main.currentTemp : main.targetTemp))
                pointSize: Style.fontSizeXS
                color: Color.mSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }

            Rectangle {
              Layout.alignment: Qt.AlignTop
              radius: height / 2
              color: root.statusBadgeColor()
              border.color: Qt.alpha(Color.mOutline, 0.12)
              border.width: 1
              implicitHeight: badgeText.implicitHeight + (Style.marginS * 2)
              implicitWidth: badgeText.implicitWidth + (Style.marginM * 2)

              NText {
                id: badgeText
                anchors.centerIn: parent
                text: root.statusBadgeText()
                pointSize: Style.fontSizeXS
                font.weight: Font.Medium
                color: root.statusBadgeTextColor()
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            radius: Style.radiusM
            color: Qt.alpha(Color.mSurface, 0.92)
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
                color: main && main.manualOverride ? "#ffb74d"
                       : (main && main.serviceActive ? Color.mPrimary : Qt.alpha(Color.mOutline, 0.35))
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                NText {
                  text: !main
                        ? "Checking..."
                        : (main.serviceActive
                           ? ("Period: " + String(main.period || "static"))
                           : "Sunsetr service is stopped")
                  pointSize: Style.fontSizeM
                  font.weight: Font.Medium
                  color: Color.mOnSurface
                }

                NText {
                  text: !main
                        ? "Waiting for runtime state"
                        : ("Current " + root.tempLabel(main.currentTemp > 0 ? main.currentTemp : main.targetTemp)
                           + " @ " + root.gammaLabel(main.currentGamma > 0 ? main.currentGamma : main.targetGamma)
                           + " • Next " + String(main.nextScheduledTime || "--:--"))
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
              implicitHeight: chipActive.implicitHeight + (Style.marginS * 2)

              NText {
                id: chipActive
                anchors.centerIn: parent
                text: "Active " + (main ? String(main.activePresetLabel || "Default") : "Default")
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                font.weight: Font.Medium
              }
            }

            Rectangle {
              Layout.fillWidth: true
              radius: Style.radiusS
              color: Qt.alpha(Color.mSurfaceVariant, 0.62)
              implicitHeight: chipNext.implicitHeight + (Style.marginS * 2)

              NText {
                id: chipNext
                anchors.centerIn: parent
                text: "Next " + (main ? (String(main.nextScheduledTime || "--:--") + " " + String(main.nextScheduledLabel || "Default")) : "--:--")
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
          pointSize: Style.fontSizeXS
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
        }
      }

      Rectangle {
        Layout.fillWidth: true
        color: Qt.alpha(Color.mSurfaceVariant, 0.36)
        radius: Style.radiusL
        border.color: Qt.alpha(Color.mOutline, 0.12)
        border.width: 1
        implicitHeight: actionLayout.implicitHeight + (Style.marginM * 2)

        ColumnLayout {
          id: actionLayout
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NButton {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              Layout.preferredWidth: 1
              text: "Auto"
              icon: "clock"
              backgroundColor: root.actionBackground("auto")
              textColor: root.actionTextColor("auto")
              onClicked: if (main) main.applyAuto()
            }

            NButton {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              Layout.preferredWidth: 1
              text: "Default"
              icon: "reload"
              backgroundColor: root.actionBackground("default")
              textColor: root.actionTextColor("default")
              onClicked: if (main) main.applyDefault()
            }

            NButton {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              Layout.preferredWidth: 1
              text: "Restart"
              icon: "refresh"
              backgroundColor: root.actionBackground("restart")
              textColor: root.actionTextColor("restart")
              onClicked: if (main) main.restartService()
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NButton {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              Layout.preferredWidth: 1
              text: "Warmer"
              icon: "chevron-up"
              backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
              textColor: Color.mOnSurface
              onClicked: if (main) main.makeWarmer()
            }

            NButton {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              Layout.preferredWidth: 1
              text: "Cooler"
              icon: "chevron-down"
              backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
              textColor: Color.mOnSurface
              onClicked: if (main) main.makeCooler()
            }

            NButton {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              Layout.preferredWidth: 1
              text: "Refresh"
              icon: "rotate"
              backgroundColor: root.actionBackground("refresh")
              textColor: root.actionTextColor("refresh")
              onClicked: if (main) main.refresh()
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NButton {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              Layout.preferredWidth: 1
              text: "Gamma +"
              icon: "plus"
              backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
              textColor: Color.mOnSurface
              onClicked: if (main) main.raiseGamma()
            }

            NButton {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              Layout.preferredWidth: 1
              text: "Gamma -"
              icon: "minus"
              backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
              textColor: Color.mOnSurface
              onClicked: if (main) main.lowerGamma()
            }

            NButton {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              Layout.preferredWidth: 1
              text: "Settings"
              icon: "settings"
              backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
              textColor: Color.mOnSurface
              onClicked: if (main) main.openSettingsUi()
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        color: Qt.alpha(Color.mSurfaceVariant, 0.28)
        radius: Style.radiusL
        border.color: Qt.alpha(Color.mOutline, 0.12)
        border.width: 1
        implicitHeight: scheduleLayout.implicitHeight + (Style.marginM * 2)

        ColumnLayout {
          id: scheduleLayout
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NText {
            text: "Schedule"
            pointSize: Style.fontSizeM
            font.weight: Font.Medium
            color: Color.mOnSurface
          }

          Repeater {
            model: main ? main.scheduleEntries : []

            delegate: Rectangle {
              required property var modelData
              Layout.fillWidth: true
              radius: Style.radiusS
              color: modelData.active
                     ? Qt.alpha(Color.mPrimary, 0.14)
                     : (modelData.scheduled ? Qt.alpha("#ffb74d", 0.14) : Qt.alpha(Color.mSurface, 0.72))
              border.color: modelData.active
                            ? Qt.alpha(Color.mPrimary, 0.28)
                            : Qt.alpha(Color.mOutline, 0.10)
              border.width: 1
              implicitHeight: rowLayout.implicitHeight + (Style.marginS * 2)

              RowLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.margins: Style.marginS
                spacing: Style.marginS

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2

                  NText {
                    text: String(modelData.start || "--:--") + " - " + String(modelData.end || "--:--") + "  " + String(modelData.label || modelData.preset || "Preset")
                    pointSize: Style.fontSizeXS
                    font.weight: Font.Medium
                    color: Color.mOnSurface
                  }

                  NText {
                    text: root.tempLabel(Number(modelData.temp || -1)) + " @ " + root.gammaLabel(Number(modelData.gamma || -1))
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                  }
                }

                Rectangle {
                  radius: height / 2
                  color: modelData.active
                         ? Qt.alpha(Color.mPrimary, 0.18)
                         : (modelData.scheduled ? Qt.alpha("#ffb74d", 0.18) : Qt.alpha(Color.mSurfaceVariant, 0.72))
                  implicitHeight: stateChip.implicitHeight + (Style.marginXS * 2)
                  implicitWidth: stateChip.implicitWidth + (Style.marginS * 2)

                  NText {
                    id: stateChip
                    anchors.centerIn: parent
                    text: modelData.active ? "Active" : (modelData.scheduled ? "Now" : "Apply")
                    pointSize: Style.fontSizeXS
                    color: modelData.active ? Color.mPrimary : Color.mOnSurface
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (main)
                      main.applyPreset(String(modelData.preset || ""));
                  }
                }
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        visible: main ? main.lastAction !== "" : false
        color: Qt.alpha(Color.mPrimary, 0.08)
        radius: Style.radiusS
        border.color: Qt.alpha(Color.mPrimary, 0.18)
        border.width: 1
        implicitHeight: actionText.implicitHeight + Style.marginM

        NText {
          id: actionText
          anchors.fill: parent
          anchors.margins: Style.marginS
          text: main ? main.lastAction : ""
          color: Color.mPrimary
          pointSize: Style.fontSizeXS
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
        }
      }
    }
  }
}
