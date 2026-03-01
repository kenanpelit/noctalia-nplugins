import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property var main: pluginApi ? pluginApi.mainInstance : null
  readonly property color accentColor: {
    if (!main)
      return Color.mOnSurface;
    if (main.isRecording)
      return Color.mError;
    if (main.anyPrivacyActive)
      return "#ffb74d";
    if (main.recorderAvailable || main.screenshotAvailable)
      return Color.mPrimary;
    return Color.mOnSurfaceVariant;
  }
  readonly property real contentWidth: Style.capsuleHeight
  readonly property real contentHeight: Style.capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusL
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: main && main.anyActive ? Qt.alpha(root.accentColor, 0.28) : Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    NIcon {
      anchors.centerIn: parent
      icon: main && main.isRecording ? "camera-video" : "camera"
      applyUiScale: false
      pointSize: Style.fontSizeM
      color: mouseArea.containsMouse ? Color.mOnHover : root.accentColor
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: function(mouse) {
      if (!main)
        return;
      if (mouse.button === Qt.RightButton) {
        main.toggleRecording();
        return;
      }
      if (pluginApi) {
        pluginApi.openPanel(root.screen);
      }
    }
  }
}
