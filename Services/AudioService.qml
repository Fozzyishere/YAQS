pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../Commons" as QsCommons

Singleton {
  id: root

  // === Public Properties ===
  
  // Filtered node lists - reduces all PipeWire nodes to sinks and sources
  // Use reduce to filter out application streams
  readonly property var nodes: Pipewire.nodes.values.reduce((acc, node) => {
    if (!node.isStream) {
      if (node.isSink) {
        acc.sinks.push(node)
      } else if (node.audio) {
        acc.sources.push(node)
      }
    }
    return acc
  }, {
    "sources": [],
    "sinks": []
  })

  // Default audio devices from PipeWire
  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property PwNode source: Pipewire.defaultAudioSource
  readonly property list<PwNode> sinks: nodes.sinks
  readonly property list<PwNode> sources: nodes.sources

  // Volume [0..1] is readonly from outside
  // Use alias with private backing property
  // This prevents binding issues during device transitions and allows explicit NaN handling
  readonly property alias volume: root._volume
  property real _volume: sink?.audio?.volume ?? 0

  readonly property alias muted: root._muted
  property bool _muted: !!sink?.audio?.muted

  // Input volume [0..1] is readonly from outside
  readonly property alias inputVolume: root._inputVolume
  property real _inputVolume: source?.audio?.volume ?? 0

  readonly property alias inputMuted: root._inputMuted
  property bool _inputMuted: !!source?.audio?.muted

  // Volume step from settings (converted from percentage to 0-1 range)
  readonly property real stepVolume: QsCommons.Settings.data.audio.volumeStep / 100.0

  // === PwObjectTracker ===
  // PwObjectTracker is required to bind nodes and make audio properties valid
  // Without this, accessing node.audio properties will fail
  PwObjectTracker {
    objects: [...root.sinks, ...root.sources]
  }

  // === Connections ===
  // Explicitly handle volume changes with NaN checks
  // PipeWire can emit NaN during device hotplug/removal
  Connections {
    target: sink?.audio ? sink.audio : null

    function onVolumeChanged() {
      var vol = (sink?.audio.volume ?? 0)
      if (isNaN(vol)) {
        return
      }
      root._volume = vol
    }

    function onMutedChanged() {
        root._muted = (sink?.audio.muted ?? true)
        QsCommons.Logger.d("AudioService", "OnMuteChanged:", root._muted)
    }
  }

  Connections {
    target: source?.audio ? source.audio : null

    function onVolumeChanged() {
      var vol = (source?.audio.volume ?? 0)
      if (isNaN(vol)) {
        return
      }
      root._inputVolume = vol
    }

    function onMutedChanged() {
        root._inputMuted = (source?.audio.muted ?? true)
        QsCommons.Logger.d("AudioService", "OnInputMutedChanged:", root._inputMuted)
    }
  }

  // === Functions ===
  
  // Output (Sink) Volume Control
  function increaseVolume() {
    setVolume(volume + stepVolume)
  }

  function decreaseVolume() {
    setVolume(volume - stepVolume)
  }

  function setVolume(newVolume: real) {
    if (sink?.ready && sink?.audio) {
      // Unmute when setting volume
      sink.audio.muted = false
      // Clamp to max (1.0 or 1.5 with overdrive setting)
      // PwNodeAudio.volume is read-write, range [0.0 - 1.5+]
      sink.audio.volume = Math.max(0, Math.min(
        QsCommons.Settings.data.audio.volumeOverdrive ? 1.5 : 1.0,
        newVolume
      ))
    } else {
      QsCommons.Logger.w("AudioService", "No sink available")
    }
  }

  function setOutputMuted(muted: bool) {
    if (sink?.ready && sink?.audio) {
      sink.audio.muted = muted
    } else {
      QsCommons.Logger.w("AudioService", "No sink available")
    }
  }

  // Input (Source) Volume Control
  function increaseInputVolume() {
    setInputVolume(inputVolume + stepVolume)
  }

  function decreaseInputVolume() {
    setInputVolume(inputVolume - stepVolume)
  }

  function setInputVolume(newVolume: real) {
    if (source?.ready && source?.audio) {
      // Unmute when setting volume
      source.audio.muted = false
      // Clamp to max (1.0 or 1.5 with overdrive setting)
      source.audio.volume = Math.max(0, Math.min(
        QsCommons.Settings.data.audio.volumeOverdrive ? 1.5 : 1.0,
        newVolume
      ))
    } else {
      QsCommons.Logger.w("AudioService", "No source available")
    }
  }

  function setInputMuted(muted: bool) {
    if (source?.ready && source?.audio) {
      source.audio.muted = muted
    } else {
      QsCommons.Logger.w("AudioService", "No source available")
    }
  }

  // Device Switching
  // Immediately update internal state when switching devices
  // This ensures UI reflects new device state without waiting for signals
  function setAudioSink(newSink: PwNode): void {
    Pipewire.preferredDefaultAudioSink = newSink
    // Immediately update internal state to match new device
    root._volume = newSink?.audio?.volume ?? 0
    root._muted = !!newSink?.audio?.muted
  }

  function setAudioSource(newSource: PwNode): void {
    Pipewire.preferredDefaultAudioSource = newSource
    // Immediately update internal state to match new device
    root._inputVolume = newSource?.audio?.volume ?? 0
    root._inputMuted = !!newSource?.audio?.muted
  }

  // === Initialization ===
  Component.onCompleted: {
    QsCommons.Logger.d("AudioService", "Initialized")
    QsCommons.Logger.d("AudioService", "Pipewire.nodes.values.length:", Pipewire.nodes.values.length)
    QsCommons.Logger.d("AudioService", "Pipewire.defaultAudioSink:", Pipewire.defaultAudioSink)
    QsCommons.Logger.d("AudioService", "Pipewire.defaultAudioSource:", Pipewire.defaultAudioSource)
    
    // Log all nodes for debugging
    const allNodes = Pipewire.nodes.values
    QsCommons.Logger.d("AudioService", "All PipeWire nodes:")
    for (var i = 0; i < allNodes.length; i++) {
      const node = allNodes[i]
      QsCommons.Logger.d("AudioService", "  Node", i + ":", 
               "name=" + node.name,
               "isStream=" + node.isStream,
               "isSink=" + node.isSink,
               "hasAudio=" + !!node.audio)
    }
  }
}
