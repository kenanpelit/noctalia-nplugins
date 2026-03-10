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

  property real contentPreferredWidth: Math.round(440 * Style.uiScaleRatio)
  property real contentPreferredHeight: mainLayout.implicitHeight + (Style.marginL * 2)

  function statusBadgeText() {
    if (!main || !main.available)
      return "Unavailable";
    if (main.status === "active")
      return "Active";
    if (main.status === "inactive")
      return "Inactive";
    return "Unknown";
  }

  function statusBadgeColor() {
    if (!main || !main.available)
      return Qt.alpha(Color.mSurfaceVariant, 0.85);
    if (main.status === "active")
      return Qt.alpha(Color.mPrimary, 0.16);
    if (main.status === "inactive")
      return Qt.alpha(Color.mSurfaceVariant, 0.82);
    return Qt.alpha(Color.mError, 0.10);
  }

  function statusBadgeTextColor() {
    if (main && main.status === "active")
      return Color.mPrimary;
    if (!main || !main.available)
      return Color.mOnSurface;
    if (main.status === "inactive")
      return Color.mOnSurface;
    return Color.mError;
  }

  function actionBackground(actionId) {
    if (!main)
      return Qt.alpha(Color.mSurfaceVariant, 0.48);
    if (actionId === "enable" && main.status !== "active")
      return Qt.alpha(Color.mPrimary, 0.16);
    if (actionId === "disable" && main.status === "active")
      return Qt.alpha(Color.mError, 0.12);
    return Qt.alpha(Color.mSurfaceVariant, 0.48);
  }

  function actionTextColor(actionId) {
    if (!main)
      return Color.mOnSurface;
    if (actionId === "enable" && main.status !== "active")
      return Color.mPrimary;
    if (actionId === "disable" && main.status === "active")
      return Color.mError;
    return Color.mOnSurface;
  }

  function previewRows() {
    if (!main || !main.rulesPreview)
      return [];
    return String(main.rulesPreview).split("\n").filter(function(line) { return line.trim() !== ""; });
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
                icon: "shield"
                pointSize: Style.fontSizeL
                color: main && main.status === "active" ? Color.mPrimary : Color.mOnSurfaceVariant
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              NText {
                text: "NUFW"
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
              }

              NText {
                text: !main ? "Reading firewall state..."
                      : (!main.available ? "UFW command is not available in this session"
                         : (main.status === "active"
                            ? (main.ruleCount + " rules • " + main.incomingPolicy + " in / " + main.outgoingPolicy + " out")
                            : "Firewall is currently inactive"))
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
                color: main && main.status === "active"
                       ? Color.mPrimary
                       : (main && main.available ? Qt.alpha(Color.mOutline, 0.35) : Color.mError)
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                NText {
                  text: !main ? "Checking..." : (main.status === "active" ? "Firewall Enabled" : (main.status === "inactive" ? "Firewall Disabled" : "Firewall State Unknown"))
                  pointSize: Style.fontSizeM
                  font.weight: Font.Medium
                  color: Color.mOnSurface
                }

                NText {
                  text: !main ? "Waiting for UFW status"
                        : (main.available
                           ? ("Logging " + main.loggingLevel + " • Routed " + main.routedPolicy)
                           : "Install UFW to enable this panel")
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
              implicitHeight: inChip.implicitHeight + (Style.marginS * 2)

              NText {
                id: inChip
                anchors.centerIn: parent
                text: "In " + (main ? main.incomingPolicy : "n/a")
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                font.weight: Font.Medium
              }
            }

            Rectangle {
              Layout.fillWidth: true
              radius: Style.radiusS
              color: Qt.alpha(Color.mSurfaceVariant, 0.62)
              implicitHeight: outChip.implicitHeight + (Style.marginS * 2)

              NText {
                id: outChip
                anchors.centerIn: parent
                text: "Out " + (main ? main.outgoingPolicy : "n/a")
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
        text: "Quick Actions"
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
            text: "Enable"
            icon: "shield-check"
            backgroundColor: root.actionBackground("enable")
            textColor: root.actionTextColor("enable")
            enabled: main && main.available && !main.actionBusy && main.status !== "active"
            onClicked: main.enableFirewall()
          }

          NButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            text: "Disable"
            icon: "shield-x"
            backgroundColor: root.actionBackground("disable")
            textColor: root.actionTextColor("disable")
            enabled: main && main.available && !main.actionBusy && main.status === "active"
            onClicked: main.disableFirewall()
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          NButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            text: "Reload"
            icon: "refresh"
            backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
            textColor: Color.mOnSurface
            enabled: main && main.available && !main.actionBusy
            onClicked: main.reloadFirewall()
          }

          NButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            text: "Refresh"
            icon: "repeat"
            backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
            textColor: Color.mOnSurface
            enabled: main && !main.actionBusy
            onClicked: main.refreshDetails()
          }
        }
      }

      NText {
        Layout.fillWidth: true
        text: "Rule Preview"
        pointSize: Style.fontSizeS
        font.weight: Font.Medium
        color: Color.mSecondary
      }

      Rectangle {
        Layout.fillWidth: true
        radius: Style.radiusM
        color: Qt.alpha(Color.mSurfaceVariant, 0.42)
        border.color: Qt.alpha(Color.mOutline, 0.12)
        border.width: 1
        implicitHeight: previewLayout.implicitHeight + (Style.marginM * 2)

        ColumnLayout {
          id: previewLayout
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          Repeater {
            model: root.previewRows()

            delegate: Rectangle {
              required property string modelData
              Layout.fillWidth: true
              radius: Style.radiusS
              color: Qt.alpha(Color.mSurface, 0.9)
              border.color: Qt.alpha(Color.mOutline, 0.08)
              border.width: 1
              implicitHeight: previewText.implicitHeight + (Style.marginS * 2)

              NText {
                id: previewText
                anchors.fill: parent
                anchors.margins: Style.marginS
                text: modelData
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                wrapMode: Text.WordWrap
              }
            }
          }

          NText {
            visible: root.previewRows().length === 0
            text: main && main.available
                  ? (main.status === "active" ? "No explicit rules were returned." : "Firewall is inactive; no active rules to preview.")
                  : "Install and configure UFW to preview rules here."
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }
        }
      }
    }
  }
}
