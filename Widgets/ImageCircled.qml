import QtQuick

/**
 * ImageCircled - Circular image
 *
 * A circular image component, extends ImageRounded with circular radius.
 * Perfect for profile pictures, app icons, etc.
 *
 * Features:
 * - Circular mask (radius = width / 2)
 * - Async image loading
 * - Fallback icon support
 * - Border support
 * - Per-screen scaling support
 *
 * Usage:
 *   ImageCircled {
 *       width: 64
 *       height: 64
 *       imagePath: "/path/to/profile.png"
 *       borderColor: Color.mPrimary
 *       borderWidth: 2
 *       fallbackIcon: "󰀄"
 *   }
 */
ImageRounded {
    id: root

    // Override radius to be circular
    imageRadius: width * 0.5

    // Ensure square dimensions for perfect circle
    implicitWidth: 64
    implicitHeight: 64
}
