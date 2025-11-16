pragma Singleton

import QtQuick
import Quickshell
import "../Commons" as QsCommons

Singleton {
  id: root

  // === State Tracking ===
  property var activeTooltip: null         // Currently visible tooltip
  property var pendingTooltip: null        // Tooltip waiting to show (delay timer)

  // === Component Definition ===
  // NOTE: Placeholder until Tooltip.qml is implemented
  property Component tooltipComponent: Component {
    QtObject {
      property var targetItem: null
      property bool visible: false
      
      function show(screen, target, text, direction, delay) {
        QsCommons.Logger.w("TooltipService", "Tooltip UI component not yet implemented")
      }
      
      function hide() {}
      function hideImmediately() {}
      function updateText(text) {}
      function destroy() {}
    }
  }

  // === Public API ===

  // Show tooltip for target widget
  function show(screen, target, text, direction, delay) {
    if (!QsCommons.Settings.data.ui.tooltipsEnabled)
      return null

    if (!screen || !target || !text || text === "") {
      QsCommons.Logger.d("TooltipService", "Missing required parameters")
      return null
    }

    // Cancel pending tooltip for different target
    if (pendingTooltip && pendingTooltip.targetItem !== target) {
      pendingTooltip.hideImmediately()
      pendingTooltip.destroy()
      pendingTooltip = null
    }

    // Hide active tooltip for different target
    if (activeTooltip && activeTooltip.targetItem !== target) {
      activeTooltip.hideImmediately()
      activeTooltip = null
    }

    // Update text if tooltip already exists for this target
    if (activeTooltip && activeTooltip.targetItem === target) {
      activeTooltip.updateText(text)
      return activeTooltip
    }

    // Create new tooltip instance
    const newTooltip = tooltipComponent.createObject(null)

    if (!newTooltip) {
      QsCommons.Logger.e("TooltipService", "Failed to create tooltip instance")
      return null
    }

    pendingTooltip = newTooltip

    // Setup lifecycle management
    newTooltip.visibleChanged.connect(() => {
      if (!newTooltip.visible) {
        Qt.callLater(() => {
          if (newTooltip && !newTooltip.visible) {
            if (activeTooltip === newTooltip)
              activeTooltip = null
            if (pendingTooltip === newTooltip)
              pendingTooltip = null
            newTooltip.destroy()
          }
        })
      } else {
        if (pendingTooltip === newTooltip) {
          activeTooltip = newTooltip
          pendingTooltip = null
        }
      }
    })

    // Show with parameters
    newTooltip.show(
      screen,
      target,
      text,
      direction || "auto",
      delay !== undefined ? delay : QsCommons.Style.tooltipDelay
    )

    return newTooltip
  }

  // Hide current tooltip (with animation)
  function hide() {
    if (pendingTooltip)
      pendingTooltip.hide()
    if (activeTooltip)
      activeTooltip.hide()
  }

  // Hide immediately (no animation)
  function hideImmediately() {
    if (pendingTooltip) {
      pendingTooltip.hideImmediately()
      pendingTooltip.destroy()
      pendingTooltip = null
    }
    if (activeTooltip) {
      activeTooltip.hideImmediately()
      activeTooltip.destroy()
      activeTooltip = null
    }
  }

  // Update text of active tooltip
  function updateText(newText) {
    if (activeTooltip)
      activeTooltip.updateText(newText)
  }
}
