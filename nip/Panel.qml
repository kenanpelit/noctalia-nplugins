import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "." as Local

Item {
  id: root

  property var pluginApi: null
  property var ipMonitorService: pluginApi?.mainInstance?.ipMonitorService || null

  readonly property var geometryPlaceholder: panelFrame
  readonly property bool allowAttach: true

  property real contentPreferredWidth: Math.round(440 * Style.uiScaleRatio)
  property real contentPreferredHeight: mainLayout.implicitHeight + (Style.marginL * 2)

  readonly property var ipData: ipMonitorService?.ipData ?? null
  readonly property string fetchState: ipMonitorService?.fetchState ?? "idle"

  function refreshIp() {
    if (ipMonitorService)
      ipMonitorService.fetchIp();
  }

  function stateTitle() {
    switch (fetchState) {
    case "loading":
      return "Refreshing";
    case "error":
      return "Unavailable";
    case "success":
      return ipData?.ip ? ipData.ip : "n/a";
    default:
      return "Ready";
    }
  }

  function stateSubtitle() {
    switch (fetchState) {
    case "loading":
      return "Requesting public IP data";
    case "error":
      return "Unable to reach the IP service";
    case "success": {
      var parts = [];
      if (ipData?.city)
        parts.push(ipData.city);
      if (ipData?.country)
        parts.push(ipData.country);
      return parts.length ? parts.join(", ") : "Public endpoint detected";
    }
    default:
      return "Waiting for first refresh";
    }
  }

  function stateBadgeText() {
    switch (fetchState) {
    case "loading":
      return "Loading";
    case "error":
      return "Error";
    case "success":
      return "Online";
    default:
      return "Idle";
    }
  }

  function stateBadgeColor() {
    if (fetchState === "success")
      return Qt.alpha(Color.mPrimary, 0.16);
    if (fetchState === "error")
      return Qt.alpha(Color.mError, 0.12);
    return Qt.alpha(Color.mSurfaceVariant, 0.82);
  }

  function stateBadgeTextColor() {
    if (fetchState === "success")
      return Color.mPrimary;
    if (fetchState === "error")
      return Color.mError;
    return Color.mOnSurface;
  }

  function stateIconName() {
    switch (fetchState) {
    case "loading":
      return "loader";
    case "error":
      return "alert-circle";
    default:
      return "world";
    }
  }

  function detailCards() {
    return [
      { label: "Hostname", value: ipData?.hostname ?? "n/a", accent: Color.mSecondary },
      { label: "Organization", value: ipData?.org ?? "n/a", accent: Color.mTertiary },
      { label: "Region", value: ipData?.region ?? "n/a", accent: Color.mPrimary },
      { label: "Timezone", value: ipData?.timezone ?? "n/a", accent: Color.mSecondary },
      { label: "Coordinates", value: ipData?.loc ?? "n/a", accent: Color.mTertiary },
      { label: "Postal", value: ipData?.postal ?? "n/a", accent: Color.mPrimary }
    ];
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
                icon: root.stateIconName()
                pointSize: Style.fontSizeL
                color: fetchState === "error" ? Color.mError : Color.mPrimary
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              NText {
                text: "Public IP"
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
              }

              NText {
                text: root.stateSubtitle()
                pointSize: Style.fontSizeXS
                color: Color.mSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }

            Rectangle {
              Layout.alignment: Qt.AlignTop
              radius: height / 2
              color: root.stateBadgeColor()
              border.color: Qt.alpha(Color.mOutline, 0.12)
              border.width: 1
              implicitHeight: badgeText.implicitHeight + (Style.marginS * 2)
              implicitWidth: badgeText.implicitWidth + (Style.marginM * 2)

              NText {
                id: badgeText
                anchors.centerIn: parent
                text: root.stateBadgeText()
                pointSize: Style.fontSizeXS
                font.weight: Font.Medium
                color: root.stateBadgeTextColor()
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
                color: fetchState === "success"
                       ? Color.mPrimary
                       : (fetchState === "error" ? Color.mError : Qt.alpha(Color.mOutline, 0.35))
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                NText {
                  text: root.stateTitle()
                  pointSize: Style.fontSizeM
                  font.weight: Font.Medium
                  color: Color.mOnSurface
                  font.family: Settings.data.ui.fontFixed
                }

                NText {
                  text: ipData?.loc ? ("Coords " + ipData.loc) : "Public endpoint lookup"
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
              implicitHeight: statusChip.implicitHeight + (Style.marginS * 2)

              NText {
                id: statusChip
                anchors.centerIn: parent
                text: fetchState === "success" ? "Reachable" : (fetchState === "error" ? "Offline" : "Pending")
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                font.weight: Font.Medium
              }
            }

            Rectangle {
              Layout.fillWidth: true
              radius: Style.radiusS
              color: Qt.alpha(Color.mSurfaceVariant, 0.62)
              implicitHeight: scopeChip.implicitHeight + (Style.marginS * 2)

              NText {
                id: scopeChip
                anchors.centerIn: parent
                text: "Public IPv4"
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
        visible: fetchState === "error"
        color: Qt.alpha(Color.mError, 0.1)
        radius: Style.radiusS
        border.color: Qt.alpha(Color.mError, 0.3)
        border.width: 1
        implicitHeight: errorText.implicitHeight + Style.marginM

        NText {
          id: errorText
          anchors.fill: parent
          anchors.margins: Style.marginS
          text: "Unable to fetch public IP details right now."
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

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NButton {
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          Layout.preferredWidth: 1
          text: fetchState === "loading" ? "Refreshing" : "Refresh"
          icon: "refresh"
          enabled: fetchState !== "loading"
          backgroundColor: Qt.alpha(Color.mPrimary, 0.16)
          textColor: Color.mPrimary
          onClicked: root.refreshIp()
        }

        Rectangle {
          Layout.fillWidth: true
          radius: Style.radiusM
          color: Qt.alpha(Color.mSurfaceVariant, 0.48)
          border.color: Qt.alpha(Color.mOutline, 0.12)
          border.width: 1
          implicitHeight: actionHint.implicitHeight + (Style.marginM * 2)

          NText {
            id: actionHint
            anchors.centerIn: parent
            text: fetchState === "success" ? "Data fresh" : "Manual refresh"
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
            font.weight: Font.Medium
          }
        }
      }

      NText {
        Layout.fillWidth: true
        text: "Endpoint Details"
        pointSize: Style.fontSizeS
        font.weight: Font.Medium
        color: Color.mSecondary
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Style.marginS
        rowSpacing: Style.marginS
        visible: fetchState === "success" && !!ipData

        Repeater {
          model: root.detailCards()

          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            radius: Style.radiusM
            color: Qt.alpha(Color.mSurface, 0.92)
            border.color: Qt.alpha(modelData.accent, 0.18)
            border.width: 1
            implicitHeight: cardContent.implicitHeight + (Style.marginM * 2)

            ColumnLayout {
              id: cardContent
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: 2

              NText {
                text: modelData.label
                pointSize: Style.fontSizeXS
                color: modelData.accent
                font.weight: Font.Medium
              }

              NText {
                text: modelData.value
                pointSize: Style.fontSizeS
                color: Color.mOnSurface
                font.family: Settings.data.ui.fontFixed
                wrapMode: Text.WrapAnywhere
                Layout.fillWidth: true
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        visible: fetchState !== "success" || !ipData
        radius: Style.radiusM
        color: Qt.alpha(Color.mSurfaceVariant, 0.42)
        border.color: Qt.alpha(Color.mOutline, 0.12)
        border.width: 1
        implicitHeight: emptyState.implicitHeight + (Style.marginL * 2)

        NText {
          id: emptyState
          anchors.centerIn: parent
          text: fetchState === "loading"
                ? "Waiting for IP data..."
                : "Refresh to fetch public IP details."
          pointSize: Style.fontSizeS
          color: Color.mOnSurfaceVariant
        }
      }
    }
  }
}
