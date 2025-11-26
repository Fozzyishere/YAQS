pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // === Typography ===
  property real fontSizeXXS: 8    // Extra small (legacy compatibility)
  property real fontSizeXS: 10    // Caption, metadata
  property real fontSizeS: 12     // Secondary text, labels
  property real fontSizeM: 14     // Body text (default)
  property real fontSizeL: 16     // Emphasis, subheadings
  property real fontSizeXL: 20    // Section headings
  property real fontSizeXXL: 24   // Panel titles
  property real fontSizeXXXL: 32  // Hero text, large displays

  property int fontWeightRegular: 400  // Body text
  property int fontWeightMedium: 500   // Subtle emphasis, labels
  property int fontWeightSemiBold: 600 // Strong emphasis
  property int fontWeightBold: 700     // Headings, important labels

  // === Border Radii ===
  // radiusRatio allows user customization (deffault is 1.0)
  property int radiusXS: Math.round(8 * Settings.data.general.radiusRatio)   // Small chips, icon buttons (non-pill)
  property int radiusS: Math.round(12 * Settings.data.general.radiusRatio)   // Standard buttons, inputs, list items
  property int radiusM: Math.round(16 * Settings.data.general.radiusRatio)   // Cards, containers, tooltips
  property int radiusL: Math.round(20 * Settings.data.general.radiusRatio)   // Large panels, dialogs
  property int radiusXL: Math.round(28 * Settings.data.general.radiusRatio)  // Extra large containers (rare)

  // === Borders (Minimal) ===
  property int borderS: Math.max(1, Math.round(1 * uiScaleRatio))  // Subtle definition
  property int borderM: Math.max(1, Math.round(2 * uiScaleRatio))  // Emphasis (focused states)
  property int borderL: Math.max(1, Math.round(3 * uiScaleRatio))  // Strong accent

  // === Spacing ===
  property int marginXXS: Math.round(4 * uiScaleRatio)   // Icon gaps
  property int marginXS: Math.round(8 * uiScaleRatio)    // List items
  property int marginS: Math.round(12 * uiScaleRatio)    // Button padding
  property int marginM: Math.round(16 * uiScaleRatio)    // Card padding
  property int marginL: Math.round(20 * uiScaleRatio)    // Panel padding
  property int marginXL: Math.round(24 * uiScaleRatio)   // Section gaps
  property int marginXXL: Math.round(32 * uiScaleRatio)  // Screen edges

  // === Opacity ===
  property real opacityDisabled: 0.38  // Disabled state
  property real opacityMedium: 0.60    // Dimmed elements
  property real opacityHigh: 0.87      // High emphasis
  property real opacityFull: 1.0       // Solid elements
  property real opacityHover: 0.08     // Hover state layer
  property real opacityFocus: 0.12     // Focus/pressed state layer
  property real opacityDragged: 0.16   // Dragged state layer
  property real opacityScrim: 0.32     // Scrim

  // === Animation ===
  property int animationFast: Settings.data.general.animationDisabled ? 0 : Math.round(100 / Settings.data.general.animationSpeed)
  property int animationNormal: Settings.data.general.animationDisabled ? 0 : Math.round(200 / Settings.data.general.animationSpeed)
  property int animationMedium: Settings.data.general.animationDisabled ? 0 : Math.round(300 / Settings.data.general.animationSpeed)
  property int animationSlow: Settings.data.general.animationDisabled ? 0 : Math.round(500 / Settings.data.general.animationSpeed)
  property int animationSlowest: Settings.data.general.animationDisabled ? 0 : Math.round(750 / Settings.data.general.animationSpeed)

  // === Delays ===
  property int tooltipDelay: 300
  property int tooltipDelayLong: 1200
  property int pillDelay: 500

  // === Widget Sizes ===
  property real baseWidgetSize: 40   
  property real sliderWidth: 200
  property real inputHeight: 56   

  property real uiScaleRatio: Settings.data.general.scaleRatio

  // === Bar Dimensions ===
  property real barHeight: {
    switch (Settings.data.bar.density) {
      case "mini":
        return (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 22 : 20
      case "compact":
        return (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 27 : 25
      case "comfortable":
        return (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 39 : 37
      default:
      case "default":
        return (Settings.data.bar.position === "left" || Settings.data.bar.position === "right") ? 33 : 31
    }
  }

  property real capsuleHeight: {
    switch (Settings.data.bar.density) {
      case "mini":
        return barHeight * 1.0
      case "compact":
        return barHeight * 0.85
      case "comfortable":
        return barHeight * 0.73
      default:
      case "default":
        return barHeight * 0.82
    }
  }
}
