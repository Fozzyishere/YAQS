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
      property string mPrimary
      property string mOnPrimary
      property string mSecondary
      property string mOnSecondary
      property string mTertiary
      property string mOnTertiary
      property string mError
      property string mOnError
      property string mSurface
      property string mOnSurface
      property string mSurfaceVariant
      property string mOnSurfaceVariant
      property string mOutline
      property string mShadow
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
      root.mSurface = adapter.mSurface || root.mSurface
      root.mOnSurface = adapter.mOnSurface || root.mOnSurface
      root.mSurfaceVariant = adapter.mSurfaceVariant || root.mSurfaceVariant
      root.mOnSurfaceVariant = adapter.mOnSurfaceVariant || root.mOnSurfaceVariant
      root.mOutline = adapter.mOutline || root.mOutline
      root.mShadow = adapter.mShadow || root.mShadow
      
      Logger.d("Color", "Colors loaded from colors.json")
    }
    
    onLoadFailed: function(error) {
      // File doesn't exist yet (first run) - will be created by ColorSchemeService
      Logger.d("Color", "colors.json not found (will be created on first scheme application)")
    }
  }
}
