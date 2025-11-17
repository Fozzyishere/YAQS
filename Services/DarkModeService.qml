pragma Singleton

import QtQuick
import Quickshell
import "../Commons" as QsCommons
import "../Services" as QsServices

Singleton {
  id: root

  // === Properties ===
  property bool initComplete: false
  property bool nextDarkModeState: false

  // === Initialization ===
  
  function init() {
    QsCommons.Logger.i("DarkMode", "Service started")
    QsCommons.Logger.d("DarkMode", "Scheduling mode: " + QsCommons.Settings.data.colorSchemes.schedulingMode)

    if (QsCommons.Settings.data.colorSchemes.schedulingMode === "manual") {
      const changes = collectManualChanges()
      initComplete = true
      applyCurrentMode(changes)
      scheduleNextMode(changes)
    }

    // Location mode
    if (QsCommons.Settings.data.colorSchemes.schedulingMode === "location") {
      if (QsServices.LocationService.data.weather !== null) {
        const changes = collectWeatherChanges(QsServices.LocationService.data.weather)
        initComplete = true
        applyCurrentMode(changes)
        scheduleNextMode(changes)
      }
    }
  }

  // === Timer for Mode Transitions ===
  
  // https://doc.qt.io/qt-6/qml-qtqml-timer.html
  Timer {
    id: transitionTimer
    running: false
    repeat: false
    
    onTriggered: {
      QsCommons.Logger.i("DarkMode", "Applying scheduled mode: darkMode=" + root.nextDarkModeState)
      
      // Apply the scheduled mode change
      QsCommons.Settings.data.colorSchemes.darkMode = root.nextDarkModeState
      
      // Recalculate and schedule next transition
      if (QsCommons.Settings.data.colorSchemes.schedulingMode === "manual") {
        const changes = root.collectManualChanges()
        root.scheduleNextMode(changes)
      }
      
      // Location mode rescheduling
      if (QsCommons.Settings.data.colorSchemes.schedulingMode === "location") {
        if (QsServices.LocationService.data.weather !== null) {
          const changes = root.collectWeatherChanges(QsServices.LocationService.data.weather)
          root.scheduleNextMode(changes)
        }
      }
    }
  }

  // === Reactivity: Manual Mode Settings Changes ===
  
  Connections {
    target: QsCommons.Settings.data.colorSchemes
    enabled: QsCommons.Settings.data.colorSchemes.schedulingMode === "manual"
    
    function onManualSunriseChanged() {
      QsCommons.Logger.d("DarkMode", "Manual sunrise changed: " + QsCommons.Settings.data.colorSchemes.manualSunrise)
      const changes = root.collectManualChanges()
      root.applyCurrentMode(changes)
      root.scheduleNextMode(changes)
    }
    
    function onManualSunsetChanged() {
      QsCommons.Logger.d("DarkMode", "Manual sunset changed: " + QsCommons.Settings.data.colorSchemes.manualSunset)
      const changes = root.collectManualChanges()
      root.applyCurrentMode(changes)
      root.scheduleNextMode(changes)
    }
  }

  // === Reactivity: Scheduling Mode Changes ===
  
  // React to scheduling mode changes (manual ↔ location)
  // Reinitialize service with new mode
  Connections {
    target: QsCommons.Settings.data.colorSchemes
    
    function onSchedulingModeChanged() {
      QsCommons.Logger.i("DarkMode", "Scheduling mode changed: " + QsCommons.Settings.data.colorSchemes.schedulingMode)
      root.init()  // Reinitialize with new mode
    }
  }

  // === Reactivity: Location Mode Weather Updates ===
  
  Connections {
    target: QsServices.LocationService.data
    enabled: QsCommons.Settings.data.colorSchemes.schedulingMode === "location"
    
    function onWeatherChanged() {
      if (QsServices.LocationService.data.weather !== null) {
        QsCommons.Logger.d("DarkMode", "Weather data updated, recalculating schedule")
        const changes = root.collectWeatherChanges(QsServices.LocationService.data.weather)
        
        if (!root.initComplete) {
          root.initComplete = true
          root.applyCurrentMode(changes)
        }
        
        root.scheduleNextMode(changes)
      }
    }
  }

  // === Core Functions ===

  // Parse time string ("HH:MM") to hour/minute object
  // JavaScript string operations: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String
  function parseTime(timeString) {
    if (!timeString || typeof timeString !== "string") {
      QsCommons.Logger.w("DarkMode", "Invalid time format: " + timeString + ", using default 06:00")
      return { "hour": 6, "minute": 0 }
    }
    
    try {
      const parts = timeString.split(":").map(Number)
      
      if (parts.length !== 2 || isNaN(parts[0]) || isNaN(parts[1])) {
        QsCommons.Logger.w("DarkMode", "Invalid time format: " + timeString + ", expected HH:MM")
        return { "hour": 6, "minute": 0 }
      }
      
      // Validate ranges
      if (parts[0] < 0 || parts[0] > 23 || parts[1] < 0 || parts[1] > 59) {
        QsCommons.Logger.w("DarkMode", "Time out of range: " + timeString)
        return { "hour": 6, "minute": 0 }
      }
      
      return { "hour": parts[0], "minute": parts[1] }
    } catch (e) {
      QsCommons.Logger.e("DarkMode", "Error parsing time: " + e)
      return { "hour": 6, "minute": 0 }
    }
  }

  // Build array of mode transitions for manual scheduling
  // JavaScript Date reference: https://doc.qt.io/qt-6/qml-qtqml-date.html
  // 
  // Creates 4 transitions:
  // 1. Yesterday's sunset (dark)
  // 2. Today's sunrise (light)
  // 3. Today's sunset (dark)
  // 4. Tomorrow's sunrise (light)
  //
  // This covers all cases regardless of current time
  function collectManualChanges() {
    const sunriseTime = parseTime(QsCommons.Settings.data.colorSchemes.manualSunrise)
    const sunsetTime = parseTime(QsCommons.Settings.data.colorSchemes.manualSunset)

    const now = new Date()
    const year = now.getFullYear()
    const month = now.getMonth()
    const day = now.getDate()

    // Create Date objects for each transition
    // Date constructor: new Date(year, monthIndex, day, hours, minutes)
    const yesterdaysSunset = new Date(year, month, day - 1, sunsetTime.hour, sunsetTime.minute)
    const todaysSunrise = new Date(year, month, day, sunriseTime.hour, sunriseTime.minute)
    const todaysSunset = new Date(year, month, day, sunsetTime.hour, sunsetTime.minute)
    const tomorrowsSunrise = new Date(year, month, day + 1, sunriseTime.hour, sunriseTime.minute)

    const changes = [
      { "time": yesterdaysSunset.getTime(), "darkMode": true },
      { "time": todaysSunrise.getTime(), "darkMode": false },
      { "time": todaysSunset.getTime(), "darkMode": true },
      { "time": tomorrowsSunrise.getTime(), "darkMode": false }
    ]
    
    QsCommons.Logger.d("DarkMode", "Collected " + changes.length + " manual transitions")
    return changes
  }

  // Build array of mode transitions from weather API data
  // LocationService integration
  //
  // Weather data structure:
  // {
  //   "daily": {
  //     "sunrise": ["2025-11-11T06:23:00Z", "2025-11-12T06:24:00Z", ...],
  //     "sunset": ["2025-11-11T17:45:00Z", "2025-11-12T17:44:00Z", ...]
  //   }
  // }
  function collectWeatherChanges(weather) {
    const changes = []

    // Handle edge case: if sun hasn't risen yet today
    if (Date.now() < Date.parse(weather.daily.sunrise[0])) {
      changes.push({
        "time": Date.now() - 1,
        "darkMode": true
      })
    }

    // Build transitions from API data (7 days)
    for (var i = 0; i < weather.daily.sunrise.length; i++) {
      changes.push({
        "time": Date.parse(weather.daily.sunrise[i]),
        "darkMode": false
      })
      changes.push({
        "time": Date.parse(weather.daily.sunset[i]),
        "darkMode": true
      })
    }

    QsCommons.Logger.d("DarkMode", "Collected " + changes.length + " weather-based transitions")
    return changes
  }

  // Apply the correct mode based on current time
  // Finds the most recent transition before now and applies that mode
  function applyCurrentMode(changes) {
    const now = Date.now()

    // Find last change before current time
    // Note: QML doesn't have Array.findLast(), so we iterate manually
    let lastChange = null
    for (var i = 0; i < changes.length; i++) {
      if (changes[i].time < now) {
        lastChange = changes[i]
      }
    }

    if (lastChange) {
      QsCommons.Settings.data.colorSchemes.darkMode = lastChange.darkMode
      QsCommons.Logger.d("DarkMode", "Applied current mode: darkMode=" + lastChange.darkMode)
    } else {
      QsCommons.Logger.w("DarkMode", "No transitions found before current time")
    }
  }

  // Schedule timer for next mode transition
  // Finds the next future transition and configures Timer
  function scheduleNextMode(changes) {
    const now = Date.now()
    
    // Find first change after current time
    // Array.find() reference: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/find
    const nextChange = changes.find(change => change.time > now)
    
    if (nextChange) {
      root.nextDarkModeState = nextChange.darkMode
      transitionTimer.interval = nextChange.time - now
      transitionTimer.restart()
      
      // Calculate friendly time display
      const minutes = Math.round(transitionTimer.interval / 60000)
      const hours = Math.floor(minutes / 60)
      const remainingMinutes = minutes % 60
      
      let timeStr = ""
      if (hours > 0) {
        timeStr = hours + "h " + remainingMinutes + "m"
      } else {
        timeStr = remainingMinutes + "m"
      }
      
      QsCommons.Logger.d("DarkMode", 
        "Scheduled: darkMode=" + nextChange.darkMode + 
        " in " + transitionTimer.interval + "ms (" + timeStr + ")")
    } else {
      QsCommons.Logger.w("DarkMode", "No upcoming transitions found, rescheduling in 1 hour")
      // Fallback: reschedule in 1 hour if no transitions found
      transitionTimer.interval = 3600000  // 1 hour
      transitionTimer.restart()
    }
  }
}
