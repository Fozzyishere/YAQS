pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons" as QsCommons
import "." as QsServices

Singleton {
  id: root

  // === Core State ===
  property var networks: ({})
  property bool scanning: false
  property bool connecting: false
  property string connectingTo: ""
  property string lastError: ""
  property bool ethernetConnected: false
  property string disconnectingFrom: ""
  property string forgettingNetwork: ""

  property bool ignoreScanResults: false
  property bool scanPending: false

  property bool initialized: false
  property bool waitingForNmcli: false

  // === Persistent Cache ===
  property string cacheFile: QsCommons.Settings.cacheDir + "network.json"
  readonly property string cachedLastConnected: cacheAdapter.lastConnected
  readonly property var cachedNetworks: cacheAdapter.knownNetworks

  FileView {
    id: cacheFileView
    path: root.cacheFile
    printErrors: false

    JsonAdapter {
      id: cacheAdapter
      property var knownNetworks: ({})
      property string lastConnected: ""
    }

    onLoadFailed: {
      cacheAdapter.knownNetworks = ({})
      cacheAdapter.lastConnected = ""
    }
  }

  // Update Settings-driven Wi-Fi toggle
  Connections {
    target: QsCommons.Settings.data.network
    function onWifiEnabledChanged() {
      const enabled = QsCommons.Settings.data.network.wifiEnabled
      QsCommons.Logger.i("NetworkService", enabled ? "Wi-Fi enabled" : "Wi-Fi disabled")
      QsServices.NotificationService.showNotice("Wi-Fi", enabled ? "Enabled" : "Disabled")
    }
  }

  function init() {
    if (initialized)
      return

    if (!QsServices.ProgramCheckerService.nmcliAvailable) {
      if (!waitingForNmcli) {
        waitingForNmcli = true
        QsCommons.Logger.w("NetworkService", "nmcli not available, waiting for ProgramChecker result")
      }
      return
    }

    waitingForNmcli = false
    initialized = true
    QsCommons.Logger.i("NetworkService", "Initializing service")

    ethernetStateProcess.running = true
    syncWifiState()
    scan()
  }

  // === Initialization ===
  Component.onCompleted: init()

  Connections {
    target: QsServices.ProgramCheckerService
    function onChecksCompleted() {
      if (!root.initialized)
        root.init()
    }

    function onNmcliAvailableChanged() {
      if (!root.initialized && QsServices.ProgramCheckerService.nmcliAvailable) {
        root.init()
      }
    }
  }

  // === Cache Persistence ===
  Timer {
    id: saveDebounce
    interval: 1000
    onTriggered: cacheFileView.writeAdapter()
  }

  function saveCache() {
    saveDebounce.restart()
  }

  // === Timers ===
  Timer {
    id: delayedScanTimer
    interval: 7000
    onTriggered: scan()
  }

  Timer {
    id: ethernetCheckTimer
    interval: 30000
    running: true
    repeat: true
    onTriggered: {
      if (root.initialized) {
        ethernetStateProcess.running = true
      }
    }
  }

  // === Public Functions ===
  function syncWifiState() {
    if (!QsServices.ProgramCheckerService.nmcliAvailable)
      return
    wifiStateProcess.running = true
  }

  function setWifiEnabled(enabled) {
    if (!QsServices.ProgramCheckerService.nmcliAvailable) {
      QsCommons.Logger.w("NetworkService", "Cannot change Wi-Fi state; nmcli unavailable")
      return
    }
    QsCommons.Settings.data.network.wifiEnabled = enabled
    wifiStateEnableProcess.running = true
  }

  function scan() {
    if (!QsServices.ProgramCheckerService.nmcliAvailable)
      return

    if (!QsCommons.Settings.data.network.wifiEnabled)
      return

    if (scanning) {
      QsCommons.Logger.d("NetworkService", "Scan already in progress, will rescan")
      ignoreScanResults = true
      scanPending = true
      return
    }

    scanning = true
    lastError = ""
    ignoreScanResults = false

    profileCheckProcess.running = true
    QsCommons.Logger.d("NetworkService", "Wi-Fi scan in progress...")
  }

  function connect(ssid, password = "") {
    if (!QsServices.ProgramCheckerService.nmcliAvailable) {
      lastError = "nmcli unavailable"
      return
    }

    if (connecting)
      return

    connecting = true
    connectingTo = ssid
    lastError = ""

    if (networks[ssid]?.existing || cachedNetworks[ssid]) {
      connectProcess.mode = "saved"
      connectProcess.ssid = ssid
      connectProcess.password = ""
    } else {
      connectProcess.mode = "new"
      connectProcess.ssid = ssid
      connectProcess.password = password
    }

    connectProcess.running = true
  }

  function disconnect(ssid) {
    if (!QsServices.ProgramCheckerService.nmcliAvailable)
      return

    disconnectingFrom = ssid
    disconnectProcess.ssid = ssid
    disconnectProcess.running = true
  }

  function forget(ssid) {
    if (!QsServices.ProgramCheckerService.nmcliAvailable)
      return

    forgettingNetwork = ssid

    let known = cacheAdapter.knownNetworks
    delete known[ssid]
    cacheAdapter.knownNetworks = known

    if (cacheAdapter.lastConnected === ssid) {
      cacheAdapter.lastConnected = ""
    }

    saveCache()

    forgetProcess.ssid = ssid
    forgetProcess.running = true
  }

  function signalIcon(signal) {
    if (signal >= 80) return "wifi"
    if (signal >= 50) return "wifi-2"
    if (signal >= 20) return "wifi-1"
    return "wifi-0"
  }

  function isSecured(security) {
    return security && security !== "--" && security.trim() !== ""
  }

  function updateNetworkStatus(ssid, connected) {
    let nets = networks

    for (let key in nets) {
      if (nets[key].connected && key !== ssid) {
        nets[key].connected = false
      }
    }

    if (nets[ssid]) {
      nets[ssid].connected = connected
      nets[ssid].existing = true
      nets[ssid].cached = true
    } else if (connected) {
      nets[ssid] = {
        "ssid": ssid,
        "security": "--",
        "signal": 100,
        "connected": true,
        "existing": true,
        "cached": true
      }
    }

    networks = ({})
    networks = nets
  }

  // === Processes ===
  Process {
    id: ethernetStateProcess
    running: false
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]

    stdout: StdioCollector {
      onStreamFinished: {
        const connected = text.split("\n").some(line => {
          const parts = line.split(":")
          return parts[1] === "ethernet" && parts[2] === "connected"
        })
        if (root.ethernetConnected !== connected) {
          root.ethernetConnected = connected
          QsCommons.Logger.d("NetworkService", "Ethernet connected: " + root.ethernetConnected)
        }
      }
    }
  }

  Process {
    id: wifiStateProcess
    running: false
    command: ["nmcli", "radio", "wifi"]

    stdout: StdioCollector {
      onStreamFinished: {
        const enabled = text.trim() === "enabled"
        QsCommons.Logger.d("NetworkService", "Wi-Fi adapter detected as enabled: " + enabled)
        if (QsCommons.Settings.data.network.wifiEnabled !== enabled) {
          QsCommons.Settings.data.network.wifiEnabled = enabled
        }
      }
    }
  }

  Process {
    id: wifiStateEnableProcess
    running: false
    command: ["nmcli", "radio", "wifi", QsCommons.Settings.data.network.wifiEnabled ? "on" : "off"]

    stdout: StdioCollector {
      onStreamFinished: {
        QsCommons.Logger.i("NetworkService", "Wi-Fi state change command executed")
        syncWifiState()
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          QsCommons.Logger.w("NetworkService", "Error changing Wi-Fi state: " + text)
        }
      }
    }
  }

  Process {
    id: profileCheckProcess
    running: false
    command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]

    stdout: StdioCollector {
      onStreamFinished: {
        if (root.ignoreScanResults) {
          QsCommons.Logger.d("NetworkService", "Ignoring profile check results (new scan requested)")
          root.scanning = false

          if (root.scanPending) {
            root.scanPending = false
            delayedScanTimer.interval = 100
            delayedScanTimer.restart()
          }
          return
        }

        const profiles = {}
        const lines = text.split("\n").filter(l => l.trim())
        for (const line of lines) {
          profiles[line.trim()] = true
        }
        scanProcess.existingProfiles = profiles
        scanProcess.running = true
      }
    }
  }

  Process {
    id: scanProcess
    running: false
    command: ["nmcli", "-t", "-f", "SSID,SECURITY,SIGNAL,IN-USE", "device", "wifi", "list", "--rescan", "yes"]

    property var existingProfiles: ({})

    stdout: StdioCollector {
      onStreamFinished: {
        if (root.ignoreScanResults) {
          QsCommons.Logger.d("NetworkService", "Ignoring scan results (new scan requested)")
          root.scanning = false

          if (root.scanPending) {
            root.scanPending = false
            delayedScanTimer.interval = 100
            delayedScanTimer.restart()
          }
          return
        }

        const lines = text.split("\n")
        const networksMap = {}

        for (var i = 0; i < lines.length; ++i) {
          const line = lines[i].trim()
          if (!line)
            continue

          const lastColonIdx = line.lastIndexOf(":")
          if (lastColonIdx === -1) {
            QsCommons.Logger.w("NetworkService", "Malformed nmcli output line: " + line)
            continue
          }

          const inUse = line.substring(lastColonIdx + 1)
          const remainingLine = line.substring(0, lastColonIdx)

          const secondLastColonIdx = remainingLine.lastIndexOf(":")
          if (secondLastColonIdx === -1) {
            QsCommons.Logger.w("NetworkService", "Malformed nmcli output line: " + line)
            continue
          }

          const signal = remainingLine.substring(secondLastColonIdx + 1)
          const remainingLine2 = remainingLine.substring(0, secondLastColonIdx)

          const thirdLastColonIdx = remainingLine2.lastIndexOf(":")
          if (thirdLastColonIdx === -1) {
            QsCommons.Logger.w("NetworkService", "Malformed nmcli output line: " + line)
            continue
          }

          const security = remainingLine2.substring(thirdLastColonIdx + 1)
          const ssid = remainingLine2.substring(0, thirdLastColonIdx)

          if (ssid) {
            const signalInt = parseInt(signal) || 0
            const connected = inUse === "*"

            if (connected && cacheAdapter.lastConnected !== ssid) {
              cacheAdapter.lastConnected = ssid
              saveCache()
            }

            if (!networksMap[ssid]) {
              networksMap[ssid] = {
                "ssid": ssid,
                "security": security || "--",
                "signal": signalInt,
                "connected": connected,
                "existing": ssid in scanProcess.existingProfiles,
                "cached": ssid in cacheAdapter.knownNetworks
              }
            } else {
              const existingNet = networksMap[ssid]
              if (connected) {
                existingNet.connected = true
              }
              if (signalInt > existingNet.signal) {
                existingNet.signal = signalInt
                existingNet.security = security || "--"
              }
            }
          }
        }

        const oldSSIDs = Object.keys(root.networks)
        const newSSIDs = Object.keys(networksMap)
        const newNetworks = newSSIDs.filter(ssid => !oldSSIDs.includes(ssid))
        const lostNetworks = oldSSIDs.filter(ssid => !newSSIDs.includes(ssid))

        if (newNetworks.length > 0 || lostNetworks.length > 0) {
          if (newNetworks.length > 0) {
            QsCommons.Logger.d("NetworkService", "New Wi-Fi SSID discovered: " + newNetworks.join(", "))
          }
          if (lostNetworks.length > 0) {
            QsCommons.Logger.d("NetworkService", "Wi-Fi SSID disappeared: " + lostNetworks.join(", "))
          }
          QsCommons.Logger.d("NetworkService", "Total Wi-Fi SSIDs: " + Object.keys(networksMap).length)
        }

        QsCommons.Logger.d("NetworkService", "Wi-Fi scan completed")
        root.networks = networksMap
        root.scanning = false

        if (root.scanPending) {
          root.scanPending = false
          delayedScanTimer.interval = 100
          delayedScanTimer.restart()
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.scanning = false
        if (text.trim()) {
          QsCommons.Logger.w("NetworkService", "Scan error: " + text)
          delayedScanTimer.interval = 5000
          delayedScanTimer.restart()
        }
      }
    }
  }

  Process {
    id: connectProcess
    property string mode: "new"
    property string ssid: ""
    property string password: ""
    running: false

    command: mode === "saved"
             ? ["nmcli", "connection", "up", "id", ssid]
             : (password && password.length > 0
                ? ["nmcli", "device", "wifi", "connect", ssid, "password", password]
                : ["nmcli", "device", "wifi", "connect", ssid])

    stdout: StdioCollector {
      onStreamFinished: {
        const output = text.trim()

        if (!output || (!output.includes("successfully activated") && !output.includes("Connection successfully"))) {
          return
        }

        let known = cacheAdapter.knownNetworks
        known[connectProcess.ssid] = {
          "profileName": connectProcess.ssid,
          "lastConnected": Date.now()
        }
        cacheAdapter.knownNetworks = known
        cacheAdapter.lastConnected = connectProcess.ssid
        saveCache()

        root.updateNetworkStatus(connectProcess.ssid, true)

        root.connecting = false
        root.connectingTo = ""
        QsCommons.Logger.i("NetworkService", `Connected to network: '${connectProcess.ssid}'`)
        QsServices.NotificationService.showNotice("Connected", `Connected to ${connectProcess.ssid}`)

        delayedScanTimer.interval = 5000
        delayedScanTimer.restart()
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.connecting = false
        root.connectingTo = ""

        if (text.trim()) {
          if (text.includes("Secrets were required") || text.includes("no secrets provided")) {
            root.lastError = "Incorrect password"
            forget(connectProcess.ssid)
          } else if (text.includes("No network with SSID")) {
            root.lastError = "Network not found"
          } else if (text.includes("Timeout")) {
            root.lastError = "Connection timeout"
          } else {
            root.lastError = text.split("\n")[0].trim()
          }

          QsCommons.Logger.w("NetworkService", "Connect error: " + text)
        }
      }
    }
  }

  Process {
    id: disconnectProcess
    property string ssid: ""
    running: false
    command: ["nmcli", "connection", "down", "id", ssid]

    stdout: StdioCollector {
      onStreamFinished: {
        QsCommons.Logger.i("NetworkService", `Disconnected from network: '${disconnectProcess.ssid}'`)
        QsServices.NotificationService.showNotice("Disconnected", `Disconnected from ${disconnectProcess.ssid}`)

        root.updateNetworkStatus(disconnectProcess.ssid, false)
        root.disconnectingFrom = ""

        delayedScanTimer.interval = 1000
        delayedScanTimer.restart()
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.disconnectingFrom = ""
        if (text.trim()) {
          QsCommons.Logger.w("NetworkService", "Disconnect error: " + text)
        }
        delayedScanTimer.interval = 5000
        delayedScanTimer.restart()
      }
    }
  }

  Process {
    id: forgetProcess
    property string ssid: ""
    running: false
    command: ["sh", "-c", `
      ssid="$1"
      deleted=false

      if nmcli connection delete id "$ssid" 2>/dev/null; then
        echo "Deleted profile: $ssid"
        deleted=true
      fi

      if nmcli connection delete id "Auto $ssid" 2>/dev/null; then
        echo "Deleted profile: Auto $ssid"
        deleted=true
      fi

      for i in 1 2 3; do
        if nmcli connection delete id "$ssid $i" 2>/dev/null; then
          echo "Deleted profile: $ssid $i"
          deleted=true
        fi
      done

      if [ "$deleted" = "false" ]; then
        echo "No profiles found for SSID: $ssid"
      fi
    `, "--", ssid]

    stdout: StdioCollector {
      onStreamFinished: {
        QsCommons.Logger.i("NetworkService", `Forget network: "${forgetProcess.ssid}"`)
        QsCommons.Logger.d("NetworkService", text.trim().replace(/[\r\n]/g, " "))

        let nets = root.networks
        if (nets[forgetProcess.ssid]) {
          nets[forgetProcess.ssid].cached = false
          nets[forgetProcess.ssid].existing = false
          root.networks = ({})
          root.networks = nets
        }

        root.forgettingNetwork = ""

        delayedScanTimer.interval = 5000
        delayedScanTimer.restart()
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.forgettingNetwork = ""
        if (text.trim() && !text.includes("No profiles found")) {
          QsCommons.Logger.w("NetworkService", "Forget error: " + text)
        }
        delayedScanTimer.interval = 5000
        delayedScanTimer.restart()
      }
    }
  }
}

