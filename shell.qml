import QtQuick
import Quickshell

import "Commons"

ShellRoot {
  id: root

  Component.onCompleted: {
    console.log("=".repeat(60))
    console.log("Minimalist Hyprland Shell - Starting")
    console.log("Architecture: Clean Architecture with Vertical Slices")
    console.log("Phase: 1.1 - Core Layer (Commons)")
    console.log("=".repeat(60))

    // Test Logger
    Logger.log("Shell", "Testing Logger singleton")
    Logger.log("Shell", "Current time:", Time.current.toLocaleString())

    // Test Theme
    Logger.log("Shell", "Theme background color:", Theme.bg)
    Logger.log("Shell", "Theme accent color:", Theme.accent)
    Logger.log("Shell", "Theme spacing_m:", Theme.spacing_m)
    Logger.log("Shell", "Theme bar_height:", Theme.bar_height)

    // Test Scaling on all screens
    Logger.log("Shell", "Testing Scaling singleton on", Quickshell.screens.length, "screen(s)")
    for (var i = 0; i < Quickshell.screens.length; i++) {
      var screen = Quickshell.screens[i]
      var scale = Scaling.getScreenScale(screen)
      Logger.log("Shell", `  Screen "${screen.name}": ${screen.width}x${screen.height}, devicePixelRatio=${screen.devicePixelRatio}, scale=${scale}`)
    }

    Logger.log("Shell", "All Commons singletons initialized successfully!")
  }
}
