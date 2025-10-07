import QtQuick
import Quickshell

import "Commons"
import "Services"
import "Modules/Bar"

ShellRoot {
  id: root

  Component.onCompleted: {
    Logger.log("Shell", "Shell started successfully")

    // ===== BarService Testing =====
    // Test widget lookup after a short delay to ensure all widgets are registered
    Qt.callLater(() => {
      Logger.log("Shell", "=== Testing BarService ===")
      
      // Test widget count
      Logger.log("Shell", `Total registered widgets: ${BarService.getWidgetCount()}`)
      
      // Test getAllRegisteredWidgets()
      const allWidgets = BarService.getAllRegisteredWidgets()
      Logger.log("Shell", `All widget IDs: ${allWidgets.join(", ")}`)
      
      // Test lookupWidget() for each widget type
      const widgetTypes = ["AppLauncher", "Clock", "WindowTitle", "Workspaces", "Audio", "Battery", "PowerMenu"]
      for (var i = 0; i < widgetTypes.length; i++) {
        const widgetId = widgetTypes[i]
        const widget = BarService.lookupWidget(widgetId)
        const found = widget !== null
        Logger.log("Shell", `  lookupWidget("${widgetId}"): ${found ? "✓ Found" : "✗ Not found"}`)
      }
      
      // Test screen-specific lookup
      const audioOnEDP = BarService.lookupWidget("Audio", "eDP-1")
      Logger.log("Shell", `  lookupWidget("Audio", "eDP-1"): ${audioOnEDP !== null ? "✓ Found" : "✗ Not found"}`)
      
      // Test getAllWidgetInstances()
      const workspaceInstances = BarService.getAllWidgetInstances("Workspaces")
      Logger.log("Shell", `  getAllWidgetInstances("Workspaces"): ${workspaceInstances.length} instance(s)`)
      
      // Test hasWidget()
      Logger.log("Shell", `  hasWidget("PowerMenu"): ${BarService.hasWidget("PowerMenu")}`)
      Logger.log("Shell", `  hasWidget("NonExistent"): ${BarService.hasWidget("NonExistent")}`)
      
      // Test getDetailedRegistry()
      const detailedInfo = BarService.getDetailedRegistry()
      Logger.log("Shell", `  Detailed registry has ${detailedInfo.length} entries`)
      
      Logger.log("Shell", "=== BarService tests complete ===")
    })

    // Test CompositorService connection
    CompositorService.workspaceChanged.connect(() => {
      Logger.log("Shell", `Workspaces updated: ${CompositorService.workspaces.count} total`)

      // Log workspace details
      for (var i = 0; i < CompositorService.workspaces.count; i++) {
        const ws = CompositorService.workspaces.get(i)
        Logger.log("Shell", `  WS ${ws.idx}: "${ws.name}" on ${ws.output} - focused=${ws.isFocused} occupied=${ws.isOccupied}`)
      }

      // Log focused window title
      const focusedTitle = CompositorService.getFocusedWindowTitle()
      if (focusedTitle) {
        Logger.log("Shell", `  Focused window: "${focusedTitle}"`)
      }
    })

    // Test BatteryService connection
    BatteryService.batteryChanged.connect(() => {
      Logger.log("Shell", 
                `Battery: ${BatteryService.batteryPercent}%, ` +
                `charging=${BatteryService.isCharging}, ` +
                `hasBattery=${BatteryService.hasBattery}, ` +
                `icon=${BatteryService.getIcon()}`);
    })

    // Test AudioService connection
    AudioService.volumeChanged.connect(() => {
      Logger.log("Shell", 
                `Audio volume: ${AudioService.volume}%, ` +
                `muted=${AudioService.muted}, ` +
                `ready=${AudioService.isReady}, ` +
                `icon=${AudioService.getIcon()}`);
    })

    AudioService.mutedChanged.connect(() => {
      Logger.log("Shell", 
                `Audio muted changed: ${AudioService.muted}`);
    })
  }

  // Floating top bar on all monitors
  Bar {}
}
