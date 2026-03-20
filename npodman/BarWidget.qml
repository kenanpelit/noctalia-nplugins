import QtQuick
import Quickshell
import Quickshell.Io
import "podmanUtils.js" as PodmanUtils
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    property bool podmanAvailable: false
    property int runningCount: 0
    property int totalCount: 0

    function resolveWatchdogInterval() {
        var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.refreshInterval, 10) : NaN;
        return (isNaN(candidate) || candidate <= 0) ? 60000 : candidate;
    }

    readonly property int watchdogInterval: resolveWatchdogInterval()
    readonly property bool hasRunningContainers: podmanAvailable && runningCount > 0
    readonly property color activeColor: "#4caf50"
    readonly property color accentColor: {
        if (!podmanAvailable)
            return Color.mError;
        if (hasRunningContainers)
            return activeColor;
        return Color.mOnSurfaceVariant;
    }
    readonly property color hoverTextColor: "#000000"
    readonly property color borderColor: hasRunningContainers
                                         ? Qt.alpha(root.activeColor, 0.22)
                                         : (podmanAvailable ? Style.capsuleBorderColor : Qt.alpha(Color.mError, 0.22))
    readonly property real contentWidth: Style.capsuleHeight
    readonly property real contentHeight: Style.capsuleHeight
    readonly property string tooltipText: {
        if (!podmanAvailable)
            return "Podman unavailable";
        var lines = [];
        lines.push("Containers: " + runningCount + " / " + totalCount);
        lines.push(hasRunningContainers ? "Active containers detected" : "No running containers");
        lines.push("Left click: Open panel");
        return lines.join("\n");
    }

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Component.onCompleted: checkProcess.running = true

    function refreshCounts() {
        if (podmanAvailable && !countProcess.running) {
            countProcess.running = true;
        }
    }

    function scheduleRefresh() {
        if (podmanAvailable) {
            eventDebounceTimer.restart();
        }
    }

    function startEventMonitor() {
        if (podmanAvailable && !eventsProcess.running) {
            eventsProcess.running = true;
        }
    }

    function handleEventData(data) {
        var text = String(data || "").trim();
        if (!text) {
            return;
        }

        scheduleRefresh();
    }

    Process {
        id: checkProcess
        command: ["podman", "version", "--format", "json"]
        onExited: function(code) {
            root.podmanAvailable = (code === 0);
            if (root.podmanAvailable) {
                root.refreshCounts();
                root.startEventMonitor();
            } else {
                root.runningCount = 0;
                root.totalCount = 0;
            }
        }
    }

    Process {
        id: countProcess
        command: ["podman", "ps", "-a", "--format", "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                var containers = PodmanUtils.parseContainers(this.text || "");
                root.totalCount = containers.length;
                root.runningCount = 0;
                containers.forEach(function(container) {
                    if (container.running) {
                        root.runningCount += 1;
                    }
                });
            }
        }
        onExited: function(code) {
            if (code !== 0) {
                root.runningCount = 0;
                root.totalCount = 0;
            }
        }
    }

    Process {
        id: eventsProcess
        command: [
            "podman", "events", "--format", "json",
            "--filter", "type=container",
            "--filter", "type=pod"
        ]
        stdout: SplitParser {
            onRead: data => root.handleEventData(data)
        }
        onRunningChanged: {
            if (!running && root.podmanAvailable) {
                eventRestartTimer.restart();
            }
        }
    }

    Timer {
        id: eventDebounceTimer
        interval: 400
        running: false
        repeat: false
        onTriggered: root.refreshCounts()
    }

    Timer {
        id: eventRestartTimer
        interval: 5000
        running: false
        repeat: false
        onTriggered: root.startEventMonitor()
    }

    Timer {
        id: watchdogTimer
        interval: root.watchdogInterval
        running: root.podmanAvailable
        repeat: true
        onTriggered: root.refreshCounts()
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: mouse.containsMouse ? Color.mHover : Style.capsuleColor
        border.color: root.borderColor
        border.width: Style.capsuleBorderWidth
        Behavior on color { ColorAnimation { duration: 150 } }

        NIcon {
            anchors.centerIn: parent
            icon: "brand-docker"
            applyUiScale: false
            pointSize: Style.fontSizeM
            color: mouse.containsMouse ? root.hoverTextColor : root.accentColor
        }

        Rectangle {
            visible: root.hasRunningContainers
            anchors.right: parent.right
            anchors.rightMargin: Style.marginXS
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.marginXS
            width: 8
            height: 8
            radius: 4
            color: root.activeColor
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (pluginApi && root.podmanAvailable) {
                pluginApi.openPanel(root.screen, root);
            }
        }

        onEntered: {
            if (root.tooltipText)
                TooltipService.show(root, root.tooltipText, BarService.getTooltipDirection(root.screen?.name));
        }

        onExited: TooltipService.hide()
    }
}
