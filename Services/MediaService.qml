pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../Commons"

Singleton {
    id: root

    // ===== Public Properties =====
    property var currentPlayer: null            // Current MprisPlayer object
    property bool isPlaying: false              // Currently playing
    property string trackTitle: ""              // Track title
    property string trackArtist: ""             // Track artist
    property string trackAlbum: ""              // Track album
    property string trackArtUrl: ""             // Album art URL
    property real trackLength: 0                // Track length in seconds
    property real trackPosition: 0              // Current position in seconds

    // Control capabilities
    property bool canPlay: false
    property bool canPause: false
    property bool canGoNext: false
    property bool canGoPrevious: false
    property bool canSeek: false

    // ===== Private Properties =====
    property int _selectedPlayerIndex: 0

    // ===== Initialization =====
    Component.onCompleted: {
        Logger.log("MediaService", "Initialized");
        updateCurrentPlayer();
    }

    // ===== Watch for player changes =====
    Connections {
        target: Mpris.players

        function onValuesChanged() {
            Logger.log("MediaService", "Players changed");
            updateCurrentPlayer();
        }
    }

    // ===== Watch current player changes =====
    Connections {
        target: root.currentPlayer
        enabled: root.currentPlayer !== null

        function onPlaybackStateChanged() {
            updatePlaybackState();
        }

        function onMetadataChanged() {
            updateTrackInfo();
        }

        function onPositionChanged() {
            updatePosition();
        }

        function onCanPlayChanged() {
            updateCapabilities();
        }

        function onCanPauseChanged() {
            updateCapabilities();
        }

        function onCanGoNextChanged() {
            updateCapabilities();
        }

        function onCanGoPreviousChanged() {
            updateCapabilities();
        }

        function onCanSeekChanged() {
            updateCapabilities();
        }
    }

    // ===== Player Management =====

    // Get list of available players
    function getAvailablePlayers() {
        if (!Mpris.players || !Mpris.players.values) {
            return [];
        }

        const allPlayers = Mpris.players.values;
        const controllable = [];

        for (let i = 0; i < allPlayers.length; i++) {
            const player = allPlayers[i];
            if (player && player.canControl) {
                controllable.push(player);
            }
        }

        return controllable;
    }

    // Find the active/best player
    function findActivePlayer() {
        const available = getAvailablePlayers();

        if (available.length === 0) {
            Logger.log("MediaService", "No active player found");
            return null;
        }

        // Use selected index if valid
        if (_selectedPlayerIndex < available.length) {
            return available[_selectedPlayerIndex];
        }

        // Default to first player
        _selectedPlayerIndex = 0;
        return available[0];
    }

    // Update current player
    function updateCurrentPlayer() {
        const newPlayer = findActivePlayer();

        if (newPlayer === currentPlayer) return;

        currentPlayer = newPlayer;

        if (currentPlayer) {
            Logger.log("MediaService", "Switched to player:", currentPlayer.identity || "Unknown");
            updatePlaybackState();
            updateTrackInfo();
            updatePosition();
            updateCapabilities();
        } else {
            Logger.log("MediaService", "No player available");
            clearPlayerInfo();
        }
    }

    // ===== Update Functions =====

    function updatePlaybackState() {
        if (!currentPlayer) {
            isPlaying = false;
            return;
        }

        try {
            isPlaying = currentPlayer.playbackState === MprisPlaybackState.Playing;
        } catch (e) {
            Logger.error("MediaService", "Failed to read playback state:", e);
            isPlaying = false;
        }
    }

    function updateTrackInfo() {
        if (!currentPlayer) {
            clearTrackInfo();
            return;
        }

        try {
            trackTitle = currentPlayer.trackTitle || "";
            trackArtist = currentPlayer.trackArtist || "";
            trackAlbum = currentPlayer.trackAlbum || "";
            trackArtUrl = currentPlayer.trackArtUrl || "";
            trackLength = (currentPlayer.length || 0) / 1000000;  // Convert to seconds

            if (trackTitle) {
                Logger.log("MediaService", "Track:", trackTitle, "by", trackArtist);
            }
        } catch (e) {
            Logger.error("MediaService", "Failed to read track info:", e);
            clearTrackInfo();
        }
    }

    function updatePosition() {
        if (!currentPlayer) {
            trackPosition = 0;
            return;
        }

        try {
            trackPosition = (currentPlayer.position || 0) / 1000000;  // Convert to seconds
        } catch (e) {
            Logger.error("MediaService", "Failed to read position:", e);
            trackPosition = 0;
        }
    }

    function updateCapabilities() {
        if (!currentPlayer) {
            clearCapabilities();
            return;
        }

        try {
            canPlay = currentPlayer.canPlay || false;
            canPause = currentPlayer.canPause || false;
            canGoNext = currentPlayer.canGoNext || false;
            canGoPrevious = currentPlayer.canGoPrevious || false;
            canSeek = currentPlayer.canSeek || false;
        } catch (e) {
            Logger.error("MediaService", "Failed to read capabilities:", e);
            clearCapabilities();
        }
    }

    function clearPlayerInfo() {
        clearTrackInfo();
        clearCapabilities();
        isPlaying = false;
        trackPosition = 0;
    }

    function clearTrackInfo() {
        trackTitle = "";
        trackArtist = "";
        trackAlbum = "";
        trackArtUrl = "";
        trackLength = 0;
    }

    function clearCapabilities() {
        canPlay = false;
        canPause = false;
        canGoNext = false;
        canGoPrevious = false;
        canSeek = false;
    }

    // ===== Position Timer =====
    // Update position every second while playing
    Timer {
        id: positionTimer
        interval: 1000
        running: root.isPlaying && root.trackLength > 0
        repeat: true

        onTriggered: {
            if (root.currentPlayer && root.isPlaying) {
                updatePosition();
            }
        }
    }

    // ===== Playback Control Functions =====

    function play() {
        if (!currentPlayer || !canPlay) return;

        try {
            currentPlayer.play();
            Logger.log("MediaService", "Play");
        } catch (e) {
            Logger.error("MediaService", "Failed to play:", e);
        }
    }

    function pause() {
        if (!currentPlayer || !canPause) return;

        try {
            currentPlayer.pause();
            Logger.log("MediaService", "Pause");
        } catch (e) {
            Logger.error("MediaService", "Failed to pause:", e);
        }
    }

    function playPause() {
        if (!currentPlayer) return;

        if (isPlaying) {
            pause();
        } else {
            play();
        }
    }

    function next() {
        if (!currentPlayer || !canGoNext) return;

        try {
            currentPlayer.next();
            Logger.log("MediaService", "Next track");
        } catch (e) {
            Logger.error("MediaService", "Failed to skip next:", e);
        }
    }

    function previous() {
        if (!currentPlayer || !canGoPrevious) return;

        try {
            currentPlayer.previous();
            Logger.log("MediaService", "Previous track");
        } catch (e) {
            Logger.error("MediaService", "Failed to skip previous:", e);
        }
    }

    function stop() {
        if (!currentPlayer) return;

        try {
            currentPlayer.stop();
            Logger.log("MediaService", "Stop");
        } catch (e) {
            Logger.error("MediaService", "Failed to stop:", e);
        }
    }

    function seek(positionSeconds) {
        if (!currentPlayer || !canSeek) return;

        try {
            const positionMicroseconds = positionSeconds * 1000000;
            currentPlayer.position = positionMicroseconds;
            trackPosition = positionSeconds;
            Logger.log("MediaService", "Seek to:", positionSeconds + "s");
        } catch (e) {
            Logger.error("MediaService", "Failed to seek:", e);
        }
    }

    // ===== Helper Functions =====

    // Get playback icon
    function getIcon() {
        if (!currentPlayer) return "󰝚";  // music-note

        if (isPlaying) return "󰏤";  // pause
        return "󰐊";  // play
    }

    // Get color based on state
    function getColor() {
        if (!currentPlayer) return Color.mOutlineVariant;
        if (isPlaying) return Color.mPrimary;
        return Color.mOnSurface;
    }

    // Get formatted track display
    function getTrackDisplay() {
        if (!trackTitle) return "No media playing";

        if (trackArtist) {
            return trackTitle + " - " + trackArtist;
        }

        return trackTitle;
    }

    // Format time (seconds to MM:SS)
    function formatTime(seconds) {
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    // Get position ratio (0.0 - 1.0)
    function getPositionRatio() {
        if (trackLength === 0) return 0;
        return Math.max(0, Math.min(1, trackPosition / trackLength));
    }
}
