import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property var main: pluginApi ? pluginApi.mainInstance : null
  readonly property bool showLabel: pluginApi && pluginApi.pluginSettings ? pluginApi.pluginSettings.showLabelInBar !== false : true
  readonly property bool showText: showLabel || showRates
  readonly property bool online: main ? main.online : false
  readonly property bool fullyOnline: main ? main.fullyOnline : false
  readonly property string activeType: main ? main.activeType : ""
  readonly property string activeDeviceName: main ? main.activeDevice : ""
  readonly property string statusText: fullyOnline ? "Online" : (online ? "Limited" : "Offline")
  readonly property string downRateText: online ? formatRate(rxRateBps) : "--"
  readonly property string upRateText: online ? formatRate(txRateBps) : "--"
  readonly property string iconName: {
    if (activeType === "wifi")
      return "router";
    if (activeType === "ethernet")
      return "plug-connected";
    return main && main.nmcliAvailable ? "network" : "world";
  }
  readonly property color accentColor: fullyOnline ? Color.mPrimary : (online ? "#ffb74d" : Color.mOnSurface)
  readonly property color downColor: online ? "#4fc3f7" : Color.mOnSurfaceVariant
  readonly property color upColor: online ? "#81c784" : Color.mOnSurfaceVariant
  readonly property color hoverTextColor: "#000000"
  readonly property color baseTextColor: Color.mOnSurfaceVariant
  readonly property real rateChipWidth: Math.round(72 * Style.uiScaleRatio)
  readonly property real contentWidth: showText ? row.implicitWidth + (Style.marginM * 2) : Style.capsuleHeight
  readonly property real contentHeight: Style.capsuleHeight

  property bool showRates: true
  property real rxRateBps: 0
  property real txRateBps: 0
  property double lastRxBytes: -1
  property double lastTxBytes: -1
  property double lastSampleMs: 0

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  function labelText() {
    if (!showLabel)
      return "";
    if (!main)
      return "Offline";
    var text = String(main.displayName || "Offline");
    if (activeType === "wifi" && main.activeSignal >= 0) {
      return text + " | " + main.activeSignal + "%";
    }
    return text + " | " + statusText;
  }

  function resetStats() {
    rxRateBps = 0;
    txRateBps = 0;
    lastRxBytes = -1;
    lastTxBytes = -1;
    lastSampleMs = 0;
  }

  function formatRate(bytesPerSecond) {
    var value = Number(bytesPerSecond || 0);
    var units = ["B/s", "K/s", "M/s", "G/s"];
    var idx = 0;
    while (value >= 1024 && idx < units.length - 1) {
      value /= 1024;
      idx += 1;
    }
    return (value >= 10 || idx === 0 ? value.toFixed(0) : value.toFixed(1)) + units[idx];
  }

  function requestStats() {
    if (!main || !main.activeDevice || !online || statsProcess.running)
      return;
    statsProcess.command = [
      "cat",
      "/sys/class/net/" + main.activeDevice + "/statistics/rx_bytes",
      "/sys/class/net/" + main.activeDevice + "/statistics/tx_bytes"
    ];
    statsProcess.running = true;
  }

  onOnlineChanged: {
    if (!online) {
      statsTimer.stop();
      resetStats();
    } else if (showRates) {
      requestStats();
    }
  }

  onMainChanged: resetStats()

  onActiveDeviceNameChanged: {
    resetStats();
    if (showRates && online) {
      requestStats();
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusL
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: online ? Qt.alpha(accentColor, 0.24) : Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        icon: root.iconName
        applyUiScale: false
        color: mouseArea.containsMouse ? root.hoverTextColor : accentColor
      }

      RowLayout {
        visible: showRates
        spacing: Style.marginXS

        Rectangle {
          radius: Style.radiusM
          color: mouseArea.containsMouse ? Qt.alpha("#ffffff", 0.70) : Qt.alpha(root.downColor, 0.12)
          border.color: mouseArea.containsMouse ? Qt.alpha(root.hoverTextColor, 0.16) : Qt.alpha(root.downColor, 0.22)
          border.width: 1
          Layout.preferredHeight: Math.max(Style.capsuleHeight - 10, 18)
          Layout.preferredWidth: root.rateChipWidth

          RowLayout {
            id: downRow
            anchors.centerIn: parent
            spacing: 4

            NText {
              text: "↓"
              pointSize: Math.max(Style.barFontSize - 1, 8)
              font.weight: Font.DemiBold
              color: mouseArea.containsMouse ? root.hoverTextColor : root.downColor
            }

            NText {
              text: root.downRateText
              pointSize: Style.barFontSize
              font.weight: Font.Medium
              color: mouseArea.containsMouse ? root.hoverTextColor : root.baseTextColor
            }
          }
        }

        Rectangle {
          radius: Style.radiusM
          color: mouseArea.containsMouse ? Qt.alpha("#ffffff", 0.70) : Qt.alpha(root.upColor, 0.12)
          border.color: mouseArea.containsMouse ? Qt.alpha(root.hoverTextColor, 0.16) : Qt.alpha(root.upColor, 0.22)
          border.width: 1
          Layout.preferredHeight: Math.max(Style.capsuleHeight - 10, 18)
          Layout.preferredWidth: root.rateChipWidth

          RowLayout {
            id: upRow
            anchors.centerIn: parent
            spacing: 4

            NText {
              text: "↑"
              pointSize: Math.max(Style.barFontSize - 1, 8)
              font.weight: Font.DemiBold
              color: mouseArea.containsMouse ? root.hoverTextColor : root.upColor
            }

            NText {
              text: root.upRateText
              pointSize: Style.barFontSize
              font.weight: Font.Medium
              color: mouseArea.containsMouse ? root.hoverTextColor : root.baseTextColor
            }
          }
        }
      }

      NText {
        visible: !showRates && showLabel
        text: root.labelText()
        color: mouseArea.containsMouse ? root.hoverTextColor : root.baseTextColor
        pointSize: Style.barFontSize
        font.weight: Font.Medium
        elide: Text.ElideRight
      }

      Rectangle {
        visible: online
        Layout.preferredWidth: 8
        Layout.preferredHeight: 8
        radius: 4
        color: accentColor
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        if (!main || !main.activeDevice)
          return;
        showRates = !showRates;
        if (showRates) {
          requestStats();
          statsTimer.start();
        } else {
          statsTimer.stop();
          resetStats();
        }
        return;
      }
      if (pluginApi) {
        pluginApi.openPanel(root.screen);
      }
    }
  }

  Process {
    id: statsProcess
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = String(this.text || "").trim().split("\n");
        if (lines.length < 2)
          return;
        var rx = parseFloat(lines[0]);
        var tx = parseFloat(lines[1]);
        if (isNaN(rx) || isNaN(tx))
          return;
        var now = Date.now();
        if (root.lastSampleMs > 0 && root.lastRxBytes >= 0 && root.lastTxBytes >= 0) {
          var seconds = Math.max((now - root.lastSampleMs) / 1000.0, 0.25);
          root.rxRateBps = Math.max((rx - root.lastRxBytes) / seconds, 0);
          root.txRateBps = Math.max((tx - root.lastTxBytes) / seconds, 0);
        }
        root.lastRxBytes = rx;
        root.lastTxBytes = tx;
        root.lastSampleMs = now;
      }
    }
    onExited: function() {
      if (showRates && online) {
        statsTimer.restart();
      }
    }
  }

  Timer {
    id: statsTimer
    interval: 2000
    running: false
    repeat: false
    onTriggered: root.requestStats()
  }
}
