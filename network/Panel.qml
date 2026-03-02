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

  Component.onCompleted: if (main) main.refresh()

  Rectangle {
    id: panelFrame
    anchors.fill: parent
    color: Color.mSurface
    radius: Style.radiusL
    border.color: Qt.alpha(Color.mOutline, 0.2)
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      Rectangle {
        Layout.fillWidth: true
        color: Qt.alpha(root.connectivityColor(), 0.08)
        radius: Style.radiusL
        border.color: Qt.alpha(root.connectivityColor(), 0.16)
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
              color: Qt.alpha(root.connectivityColor(), 0.14)
              border.color: Qt.alpha(root.connectivityColor(), 0.22)
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
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
              }

              NText {
                text: main
                      ? (main.displayName + " • " + root.connectivityLabel())
                      : "NetworkManager state unavailable"
                pointSize: Style.fontSizeXS
                color: Color.mSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }

            Rectangle {
              Layout.alignment: Qt.AlignTop
              radius: height / 2
              color: Qt.alpha(root.connectivityColor(), 0.14)
              border.color: Qt.alpha(Color.mOutline, 0.12)
              border.width: 1
              implicitHeight: badgeLabel.implicitHeight + (Style.marginS * 2)
              implicitWidth: badgeLabel.implicitWidth + (Style.marginM * 2)

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
                color: root.connectivityColor()
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                NText {
                  text: root.valueOrFallback(main ? main.displayName : "", "No active link")
                  pointSize: Style.fontSizeM
                  font.weight: Font.Medium
                  color: Color.mOnSurface
                }

                NText {
                  text: main
                        ? (root.valueOrFallback(main.activeDevice, "No device") + " • " + root.valueOrFallback(main.activeType, "Unknown"))
                        : "Checking network path..."
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
              implicitHeight: radioChipText.implicitHeight + (Style.marginS * 2)

              NText {
                id: radioChipText
                anchors.centerIn: parent
                text: "Wi-Fi " + ((main && main.wifiEnabled) ? "On" : "Off")
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                font.weight: Font.Medium
              }
            }

            Rectangle {
              Layout.fillWidth: true
              radius: Style.radiusS
              color: Qt.alpha(Color.mSurfaceVariant, 0.62)
              implicitHeight: ipChipText.implicitHeight + (Style.marginS * 2)

              NText {
                id: ipChipText
                anchors.centerIn: parent
                text: root.valueOrFallback(main ? main.ipAddress : "", "No IP")
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                font.weight: Font.Medium
                elide: Text.ElideRight
              }
            }
          }
        }
      }

      NText {
        Layout.fillWidth: true
        text: "Quick Actions"
        pointSize: Style.fontSizeS
        font.weight: Font.Medium
        color: Color.mSecondary
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NButton {
          Layout.fillWidth: true
          text: "Refresh"
          icon: "refresh"
          backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
          textColor: Color.mOnSurface
          enabled: !!main && !main.actionBusy
          onClicked: main.refresh()
        }

        NButton {
          Layout.fillWidth: true
          text: main && main.wifiEnabled ? "Wi-Fi Off" : "Wi-Fi On"
          icon: "power"
          backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
          textColor: Color.mOnSurface
          enabled: !!main && main.nmcliAvailable && !main.actionBusy
          onClicked: main.toggleWifi()
        }

        NButton {
          Layout.fillWidth: true
          text: "Rescan"
          icon: "refresh"
          backgroundColor: Qt.alpha(Color.mSurfaceVariant, 0.48)
          textColor: Color.mOnSurface
          enabled: !!main && main.wifiEnabled && !main.actionBusy
          onClicked: main.rescanWifi()
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

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Style.radiusL
        color: Qt.alpha(Color.mSurfaceVariant, 0.42)
        border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.10)
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
              implicitWidth: wifiBadgeLabel.implicitWidth + (Style.marginM * 2)
              implicitHeight: wifiBadgeLabel.implicitHeight + (Style.marginS * 2)

              NText {
                id: wifiBadgeLabel
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
                  color: modelData.inUse ? Qt.alpha(Color.mPrimary, 0.10) : Qt.alpha(Color.mSurface, 0.9)
                  border.color: modelData.inUse ? Qt.alpha(Color.mPrimary, 0.20) : Qt.alpha(Color.mOutline, 0.08)
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
                          border.color: modelData.inUse ? Qt.alpha(Color.mPrimary, 0.20) : Qt.alpha(Color.mOutline, 0.08)
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
                      backgroundColor: modelData.inUse ? Qt.alpha(Color.mPrimary, 0.12) : Qt.alpha(Color.mSurfaceVariant, 0.48)
                      textColor: modelData.inUse ? Color.mPrimary : Color.mOnSurface
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
            radius: Style.radiusM
            color: Qt.alpha(Color.mSurfaceVariant, 0.42)
            border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.08)
            border.width: 1
            implicitHeight: metaCol.implicitHeight + (Style.marginS * 2)

            ColumnLayout {
              id: metaCol
              anchors.fill: parent
              anchors.margins: Style.marginS
              spacing: 2

              NText {
                text: modelData.label
                pointSize: Style.fontSizeXS
                color: Color.mSecondary
              }

              NText {
                text: String(modelData.value)
                pointSize: Style.fontSizeS
                font.weight: Font.Medium
                color: Color.mOnSurface
                wrapMode: Text.WordWrap
              }
            }
          }
        }
      }
    }
  }
}
