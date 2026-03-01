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
      icon: "clipboard-text"
      color: main && String(main.currentClipboard || "").trim() !== "" ? Color.mPrimary : Color.mOnSurface
    }

    ColumnLayout {
      spacing: 2

      NText {
        text: "NClipper"
        font.weight: Font.DemiBold
      }

      NText {
        text: main ? (main.clipCount + " saved | " + main.pinnedCount + " pinned") : "Checking..."
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
