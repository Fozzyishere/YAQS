pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Commons" as QsCommons

// Thin wrapper around cliphist CLI
Singleton {
  id: root
  
  // === Public Properties ===
  
  property bool active: QsCommons.Settings.data.appLauncher?.enableClipboardHistory && 
                        cliphistAvailable
  
  property bool loading: false
  
  // Array of clipboard items: [{id, preview, mime, isImage}]
  property var items: []
  
  // === Dependency Check ===
  
  property bool cliphistAvailable: false
  property bool dependencyChecked: false
  
  // === Watchers ===
  
  // Automatically start clipboard watchers when active
  property bool autoWatch: true
  property bool watchersStarted: false
  
  // === Image Cache ===
  
  // Cached base64 image data URLs by clipboard entry ID: { "123": "data:image/png;base64,..." }
  property var imageDataById: ({})
  
  // Revision counter - increment whenever imageDataById changes
  // Forces QML bindings to re-evaluate (QML doesn't detect object property changes)
  property int revision: 0
  
  // === First-Seen Timestamps ===
  
  // Approximate copy time tracking
  // Records when each clipboard ID was first seen by quickshell
  // Format: { "123": 1730678400 }
  property var firstSeenById: ({})
  
  // === Queue for Base64 Decodes ===
  

  // Ensures sequential processing (can't run multiple shell commands in parallel)
  property var _b64Queue: []
  
  // Currently processing base64 decode job
  property var _b64CurrentCb: null      // Callback function
  property string _b64CurrentMime: ""   // MIME type
  property string _b64CurrentId: ""     // Clipboard entry ID
  
  // === Internal ===
  
  // Callback for text decode operations
  property var _decodeCallback: null
  
  // === Signals ===
  
  signal listCompleted()
  
  // === Initialization ===
  
  Component.onCompleted: {
    checkCliphistAvailability()
  }
  
  // === Dependency Check ===
  
  function checkCliphistAvailability() {
    if (dependencyChecked) return
    
    dependencyCheckProcess.command = ["which", "cliphist"]
    dependencyCheckProcess.running = true
  }
  
  Process {
    id: dependencyCheckProcess
    stdout: StdioCollector {}
    
    onExited: (exitCode, exitStatus) => {
      root.dependencyChecked = true
      
      if (exitCode === 0) {
        root.cliphistAvailable = true
        QsCommons.Logger.i("Clipboard", "cliphist available")
        
        // Start watchers if feature enabled
        if (root.active) {
          startWatchers()
        }
      } else {
        root.cliphistAvailable = false
        QsCommons.Logger.w("Clipboard", "cliphist not available")
        
        // Show warning if feature enabled but tool missing
        if (QsCommons.Settings.data.appLauncher?.enableClipboardHistory) {
          QsServices.NotificationService.showWarning("Clipboard history unavailable", 
            "Install cliphist to enable clipboard history")
          QsCommons.Logger.w("Clipboard", 
            "Clipboard history enabled but cliphist not installed")
        }
      }
    }
  }
  
  // === Start/Stop Watchers ===
  
  // React to active state changes
  onActiveChanged: {
    if (root.active) {
      startWatchers()
    } else {
      stopWatchers()
      loading = false
      // Clear items to avoid stale UI
      items = []
    }
  }
  
  function startWatchers() {
    if (!root.active || !autoWatch || watchersStarted || !root.cliphistAvailable) {
      return
    }
    
    watchersStarted = true
    
    // Start text watcher
    // wl-paste --watch calls cliphist store whenever clipboard changes
    watchText.command = ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    watchText.running = true
    
    // Start image watcher
    watchImage.command = ["wl-paste", "--type", "image", "--watch", "cliphist", "store"]
    watchImage.running = true
    
    QsCommons.Logger.i("Clipboard", "Watchers started")
  }
  
  function stopWatchers() {
    if (!watchersStarted) return
    
    watchText.running = false
    watchImage.running = false
    watchersStarted = false
    
    QsCommons.Logger.i("Clipboard", "Watchers stopped")
  }
  
  // === Watcher Processes ===
  
  // Long-running text clipboard watcher
  // Auto-restarts if it exits unexpectedly
  Process {
    id: watchText
    stdout: StdioCollector {}
    
    onExited: (exitCode, exitStatus) => {
      // Auto-restart if watcher dies (compositor restart, etc.)
      if (root.autoWatch) {
        Qt.callLater(() => { running = true })
      }
    }
  }
  
  // Long-running image clipboard watcher
  Process {
    id: watchImage
    stdout: StdioCollector {}
    
    onExited: (exitCode, exitStatus) => {
      if (root.autoWatch) {
        Qt.callLater(() => { running = true })
      }
    }
  }
  
  // === Auto-Refresh Timer ===
  
  // Periodically refresh clipboard list for reliability
  // Ensures UI stays in sync even if watchers miss events
  // 5 seconds is imperceptible but catches most changes
  Timer {
    interval: 5000  // 5 seconds
    repeat: true
    running: root.active  // Only when service is active
    onTriggered: list()   // Re-query clipboard history
  }
  
  // === List Clipboard History ===
  
  function list(maxPreviewWidth) {
    if (!root.active || !root.cliphistAvailable) {
      return
    }
    if (listProc.running) {
      return
    }
    
    loading = true
    const width = maxPreviewWidth || 100
    listProc.command = ["cliphist", "list", "-preview-width", String(width)]
    listProc.running = true
  }
  
  Process {
    id: listProc
    stdout: StdioCollector {}
    
    onExited: (exitCode, exitStatus) => {
      const out = String(stdout.text)
      const lines = out.split('\n').filter(l => l.length > 0)
      
      // Parse cliphist output: "<id> <preview>" or "<id>\t<preview>"
      // Noctalia pattern: try regex first (common case), then tab fallback
      const parsed = lines.map(l => {
        let id = ""
        let preview = ""
        
        // Try regex match first (handles space-separated format)
        const m = l.match(/^(\d+)\s+(.+)$/)
        if (m) {
          id = m[1]
          preview = m[2]
        } else {
          // Fallback to tab-separated format
          const tabIdx = l.indexOf('\t')
          if (tabIdx > -1) {
            id = l.slice(0, tabIdx)
            preview = l.slice(tabIdx + 1)
          } else {
            id = l
            preview = ""
          }
        }
        
        // Detect if entry is an image
        const lower = preview.toLowerCase()
        const isImage = lower.startsWith("[image]") || 
                        lower.includes(" binary data ")
        
        // Best-effort MIME type guess from preview text
        var mime = "text/plain"
        if (isImage) {
          if (lower.includes(" png")) mime = "image/png"
          else if (lower.includes(" jpg") || lower.includes(" jpeg")) 
            mime = "image/jpeg"
          else if (lower.includes(" webp")) mime = "image/webp"
          else if (lower.includes(" gif")) mime = "image/gif"
          else mime = "image/*"
        }
        
        // Track first-seen timestamp for new IDs (approximate copy time)
        if (!root.firstSeenById[id]) {
          root.firstSeenById[id] = QsCommons.Time.timestamp
        }
        
        return {
          "id": id,
          "preview": preview,
          "isImage": isImage,
          "mime": mime
        }
      })
      
      items = parsed
      loading = false
      
      QsCommons.Logger.d("Clipboard", `Loaded ${parsed.length} items`)
      
      // Emit signal for subscribers (e.g., Launcher clipboard plugin)
      root.listCompleted()
    }
  }
  
  // === Decode Full Content ===
  
  // Decode clipboard entry by ID and return full content via callback
  // Useful for text entries or when you need raw binary data
  function decode(id, cb) {
    if (!root.cliphistAvailable) {
      if (cb) cb("")
      return
    }
    
    root._decodeCallback = cb
    decodeProc.command = ["cliphist", "decode", id]
    decodeProc.running = true
  }
  
  Process {
    id: decodeProc
    stdout: StdioCollector {}
    
    onExited: (exitCode, exitStatus) => {
      const out = String(stdout.text)
      if (root._decodeCallback) {
        try {
          root._decodeCallback(out)
        } finally {
          root._decodeCallback = null
        }
      }
    }
  }
  
  // === Decode to Data URL (Queued) ===
  
  // Decode image clipboard entry to base64 data URL
  // Uses queue pattern to ensure sequential processing
  // Results are cached in imageDataById for reuse
  function decodeToDataUrl(id, mime, cb) {
    if (!root.cliphistAvailable) {
      if (cb) cb("")
      return
    }
    
    // If cached, return immediately
    if (root.imageDataById[id]) {
      if (cb) cb(root.imageDataById[id])
      return
    }
    
    // Queue request
    // Ensures single process handles sequentially (can't run multiple in parallel)
    root._b64Queue.push({
      "id": id,
      "mime": mime || "image/*",
      "cb": cb
    })
    
    // Start processing if idle
    if (!decodeB64Proc.running && root._b64CurrentCb === null) {
      _startNextB64()
    }
  }
  
  // Get cached image data URL by ID
  // Returns null if not cached or ID is undefined
  function getImageData(id) {
    // Noctalia: explicit undefined check for safety
    if (id === undefined) {
      return null
    }
    return root.imageDataById[id] || null
  }
  
  // Base64 decode process
  // Pipes cliphist decode output through base64 encoder
  Process {
    id: decodeB64Proc
    stdout: StdioCollector {}
    
    onExited: (exitCode, exitStatus) => {
      const b64 = String(stdout.text).trim()
      
      // Call callback if provided
      if (root._b64CurrentCb) {
        const url = `data:${root._b64CurrentMime};base64,${b64}`
        try {
          root._b64CurrentCb(url)
        } catch (e) {
          // Callback error - just continue
        }
      }
      
      // Cache result for future use
      if (root._b64CurrentId !== "") {
        root.imageDataById[root._b64CurrentId] = 
          `data:${root._b64CurrentMime};base64,${b64}`
        
        // Increment revision to notify UI bindings
        root.revision += 1
      }
      
      // Reset and process next job in queue
      root._b64CurrentCb = null
      root._b64CurrentMime = ""
      root._b64CurrentId = ""
      Qt.callLater(root._startNextB64)
    }
  }
  
  // Process next base64 decode job from queue
  function _startNextB64() {
    // Noctalia: guard against both empty queue AND unavailable cliphist
    if (root._b64Queue.length === 0 || !root.cliphistAvailable) return
    
    const job = root._b64Queue.shift()
    root._b64CurrentCb = job.cb
    root._b64CurrentMime = job.mime
    root._b64CurrentId = job.id
    
    // Use sh -lc (login shell) for better PATH handling
    // -l loads shell profile (ensures cliphist in PATH)
    // -c executes the command string
    // Pipe preserves binary data for images
    decodeB64Proc.command = ["sh", "-lc", 
      `cliphist decode ${job.id} | base64 -w 0`]
    decodeB64Proc.running = true
  }
  
  // === Copy to Clipboard ===
  
  // Copy clipboard entry back to system clipboard
  // Decodes entry and pipes to wl-copy
  function copyToClipboard(id) {
    if (!root.cliphistAvailable) return
    
    // Decode and pipe to wl-copy (use -lc for PATH)
    // Binary-safe for images
    copyProc.command = ["sh", "-lc", 
      `cliphist decode ${id} | wl-copy`]
    copyProc.running = true
  }
  
  Process {
    id: copyProc
    stdout: StdioCollector {}
  }
  
  // === Delete Operations ===
  
  // Delete single clipboard entry by ID
  // Increments revision to force UI updates
  function deleteById(id) {
    if (!root.cliphistAvailable) return
    
    // Execute detached (fire-and-forget)
    Quickshell.execDetached(["cliphist", "delete", id])
    
    // Increment revision to notify UI that cache may be invalid
    revision++
    
    // Refresh list after short delay
    Qt.callLater(() => list())
  }
  
  // Delete all clipboard history
  function wipeAll() {
    if (!root.cliphistAvailable) return
    
    Quickshell.execDetached(["cliphist", "wipe"])
    revision++
    Qt.callLater(() => list())
  }
}
