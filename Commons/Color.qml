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

  // --- Surface and Variant Colors: These provide additional options for surfaces and their contents
  property color mSurface: "#ffffff"
  property color mOnSurface: "#000000"

  property color mSurfaceVariant: "#cccccc"
  property color mOnSurfaceVariant: "#333333"

  property color mOutline: "#444444"
  property color mShadow: "#000000"

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
      property color mPrimary
      property color mOnPrimary
      property color mSecondary
      property color mOnSecondary
      property color mTertiary
      property color mOnTertiary
      property color mError
      property color mOnError
      property color mSurface
      property color mOnSurface
      property color mSurfaceVariant
      property color mOnSurfaceVariant
      property color mOutline
      property color mShadow
    }

    onLoaded: {
      // Copy from adapter to root properties for reactivity
      root.mPrimary = adapter.mPrimary
      root.mOnPrimary = adapter.mOnPrimary
      root.mSecondary = adapter.mSecondary
      root.mOnSecondary = adapter.mOnSecondary
      root.mTertiary = adapter.mTertiary
      root.mOnTertiary = adapter.mOnTertiary
      root.mError = adapter.mError
      root.mOnError = adapter.mOnError
      root.mSurface = adapter.mSurface
      root.mOnSurface = adapter.mOnSurface
      root.mSurfaceVariant = adapter.mSurfaceVariant
      root.mOnSurfaceVariant = adapter.mOnSurfaceVariant
      root.mOutline = adapter.mOutline
      root.mShadow = adapter.mShadow
      
      Logger.d("Color", "Colors loaded from colors.json")
    }
    
    onLoadFailed: function(error) {
      // File doesn't exist yet (first run) - will be created by ColorSchemeService
      Logger.d("Color", "colors.json not found (will be created on first scheme application)")
    }
  }
}
