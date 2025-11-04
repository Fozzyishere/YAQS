pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Public API ===
  property var events: ([])              // Array of event objects
  property bool loading: false           // Loading state
  property bool available: false         // EDS availability
  property var calendars: ([])           // Available calendars
  property string lastError: ""          // Error message for UI
  property bool availabilityChecked: false  // Has availability check completed?
  
  // === Signals ===
  signal availabilityCheckCompleted()

  // === Cache Configuration ===
  property string cacheFile: QsCommons.Settings.cacheDir + "calendar.json"

  // === Python Script Paths ===
  readonly property string checkScript: Quickshell.shellDir + '/Helpers/calendar/check-calendar.py'
  readonly property string listScript: Quickshell.shellDir + '/Helpers/calendar/list-calendars.py'
  readonly property string eventsScript: Quickshell.shellDir + '/Helpers/calendar/calendar-events.py'

  // === Cache File Handling ===
  FileView {
    id: cacheFileView
    path: root.cacheFile
    printErrors: false

    JsonAdapter {
      id: cacheAdapter
      property var cachedEvents: ([])
      property var cachedCalendars: ([])
      property string lastUpdate: ""
    }

    onLoadFailed: {
      // Initialize empty cache on failure
      cacheAdapter.cachedEvents = ([])
      cacheAdapter.cachedCalendars = ([])
      cacheAdapter.lastUpdate = ""
    }

    onLoaded: {
      loadFromCache()
    }
  }

  // === Initialization ===
  Component.onCompleted: {
    QsCommons.Logger.i("Calendar", "Service initialized")
    
    // Load from cache immediately (synchronous, instant events)
    loadFromCache()
    
    // Check availability in background (async)
    checkAvailability()
  }

  // === Cache Management ===
  
  // Debounced save timer (1 second)
  Timer {
    id: saveDebounce
    interval: 1000
    onTriggered: cacheFileView.writeAdapter()
  }

  function saveCache() {
    saveDebounce.restart()
  }

  function loadFromCache() {
    if (cacheAdapter.cachedEvents && cacheAdapter.cachedEvents.length > 0) {
      root.events = cacheAdapter.cachedEvents
      QsCommons.Logger.i("Calendar", `Loaded ${cacheAdapter.cachedEvents.length} cached event(s)`)
    }

    if (cacheAdapter.cachedCalendars && cacheAdapter.cachedCalendars.length > 0) {
      root.calendars = cacheAdapter.cachedCalendars
      QsCommons.Logger.i("Calendar", `Loaded ${cacheAdapter.cachedCalendars.length} cached calendar(s)`)
    }

    if (cacheAdapter.lastUpdate) {
      QsCommons.Logger.i("Calendar", `Cache last updated: ${cacheAdapter.lastUpdate}`)
    }
  }

  // === Auto-Refresh Timer (5 minutes) ===
  Timer {
    id: refreshTimer
    interval: 300000  // 5 minutes
    running: true
    repeat: true
    onTriggered: {
      if (root.available && QsCommons.Settings.data.calendar && 
          QsCommons.Settings.data.calendar.enabled &&
          QsCommons.Settings.data.calendar.autoRefresh) {
        loadEvents()
      }
    }
  }

  // === Public Functions ===
  
  function checkAvailability() {
    const calendarSettings = QsCommons.Settings.data.calendar
    if (calendarSettings && calendarSettings.enabled) {
      availabilityCheckProcess.running = true
    } else {
      root.available = false
      QsCommons.Logger.i("Calendar", "Calendar disabled in settings")
    }
  }

  function loadCalendars() {
    if (!root.available) {
      QsCommons.Logger.w("Calendar", "Cannot load calendars - EDS not available")
      return
    }
    listCalendarsProcess.running = true
  }

  function loadEvents(daysAhead, daysBehind) {
    // Get settings or use defaults
    const calendarSettings = QsCommons.Settings.data.calendar || {}
    const ahead = daysAhead !== undefined ? daysAhead : (calendarSettings.daysAhead || 31)
    const behind = daysBehind !== undefined ? daysBehind : (calendarSettings.daysBehind || 14)

    // Check if enabled
    if (!calendarSettings.enabled) {
      root.loading = false
      root.events = []
      return
    }

    // Prevent concurrent loads
    if (loading) {
      return
    }

    loading = true
    lastError = ""

    // Calculate date range
    const now = new Date()
    const startDate = new Date(now.getTime() - (behind * 24 * 60 * 60 * 1000))
    const endDate = new Date(now.getTime() + (ahead * 24 * 60 * 60 * 1000))

    loadEventsProcess.startTime = Math.floor(startDate.getTime() / 1000)
    loadEventsProcess.endTime = Math.floor(endDate.getTime() / 1000)
    loadEventsProcess.running = true

    QsCommons.Logger.i("Calendar", 
      `Loading events (${behind} days behind, ${ahead} days ahead): ` +
      `${startDate.toLocaleDateString()} to ${endDate.toLocaleDateString()}`)
  }

  // === Helper Functions ===
  
  function formatDateTime(timestamp) {
    const date = new Date(timestamp * 1000)
    return Qt.formatDateTime(date, "yyyy-MM-dd hh:mm")
  }

  // === Process: Check EDS Availability ===
  Process {
    id: availabilityCheckProcess
    running: false
    
    // Use compound shell command to gracefully handle missing Python
    command: [
      "sh", "-c",
      "command -v python3 >/dev/null 2>&1 && python3 " + root.checkScript + 
      " || echo 'unavailable: python3 not installed'"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        const result = text.trim()
        root.available = result === "available"

        if (root.available) {
          QsCommons.Logger.i("Calendar", "Evolution Data Server libraries available")
          // Auto-load calendars after confirming EDS availability
          loadCalendars()
        } else {
          QsCommons.Logger.w("Calendar", `EDS libraries not available: ${result}`)
          root.lastError = "Evolution Data Server libraries not installed"
        }
        
        root.availabilityChecked = true
        root.availabilityCheckCompleted()
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          QsCommons.Logger.d("Calendar", `Availability check error: ${text}`)
          root.available = false
          root.lastError = "Failed to check library availability"
        }
        
        root.availabilityChecked = true
        root.availabilityCheckCompleted()
      }
    }
  }

  // === Process: List Calendars ===
  Process {
    id: listCalendarsProcess
    running: false
    command: ["python3", root.listScript]

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const result = JSON.parse(text.trim())
          root.calendars = result
          cacheAdapter.cachedCalendars = result
          saveCache()

          QsCommons.Logger.i("Calendar", `Found ${result.length} calendar(s)`)

          // Smart auto-load: only load events if we have calendars
          if (result.length > 0) {
            if (root.events.length === 0) {
              // No cached events, load immediately
              QsCommons.Logger.i("Calendar", "Loading events for first time")
              loadEvents()
            } else {
              // Have cached events, refresh in background
              QsCommons.Logger.i("Calendar", "Refreshing events in background")
              loadEvents()
            }
          } else {
            QsCommons.Logger.w("Calendar", "No calendars found")
            root.lastError = "No calendars configured"
          }
        } catch (e) {
          QsCommons.Logger.e("Calendar", `Failed to parse calendars: ${e}`)
          root.lastError = "Failed to parse calendar list"
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          QsCommons.Logger.d("Calendar", `List calendars error: ${text}`)
          root.lastError = text.trim()
        }
      }
    }
  }

  // === Process: Load Events ===
  Process {
    id: loadEventsProcess
    running: false
    property int startTime: 0
    property int endTime: 0

    command: ["python3", root.eventsScript, startTime.toString(), endTime.toString()]

    stdout: StdioCollector {
      onStreamFinished: {
        root.loading = false

        try {
          const result = JSON.parse(text.trim())
          root.events = result
          cacheAdapter.cachedEvents = result
          cacheAdapter.lastUpdate = new Date().toISOString()
          saveCache()

          QsCommons.Logger.i("Calendar", `Loaded ${result.length} event(s)`)
        } catch (e) {
          QsCommons.Logger.e("Calendar", `Failed to parse events: ${e}`)
          root.lastError = "Failed to parse events"

          // Fall back to cached events if available
          if (cacheAdapter.cachedEvents && cacheAdapter.cachedEvents.length > 0) {
            root.events = cacheAdapter.cachedEvents
            QsCommons.Logger.i("Calendar", "Using cached events after parse error")
          }
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.loading = false

        if (text.trim()) {
          QsCommons.Logger.d("Calendar", `Load events error: ${text}`)
          root.lastError = text.trim()

          // Fall back to cached events if available
          if (cacheAdapter.cachedEvents && cacheAdapter.cachedEvents.length > 0) {
            root.events = cacheAdapter.cachedEvents
            QsCommons.Logger.i("Calendar", "Using cached events due to error")
          }
        }
      }
    }
  }
}

