import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var main: pluginApi ? pluginApi.mainInstance : null

  implicitWidth: Math.round(220 * Style.uiScaleRatio)
  implicitHeight: ccRect.implicitHeight

  Rectangle {
    id: ccRect
    anchors.fill: parent
    radius: Style.radiusL
    color: Color.mSurfaceVariant
    border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.12)
    border.width: 1
    implicitHeight: row.implicitHeight + (Style.marginM * 2)

    RowLayout {
      id: row
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NIcon {
        icon: "activity"
        color: Color.mPrimary
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        NText {
          text: "NSystem"
          font.weight: Font.DemiBold
        }

        NText {
          text: main ? ("CPU " + main.cpuUsage + "% • RAM " + main.memPercent + "%") : "Reading system state..."
          color: Color.mOnSurfaceVariant
          pointSize: Style.fontSizeS * Style.uiScaleRatio
          wrapMode: Text.Wrap
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: if (pluginApi) pluginApi.togglePanel();
    }
  }
}
