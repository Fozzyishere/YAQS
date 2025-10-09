pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ===== Spacing =====
    // Comprehensive spacing scale for various UI elements
    readonly property int spacing_0: 0      // No spacing
    readonly property int spacing_xxs: 1    // Minimal (separator gaps)
    readonly property int spacing_xs: 2     // Extra small (tight elements)
    readonly property int spacing_s: 4      // Small (compact widgets)
    readonly property int spacing_m: 8      // Medium (standard gap)
    readonly property int spacing_l: 12     // Large (section spacing)
    readonly property int spacing_xl: 16    // Extra large (major sections)
    readonly property int spacing_2xl: 24   // 2X large (panel padding)
    readonly property int spacing_3xl: 32   // 3X large (screen margins)

    // ===== Radius =====
    readonly property int radius_xs: 2      // Extra small (subtle rounding)
    readonly property int radius_s: 4       // Small (buttons, inputs)
    readonly property int radius_m: 8       // Medium (panels, cards)
    readonly property int radius_l: 12      // Large (modal dialogs)
    readonly property int radius_xl: 16     // Extra large (screens)
    readonly property int radius_full: 9999 // Fully rounded (pills, circles)

    // ===== Animation Durations (ms) =====
    readonly property int duration_instant: 0     // No animation
    readonly property int duration_fast: 100      // Quick transitions
    readonly property int duration_normal: 200    // Standard animations
    readonly property int duration_slow: 300      // Slower animations

    // ===== Opacity =====
    readonly property real opacity_none: 0.0      // Fully transparent
    readonly property real opacity_light: 0.25    // Subtle overlay
    readonly property real opacity_medium: 0.5    // Half transparent
    readonly property real opacity_heavy: 0.75    // Mostly opaque
    readonly property real opacity_full: 1.0      // Fully opaque

    // ===== Bar Configuration =====
    readonly property int bar_height: 22

    // Bar margins
    readonly property int bar_margin_top: 4        // 4px top
    readonly property int bar_margin_side: 4       // 4px sides
    readonly property int bar_margin_bottom: 4     // 4px bottom

    // ===== Typography =====
    readonly property string font_family: "JetBrainsMono Nerd Font"
    readonly property int font_size: 7
    readonly property int font_size_small: 5
    readonly property int font_size_large: 9
    readonly property int font_size_xlarge: 9

    // ===== Icons =====
    readonly property int icon_size: 9

    // ===== Colors (loaded from JSON or defaults) =====

    // Background core
    readonly property color bg0_hard: customColors.bg0_hard
    readonly property color bg0: customColors.bg0
    readonly property color bg0_soft: customColors.bg0_soft
    readonly property color bg1: customColors.bg1
    readonly property color bg2: customColors.bg2
    readonly property color bg3: customColors.bg3
    readonly property color bg4: customColors.bg4

    // Foreground core
    readonly property color fg0: customColors.fg0
    readonly property color fg1: customColors.fg1
    readonly property color fg2: customColors.fg2
    readonly property color fg3: customColors.fg3
    readonly property color fg4: customColors.fg4
    readonly property color gray: customColors.gray

    // Semantic aliases for existing callers
    readonly property color bg: bg0_hard
    readonly property color bg_alt: bg0
    readonly property color bg_hover: bg1
    readonly property color bg_panel: bg0
    readonly property color surface: bg0
    readonly property color selection: bg1
    readonly property color border: bg2
    readonly property color gutter: bg0
    readonly property color fg: fg1
    readonly property color fg_dim: fg3
    readonly property color comment: gray

    // Accent colors
    readonly property color red: customColors.red
    readonly property color red_dim: customColors.red_dim
    readonly property color green: customColors.green
    readonly property color green_dim: customColors.green_dim
    readonly property color yellow: customColors.yellow
    readonly property color yellow_dim: customColors.yellow_dim
    readonly property color blue: customColors.blue
    readonly property color blue_dim: customColors.blue_dim
    readonly property color purple: customColors.purple
    readonly property color purple_dim: customColors.purple_dim
    readonly property color aqua: customColors.aqua
    readonly property color aqua_dim: customColors.aqua_dim
    readonly property color orange: customColors.orange
    readonly property color orange_dim: customColors.orange_dim

    // ===== Default Colors (Tokyo Night) =====
    QtObject {
        id: defaultColors

        property color bg0_hard: "#16161E"
        property color bg0: "#1A1B26"
        property color bg0_soft: "#24283B"
        property color bg1: "#292E42"
        property color bg2: "#3B4261"
        property color bg3: "#414868"
        property color bg4: "#565F89"
        property color fg0: "#C0CAF5"
        property color fg1: "#A9B1D6"
        property color fg2: "#9AA5CE"
        property color fg3: "#7982A9"
        property color fg4: "#6C7AA0"
        property color gray: "#565F89"
        property color red: "#F7768E"
        property color red_dim: "#DB4B4B"
        property color green: "#9ECE6A"
        property color green_dim: "#73DACA"
        property color yellow: "#E0AF68"
        property color yellow_dim: "#D8A657"
        property color blue: "#7AA2F7"
        property color blue_dim: "#6183BB"
        property color purple: "#BB9AF7"
        property color purple_dim: "#9D7CD8"
        property color aqua: "#7DCFFF"
        property color aqua_dim: "#2AC3DE"
        property color orange: "#FF9E64"
        property color orange_dim: "#E0823D"
        property color accent: "#7AA2F7"
        property color urgent: "#F7768E"
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
                reload();
            }
        }

        onLoadFailed: function (error) {
            if (error.toString().includes("No such file") || error === 2) {
                // File doesn't exist, create it with default values
                writeAdapter();
            }
        }

        JsonAdapter {
            id: customColors

            property color bg0_hard: defaultColors.bg0_hard
            property color bg0: defaultColors.bg0
            property color bg0_soft: defaultColors.bg0_soft
            property color bg1: defaultColors.bg1
            property color bg2: defaultColors.bg2
            property color bg3: defaultColors.bg3
            property color bg4: defaultColors.bg4
            property color fg0: defaultColors.fg0
            property color fg1: defaultColors.fg1
            property color fg2: defaultColors.fg2
            property color fg3: defaultColors.fg3
            property color fg4: defaultColors.fg4
            property color gray: defaultColors.gray
            property color red: defaultColors.red
            property color red_dim: defaultColors.red_dim
            property color green: defaultColors.green
            property color green_dim: defaultColors.green_dim
            property color yellow: defaultColors.yellow
            property color yellow_dim: defaultColors.yellow_dim
            property color blue: defaultColors.blue
            property color blue_dim: defaultColors.blue_dim
            property color purple: defaultColors.purple
            property color purple_dim: defaultColors.purple_dim
            property color aqua: defaultColors.aqua
            property color aqua_dim: defaultColors.aqua_dim
            property color orange: defaultColors.orange
            property color orange_dim: defaultColors.orange_dim
        }
    }
}
