import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property bool protectedMode: Boolean(mainInstance?.vpnConnected || mainInstance?.blockyActive)
    readonly property bool customMode: Boolean(mainInstance?.isCustomDns && !protectedMode)
    readonly property color accentColor: protectedMode
                                      ? Color.mPrimary
                                      : (customMode ? Color.mSecondary : Color.mOnSurface)
    readonly property color hoverTextColor: "#000000"
    readonly property color baseTextColor: Color.mOnSurfaceVariant
    readonly property string chipText: mainInstance?.currentDnsName || pluginApi?.tr("plugin.short_title") || "DNS"
    readonly property real infoChipWidth: Math.round(88 * Style.uiScaleRatio)
    readonly property real contentWidth: contentRow.implicitWidth + (Style.marginM * 2)
    readonly property real contentHeight: Style.capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        radius: height / 2
        border.color: Qt.alpha(root.accentColor, 0.22)
        border.width: Style.capsuleBorderWidth

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                icon: mainInstance?.currentIconName || "world"
                applyUiScale: false
                color: mouseArea.containsMouse ? root.hoverTextColor : root.accentColor
            }

            Rectangle {
                radius: Style.radiusM
                color: mouseArea.containsMouse ? Qt.alpha("#ffffff", 0.70) : Qt.alpha(root.accentColor, 0.12)
                border.color: mouseArea.containsMouse ? Qt.alpha(root.hoverTextColor, 0.16) : Qt.alpha(root.accentColor, 0.22)
                border.width: 1
                Layout.preferredHeight: Math.max(Style.capsuleHeight - 10, 18)
                Layout.preferredWidth: root.infoChipWidth

                NText {
                    anchors.fill: parent
                    anchors.leftMargin: Style.marginS
                    anchors.rightMargin: Style.marginS
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.chipText
                    pointSize: Style.barFontSize
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    color: mouseArea.containsMouse ? root.hoverTextColor : root.baseTextColor
                }
            }

            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: 4
                color: protectedMode ? Color.mPrimary : (customMode ? Color.mSecondary : Qt.alpha(Color.mOutline, 0.45))
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (pluginApi) {
                pluginApi.openPanel(root.screen, root);
            }
        }
    }
}
