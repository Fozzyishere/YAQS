pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Cache for current scales: { "screen-name": 1.0 }
    property var screenScales: ({})

    // Signal emitted when scale changes
    signal scaleChanged(string screenName, real scale)

    Component.onCompleted: {
        Logger.log("Scaling", "Initialized");
    }

    /**
   * Get scale for a screen (auto-detect from devicePixelRatio or use cached override)
   *
   * Auto-detection logic:
   * - Uses ShellScreen.devicePixelRatio as base
   * - Rounds to nearest 0.25 increment for UI consistency
   * - Falls back to 1.0 if screen is invalid
   *
   * @param screen - ShellScreen object
   * @return real - Scaling factor (e.g., 1.0, 1.25, 1.5, 2.0)
   */
    function getScreenScale(screen) {
        if (!screen || !screen.name) {
            return 1.0;
        }

        // Check cache first (manual overrides)
        if (screenScales[screen.name] !== undefined) {
            return screenScales[screen.name];
        }

        // Auto-detect from devicePixelRatio
        // devicePixelRatio: ratio between physical pixels and device-independent pixels
        // 1.0 = standard DPI (96), 2.0 = HiDPI/Retina (192 DPI)
        const ratio = screen.devicePixelRatio || 1.0;

        // Round to nearest 0.25 increment (1.0, 1.25, 1.5, 1.75, 2.0, etc.)
        const scale = Math.round(ratio * 4) / 4;

        // Cache auto-detected value
        screenScales[screen.name] = scale;

        Logger.log("Scaling", `Screen "${screen.name}" auto-detected: devicePixelRatio=${ratio}, scale=${scale}`);

        return scale;
    }

    /**
   * Manually set scale for a screen (overrides auto-detection)
   *
   * Useful for per-monitor customization when auto-detection isn't ideal.
   * Changes are stored in memory only (not persisted to disk in minimalist version).
   *
   * @param screenName - Screen name (e.g., "DP-1", "HDMI-1")
   * @param scale - Desired scaling factor
   */
    function setScreenScale(screenName, scale) {
        if (!screenName) {
            Logger.warn("Scaling", "setScreenScale called with invalid screenName");
            return;
        }

        // Check if scale actually changed
        const oldScale = screenScales[screenName] || 1.0;
        if (oldScale === scale) {
            // No change needed
            return;
        }

        // Update cache
        screenScales[screenName] = scale;

        // Emit signal for components to react
        scaleChanged(screenName, scale);

        Logger.log("Scaling", `Manual override for "${screenName}": ${oldScale} → ${scale}`);
    }

    /**
   * Get scale by screen name (for cache lookups)
   *
   * @param screenName - Screen name
   * @return real - Cached scale or 1.0 if not found
   */
    function getScreenScaleByName(screenName) {
        if (!screenName) {
            return 1.0;
        }
        return screenScales[screenName] || 1.0;
    }

    /**
   * Reset scale for a screen to auto-detected value
   *
   * @param screen - ShellScreen object
   */
    function resetScreenScale(screen) {
        if (!screen || !screen.name) {
            return;
        }

        // Remove from cache to force re-detection
        delete screenScales[screen.name];

        // Recalculate
        const newScale = getScreenScale(screen);

        // Emit signal
        scaleChanged(screen.name, newScale);

        Logger.log("Scaling", `Reset scale for "${screen.name}" to auto-detected: ${newScale}`);
    }
}
