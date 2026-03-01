import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "podmanUtils.js" as PodmanUtils
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    readonly property var geometryPlaceholder: panelFrame
    readonly property bool allowAttach: true

    property real contentPreferredWidth: Math.round(860 * Style.uiScaleRatio)
    property real contentPreferredHeight: Math.round(620 * Style.uiScaleRatio)

    property bool podmanAvailable: false
    property bool actionBusy: false
    property int currentTabIndex: 0
    property string lastError: ""
    property int containerCount: 0
    property int runningContainerCount: 0
    property int imageCount: 0
    property int podCount: 0
    property int runningPodCount: 0
    property var pendingCallback: null

    function resolveWatchdogInterval() {
        var candidate = pluginApi && pluginApi.pluginSettings ? parseInt(pluginApi.pluginSettings.refreshInterval, 10) : NaN;
        return (isNaN(candidate) || candidate <= 0) ? 60000 : candidate;
    }

    readonly property int watchdogInterval: resolveWatchdogInterval()

    ListModel { id: containersModel }
    ListModel { id: imagesModel }
    ListModel { id: podsModel }

    function appendRows(model, rows) {
        model.clear();
        rows.forEach(function(row) {
            model.append(row);
        });
    }

    function updateStats() {
        containerCount = containersModel.count;
        imageCount = imagesModel.count;
        podCount = podsModel.count;

        var runningContainers = 0;
        for (var i = 0; i < containersModel.count; ++i) {
            if (containersModel.get(i).running) {
                runningContainers += 1;
            }
        }
        runningContainerCount = runningContainers;

        var runningPods = 0;
        for (var j = 0; j < podsModel.count; ++j) {
            if (podsModel.get(j).running) {
                runningPods += 1;
            }
        }
        runningPodCount = runningPods;
    }

    function applyContainers(text) {
        appendRows(containersModel, PodmanUtils.parseContainers(text));
        updateStats();
    }

    function applyImages(text) {
        appendRows(imagesModel, PodmanUtils.parseImages(text));
        updateStats();
    }

    function applyPods(text) {
        appendRows(podsModel, PodmanUtils.parsePods(text));
        updateStats();
    }

    function refreshAll() {
        if (!podmanAvailable || actionBusy) {
            return;
        }
        if (!containersProcess.running) {
            containersProcess.running = true;
        }
        if (!imagesProcess.running) {
            imagesProcess.running = true;
        }
        if (!podsProcess.running) {
            podsProcess.running = true;
        }
    }

    function scheduleRefresh() {
        if (podmanAvailable && visible) {
            eventDebounceTimer.restart();
        }
    }

    function startEventMonitor() {
        if (podmanAvailable && visible && !eventsProcess.running) {
            eventsProcess.running = true;
        }
    }

    function stopEventMonitor() {
        eventsRestartTimer.stop();
        if (eventsProcess.running) {
            eventsProcess.running = false;
        }
    }

    function handleEventData(data) {
        var text = String(data || "").trim();
        if (!text) {
            return;
        }

        scheduleRefresh();
    }

    function runCommand(cmdArgs, callback) {
        if (commandRunner.running) {
            return;
        }
        pendingCallback = callback || null;
        lastError = "";
        actionBusy = true;
        commandRunner.command = cmdArgs;
        commandRunner.running = true;
    }

    function startContainer(containerId) { runCommand(["podman", "start", containerId], refreshAll); }
    function stopContainer(containerId) {
        runCommand([
            "sh", "-lc",
            'podman stop -t 3 -- "$1" >/dev/null 2>&1 || podman kill -- "$1"',
            "npodman-stop-container", containerId
        ], refreshAll);
    }
    function restartContainer(containerId) { runCommand(["podman", "restart", "-t", "3", containerId], refreshAll); }
    function removeContainer(containerId) { runCommand(["podman", "rm", "-f", containerId], refreshAll); }
    function removeImage(imageId) { runCommand(["podman", "rmi", imageId], refreshAll); }
    function startPod(name) { runCommand(["podman", "pod", "start", name], refreshAll); }
    function stopPod(name) {
        runCommand([
            "sh", "-lc",
            'podman pod stop -t 3 -- "$1" >/dev/null 2>&1 || podman pod kill -- "$1"',
            "npodman-stop-pod", name
        ], refreshAll);
    }
    function removePod(name) { runCommand(["podman", "pod", "rm", "-f", name], refreshAll); }


    function compactContainerLine(name, shortId, image, status, ports) {
        var parts = [];
        parts.push(String(name || shortId || "container"));
        if (String(image || "").trim() !== "") {
            parts.push(String(image));
        }
        if (String(status || "").trim() !== "") {
            parts.push(String(status));
        }
        if (String(ports || "").trim() !== "") {
            parts.push(String(ports));
        }
        return parts.join(" | ");
    }

    Component.onCompleted: checkProcess.running = true

    onVisibleChanged: {
        if (!podmanAvailable) {
            return;
        }

        if (visible) {
            refreshAll();
            startEventMonitor();
        } else {
            stopEventMonitor();
        }
    }

    Process {
        id: checkProcess
        command: ["podman", "version", "--format", "json"]
        stderr: StdioCollector { id: checkStderr }
        onExited: function(code) {
            podmanAvailable = (code === 0);
            if (podmanAvailable) {
                refreshAll();
                if (root.visible) {
                    startEventMonitor();
                }
            } else {
                stopEventMonitor();
                lastError = (checkStderr.text || "Podman not available").trim();
            }
        }
    }

    Process {
        id: containersProcess
        command: ["podman", "ps", "-a", "--format", "json"]
        stdout: StdioCollector {
            id: containersStdout
            onStreamFinished: root.applyContainers(this.text || "")
        }
        stderr: StdioCollector { id: containersStderr }
        onExited: function(code) {
            if (code !== 0) {
                lastError = (containersStderr.text || "Failed to read Podman containers").trim();
            }
        }
    }

    Process {
        id: imagesProcess
        command: ["podman", "images", "--format", "json"]
        stdout: StdioCollector {
            id: imagesStdout
            onStreamFinished: root.applyImages(this.text || "")
        }
        stderr: StdioCollector { id: imagesStderr }
        onExited: function(code) {
            if (code !== 0) {
                lastError = (imagesStderr.text || "Failed to read Podman images").trim();
            }
        }
    }

    Process {
        id: podsProcess
        command: ["podman", "pod", "ps", "--format", "json"]
        stdout: StdioCollector {
            id: podsStdout
            onStreamFinished: root.applyPods(this.text || "")
        }
        stderr: StdioCollector { id: podsStderr }
        onExited: function(code) {
            if (code !== 0) {
                lastError = (podsStderr.text || "Failed to read Podman pods").trim();
            }
        }
    }

    Process {
        id: commandRunner
        stdout: StdioCollector { id: runnerStdout }
        stderr: StdioCollector { id: runnerStderr }
        onExited: function(code) {
            actionBusy = false;
            if (code !== 0) {
                lastError = (runnerStderr.text || runnerStdout.text || ("Podman command failed (" + code + ")")).trim();
            }
            if (pendingCallback) {
                var cb = pendingCallback;
                pendingCallback = null;
                cb();
            }
        }
    }

    Process {
        id: eventsProcess
        command: [
            "podman", "events", "--format", "json",
            "--filter", "type=container",
            "--filter", "type=pod",
            "--filter", "type=image"
        ]
        stdout: SplitParser {
            onRead: data => root.handleEventData(data)
        }
        onRunningChanged: {
            if (!running && root.visible && root.podmanAvailable) {
                eventsRestartTimer.restart();
            }
        }
    }

    Timer {
        id: eventDebounceTimer
        interval: 400
        running: false
        repeat: false
        onTriggered: root.refreshAll()
    }

    Timer {
        id: eventsRestartTimer
        interval: 5000
        running: false
        repeat: false
        onTriggered: root.startEventMonitor()
    }

    Timer {
        id: watchdogTimer
        interval: root.watchdogInterval
        running: root.visible && root.podmanAvailable
        repeat: true
        onTriggered: root.refreshAll()
    }

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

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                Rectangle {
                    Layout.preferredWidth: Math.round(44 * Style.uiScaleRatio)
                    Layout.preferredHeight: Math.round(44 * Style.uiScaleRatio)
                    radius: width / 2
                    color: Qt.alpha(Color.mPrimary, 0.14)
                    border.color: Qt.alpha(Color.mPrimary, 0.2)
                    border.width: 1

                    NIcon {
                        anchors.centerIn: parent
                        icon: "brand-docker"
                        pointSize: Style.fontSizeL
                        color: Color.mPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    NText {
                        text: "NPodman"
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                    }

                    NText {
                        text: root.podmanAvailable
                              ? (root.actionBusy ? "Applying Podman action..." : "Podman containers, images, and pods in one compact panel")
                              : "Podman CLI is not available in this session"
                        pointSize: Style.fontSizeXS
                        color: Color.mSecondary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                NButton {
                    text: "Refresh"
                    icon: "refresh"
                    enabled: root.podmanAvailable && !root.actionBusy
                    onClicked: root.refreshAll()
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: Style.marginS
                rowSpacing: Style.marginS

                Rectangle {
                    Layout.fillWidth: true
                    radius: Style.radiusM
                    color: Qt.alpha(Color.mPrimary, 0.08)
                    border.color: Qt.alpha(Color.mPrimary, 0.14)
                    border.width: 1
                    implicitHeight: containersSummary.implicitHeight + (Style.marginM * 2)

                    ColumnLayout {
                        id: containersSummary
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: 2

                        NText { text: "Containers"; pointSize: Style.fontSizeXS; color: Color.mSecondary }
                        NText { text: root.runningContainerCount + " / " + root.containerCount; pointSize: Style.fontSizeL; font.weight: Font.Medium; color: Color.mOnSurface }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: Style.radiusM
                    color: Qt.alpha(Color.mPrimary, 0.08)
                    border.color: Qt.alpha(Color.mPrimary, 0.14)
                    border.width: 1
                    implicitHeight: imagesSummary.implicitHeight + (Style.marginM * 2)

                    ColumnLayout {
                        id: imagesSummary
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: 2

                        NText { text: "Images"; pointSize: Style.fontSizeXS; color: Color.mSecondary }
                        NText { text: String(root.imageCount); pointSize: Style.fontSizeL; font.weight: Font.Medium; color: Color.mOnSurface }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: Style.radiusM
                    color: Qt.alpha(Color.mPrimary, 0.08)
                    border.color: Qt.alpha(Color.mPrimary, 0.14)
                    border.width: 1
                    implicitHeight: podsSummary.implicitHeight + (Style.marginM * 2)

                    ColumnLayout {
                        id: podsSummary
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: 2

                        NText { text: "Pods"; pointSize: Style.fontSizeXS; color: Color.mSecondary }
                        NText { text: root.runningPodCount + " / " + root.podCount; pointSize: Style.fontSizeL; font.weight: Font.Medium; color: Color.mOnSurface }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.lastError !== ""
                color: Qt.alpha(Color.mError, 0.1)
                radius: Style.radiusS
                border.color: Qt.alpha(Color.mError, 0.3)
                border.width: 1
                implicitHeight: errorText.implicitHeight + Style.marginM

                NText {
                    id: errorText
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    text: root.lastError
                    color: Color.mError
                    pointSize: Style.fontSizeS
                    wrapMode: Text.WordWrap
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                Repeater {
                    model: ["Containers", "Images", "Pods"]

                    delegate: NButton {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        text: modelData
                        backgroundColor: root.currentTabIndex === index ? Qt.alpha(Color.mPrimary, 0.14) : Qt.alpha(Color.mSurfaceVariant, 0.48)
                        textColor: root.currentTabIndex === index ? Color.mPrimary : Color.mOnSurface
                        onClicked: root.currentTabIndex = index
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentTabIndex

                Item {
                    ListView {
                        id: containersView
                        anchors.fill: parent
                        model: containersModel
                        spacing: Style.marginS
                        clip: true
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            required property string uid
                            required property string shortId
                            required property string name
                            required property string image
                            required property string state
                            required property string status
                            required property string ports
                            required property bool running
                            required property bool canStart
                            required property bool canStop
                            required property bool canRestart
                            required property string statusColor

                            width: ListView.view.width - 8
                            radius: Style.radiusM
                            color: Qt.alpha(Color.mSurfaceVariant, 0.34)
                            border.color: Qt.alpha(Color.mOutline, 0.12)
                            border.width: 1
                            implicitHeight: containerLayout.implicitHeight + (Style.marginM * 2)

                            ColumnLayout {
                                id: containerLayout
                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                spacing: Style.marginS

                                NText {
                                    Layout.fillWidth: true
                                    text: root.compactContainerLine(name, shortId, image, status, ports)
                                    pointSize: Style.fontSizeS
                                    font.weight: Font.Medium
                                    color: Color.mOnSurface
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Style.marginS

                                    NButton {
                                        text: "Start"
                                        icon: "player-play"
                                        Layout.fillWidth: true
                                        enabled: !root.actionBusy && canStart
                                        onClicked: root.startContainer(uid)
                                    }

                                    NButton {
                                        text: "Stop"
                                        icon: "player-stop"
                                        Layout.fillWidth: true
                                        enabled: !root.actionBusy && canStop
                                        onClicked: root.stopContainer(uid)
                                    }

                                    NButton {
                                        text: "Restart"
                                        icon: "refresh"
                                        Layout.fillWidth: true
                                        enabled: !root.actionBusy && canRestart
                                        onClicked: root.restartContainer(uid)
                                    }

                                    NButton {
                                        text: "Remove"
                                        icon: "trash"
                                        Layout.fillWidth: true
                                        enabled: !root.actionBusy
                                        onClicked: root.removeContainer(uid)
                                    }
                                }
                            }
                        }
                    }

                    NText {
                        anchors.centerIn: parent
                        visible: !root.actionBusy && containersModel.count === 0
                        text: root.podmanAvailable ? "No Podman containers found" : "Podman unavailable"
                        color: Color.mSecondary
                    }
                }

                Item {
                    ListView {
                        id: imagesView
                        anchors.fill: parent
                        model: imagesModel
                        spacing: Style.marginS
                        clip: true
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            required property string uid
                            required property string shortId
                            required property string repository
                            required property string tag
                            required property string size
                            required property string created

                            width: ListView.view.width - 8
                            radius: Style.radiusM
                            color: Qt.alpha(Color.mSurfaceVariant, 0.34)
                            border.color: Qt.alpha(Color.mOutline, 0.12)
                            border.width: 1
                            implicitHeight: imageLayout.implicitHeight + (Style.marginM * 2)

                            ColumnLayout {
                                id: imageLayout
                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                spacing: Style.marginS

                                RowLayout {
                                    Layout.fillWidth: true
                                    NText {
                                        Layout.fillWidth: true
                                        text: repository + ":" + tag
                                        pointSize: Style.fontSizeS
                                        font.weight: Font.Medium
                                        color: Color.mOnSurface
                                        wrapMode: Text.WordWrap
                                    }
                                    NText {
                                        text: shortId
                                        pointSize: Style.fontSizeXS
                                        color: Color.mSecondary
                                    }
                                }

                                NText { text: size; visible: text !== ""; pointSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }
                                NText { text: created; visible: text !== ""; pointSize: Style.fontSizeXS; color: Color.mSecondary; wrapMode: Text.WordWrap }

                                NButton {
                                    Layout.fillWidth: true
                                    text: "Remove Image"
                                    icon: "trash"
                                    enabled: !root.actionBusy
                                    onClicked: root.removeImage(id)
                                }
                            }
                        }
                    }

                    NText {
                        anchors.centerIn: parent
                        visible: !root.actionBusy && imagesModel.count === 0
                        text: root.podmanAvailable ? "No Podman images found" : "Podman unavailable"
                        color: Color.mSecondary
                    }
                }

                Item {
                    ListView {
                        id: podsView
                        anchors.fill: parent
                        model: podsModel
                        spacing: Style.marginS
                        clip: true
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            required property string name
                            required property string shortId
                            required property string status
                            required property string containers
                            required property bool running
                            required property bool canStart
                            required property bool canStop
                            required property string statusColor

                            width: ListView.view.width - 8
                            radius: Style.radiusM
                            color: Qt.alpha(Color.mSurfaceVariant, 0.34)
                            border.color: Qt.alpha(Color.mOutline, 0.12)
                            border.width: 1
                            implicitHeight: podLayout.implicitHeight + (Style.marginM * 2)

                            ColumnLayout {
                                id: podLayout
                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                spacing: Style.marginS

                                RowLayout {
                                    Layout.fillWidth: true

                                    NText {
                                        text: name || shortId
                                        pointSize: Style.fontSizeS
                                        font.weight: Font.Medium
                                        color: Color.mOnSurface
                                    }

                                    Rectangle {
                                        radius: height / 2
                                        color: statusColor
                                        implicitWidth: podStateText.implicitWidth + (Style.marginS * 2)
                                        implicitHeight: podStateText.implicitHeight + Style.marginS

                                        NText {
                                            id: podStateText
                                            anchors.centerIn: parent
                                            text: status
                                            pointSize: Style.fontSizeXS
                                            color: "white"
                                        }
                                    }
                                }

                                NText { text: "Containers: " + containers; pointSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Style.marginS

                                    NButton {
                                        text: "Start"
                                        icon: "player-play"
                                        Layout.fillWidth: true
                                        enabled: !root.actionBusy && canStart
                                        onClicked: root.startPod(name)
                                    }

                                    NButton {
                                        text: "Stop"
                                        icon: "player-stop"
                                        Layout.fillWidth: true
                                        enabled: !root.actionBusy && canStop
                                        onClicked: root.stopPod(name)
                                    }

                                    NButton {
                                        text: "Remove"
                                        icon: "trash"
                                        Layout.fillWidth: true
                                        enabled: !root.actionBusy
                                        onClicked: root.removePod(name)
                                    }
                                }
                            }
                        }
                    }

                    NText {
                        anchors.centerIn: parent
                        visible: !root.actionBusy && podsModel.count === 0
                        text: root.podmanAvailable ? "No Podman pods found" : "Podman unavailable"
                        color: Color.mSecondary
                    }
                }
            }
        }
    }
}
