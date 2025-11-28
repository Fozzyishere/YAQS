import QtQuick
import "../Commons" as QsCommons
import "../Components" as QsComponents

Row {
  id: root

  // === Public Properties ===
  property date dateTime: new Date()
  property string dateFormat: "ddd, MMM d"
  property string timeFormat: "h:mm AP"
  property bool showDate: true
  property bool showTime: true
  property string separator: " • "
  property color textColor: QsCommons.Color.mOnSurface
  property real fontSize: QsCommons.Style.fontSizeM

  spacing: 0

  // Date display
  QsComponents.CText {
    text: Qt.formatDate(root.dateTime, root.dateFormat)
    pointSize: root.fontSize
    color: root.textColor
    visible: root.showDate
  }

  // Separator
  QsComponents.CText {
    text: root.separator
    pointSize: root.fontSize
    color: QsCommons.Color.mOnSurfaceVariant
    visible: root.showDate && root.showTime
  }

  // Time display
  QsComponents.CText {
    text: Qt.formatTime(root.dateTime, root.timeFormat)
    pointSize: root.fontSize
    color: root.textColor
    visible: root.showTime
  }
}

