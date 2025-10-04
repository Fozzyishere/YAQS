pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  property var current: new Date()

  Timer {
    interval: 1000
    repeat: true
    running: true
    onTriggered: root.current = new Date()
  }

  function getFormattedTimestamp(date) {
    if (!date) {
      date = new Date()
    }
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    const hours = String(date.getHours()).padStart(2, '0')
    const minutes = String(date.getMinutes()).padStart(2, '0')
    const seconds = String(date.getSeconds()).padStart(2, '0')

    return `${year}${month}${day}-${hours}${minutes}${seconds}`
  }
}