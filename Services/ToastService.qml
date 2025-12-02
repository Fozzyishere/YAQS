pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Configuration ===
  property int maxVisible: 5
  property int defaultNoticeDuration: 3000
  property int defaultWarningDuration: 4000
  property int defaultErrorDuration: 5000

  // === Toast List Model ===
  // UI components bind to this model via Repeater
  property ListModel toastList: ListModel {}

  // === Internal State ===
  property int _nextId: 1

  // === Auto-Expire Timer ===
  // Checks for expired toasts and removes them
  Timer {
    id: expireTimer
    interval: 200  // Check 5 times/sec
    repeat: true
    running: toastList.count > 0
    onTriggered: root._removeExpiredToasts()
  }

  // === Convenience Methods ===
  function showNotice(message, description = "", duration = -1) {
    _addToast(message, description, "notice", duration > 0 ? duration : defaultNoticeDuration)
  }

  function showWarning(message, description = "", duration = -1) {
    _addToast(message, description, "warning", duration > 0 ? duration : defaultWarningDuration)
  }

  function showError(message, description = "", duration = -1) {
    _addToast(message, description, "error", duration > 0 ? duration : defaultErrorDuration)
  }

  // === Internal Functions ===
  function _addToast(message, description, type, duration) {
    QsCommons.Logger.d("ToastService", "Adding toast:", type, message)

    var toastId = "toast_" + _nextId++
    var now = Date.now()

    // Add to list (newest at bottom, oldest at top)
    toastList.append({
      "toastId": toastId,
      "message": message,
      "description": description || "",
      "type": type,
      "duration": duration,
      "timestamp": now
    })

    // Enforce max visible - remove oldest (top) if over limit
    while (toastList.count > maxVisible) {
      QsCommons.Logger.d("ToastService", "Max toasts reached, removing oldest")
      toastList.remove(0)
    }
  }

  function _removeExpiredToasts() {
    var now = Date.now()
    var toRemove = []

    for (var i = 0; i < toastList.count; i++) {
      var toast = toastList.get(i)
      var elapsed = now - toast.timestamp

      // Mark for removal if expired
      if (elapsed >= toast.duration) {
        toRemove.push(i)
      }
    }

    // Remove expired toasts (reverse order to preserve indices)
    for (var j = toRemove.length - 1; j >= 0; j--) {
      toastList.remove(toRemove[j])
    }
  }

  function dismissToast(toastId) {
    for (var i = 0; i < toastList.count; i++) {
      if (toastList.get(i).toastId === toastId) {
        toastList.remove(i)
        break
      }
    }
  }

  function clearAll() {
    toastList.clear()
  }

  // === IPC Handler ===
  IpcHandler {
    target: "toast"

    function showNotice(message: string, description: string): void {
      root.showNotice(message, description)
    }

    function showWarning(message: string, description: string): void {
      root.showWarning(message, description)
    }

    function showError(message: string, description: string): void {
      root.showError(message, description)
    }

    function clearAll(): void {
      root.clearAll()
    }
  }

  // === Initialization ===
  Component.onCompleted: {
    QsCommons.Logger.i("ToastService", "Service initialized")
  }
}
