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
    // Extended Ayu Dark palette
    readonly property color surface: customColors.surface
    readonly property color selection: customColors.selection
    readonly property color border: customColors.border
    readonly property color gutter: customColors.gutter
    readonly property color comment: customColors.comment
    readonly property color purple: customColors.purple
    readonly property color magenta: customColors.magenta
    readonly property color cyan: customColors.cyan
    readonly property color teal: customColors.teal
    readonly property color bg_panel: customColors.bg_panel
    readonly property color bg_alt: customColors.bg_alt

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
        property color surface: "#0F1318"    // Panels / elevated surfaces
        property color selection: "#22303B"  // Selection / highlight background
        property color border: "#1B2329"     // Borders / dividers
        property color gutter: "#0D1116"     // Muted gutter / background lines
        property color comment: "#626A73"    // Comments / secondary text
        property color purple: "#C39DFF"    // Purple accent
        property color magenta: "#FF7AC6"   // Magenta / pink accent
        property color cyan: "#7FD6FF"      // Cyan / link
        property color teal: "#39C5A6"      // Teal accent
        property color bg_panel: "#0B0F14"   // Slightly different panel background
        property color bg_alt: "#0D1116"     // Alternate background
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

            property color bg: defaultColors.bg
            property color bg_hover: defaultColors.bg_hover
            property color fg: defaultColors.fg
            property color fg_dim: defaultColors.fg_dim
            property color accent: defaultColors.accent
            property color urgent: defaultColors.urgent
            property color blue: defaultColors.blue
            property color green: defaultColors.green
            property color yellow: defaultColors.yellow
            // Extended Ayu Dark palette (allow overrides via JSON)
            property color surface: defaultColors.surface
            property color selection: defaultColors.selection
            property color border: defaultColors.border
            property color gutter: defaultColors.gutter
            property color comment: defaultColors.comment
            property color purple: defaultColors.purple
            property color magenta: defaultColors.magenta
            property color cyan: defaultColors.cyan
            property color teal: defaultColors.teal
            property color bg_panel: defaultColors.bg_panel
            property color bg_alt: defaultColors.bg_alt
        }
    }
}
