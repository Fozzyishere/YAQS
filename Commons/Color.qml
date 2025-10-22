pragma Singleton

import QtQuick
import Quickshell

/**
 * Color - Material Design 3 color tokens (singleton)
 *
 * Uses backing properties to prevent accidental mutations
 * while still allowing runtime updates from MatugenService.
 *
 * Pattern:
 * - Internal _mPrimary (mutable) - only this file can write
 * - Public mPrimary (readonly) - widgets can only read
 * - updateFromMatugen() - controlled update function
 *
 * Note: Follows Material Design 3 spec exactly.
 * - For success states, use mTertiary
 * - For warning/caution states, use mSecondary
 * - For error/destructive states, use mError
 */
QtObject {
    id: root

    // ============================================================================
    // INTERNAL BACKING PROPERTIES
    // ============================================================================

    // Primary colors (internal)
    property color _mPrimary: "#8EC07C"
    property color _mOnPrimary: "#1D2021"
    property color _mPrimaryContainer: "#689D6A"
    property color _mOnPrimaryContainer: "#FBF1C7"

    // Secondary colors (internal)
    property color _mSecondary: "#FABD2F"
    property color _mOnSecondary: "#1D2021"
    property color _mSecondaryContainer: "#D79921"
    property color _mOnSecondaryContainer: "#FBF1C7"

    // Tertiary colors (internal)
    property color _mTertiary: "#D3869B"
    property color _mOnTertiary: "#1D2021"
    property color _mTertiaryContainer: "#B16286"
    property color _mOnTertiaryContainer: "#FBF1C7"

    // Error colors (internal)
    property color _mError: "#FB4934"
    property color _mOnError: "#1D2021"
    property color _mErrorContainer: "#CC241D"
    property color _mOnErrorContainer: "#FBF1C7"

    // Background/Surface colors (internal)
    property color _mBackground: "#1D2021"
    property color _mOnBackground: "#EBDBB2"
    property color _mSurface: "#282828"
    property color _mOnSurface: "#EBDBB2"
    property color _mSurfaceVariant: "#3C3836"
    property color _mOnSurfaceVariant: "#A89984"
    property color _mSurfaceContainer: "#32302F"
    property color _mSurfaceContainerLow: "#282828"
    property color _mSurfaceContainerHigh: "#3C3836"
    property color _mSurfaceContainerHighest: "#504945"

    // Outline colors (internal)
    property color _mOutline: "#665C54"
    property color _mOutlineVariant: "#504945"
    property color _mShadow: "#000000"

    // ============================================================================
    // PUBLIC READONLY INTERFACE (Widgets can only read)
    // ============================================================================

    // Primary colors (public readonly)
    readonly property color mPrimary: _mPrimary
    readonly property color mOnPrimary: _mOnPrimary
    readonly property color mPrimaryContainer: _mPrimaryContainer
    readonly property color mOnPrimaryContainer: _mOnPrimaryContainer

    // Secondary colors (public readonly)
    readonly property color mSecondary: _mSecondary
    readonly property color mOnSecondary: _mOnSecondary
    readonly property color mSecondaryContainer: _mSecondaryContainer
    readonly property color mOnSecondaryContainer: _mOnSecondaryContainer

    // Tertiary colors (public readonly)
    readonly property color mTertiary: _mTertiary
    readonly property color mOnTertiary: _mOnTertiary
    readonly property color mTertiaryContainer: _mTertiaryContainer
    readonly property color mOnTertiaryContainer: _mOnTertiaryContainer

    // Error colors (public readonly)
    readonly property color mError: _mError
    readonly property color mOnError: _mOnError
    readonly property color mErrorContainer: _mErrorContainer
    readonly property color mOnErrorContainer: _mOnErrorContainer

    // Background/Surface colors (public readonly)
    readonly property color mBackground: _mBackground
    readonly property color mOnBackground: _mOnBackground
    readonly property color mSurface: _mSurface
    readonly property color mOnSurface: _mOnSurface
    readonly property color mSurfaceVariant: _mSurfaceVariant
    readonly property color mOnSurfaceVariant: _mOnSurfaceVariant
    readonly property color mSurfaceContainer: _mSurfaceContainer
    readonly property color mSurfaceContainerLow: _mSurfaceContainerLow
    readonly property color mSurfaceContainerHigh: _mSurfaceContainerHigh
    readonly property color mSurfaceContainerHighest: _mSurfaceContainerHighest

    // Outline colors (public readonly)
    readonly property color mOutline: _mOutline
    readonly property color mOutlineVariant: _mOutlineVariant
    readonly property color mShadow: _mShadow

    // Utility colors (always readonly)
    readonly property color transparent: "transparent"
    readonly property color white: "#FFFFFF"
    readonly property color black: "#000000"

    // ============================================================================
    // SIGNALS
    // ============================================================================

    signal colorsChanged()

    // ============================================================================
    // CONTROLLED UPDATE FUNCTION (Only way to modify colors)
    // ============================================================================

    function updateFromMatugen(colorsObject) {
        Logger.log("Color", "Updating colors from matugen")

        // Only update if new value provided (fallback to current value)
        _mPrimary = colorsObject.mPrimary ?? _mPrimary
        _mOnPrimary = colorsObject.mOnPrimary ?? _mOnPrimary
        _mPrimaryContainer = colorsObject.mPrimaryContainer ?? _mPrimaryContainer
        _mOnPrimaryContainer = colorsObject.mOnPrimaryContainer ?? _mOnPrimaryContainer

        _mSecondary = colorsObject.mSecondary ?? _mSecondary
        _mOnSecondary = colorsObject.mOnSecondary ?? _mOnSecondary
        _mSecondaryContainer = colorsObject.mSecondaryContainer ?? _mSecondaryContainer
        _mOnSecondaryContainer = colorsObject.mOnSecondaryContainer ?? _mOnSecondaryContainer

        _mTertiary = colorsObject.mTertiary ?? _mTertiary
        _mOnTertiary = colorsObject.mOnTertiary ?? _mOnTertiary
        _mTertiaryContainer = colorsObject.mTertiaryContainer ?? _mTertiaryContainer
        _mOnTertiaryContainer = colorsObject.mOnTertiaryContainer ?? _mOnTertiaryContainer

        _mError = colorsObject.mError ?? _mError
        _mOnError = colorsObject.mOnError ?? _mOnError
        _mErrorContainer = colorsObject.mErrorContainer ?? _mErrorContainer
        _mOnErrorContainer = colorsObject.mOnErrorContainer ?? _mOnErrorContainer

        _mBackground = colorsObject.mBackground ?? _mBackground
        _mOnBackground = colorsObject.mOnBackground ?? _mOnBackground
        _mSurface = colorsObject.mSurface ?? _mSurface
        _mOnSurface = colorsObject.mOnSurface ?? _mOnSurface
        _mSurfaceVariant = colorsObject.mSurfaceVariant ?? _mSurfaceVariant
        _mOnSurfaceVariant = colorsObject.mOnSurfaceVariant ?? _mOnSurfaceVariant
        _mSurfaceContainer = colorsObject.mSurfaceContainer ?? _mSurfaceContainer
        _mSurfaceContainerLow = colorsObject.mSurfaceContainerLow ?? _mSurfaceContainerLow
        _mSurfaceContainerHigh = colorsObject.mSurfaceContainerHigh ?? _mSurfaceContainerHigh
        _mSurfaceContainerHighest = colorsObject.mSurfaceContainerHighest ?? _mSurfaceContainerHighest

        _mOutline = colorsObject.mOutline ?? _mOutline
        _mOutlineVariant = colorsObject.mOutlineVariant ?? _mOutlineVariant
        _mShadow = colorsObject.mShadow ?? _mShadow

        colorsChanged()
        Logger.log("Color", "Colors updated successfully")
    }

    function resetToDefaults() {
        Logger.log("Color", "Resetting to default Gruvbox Dark Hard colors")

        // Reset to Gruvbox Dark Hard
        _mPrimary = "#8EC07C"
        _mOnPrimary = "#1D2021"
        _mPrimaryContainer = "#689D6A"
        _mOnPrimaryContainer = "#FBF1C7"

        _mSecondary = "#FABD2F"
        _mOnSecondary = "#1D2021"
        _mSecondaryContainer = "#D79921"
        _mOnSecondaryContainer = "#FBF1C7"

        _mTertiary = "#D3869B"
        _mOnTertiary = "#1D2021"
        _mTertiaryContainer = "#B16286"
        _mOnTertiaryContainer = "#FBF1C7"

        _mError = "#FB4934"
        _mOnError = "#1D2021"
        _mErrorContainer = "#CC241D"
        _mOnErrorContainer = "#FBF1C7"

        _mBackground = "#1D2021"
        _mOnBackground = "#EBDBB2"
        _mSurface = "#282828"
        _mOnSurface = "#EBDBB2"
        _mSurfaceVariant = "#3C3836"
        _mOnSurfaceVariant = "#A89984"
        _mSurfaceContainer = "#32302F"
        _mSurfaceContainerLow = "#282828"
        _mSurfaceContainerHigh = "#3C3836"
        _mSurfaceContainerHighest = "#504945"

        _mOutline = "#665C54"
        _mOutlineVariant = "#504945"
        _mShadow = "#000000"

        colorsChanged()
        Logger.log("Color", "Reset to defaults complete")
    }
}
