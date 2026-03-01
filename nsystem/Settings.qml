import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginM

    NText {
      text: "NSystem Settings"
      font.weight: Font.Bold
      font.pointSize: Style.fontSizeL * Style.uiScaleRatio
    }

    NText {
      text: "Tune refresh frequency and external tool commands."
      color: Color.mOnSurfaceVariant
      wrapMode: Text.Wrap
    }

    NText { text: "Watchdog Interval (ms)" }
    SpinBox {
      from: 1500
      to: 30000
      stepSize: 500
      value: settings && settings.watchdogInterval ? settings.watchdogInterval : 4000
      editable: true
      onValueModified: if (settings) settings.watchdogInterval = value
    }

    NText { text: "btop command" }
    TextField {
      Layout.fillWidth: true
      text: settings && settings.btopCommand ? settings.btopCommand : "kitty --class btop -e btop"
      selectByMouse: true
      onEditingFinished: if (settings) settings.btopCommand = text.trim()
    }

    NText { text: "htop command" }
    TextField {
      Layout.fillWidth: true
      text: settings && settings.htopCommand ? settings.htopCommand : "kitty --class htop -e htop"
      selectByMouse: true
      onEditingFinished: if (settings) settings.htopCommand = text.trim()
    }

    NText { text: "top command" }
    TextField {
      Layout.fillWidth: true
      text: settings && settings.topCommand ? settings.topCommand : "kitty --class top -e top"
      selectByMouse: true
      onEditingFinished: if (settings) settings.topCommand = text.trim()
    }
  }
}
