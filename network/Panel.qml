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

  property real contentPreferredWidth: 860 * Style.uiScaleRatio
  property real contentPreferredHeight: 620 * Style.uiScaleRatio

  function valueOrFallback(value, fallbackText) {
    var text = String(value || "").trim();
    return text ? text : fallbackText;
  }

  function connectivityLabel() {
    if (!main)
      return "Unknown";
    if (main.connectivity === "full")
      return "Online";
    if (main.connectivity === "limited")
      return "Limited";
    if (main.connectivity === "portal")
      return "Portal";
    if (main.connectivity === "none")
      return "Offline";
    return String(main.connectivity || "Unknown");
  }

  function connectivityColor() {
    if (!main)
      return Color.mSecondary;
    if (main.connectivity === "full")
      return Color.mPrimary;
    if (main.connectivity === "limited" || main.connectivity === "portal")
      return "#ffb74d";
    return Color.mError;
  }

  Component.onCompleted: {
    if (main)
      main.refresh();
  }

  Rectangle {
    id: panelFrame
    anchors.fill: parent
    radius: Style.radiusL
    color: Color.mSurface
    border.color: Qt.alpha(Color.mOutline, 0.18)
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        Rectangle {
          Layout.preferredWidth: 44
          Layout.preferredHeight: 44
          radius: 22
          color: Qt.alpha(root.connectivityColor(), 0.12)
          border.color: Qt.alpha(root.connectivityColor(), 0.24)
          border.width: 1

          NIcon {
            anchors.centerIn: parent
            icon: main && main.activeType === "wifi" ? "router" : "network"
            pointSize: Style.fontSizeL
            color: root.connectivityColor()
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          NText {
            text: "Network Console"
            pointSize: Style.fontSizeL
            font.weight: Font.Bold
            color: Color.mOnSurface
          }

          NText {
            text: main
                  ? (main.displayName + "  |  " + root.connectivityLabel())
                  : "NetworkManager state unavailable"
            pointSize: Style.fontSizeXS
            color: Color.mSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }
        }

        NButton {
          text: "Refresh"
          icon: "refresh"
          enabled: !!main && !main.actionBusy
          onClicked: main.refresh()
        }

        NButton {
          text: main && main.wifiEnabled ? "Wi-Fi Off" : "Wi-Fi On"
          icon: "power"
          enabled: !!main && main.nmcliAvailable && !main.actionBusy
          onClicked: main.toggleWifi()
        }

        NButton {
          text: "Rescan"
          icon: "refresh"
          enabled: !!main && main.wifiEnabled && !main.actionBusy
          onClicked: main.rescanWifi()
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Style.marginS
        rowSpacing: Style.marginS

        Repeater {
          model: [
            { label: "Connectivity", value: root.connectivityLabel() },
            { label: "Device", value: root.valueOrFallback(main ? main.activeDevice : "", "No active link") },
            { label: "Connection", value: root.valueOrFallback(main ? main.displayName : "", "Offline") }
          ]

          delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            radius: Style.radiusM
            color: Qt.alpha(Color.mPrimary, 0.08)
            border.color: Qt.alpha(Color.mPrimary, 0.14)
            border.width: 1
            implicitHeight: cardCol.implicitHeight + (Style.marginM * 2)

            ColumnLayout {
              id: cardCol
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: 2

              NText { text: modelData.label; pointSize: Style.fontSizeXS; color: Color.mSecondary }
              NText {
                text: String(modelData.value)
                pointSize: Style.fontSizeL
                font.weight: Font.Medium
                color: Color.mOnSurface
                wrapMode: Text.WordWrap
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Style.radiusM
        color: Qt.alpha(Color.mSurfaceVariant, 0.36)
        border.color: Qt.alpha(Color.mOutline, 0.1)
        border.width: 1

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              NText {
                text: "Nearby Wi-Fi"
                pointSize: Style.fontSizeM
                font.weight: Font.Medium
                color: Color.mOnSurface
              }

              NText {
                text: main && main.wifiEnabled
                      ? "Visible access points and quick-connect actions."
                      : "Wi-Fi is disabled. Enable the radio to scan nearby networks."
                pointSize: Style.fontSizeXS
                color: Color.mSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }

            Rectangle {
              radius: Style.radiusS
              color: Qt.alpha(root.connectivityColor(), 0.1)
              border.color: Qt.alpha(root.connectivityColor(), 0.22)
              border.width: 1
              implicitWidth: badgeLabel.implicitWidth + (Style.marginM * 2)
              implicitHeight: badgeLabel.implicitHeight + (Style.marginS * 2)

              NText {
                id: badgeLabel
                anchors.centerIn: parent
                text: root.connectivityLabel()
                pointSize: Style.fontSizeXS
                font.weight: Font.Medium
                color: root.connectivityColor()
              }
            }
          }

          NText {
            visible: !main || main.nearbyNetworks.length === 0
            text: main && !main.wifiEnabled ? "Wi-Fi is disabled." : "No visible networks right now."
            pointSize: Style.fontSizeS
            color: Color.mSecondary
          }

          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: !!main && main.nearbyNetworks.length > 0

            ColumnLayout {
              width: parent.width
              spacing: Style.marginS

              Repeater {
                model: main ? main.nearbyNetworks : []

                delegate: Rectangle {
                  required property var modelData
                  Layout.fillWidth: true
                  radius: Style.radiusS
                  color: modelData.inUse ? Qt.alpha(Color.mPrimary, 0.1) : Color.mSurface
                  border.color: modelData.inUse ? Qt.alpha(Color.mPrimary, 0.2) : Qt.alpha(Color.mOutline, 0.08)
                  border.width: 1
                  implicitHeight: wifiRow.implicitHeight + (Style.marginS * 2)

                  RowLayout {
                    id: wifiRow
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginS

                    Rectangle {
                      Layout.preferredWidth: 28
                      Layout.preferredHeight: 28
                      radius: 14
                      color: modelData.inUse ? Qt.alpha(Color.mPrimary, 0.14) : Qt.alpha(Color.mSurfaceVariant, 0.42)

                      NIcon {
                        anchors.centerIn: parent
                        icon: modelData.inUse ? "router" : "network"
                        pointSize: Style.fontSizeS
                        color: modelData.inUse ? Color.mPrimary : Color.mOnSurfaceVariant
                      }
                    }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 1

                      NText {
                        text: modelData.ssid
                        pointSize: Style.fontSizeS
                        font.weight: Font.Medium
                        color: Color.mOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginXS

                        Rectangle {
                          radius: Style.radiusS
                          color: Qt.alpha(Color.mSurfaceVariant, 0.52)
                          border.color: Qt.alpha(Color.mOutline, 0.08)
                          border.width: 1
                          implicitWidth: securityLabel.implicitWidth + (Style.marginS * 2)
                          implicitHeight: securityLabel.implicitHeight + (Style.marginXS * 2)

                          NText {
                            id: securityLabel
                            anchors.centerIn: parent
                            text: modelData.security === "Open" ? "Open" : modelData.security
                            pointSize: Style.fontSizeXS
                            color: Color.mSecondary
                          }
                        }

                        Rectangle {
                          radius: Style.radiusS
                          color: modelData.inUse ? Qt.alpha(Color.mPrimary, 0.12) : Qt.alpha(Color.mSurfaceVariant, 0.42)
                          border.color: modelData.inUse ? Qt.alpha(Color.mPrimary, 0.2) : Qt.alpha(Color.mOutline, 0.08)
                          border.width: 1
                          implicitWidth: signalLabel.implicitWidth + (Style.marginS * 2)
                          implicitHeight: signalLabel.implicitHeight + (Style.marginXS * 2)

                          NText {
                            id: signalLabel
                            anchors.centerIn: parent
                            text: modelData.signal + "%"
                            pointSize: Style.fontSizeXS
                            color: modelData.inUse ? Color.mPrimary : Color.mOnSurfaceVariant
                          }
                        }
                      }
                    }

                    NButton {
                      text: modelData.inUse ? "Connected" : "Connect"
                      enabled: !!main && main.wifiEnabled && !main.actionBusy && !modelData.inUse
                      onClicked: main.connectWifi(modelData.ssid)
                    }
                  }
                }
              }
            }
          }
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 5
        columnSpacing: Style.marginS
        rowSpacing: Style.marginS

        Repeater {
          model: [
            { label: "Interface", value: root.valueOrFallback(main ? main.activeDevice : "", "None") },
            { label: "Transport", value: root.valueOrFallback(main ? main.activeType : "", "Unknown") },
            { label: "IP", value: root.valueOrFallback(main ? main.ipAddress : "", "Unavailable") },
            { label: "Gateway", value: root.valueOrFallback(main ? main.gateway : "", "Unavailable") },
            { label: "Wi-Fi Radio", value: (main && main.wifiEnabled) ? "Enabled" : "Disabled" }
          ]

          delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            radius: Style.radiusS
            color: Qt.alpha(Color.mSurfaceVariant, 0.42)
            border.color: Qt.alpha(Color.mOutline, 0.08)
            border.width: 1
            implicitHeight: infoCol.implicitHeight + (Style.marginS * 2)

            ColumnLayout {
              id: infoCol
              anchors.fill: parent
              anchors.margins: Style.marginS
              spacing: 1

              NText { text: modelData.label; pointSize: Style.fontSizeXS; color: Color.mSecondary }
              NText {
                text: String(modelData.value)
                pointSize: Style.fontSizeS
                font.weight: Font.Medium
                color: Color.mOnSurface
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        visible: !!main && main.lastError !== ""
        radius: Style.radiusS
        color: Qt.alpha(Color.mError, 0.1)
        border.color: Qt.alpha(Color.mError, 0.3)
        border.width: 1
        implicitHeight: errorText.implicitHeight + (Style.marginM * 2)

        NText {
          id: errorText
          anchors.fill: parent
          anchors.margins: Style.marginM
          text: main ? main.lastError : ""
          color: Color.mError
          pointSize: Style.fontSizeS
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
