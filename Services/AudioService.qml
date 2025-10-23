pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../Commons"

Singleton {
    id: root

    // ===== Properties =====
    readonly property int volume: _volume        // Volume percentage (0-100)
    readonly property bool muted: _muted         // Mute state
    readonly property bool isReady: _isReady     // Audio sink ready

    // ===== Private state =====
    property int _volume: 0
    property bool _muted: false
    property bool _isReady: false
    property bool initialized: false

    // ===== Audio sink reference =====
    readonly property var sink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: [root.sink]
    }

    // ===== Initialization =====
    function init() {
        if (initialized) {
            Logger.warn("AudioService", "Already initialized");
            return;
        }

        Logger.log("AudioService", "Initializing...");
        updateAudio();
        initialized = true;
        Logger.log("AudioService", "Initialization complete");
    }

    // ===== Watch for sink changes =====
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            Logger.log("AudioService", "Default audio sink changed");
            root.updateAudio();
        }
    }

    // ===== Watch for audio property changes =====
    Connections {
        target: root.sink !== null ? root.sink.audio : null
        enabled: root.sink !== null

        function onVolumeChanged() {
            root.safeUpdateVolume();
        }

        function onMutedChanged() {
            root.safeUpdateMuted();
        }
    }

    // ===== Update audio state =====
    function updateAudio() {
        try {
            if (!sink || !sink.audio) {
                _isReady = false;
                _volume = 0;
                _muted = false;
                Logger.warn("AudioService", "No audio sink available");
                return;
            }

            _isReady = true;
            safeUpdateVolume();
            safeUpdateMuted();
            Logger.log("AudioService", "Audio ready - Volume:", _volume, "Muted:", _muted);
        } catch (e) {
            Logger.error("AudioService", "Failed to update audio:", e);
            Logger.callStack();
            _isReady = false;
        }
    }

    // ===== Safe volume update =====
    function safeUpdateVolume() {
        if (!sink || !sink.audio) {
            _volume = 0;
            volumeChanged();
            return;
        }

        try {
            const vol = sink.audio.volume;
            if (typeof vol === "number" && !isNaN(vol)) {
                _volume = Math.round(Math.max(0, Math.min(1, vol)) * 100);
                volumeChanged();
            }
        } catch (e) {
            Logger.error("AudioService", "Failed to read volume:", e);
        }
    }

    // ===== Safe mute update =====
    function safeUpdateMuted() {
        if (!sink || !sink.audio) {
            _muted = false;
            mutedChanged();
            return;
        }

        try {
            const mute = sink.audio.muted;
            if (typeof mute === "boolean") {
                _muted = mute;
                mutedChanged();
            }
        } catch (e) {
            Logger.error("AudioService", "Failed to read mute state:", e);
        }
    }

    // ===== Public API: Toggle mute =====
    function toggleMute() {
        if (!sink || !sink.audio) {
            Logger.warn("AudioService", "Cannot toggle mute: no sink available");
            return;
        }

        try {
            const newMuted = !sink.audio.muted;
            sink.audio.muted = newMuted;
            Logger.log("AudioService", `Mute toggled: ${newMuted}`);
        } catch (e) {
            Logger.error("AudioService", "Failed to toggle mute:", e);
        }
    }

    // ===== Public API: Set volume =====
    function setVolume(percent) {
        if (!sink || !sink.audio) {
            Logger.warn("AudioService", "Cannot set volume: no sink available");
            return;
        }

        try {
            // Clamp to 0-100%
            const clampedPercent = Math.max(0, Math.min(100, percent));
            sink.audio.volume = clampedPercent / 100.0;
            Logger.log("AudioService", `Volume set: ${clampedPercent}%`);
        } catch (e) {
            Logger.error("AudioService", "Failed to set volume:", e);
        }
    }

    // ===== Public API: Increase volume =====
    function increaseVolume(step = 5) {
        setVolume(_volume + step);
    }

    // ===== Public API: Decrease volume =====
    function decreaseVolume(step = 5) {
        setVolume(_volume - step);
    }

    // ===== Helper: Get icon based on state =====
    function getIcon() {
        if (!isReady) {
            return "󰝟";  // volume-off (Nerd Font)
        }

        if (muted) {
            return "󰝟";  // volume-mute (Nerd Font)
        }

        // Icon based on volume level
        if (volume === 0) return "󰕿";     // volume-zero
        if (volume < 33) return "󰖀";      // volume-low
        if (volume < 66) return "󰕾";      // volume-medium
        return "󰕾";                        // volume-high
    }

    // ===== Helper: Get color based on state =====
    function getColor() {
        if (!isReady) {
            return Color.mOutlineVariant;
        }

        if (muted) {
            return Color.mOutlineVariant;  // Dimmed when muted
        }

        return Color.mPrimary;  // Primary color when active
    }
}
