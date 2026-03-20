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
      icon: main && main.period === "night" ? "moon" : "temperature"
      color: Color.mPrimary
    }

    ColumnLayout {
      spacing: 2

      NText {
        text: main ? String(main.activePresetLabel || "Sunsetr") : "Sunsetr"
        font.weight: Font.DemiBold
      }

      NText {
        text: main
              ? ((main.currentTemp > 0 ? Math.round(main.currentTemp) + "K" : "--") + " | " + (main.serviceActive ? String(main.period || "static") : "stopped"))
              : "Checking..."
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
        main.openPanelUi();
    }
  }
}
