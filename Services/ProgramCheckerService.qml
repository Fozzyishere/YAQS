pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Public Properties (one per program) ===
  property bool matugenAvailable: false
  property bool kittyAvailable: false
  property bool footAvailable: false
  property bool ghosttyAvailable: false
  property bool gpuScreenRecorderAvailable: false
  property bool nmcliAvailable: false
  property bool bluetoothctlAvailable: false
  property bool brightnessctlAvailable: false
  property bool playerctlAvailable: false

  // === Signals ===
  signal checksCompleted()

  // === Programs to Check ===
  readonly property var programsToCheck: ({
    // Core theming
    "matugenAvailable": ["which", "matugen"],
    
    // Terminal emulators (for theme templates)
    "kittyAvailable": ["which", "kitty"],
    "footAvailable": ["which", "foot"],
    "ghosttyAvailable": ["which", "ghostty"],
    
    // Screen recording (check both binary and Flatpak)
    "gpuScreenRecorderAvailable": ["sh", "-c",
      "command -v gpu-screen-recorder >/dev/null 2>&1 || " +
      "(command -v flatpak >/dev/null 2>&1 && flatpak list --app | grep -q 'com.dec05eba.gpu_screen_recorder')"],
    
    // Network tools
    "nmcliAvailable": ["which", "nmcli"],
    
    // Bluetooth
    "bluetoothctlAvailable": ["which", "bluetoothctl"],
    
    // Brightness
    "brightnessctlAvailable": ["which", "brightnessctl"],
    
    // Media control
    "playerctlAvailable": ["which", "playerctl"]
  })

  // === Internal State ===
  property int completedChecks: 0
  property int totalChecks: Object.keys(programsToCheck).length
  property var checkQueue: []
  property int currentCheckIndex: 0

  // === Single Reusable Process ===
  Process {
    id: checker
    running: false
    property string currentProperty: ""

    onExited: function(exitCode) {
      // Set availability based on exit code
      root[currentProperty] = (exitCode === 0)

      // Log result for debugging
      if (exitCode === 0) {
        QsCommons.Logger.d("ProgramChecker", currentProperty, "✓ available")
      } else {
        QsCommons.Logger.d("ProgramChecker", currentProperty, "✗ not found")
      }

      // Stop process to free resources
      running = false

      // Track completion
      root.completedChecks++

      // Check next program or signal completion
      if (root.completedChecks >= root.totalChecks) {
        QsCommons.Logger.i("ProgramChecker", "All checks completed")
        root.checksCompleted()
      } else {
        root.checkNextProgram()
      }
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  // === Functions ===
  function checkNextProgram() {
    if (currentCheckIndex >= checkQueue.length) return

    var propertyName = checkQueue[currentCheckIndex]
    var command = programsToCheck[propertyName]

    checker.currentProperty = propertyName
    checker.command = command
    checker.running = true

    currentCheckIndex++
  }

  function checkAllPrograms() {
    // Reset state
    completedChecks = 0
    currentCheckIndex = 0
    checkQueue = Object.keys(programsToCheck)

    if (checkQueue.length > 0) {
      QsCommons.Logger.i("ProgramChecker", "Starting checks for", checkQueue.length, "programs")
      checkNextProgram()
    }
  }

  // Optional: Check single program on-demand (for future Settings UI)
  function recheckProgram(programProperty) {
    if (!programsToCheck.hasOwnProperty(programProperty)) {
      QsCommons.Logger.w("ProgramChecker", "Unknown program property:", programProperty)
      return
    }

    checker.currentProperty = programProperty
    checker.command = programsToCheck[programProperty]
    checker.running = true
  }

  // === Initialization ===
  Component.onCompleted: {
    QsCommons.Logger.i("ProgramChecker", "Initializing...")
    checkAllPrograms()
  }
}
