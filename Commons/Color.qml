pragma Singleton

import QtQuick
import Quickshell

// Material Design 3 Dark Color Scheme (Subdued for Desktop Shell)
QtObject {
    id: root

    // Primary colors - Muted blue/purple  
    readonly property color mPrimary: "#8EC07C"           // Gruvbox aqua (primary accent)
    readonly property color mOnPrimary: "#1D2021"         // Dark on bright accent
    readonly property color mPrimaryContainer: "#689D6A"  // Darker aqua container
    readonly property color mOnPrimaryContainer: "#FBF1C7" // Light on dark container

    // Secondary colors - Muted teal
    readonly property color mSecondary: "#FABD2F"         // Gruvbox yellow
    readonly property color mOnSecondary: "#1D2021"       
    readonly property color mSecondaryContainer: "#D79921"
    readonly property color mOnSecondaryContainer: "#FBF1C7"

    // Tertiary colors - Muted pink
    readonly property color mTertiary: "#D3869B"          // Gruvbox purple/pink
    readonly property color mOnTertiary: "#1D2021"        
    readonly property color mTertiaryContainer: "#B16286" 
    readonly property color mOnTertiaryContainer: "#FBF1C7"

    // Error colors
    readonly property color mError: "#FB4934"             // Gruvbox bright red
    readonly property color mOnError: "#1D2021"           
    readonly property color mErrorContainer: "#CC241D"    // Gruvbox dark red
    readonly property color mOnErrorContainer: "#FBF1C7"

    // Surface colors - Dark theme
    readonly property color mSurface: "#282828"           // Gruvbox bg0
    readonly property color mOnSurface: "#EBDBB2"         // Gruvbox light1
    readonly property color mSurfaceVariant: "#3C3836"    // Gruvbox bg1
    readonly property color mOnSurfaceVariant: "#A89984"  // Gruvbox light4
    readonly property color mSurfaceContainer: "#32302F"  // Gruvbox bg0_s
    readonly property color mSurfaceContainerLow: "#1D2021"      // Gruvbox bg0_h
    readonly property color mSurfaceContainerHigh: "#3C3836"     // Gruvbox bg1
    readonly property color mSurfaceContainerHighest: "#504945"  // Gruvbox bg2

    // Outline colors
    readonly property color mOutline: "#665C54"           // Gruvbox bg3
    readonly property color mOutlineVariant: "#504945"    // Gruvbox bg2
    readonly property color mShadow: "#000000"            

    // Extension: Success color
    readonly property color mSuccess: "#B8BB26"           // Gruvbox bright green
    readonly property color mOnSuccess: "#1D2021"
    readonly property color mSuccessContainer: "#98971A"  // Gruvbox dark green
    readonly property color mOnSuccessContainer: "#FBF1C7"

    // Extension: Warning color
    readonly property color mWarning: "#FE8019"           // Gruvbox orange
    readonly property color mOnWarning: "#1D2021"
    readonly property color mWarningContainer: "#D65D0E"  // Dark orange
    readonly property color mOnWarningContainer: "#FBF1C7"

    // Utility colors
    readonly property color transparent: "transparent"
    readonly property color white: "#FFFFFF"
    readonly property color black: "#000000"
}
