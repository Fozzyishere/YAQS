pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Core Properties ===
  
  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
  readonly property bool available: (adapter !== null)
  readonly property bool enabled: adapter?.enabled ?? false
  readonly property bool discovering: adapter?.discovering ?? false
  
  // Direct access to all devices from adapter
  readonly property var devices: adapter ? adapter.devices : null
  
  // === Computed Device Lists ===
  
  // Devices that are paired or trusted (saved for auto-reconnect)
  readonly property var pairedDevices: {
    if (!adapter || !adapter.devices) {
      return []
    }
    
    return adapter.devices.values.filter(device => {
      return device && (device.paired || device.trusted)
    })
  }
  
  // Devices currently connected
  readonly property var connectedDevices: {
    if (!adapter || !adapter.devices) {
      return []
    }
    
    return adapter.devices.values.filter(device => {
      return device && device.connected
    })
  }
  
  // Devices with battery information available
  readonly property var allDevicesWithBattery: {
    if (!adapter || !adapter.devices) {
      return []
    }
    
    return adapter.devices.values.filter(device => {
      return device && device.batteryAvailable && device.battery > 0
    })
  }
  
  // === Initialization ===
  
  function init() {
    QsCommons.Logger.i("BluetoothService", "Service initialized")
  }
  
  // === Discovery Timer ===
  // Delays discovery start after enabling Bluetooth to avoid immediate conflicts
  
  Timer {
    id: discoveryTimer
    interval: 1000
    repeat: false
    onTriggered: {
      if (adapter) {
        adapter.discovering = true
      }
    }
  }
  
  // === Adapter State Tracking ===
  
  Connections {
    target: adapter
    
    function onEnabledChanged() {
      if (!adapter) {
        QsCommons.Logger.w("BluetoothService", "onEnabledChanged but adapter is null")
        return
      }
      
      QsCommons.Logger.d("BluetoothService", "Bluetooth enabled:", adapter.enabled)
      
      const newState = adapter.enabled
      if (Settings.data.bluetooth.enabled !== newState) {
        Settings.data.bluetooth.enabled = newState
        QsServices.NotificationService.showNotice(
          "Bluetooth", 
          newState ? "Bluetooth enabled" : "Bluetooth disabled"
        )
      }
    }
  }
  
  // === Helper Functions ===
  
  /**
   * Sort devices by real names first, then alphabetically, then by signal strength
   * Real names contain spaces and are longer than 3 characters (e.g., "AirPods Pro")
   * Generic names are MAC-based (e.g., "12:34:56:78:9A:BC")
   */
  function sortDevices(deviceList) {
    return deviceList.sort((deviceA, deviceB) => {
      const nameA = deviceA.name || deviceA.deviceName || ""
      const nameB = deviceB.name || deviceB.deviceName || ""
      
      const hasRealNameA = nameA.includes(" ") && nameA.length > 3
      const hasRealNameB = nameB.includes(" ") && nameB.length > 3
      
      // Different name status: real names first
      if (hasRealNameA !== hasRealNameB) {
        return hasRealNameA ? -1 : 1
      }
      
      // Both have real names: sort alphabetically
      if (hasRealNameA) {
        return nameA.localeCompare(nameB)
      }
      
      // Neither has real name: sort by signal strength (stronger first)
      const signalA = (deviceA.signalStrength !== undefined && deviceA.signalStrength > 0) ? deviceA.signalStrength : 0
      const signalB = (deviceB.signalStrength !== undefined && deviceB.signalStrength > 0) ? deviceB.signalStrength : 0
      return signalB - signalA
    })
  }
  
  /**
   * Get device icon based on type
   * Matches device.icon property and name patterns
   */
  function getDeviceIcon(device) {
    if (!device) {
      return "bt-device-generic"
    }
    
    const deviceName = (device.name || device.deviceName || "").toLowerCase()
    const iconName = (device.icon || "").toLowerCase()
    
    // Audio devices (headphones, headsets, earbuds)
    if (iconName.includes("headset") || iconName.includes("audio") ||
        deviceName.includes("headphone") || deviceName.includes("airpod") ||
        deviceName.includes("headset") || deviceName.includes("arctis")) {
      return "bt-device-headphones"
    }
    
    // Input devices
    if (iconName.includes("mouse") || deviceName.includes("mouse")) {
      return "bt-device-mouse"
    }
    
    if (iconName.includes("keyboard") || deviceName.includes("keyboard")) {
      return "bt-device-keyboard"
    }
    
    // Mobile devices
    if (iconName.includes("phone") || deviceName.includes("phone") ||
        deviceName.includes("iphone") || deviceName.includes("android") ||
        deviceName.includes("samsung")) {
      return "bt-device-phone"
    }
    
    // Wearables
    if (iconName.includes("watch") || deviceName.includes("watch")) {
      return "bt-device-watch"
    }
    
    // Audio output
    if (iconName.includes("speaker") || deviceName.includes("speaker")) {
      return "bt-device-speaker"
    }
    
    // Display devices
    if (iconName.includes("display") || deviceName.includes("tv")) {
      return "bt-device-tv"
    }
    
    return "bt-device-generic"
  }
  
  /**
   * Check if device can be connected
   * We check !connected, not !paired
   */
  function canConnect(device) {
    if (!device) {
      return false
    }
    
    return !device.connected && !device.pairing && !device.blocked
  }
  
  /**
   * Check if device can be disconnected
   */
  function canDisconnect(device) {
    if (!device) {
      return false
    }
    
    return device.connected && !device.pairing && !device.blocked
  }
  
  /**
   * Get device status string for UI display
   */
  function getStatusString(device) {
    if (!device) {
      return ""
    }
    
    if (device.state === BluetoothDeviceState.Connecting) {
      return "Connecting..."
    }
    
    if (device.pairing) {
      return "Pairing..."
    }
    
    if (device.blocked) {
      return "Blocked"
    }
    
    return ""
  }
  
  /**
   * Get human-readable signal strength label
   */
  function getSignalStrength(device) {
    if (!device || device.signalStrength === undefined || device.signalStrength <= 0) {
      return "Signal: Unknown"
    }
    
    const signal = device.signalStrength
    
    if (signal >= 80) return "Signal: Excellent"
    if (signal >= 60) return "Signal: Good"
    if (signal >= 40) return "Signal: Fair"
    if (signal >= 20) return "Signal: Poor"
    
    return "Signal: Very poor"
  }
  
  /**
   * Get battery level string (formatted as percentage)
   */
  function getBattery(device) {
    if (!device || !device.batteryAvailable) {
      return ""
    }
    
    return `Battery: ${Math.round(device.battery * 100)}%`
  }
  
  /**
   * Get signal strength icon name
   */
  function getSignalIcon(device) {
    if (!device || device.signalStrength === undefined || device.signalStrength <= 0) {
      return "antenna-bars-off"
    }
    
    const signal = device.signalStrength
    
    if (signal >= 80) return "antenna-bars-5"
    if (signal >= 60) return "antenna-bars-4"
    if (signal >= 40) return "antenna-bars-3"
    if (signal >= 20) return "antenna-bars-2"
    
    return "antenna-bars-1"
  }
  
  /**
   * Check if device is currently performing an operation
   */
  function isDeviceBusy(device) {
    if (!device) {
      return false
    }
    
    return device.pairing ||
           device.state === BluetoothDeviceState.Connecting ||
           device.state === BluetoothDeviceState.Disconnecting
  }
  
  // === Device Actions ===
  
  /**
   * Connect to device and set as trusted for auto-reconnect
   */
  function connectDeviceWithTrust(device) {
    if (!device) {
      return
    }
    
    QsCommons.Logger.i("BluetoothService", "Connecting to device:", device.name || device.address)
    
    // Set trusted to allow auto-reconnect
    device.trusted = true
    device.connect()
  }
  
  /**
   * Disconnect from device
   */
  function disconnectDevice(device) {
    if (!device) {
      return
    }
    
    QsCommons.Logger.i("BluetoothService", "Disconnecting from device:", device.name || device.address)
    
    device.disconnect()
  }
  
  /**
   * Forget device (removes pairing information)
   */
  function forgetDevice(device) {
    if (!device) {
      return
    }
    
    QsCommons.Logger.i("BluetoothService", "Forgetting device:", device.name || device.address)
    
    // Remove trust and forget pairing
    device.trusted = false
    device.forget()
  }
  
  /**
   * Enable or disable Bluetooth adapter
   */
  function setBluetoothEnabled(state) {
    if (!adapter) {
      QsCommons.Logger.w("BluetoothService", "Cannot set Bluetooth state: no adapter available")
      return
    }
    
    QsCommons.Logger.i("BluetoothService", "Setting Bluetooth enabled:", state)
    adapter.enabled = state
  }
  
  // === Component Lifecycle ===
  
  Component.onCompleted: {
    QsCommons.Logger.i("BluetoothService", "Service initialized")
    QsCommons.Logger.d("BluetoothService", "Bluetooth.defaultAdapter:", adapter)
    QsCommons.Logger.d("BluetoothService", "Adapter available:", available)
    if (adapter) {
      QsCommons.Logger.d("BluetoothService", "Adapter enabled:", adapter.enabled)
      QsCommons.Logger.d("BluetoothService", "Adapter devices:", adapter.devices)
    }
  }
}
