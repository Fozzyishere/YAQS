pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  // --- Key Colors: These are the main accent colors that define your app's style
  property color mPrimary: "transparent"
  property color mOnPrimary: "transparent"
  property color mSecondary: "transparent"
  property color mOnSecondary: "transparent"
  property color mTertiary: "transparent"
  property color mOnTertiary: "transparent"

  // --- Utility Colors: These colors serve specific, universal purposes like indicating errors
  property color mError: "transparent"
  property color mOnError: "transparent"

  // --- Surface and Variant Colors: These provide additional options for surfaces and their contents
  property color mSurface: "transparent"
  property color mOnSurface: "transparent"

  property color mSurfaceVariant: "transparent"
  property color mOnSurfaceVariant: "transparent"

  property color mOutline: "transparent"
  property color mShadow: "transparent"

  property color transparent: "transparent"
}
