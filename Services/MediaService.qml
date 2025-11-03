pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Public Properties ===
  
  // Current active player (may be virtual player with _stateSource and _controlTarget)
  property var currentPlayer: null
  
  // Current playback position (in seconds for YAQS - converted from microseconds)
  property real currentPosition: 0
  
  // User is dragging seek slider (prevents position updates)
  property bool isSeeking: false
  
  // Index of selected player (for manual selection)
  property int selectedPlayerIndex: 0
  
  // Playback state
  property bool isPlaying: currentPlayer ? 
    (currentPlayer.playbackState === MprisPlaybackState.Playing || currentPlayer.isPlaying) : false
  
  // Track metadata
  property string trackTitle: currentPlayer ? 
    (currentPlayer.trackTitle !== undefined ? 
      currentPlayer.trackTitle.replace(/(\r\n|\n|\r)/g, "") : "") : ""
  property string trackArtist: currentPlayer ? (currentPlayer.trackArtist || "") : ""
  property string trackAlbum: currentPlayer ? (currentPlayer.trackAlbum || "") : ""
  property string trackArtUrl: currentPlayer ? (currentPlayer.trackArtUrl || "") : ""
  
  // Track length in seconds (filtered for infinite values)
  // MPRIS max value (near LLONG_MAX/1000) used by players for "infinite" streams (TODO: Fix magic number soon?)
  readonly property real infiniteTrackLength: 922337203685 / 1000000  // ~10.7 days in seconds
  property real trackLength: currentPlayer ? 
    ((currentPlayer.length / 1000000 < infiniteTrackLength) ? 
      currentPlayer.length / 1000000 : 0) : 0
  
  // Playback capabilities
  property bool canPlay: currentPlayer ? currentPlayer.canPlay : false
  property bool canPause: currentPlayer ? currentPlayer.canPause : false
  property bool canGoNext: currentPlayer ? currentPlayer.canGoNext : false
  property bool canGoPrevious: currentPlayer ? currentPlayer.canGoPrevious : false
  property bool canSeek: currentPlayer ? currentPlayer.canSeek : false

  // === Initialization ===
  Component.onCompleted: {
    QsCommons.Logger.i("MediaService", "Initialized")
    updateCurrentPlayer()
  }

  // === Player Discovery and Pairing ===
  
  function getAvailablePlayers() {
    if (!Mpris.players || !Mpris.players.values) {
      return []
    }

    let allPlayers = Mpris.players.values
    let finalPlayers = []
    const genericBrowsers = ["firefox", "chromium", "chrome"]
    const blacklist = (QsCommons.Settings.data.audio && QsCommons.Settings.data.audio.mprisBlacklist) ? 
                      QsCommons.Settings.data.audio.mprisBlacklist : []

    // Separate players into specific (apps) and generic (browsers) lists
    let specificPlayers = []
    let genericPlayers = []
    
    for (var i = 0; i < allPlayers.length; i++) {
      const identity = String(allPlayers[i].identity || "").toLowerCase()
      
      // Check blacklist
      const match = blacklist.find(b => {
        const s = String(b || "").toLowerCase()
        return s && (identity.includes(s))
      })
      if (match) continue
      
      // Categorize as generic browser or specific app
      if (genericBrowsers.some(b => identity.includes(b))) {
        genericPlayers.push(allPlayers[i])
      } else {
        specificPlayers.push(allPlayers[i])
      }
    }

    let matchedGenericIndices = {}

    // For each specific player, try to find and pair with a generic partner
    // This creates "virtual players" combining app identity with browser metadata
    for (var i = 0; i < specificPlayers.length; i++) {
      let specificPlayer = specificPlayers[i]
      let title1 = String(specificPlayer.trackTitle || "").trim()
      let wasMatched = false

      if (title1) {
        for (var j = 0; j < genericPlayers.length; j++) {
          if (matchedGenericIndices[j]) continue
          
          let genericPlayer = genericPlayers[j]
          let title2 = String(genericPlayer.trackTitle || "").trim()

          // Attempt to match by title similarity (e.g., Spotify app + Spotify in Chrome)
          if (title2 && (title1.includes(title2) || title2.includes(title1))) {
            // Choose data source based on metadata quality (prefer one with artwork)
            let dataPlayer = genericPlayer
            let identityPlayer = specificPlayer

            let scoreSpecific = (specificPlayer.trackArtUrl ? 1 : 0)
            let scoreGeneric = (genericPlayer.trackArtUrl ? 1 : 0)
            if (scoreSpecific > scoreGeneric) {
              dataPlayer = specificPlayer
            }

            // Create virtual player combining best of both
            let virtualPlayer = {
              "identity": identityPlayer.identity,
              "desktopEntry": identityPlayer.desktopEntry,
              "trackTitle": dataPlayer.trackTitle,
              "trackArtist": dataPlayer.trackArtist,
              "trackAlbum": dataPlayer.trackAlbum,
              "trackArtUrl": dataPlayer.trackArtUrl,
              "length": dataPlayer.length || 0,
              "position": dataPlayer.position || 0,
              "playbackState": dataPlayer.playbackState,
              "isPlaying": dataPlayer.isPlaying || false,
              "canPlay": dataPlayer.canPlay || false,
              "canPause": dataPlayer.canPause || false,
              "canGoNext": dataPlayer.canGoNext || false,
              "canGoPrevious": dataPlayer.canGoPrevious || false,
              "canSeek": dataPlayer.canSeek || false,
              "canControl": dataPlayer.canControl || false,
              "_stateSource": dataPlayer,      // Read state from this player
              "_controlTarget": identityPlayer  // Send commands to this player
            }
            
            finalPlayers.push(virtualPlayer)
            matchedGenericIndices[j] = true
            wasMatched = true
            break
          }
        }
      }
      
      // Add unmatched specific players
      if (!wasMatched) {
        finalPlayers.push(specificPlayer)
      }
    }

    // Add any generic players that were not matched
    for (var i = 0; i < genericPlayers.length; i++) {
      if (!matchedGenericIndices[i]) {
        finalPlayers.push(genericPlayers[i])
      }
    }

    // Filter for controllable players only
    let controllablePlayers = []
    for (var i = 0; i < finalPlayers.length; i++) {
      let player = finalPlayers[i]
      if (player && player.canControl) {
        controllablePlayers.push(player)
      }
    }
    
    return controllablePlayers
  }

  // === Active Player Detection ===
  
  function findActivePlayer() {
    let availablePlayers = getAvailablePlayers()
    if (availablePlayers.length === 0) {
      return null
    }

    // Priority 1: Actively playing player
    for (var i = 0; i < availablePlayers.length; i++) {
      if (availablePlayers[i] && 
          availablePlayers[i].playbackState === MprisPlaybackState.Playing) {
        QsCommons.Logger.d("Media", "Found actively playing player: " + 
                          availablePlayers[i].identity)
        selectedPlayerIndex = i
        return availablePlayers[i]
      }
    }

    // Priority 2: Preferred player from settings
    const preferred = (QsCommons.Settings.data.audio.preferredPlayer || "")
    if (preferred !== "") {
      for (var i = 0; i < availablePlayers.length; i++) {
        const p = availablePlayers[i]
        const identity = String(p.identity || "").toLowerCase()
        const pref = preferred.toLowerCase()
        if (identity.includes(pref)) {
          selectedPlayerIndex = i
          return p
        }
      }
    }

    // Priority 3: Previously selected player (if still valid)
    if (selectedPlayerIndex < availablePlayers.length) {
      return availablePlayers[selectedPlayerIndex]
    } else {
      // Fallback: First available player
      selectedPlayerIndex = 0
      return availablePlayers[0]
    }
  }

  // Switch to the most recently active player
  function updateCurrentPlayer() {
    let newPlayer = findActivePlayer()
    if (newPlayer !== currentPlayer) {
      currentPlayer = newPlayer
      // Convert microseconds to seconds
      currentPosition = currentPlayer ? currentPlayer.position / 1000000 : 0
      QsCommons.Logger.d("Media", "Switched to player: " + 
                        (currentPlayer ? currentPlayer.identity : "none"))
    }
  }

  // === Playback Control Functions ===
  
  function playPause() {
    if (currentPlayer) {
      let stateSource = currentPlayer._stateSource || currentPlayer
      let controlTarget = currentPlayer._controlTarget || currentPlayer
      
      if (stateSource.playbackState === MprisPlaybackState.Playing) {
        controlTarget.pause()
      } else {
        controlTarget.play()
      }
    }
  }

  function play() {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null
    if (target && target.canPlay) {
      target.play()
    }
  }

  function stop() {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null
    if (target) {
      target.stop()
    }
  }

  function pause() {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null
    if (target && target.canPause) {
      target.pause()
    }
  }

  function next() {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null
    if (target && target.canGoNext) {
      target.next()
    }
  }

  function previous() {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null
    if (target && target.canGoPrevious) {
      target.previous()
    }
  }

  function seek(position) {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null
    if (target && target.canSeek) {
      // Convert seconds to microseconds for MPRIS
      target.position = position * 1000000
      currentPosition = position
    }
  }

  // Seek to position based on ratio (0.0 to 1.0)
  function seekByRatio(ratio) {
    let target = currentPlayer ? (currentPlayer._controlTarget || currentPlayer) : null
    if (target && target.canSeek && target.length > 0) {
      let seekPosition = ratio * target.length  // in microseconds
      target.position = seekPosition
      currentPosition = seekPosition / 1000000  // Store in seconds
    }
  }

  // === Position Tracking Timer ===
  // Noctalia optimization: Extra checks and else clause
  Timer {
    id: positionTimer
    interval: 1000
    running: currentPlayer && !root.isSeeking && currentPlayer.isPlaying && 
             currentPlayer.length > 0 && 
             currentPlayer.playbackState === MprisPlaybackState.Playing
    repeat: true
    onTriggered: {
      if (currentPlayer && !root.isSeeking && currentPlayer.isPlaying && 
          currentPlayer.playbackState === MprisPlaybackState.Playing) {
        // Convert microseconds to seconds
        currentPosition = currentPlayer.position / 1000000
      } else {
        running = false  // Optimization: stop timer if conditions no longer met
      }
    }
  }

  // === Position Synchronization ===
  // Avoid overwriting currentPosition while seeking
  Connections {
    target: currentPlayer
    
    function onPositionChanged() {
      if (!root.isSeeking && currentPlayer) {
        currentPosition = currentPlayer.position / 1000000
      }
    }
    
    function onPlaybackStateChanged() {
      if (!root.isSeeking && currentPlayer) {
        currentPosition = currentPlayer.position / 1000000
      }
    }
  }

  // === Player State Monitoring ===
  
  // Reset position when switching to inactive player
  onCurrentPlayerChanged: {
    if (!currentPlayer || !currentPlayer.isPlaying || 
        currentPlayer.playbackState !== MprisPlaybackState.Playing) {
      currentPosition = 0
    }
  }

  // Monitor player state and update if needed
  Timer {
    id: playerStateMonitor
    interval: 2000  // Check every 2 seconds
    repeat: true
    running: true
    onTriggered: {
      // Only update if we don't have a playing player or if current player is paused
      if (!currentPlayer || !currentPlayer.isPlaying || 
          currentPlayer.playbackState !== MprisPlaybackState.Playing) {
        updateCurrentPlayer()
      }
    }
  }

  // Update current player when available players change
  Connections {
    target: Mpris.players
    function onValuesChanged() {
      QsCommons.Logger.d("Media", "Players changed")
      updateCurrentPlayer()
    }
  }
}
