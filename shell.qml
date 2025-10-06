import QtQuick
import Quickshell

import "Commons"
import "Services"
import "Modules/Bar"

ShellRoot {
  id: root

  Component.onCompleted: {
    Logger.log("Shell", "Shell started successfully")

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
