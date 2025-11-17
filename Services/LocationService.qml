pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons" as QsCommons

// Weather and location service with stable UI properties
Singleton {
  id: root

  // === Configuration ===
  readonly property string cacheFile: QsCommons.Settings.cacheDir + "location.json"
  readonly property int weatherUpdateFrequency: 30 * 60  // 30 minutes in seconds
  
  // === Status ===
  property bool isFetchingWeather: false
  
  // === Stable UI Properties (Noctalia pattern) ===
  // These ONLY update when weather fetch is COMPLETE
  property bool coordinatesReady: false
  property string stableLatitude: ""
  property string stableLongitude: ""
  property string stableName: ""
  
  // === Data Access Alias ===
  // Use LocationService.data.weather.current_weather.temperature
  readonly property alias data: adapter
  
  // === Helper for UI ===
  readonly property string displayCoordinates: {
    if (!coordinatesReady || stableLatitude === "" || stableLongitude === "") {
      return ""
    }
    const lat = parseFloat(stableLatitude).toFixed(4)
    const lon = parseFloat(stableLongitude).toFixed(4)
    return `${lat}, ${lon}`
  }

  // === Cache Management (FileView + JsonAdapter) ===
  FileView {
    id: locationFileView
    path: cacheFile
    printErrors: false
    
    // Auto-save when adapter changes (debounced via saveTimer)
    onAdapterUpdated: saveTimer.start()
    
    onLoaded: {
      QsCommons.Logger.d("Location", "Loaded cached data")
      
      // Initialize stable properties from cache
      if (adapter.latitude !== "" && adapter.longitude !== "" && adapter.weatherLastFetch > 0) {
        root.stableLatitude = adapter.latitude
        root.stableLongitude = adapter.longitude
        root.stableName = adapter.name
        root.coordinatesReady = true
        QsCommons.Logger.i("Location", "Coordinates ready from cache")
      }
      
      updateWeather()
    }
    
    onLoadFailed: function(error) {
      QsCommons.Logger.w("Location", "Cache load failed, will fetch fresh")
      updateWeather()
    }

    JsonAdapter {
      id: adapter
      
      // Core data properties (internal working state)
      property string latitude: ""
      property string longitude: ""
      property string name: ""
      property int weatherLastFetch: 0
      property var weather: null  // Full Open-Meteo API response
    }
  }

  // Debounced save timer (prevents excessive disk writes)
  Timer {
    id: saveTimer
    interval: 1000
    onTriggered: locationFileView.writeAdapter()
  }

  // Auto-update timer (check every 20s if we need fresh data)
  Timer {
    id: updateTimer
    interval: 20 * 1000
    running: QsCommons.Settings.data.location.weatherEnabled || 
             QsCommons.Settings.data.colorSchemes.schedulingMode == "location"
    repeat: true
    onTriggered: updateWeather()
  }

  // === Initialization ===
  function init() {
    QsCommons.Logger.i("Location", "Service started")
    // FileView will trigger onLoaded which calls updateWeather()
  }

  // === Reset Function ===
  function resetWeather() {
    QsCommons.Logger.i("Location", "Resetting weather data")
    
    // Mark as changing to prevent UI updates
    root.coordinatesReady = false
    
    // Reset stable properties
    root.stableLatitude = ""
    root.stableLongitude = ""
    root.stableName = ""
    
    // Reset core data
    adapter.latitude = ""
    adapter.longitude = ""
    adapter.name = ""
    adapter.weatherLastFetch = 0
    adapter.weather = null
    
    // Fetch immediately
    updateWeather()
  }

  // === Update Logic ===
  function updateWeather() {
    if (!QsCommons.Settings.data.location.weatherEnabled) {
      return
    }
    
    if (isFetchingWeather) {
      QsCommons.Logger.w("Location", "Weather is still fetching")
      return
    }
    
    const currentTime = QsCommons.Time.timestamp  // Current Unix timestamp
    const cacheAge = currentTime - adapter.weatherLastFetch
    const cityChanged = adapter.name !== QsCommons.Settings.data.location.name
    
    // Conditions that trigger fresh fetch:
    // 1. No weather data yet (adapter.weather === null)
    // 2. No coordinates yet
    // 3. City name changed in settings
    // 4. Cache is older than weatherUpdateFrequency (30 min)
    const needsUpdate = (adapter.weather === null) ||
                       (adapter.latitude === "" || adapter.longitude === "") ||
                       cityChanged ||
                       (cacheAge >= weatherUpdateFrequency)
    
    if (needsUpdate) {
      getFreshWeather()
    }
  }

  // === Trigger Fresh Weather Fetch ===
  function getFreshWeather() {
    isFetchingWeather = true
    
    // Check if location name has changed
    const locationChanged = adapter.name !== QsCommons.Settings.data.location.name
    if (locationChanged) {
      root.coordinatesReady = false
      QsCommons.Logger.d("Location", "Location changed from", 
                         adapter.name, "to", QsCommons.Settings.data.location.name)
    }
    
    // If we don't have coordinates or city changed, geocode first
    if ((adapter.latitude === "") || (adapter.longitude === "") || locationChanged) {
      geocodeLocation(QsCommons.Settings.data.location.name)
    } else {
      // We have coordinates, fetch weather directly
      fetchWeatherData(adapter.latitude, adapter.longitude)
    }
  }

  // === Geocoding with Open-Meteo ===
  function geocodeLocation(cityName) {
    QsCommons.Logger.d("Location", "Geocoding city name:", cityName)
    
    // Open-Meteo Geocoding API
    const url = "https://geocoding-api.open-meteo.com/v1/search" +
                "?name=" + encodeURIComponent(cityName) +
                "&count=1" +
                "&language=en" +
                "&format=json"
    
    const xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
      handleGeocodeResponse(xhr, cityName)
    }
    
    xhr.open("GET", url)
    xhr.send()
  }
  
  function handleGeocodeResponse(xhr, cityName) {
    // Wait for request to complete
    if (xhr.readyState !== XMLHttpRequest.DONE) {
      return
    }
    
    // Handle HTTP errors
    if (xhr.status !== 200) {
      errorCallback("Location", "Geocoding error: HTTP " + xhr.status)
      return
    }
    
    // Parse response
    let geoData
    try {
      geoData = JSON.parse(xhr.responseText)
    } catch (e) {
      errorCallback("Location", "Failed to parse geocoding data: " + e)
      return
    }
    
    // Validate results
    if (!geoData.results || geoData.results.length === 0) {
      errorCallback("Location", "Could not resolve city name: " + cityName)
      return
    }
    
    // Process successful geocoding
    const result = geoData.results[0]
    QsCommons.Logger.d("Location", "Geocoded to:", 
                      result.latitude, "/", result.longitude)
    
    // Save location data to adapter (working properties)
    adapter.name = cityName
    adapter.latitude = result.latitude.toString()
    adapter.longitude = result.longitude.toString()
    
    // Save display name (for UI)
    root.stableName = result.name + ", " + result.country
    
    // Now fetch weather data
    fetchWeatherData(adapter.latitude, adapter.longitude)
  }

  // === Weather Fetch with Open-Meteo ===
  function fetchWeatherData(lat, lon) {
    QsCommons.Logger.d("Location", "Fetching weather from Open-Meteo")
    
    // Open-Meteo Forecast API with all needed data
    const url = "https://api.open-meteo.com/v1/forecast" +
                "?latitude=" + lat +
                "&longitude=" + lon +
                "&current_weather=true" +
                "&current=relativehumidity_2m,surface_pressure" +
                "&daily=temperature_2m_max,temperature_2m_min,weathercode,sunset,sunrise" +
                "&timezone=auto"
    
    const xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
      handleWeatherResponse(xhr)
    }
    
    xhr.open("GET", url)
    xhr.send()
  }
  
  function handleWeatherResponse(xhr) {
    // Wait for request to complete
    if (xhr.readyState !== XMLHttpRequest.DONE) {
      return
    }
    
    // Handle HTTP errors
    if (xhr.status !== 200) {
      errorCallback("Location", "Weather fetch error: HTTP " + xhr.status)
      return
    }
    
    // Parse response
    let weatherData
    try {
      weatherData = JSON.parse(xhr.responseText)
    } catch (e) {
      errorCallback("Location", "Failed to parse weather data: " + e)
      return
    }
    
    // Process successful weather fetch
    // Save entire weather response to adapter
    adapter.weather = weatherData
    adapter.weatherLastFetch = QsCommons.Time.timestamp
    
    // Update stable display properties ONLY when complete
    // This prevents UI flicker during partial updates
    root.stableLatitude = weatherData.latitude.toString()
    root.stableLongitude = weatherData.longitude.toString()
    root.coordinatesReady = true
    
    isFetchingWeather = false
    
    QsCommons.Logger.i("Location", "Weather updated successfully")
    QsCommons.Logger.d("Location", "Temperature:", 
                      weatherData.current_weather.temperature + "°C")
    
    // FileView will auto-save via onAdapterUpdated
  }

  // === Error Handler ===
  function errorCallback(module, message) {
    QsCommons.Logger.e(module, message)
    isFetchingWeather = false
    // Don't clear cached data on error - UI can still display last known data
  }

  // === Helper Functions ===
  
  // Convert WMO weather code to icon name
  // WMO codes: https://open-meteo.com/en/docs (Weather codes section)
  function weatherSymbolFromCode(code) {
    if (code === 0) return "weather-sun"           // Clear sky
    if (code === 1 || code === 2) return "weather-cloud-sun"  // Mainly/partly clear
    if (code === 3) return "weather-cloud"         // Overcast
    if (code >= 45 && code <= 48) return "weather-cloud-haze"  // Fog
    if (code >= 51 && code <= 67) return "weather-cloud-rain"  // Drizzle/Rain
    if (code >= 71 && code <= 77) return "weather-cloud-snow"  // Snow
    if (code >= 85 && code <= 86) return "weather-cloud-snow"  // Snow showers
    if (code >= 95 && code <= 99) return "weather-cloud-lightning"  // Thunderstorm
    
    return "weather-cloud"  // Default fallback
  }

  // Human-readable description
  function weatherDescriptionFromCode(code) {
    if (code === 0) return "Clear sky"
    if (code === 1) return "Mainly clear"
    if (code === 2) return "Partly cloudy"
    if (code === 3) return "Overcast"
    if (code === 45 || code === 48) return "Fog"
    if (code >= 51 && code <= 67) return "Drizzle"
    if (code >= 71 && code <= 77) return "Snow"
    if (code >= 80 && code <= 82) return "Rain showers"
    if (code >= 95 && code <= 99) return "Thunderstorm"
    
    return "Unknown"
  }

  // Temperature conversion helper
  function celsiusToFahrenheit(celsius) {
    return 32 + celsius * 1.8
  }
}
