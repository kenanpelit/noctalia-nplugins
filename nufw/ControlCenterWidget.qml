import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var main: pluginApi ? pluginApi.mainInstance : null

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusM
    color: Qt.alpha(Color.mSurfaceVariant, 0.4)
    border.color: Qt.alpha(Color.mOutline, 0.12)
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      Rectangle {
        Layout.preferredWidth: Math.round(34 * Style.uiScaleRatio)
        Layout.preferredHeight: Math.round(34 * Style.uiScaleRatio)
        radius: width / 2
        color: Qt.alpha(Color.mPrimary, 0.14)

        NIcon {
          anchors.centerIn: parent
          icon: "shield"
          pointSize: Style.fontSizeM
          color: Color.mPrimary
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        NText {
          text: "NUFW"
          pointSize: Style.fontSizeS
          font.weight: Font.Medium
          color: Color.mOnSurface
        }

        NText {
          text: {
            if (!main || !main.available)
              return "UFW unavailable";
            return main.status === "active"
                   ? ("Active • " + main.ruleCount + " rules")
                   : "Inactive";
          }
          pointSize: Style.fontSizeXS
          color: Color.mOnSurfaceVariant
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {
        if (!pluginApi)
          return;
        pluginApi.withCurrentScreen(function(screen) {
          pluginApi.togglePanel(screen, null);
        });
      }
    }
  }
}
