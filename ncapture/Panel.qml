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

  property real contentPreferredWidth: 920 * Style.uiScaleRatio
  property real contentPreferredHeight: 620 * Style.uiScaleRatio

  function boolLabel(value) {
    return value ? "Active" : "Idle";
  }

  function appsLabel(apps) {
    return apps && apps.length ? apps.join(", ") : "None";
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
          color: Qt.alpha(main && main.isRecording ? Color.mError : Color.mPrimary, 0.12)
          border.color: Qt.alpha(main && main.isRecording ? Color.mError : Color.mPrimary, 0.24)
          border.width: 1

          NIcon {
            anchors.centerIn: parent
            icon: main && main.isRecording ? "camera-video" : "camera"
            pointSize: Style.fontSizeL
            color: main && main.isRecording ? Color.mError : Color.mPrimary
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          NText {
            text: "NCapture"
            pointSize: Style.fontSizeL
            font.weight: Font.Bold
            color: Color.mOnSurface
          }

          NText {
            text: main ? (main.statusSummary() + " | screenshots " + (main.screenshotAvailable ? "ready" : "unavailable")) : "Capture state unavailable"
            pointSize: Style.fontSizeXS
            color: Color.mSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }
        }

        NButton {
          text: "Refresh"
          icon: "refresh"
          enabled: !!main
          onClicked: main.refresh()
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: Style.marginS
        rowSpacing: Style.marginS

        Repeater {
          model: [
            { label: "Recorder", value: main && main.recorderAvailable ? "Ready" : "Missing" },
            { label: "Screenshots", value: main && main.screenshotAvailable ? "Ready" : "Missing" },
            { label: "Recording", value: main && main.isRecording ? "Live" : "Idle" },
            { label: "Privacy", value: main && main.anyPrivacyActive ? "Active" : "Quiet" }
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
              NText { text: String(modelData.value); pointSize: Style.fontSizeL; font.weight: Font.Medium; color: Color.mOnSurface }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        radius: Style.radiusM
        color: Qt.alpha(Color.mSurfaceVariant, 0.36)
        border.color: Qt.alpha(Color.mOutline, 0.1)
        border.width: 1
        implicitHeight: actionsCol.implicitHeight + (Style.marginM * 2)

        ColumnLayout {
          id: actionsCol
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NText {
            text: "Capture Actions"
            pointSize: Style.fontSizeM
            font.weight: Font.Medium
            color: Color.mOnSurface
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NButton { Layout.fillWidth: true; text: "Region"; icon: "crop"; enabled: !!main; onClicked: main.takeScreenshot("region") }
            NButton { Layout.fillWidth: true; text: "Screen"; icon: "screen-share"; enabled: !!main; onClicked: main.takeScreenshot("screen") }
            NButton { Layout.fillWidth: true; text: "Window"; icon: "window"; enabled: !!main; onClicked: main.takeScreenshot("window") }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NButton {
              Layout.fillWidth: true
              text: main && main.isRecording ? "Stop Recording" : "Start Recording"
              icon: main && main.isRecording ? "player-stop" : "camera-video"
              enabled: !!main
              onClicked: main.toggleRecording()
            }
          }
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Style.marginS
        rowSpacing: Style.marginS

        Repeater {
          model: [
            { label: "Microphone", value: root.boolLabel(main && main.micActive), detail: root.appsLabel(main ? main.micApps : []) },
            { label: "Camera", value: root.boolLabel(main && main.camActive), detail: root.appsLabel(main ? main.camApps : []) },
            { label: "Screen Share", value: root.boolLabel(main && main.shareActive), detail: root.appsLabel(main ? main.shareApps : []) }
          ]

          delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            radius: Style.radiusM
            color: Qt.alpha(Color.mSurfaceVariant, 0.42)
            border.color: Qt.alpha(Color.mOutline, 0.08)
            border.width: 1
            implicitHeight: privacyCol.implicitHeight + (Style.marginM * 2)

            ColumnLayout {
              id: privacyCol
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: 2

              NText { text: modelData.label; pointSize: Style.fontSizeXS; color: Color.mSecondary }
              NText { text: modelData.value; pointSize: Style.fontSizeM; font.weight: Font.Medium; color: Color.mOnSurface }
              NText { text: modelData.detail; pointSize: Style.fontSizeXS; color: Color.mSecondary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        radius: Style.radiusS
        color: Qt.alpha(Color.mPrimary, 0.08)
        border.color: Qt.alpha(Color.mPrimary, 0.16)
        border.width: 1
        implicitHeight: statusText.implicitHeight + (Style.marginM * 2)

        NText {
          id: statusText
          anchors.fill: parent
          anchors.margins: Style.marginM
          text: main && main.lastAction ? main.lastAction : "Use the panel actions or plugin:ncapture IPC commands to control captures."
          color: Color.mOnSurface
          pointSize: Style.fontSizeS
          wrapMode: Text.WordWrap
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
