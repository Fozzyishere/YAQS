pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // === Material Design 3 Color Properties ===
  
  // --- Key Colors: These are the main accent colors that define your app's style
  property color mPrimary: "#000000"
  property color mOnPrimary: "#ffffff"
  property color mSecondary: "#000000"
  property color mOnSecondary: "#ffffff"
  property color mTertiary: "#000000"
  property color mOnTertiary: "#ffffff"

  // --- Utility Colors: These colors serve specific, universal purposes like indicating errors
  property color mError: "#ff0000"
  property color mOnError: "#ffffff"

  // --- Container Colors: Subtle versions of accent colors for backgrounds
  property color mPrimaryContainer: "#d0e0ff"
  property color mOnPrimaryContainer: "#001849"
  property color mSecondaryContainer: "#e0e0e0"
  property color mOnSecondaryContainer: "#1a1a1a"
  property color mTertiaryContainer: "#ffe0f0"
  property color mOnTertiaryContainer: "#2d0019"
  property color mErrorContainer: "#ffdad6"
  property color mOnErrorContainer: "#410002"

  // --- Surface and Variant Colors: These provide additional options for surfaces and their contents
  property color mSurface: "#ffffff"
  property color mOnSurface: "#000000"

  property color mSurfaceVariant: "#cccccc"
  property color mOnSurfaceVariant: "#333333"

  // --- Surface Container Hierarchy (elevation levels)
  property color mSurfaceContainerLowest: "#ffffff"
  property color mSurfaceContainerLow: "#f7f7f7"
  property color mSurfaceContainer: "#eeeeee"
  property color mSurfaceContainerHigh: "#e6e6e6"
  property color mSurfaceContainerHighest: "#dddddd"

  property color mOutline: "#444444"
  property color mOutlineVariant: "#888888"
  property color mShadow: "#000000"
  property color mScrim: "#000000"

  // --- Convenience Aliases ---
  readonly property color primary: mPrimary
  readonly property color text: mOnSurface
  readonly property color textSecondary: mOnSurfaceVariant
  readonly property color background: mSurface
  readonly property color border: mOutline
  
  property color transparent: "transparent"

  // === FileView: Load colors from colors.json ===
  FileView {
    id: colorsFile
    path: Settings.configDir + "colors.json"
    watchChanges: true
    onFileChanged: reload()

    JsonAdapter {
      id: adapter
      property string mPrimary
      property string mOnPrimary
      property string mSecondary
      property string mOnSecondary
      property string mTertiary
      property string mOnTertiary
      property string mError
      property string mOnError
      property string mPrimaryContainer
      property string mOnPrimaryContainer
      property string mSecondaryContainer
      property string mOnSecondaryContainer
      property string mTertiaryContainer
      property string mOnTertiaryContainer
      property string mErrorContainer
      property string mOnErrorContainer
      property string mSurface
      property string mOnSurface
      property string mSurfaceVariant
      property string mOnSurfaceVariant
      property string mSurfaceContainerLowest
      property string mSurfaceContainerLow
      property string mSurfaceContainer
      property string mSurfaceContainerHigh
      property string mSurfaceContainerHighest
      property string mOutline
      property string mOutlineVariant
      property string mShadow
      property string mScrim
    }

    onLoaded: {
      // Copy from adapter to root properties
      // QML automatically converts string hex colors to color type when assigned to color properties
      root.mPrimary = adapter.mPrimary || root.mPrimary
      root.mOnPrimary = adapter.mOnPrimary || root.mOnPrimary
      root.mSecondary = adapter.mSecondary || root.mSecondary
      root.mOnSecondary = adapter.mOnSecondary || root.mOnSecondary
      root.mTertiary = adapter.mTertiary || root.mTertiary
      root.mOnTertiary = adapter.mOnTertiary || root.mOnTertiary
      root.mError = adapter.mError || root.mError
      root.mOnError = adapter.mOnError || root.mOnError
      root.mPrimaryContainer = adapter.mPrimaryContainer || root.mPrimaryContainer
      root.mOnPrimaryContainer = adapter.mOnPrimaryContainer || root.mOnPrimaryContainer
      root.mSecondaryContainer = adapter.mSecondaryContainer || root.mSecondaryContainer
      root.mOnSecondaryContainer = adapter.mOnSecondaryContainer || root.mOnSecondaryContainer
      root.mTertiaryContainer = adapter.mTertiaryContainer || root.mTertiaryContainer
      root.mOnTertiaryContainer = adapter.mOnTertiaryContainer || root.mOnTertiaryContainer
      root.mErrorContainer = adapter.mErrorContainer || root.mErrorContainer
      root.mOnErrorContainer = adapter.mOnErrorContainer || root.mOnErrorContainer
      root.mSurface = adapter.mSurface || root.mSurface
      root.mOnSurface = adapter.mOnSurface || root.mOnSurface
      root.mSurfaceVariant = adapter.mSurfaceVariant || root.mSurfaceVariant
      root.mOnSurfaceVariant = adapter.mOnSurfaceVariant || root.mOnSurfaceVariant
      root.mSurfaceContainerLowest = adapter.mSurfaceContainerLowest || root.mSurfaceContainerLowest
      root.mSurfaceContainerLow = adapter.mSurfaceContainerLow || root.mSurfaceContainerLow
      root.mSurfaceContainer = adapter.mSurfaceContainer || root.mSurfaceContainer
      root.mSurfaceContainerHigh = adapter.mSurfaceContainerHigh || root.mSurfaceContainerHigh
      root.mSurfaceContainerHighest = adapter.mSurfaceContainerHighest || root.mSurfaceContainerHighest
      root.mOutline = adapter.mOutline || root.mOutline
      root.mOutlineVariant = adapter.mOutlineVariant || root.mOutlineVariant
      root.mShadow = adapter.mShadow || root.mShadow
      root.mScrim = adapter.mScrim || root.mScrim
      
      Logger.d("Color", "Colors loaded from colors.json")
    }
    
    onLoadFailed: function(error) {
      // File doesn't exist yet (first run) - will be created by ColorSchemeService
      Logger.d("Color", "colors.json not found (will be created on first scheme application)")
    }
  }
}
