import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var main: pluginApi ? pluginApi.mainInstance : null

  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  RowLayout {
    id: content
    spacing: Style.marginS

    NIcon {
      icon: main && main.onAc ? "plug-connected" : "battery"
      color: Color.mPrimary
    }

    ColumnLayout {
      spacing: 2

      NText {
        text: main ? (main.onAc ? "AC Power" : "Battery") : "Power"
        font.weight: Font.DemiBold
      }

      NText {
        text: main ? ((main.batteryAvailable && main.batteryPercent >= 0 ? main.batteryPercent + "%" : "No battery") + " | " + main.profile) : "Checking..."
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeS
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (pluginApi && main)
        main.openPanel();
    }
  }
}
