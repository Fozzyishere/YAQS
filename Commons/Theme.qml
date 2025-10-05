pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  // ===== Spacing =====
  readonly property int spacing_xs: 2
  readonly property int spacing_s: 4
  readonly property int spacing_m: 6
  readonly property int spacing_l: 8

  // ===== Radius =====
  readonly property int radius_s: 4
  readonly property int radius_m: 8

  // ===== Animation Durations (ms) =====
  readonly property int duration_fast: 100
  readonly property int duration_normal: 200

  // ===== Bar Configuration =====
  readonly property int bar_height: 22
  readonly property string bar_position: "top"

  // Bar margins
  readonly property int bar_margin_top: spacing_s
  readonly property int bar_margin_side: spacing_xs
  readonly property int bar_margin_bottom: spacing_s

  // ===== Typography =====
  readonly property string font_family: "Inter"
  readonly property int font_size: 11
  readonly property int font_size_small: 9

  // ===== Colors (loaded from JSON or defaults) =====

  // Background colors
  readonly property color bg: customColors.bg
  readonly property color bg_hover: customColors.bg_hover

  // Foreground colors
  readonly property color fg: customColors.fg
  readonly property color fg_dim: customColors.fg_dim

  // Accent colors
  readonly property color accent: customColors.accent
  readonly property color urgent: customColors.urgent

  // Additional colors
  readonly property color blue: customColors.blue
  readonly property color green: customColors.green
  readonly property color yellow: customColors.yellow

  // ===== Default Colors (Ayu Dark) =====
  QtObject {
    id: defaultColors

    property color bg: "#0A0E14"        // Dark navy/black background
    property color bg_hover: "#151A1F"   // Slightly lighter for hover
    property color fg: "#B3B1AD"         // Light gray text
    property color fg_dim: "#626A73"     // Dimmed gray text
    property color accent: "#FFB454"     // Orange accent
    property color urgent: "#F07178"     // Red for urgent states
    property color blue: "#39BAE6"       // Blue accent
    property color green: "#7FD962"      // Green accent
    property color yellow: "#FFD580"     // Yellow accent
  }

  // ===== Custom Colors =====
  FileView {
    id: colorsFile
    path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
    printErrors: false
    watchChanges: true

    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    // Trigger initial load
    Component.onCompleted: {
      if (path !== undefined) {
        reload()
      }
    }

    onLoadFailed: function (error) {
      if (error.toString().includes("No such file") || error === 2) {
        // File doesn't exist, create it with default values
        writeAdapter()
      }
    }

    JsonAdapter {
      id: customColors

      property color bg: defaultColors.bg
      property color bg_hover: defaultColors.bg_hover
      property color fg: defaultColors.fg
      property color fg_dim: defaultColors.fg_dim
      property color accent: defaultColors.accent
      property color urgent: defaultColors.urgent
      property color blue: defaultColors.blue
      property color green: defaultColors.green
      property color yellow: defaultColors.yellow
    }
  }
}
