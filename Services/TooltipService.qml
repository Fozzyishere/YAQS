pragma Singleton

import QtQuick
import qs.Commons
import qs.Modules.Tooltip

QtObject {
    id: root

    property var activeTooltip: null
    property var pendingTooltip: null
    property bool initialized: false

    property Component tooltipComponent: Component {
        Tooltip {}
    }

    // ===== Initialization =====
    function init() {
        if (initialized) {
            Logger.warn("TooltipService", "Already initialized");
            return;
        }

        Logger.log("TooltipService", "Initializing...");
        // TooltipService is passive - tooltips are created on demand
        initialized = true;
        Logger.log("TooltipService", "Initialization complete");
    }

    function show(target, text, delay) {
        if (!target || !text) {
            return;
        }

        // Cancel pending tooltip for different target
        if (pendingTooltip && pendingTooltip.targetItem !== target) {
            pendingTooltip.hideImmediately();
            pendingTooltip.destroy();
            pendingTooltip = null;
        }

        // Hide active tooltip for different target
        if (activeTooltip && activeTooltip.targetItem !== target) {
            activeTooltip.hideImmediately();
            activeTooltip = null;
        }

        // Update existing tooltip for same target
        if (activeTooltip && activeTooltip.targetItem === target) {
            activeTooltip.updateText(text);
            return activeTooltip;
        }

        // Create new tooltip
        const newTooltip = tooltipComponent.createObject(null);

        if (newTooltip) {
            pendingTooltip = newTooltip;

            // Handle tooltip visibility changes
            newTooltip.visibleChanged.connect(() => {
                if (!newTooltip.visible) {
                    Qt.callLater(() => {
                        if (newTooltip && !newTooltip.visible) {
                            if (activeTooltip === newTooltip) {
                                activeTooltip = null;
                            }
                            if (pendingTooltip === newTooltip) {
                                pendingTooltip = null;
                            }
                            newTooltip.destroy();
                        }
                    });
                } else {
                    // Tooltip visible - move from pending to active
                    if (pendingTooltip === newTooltip) {
                        activeTooltip = newTooltip;
                        pendingTooltip = null;
                    }
                }
            });

            newTooltip.show(target, text, delay || 500);
            return newTooltip;
        } else {
            Logger.log("Tooltip", "Failed to create tooltip");
        }

        return null;
    }

    function hide() {
        if (pendingTooltip) {
            pendingTooltip.hide();
        }
        if (activeTooltip) {
            activeTooltip.hide();
        }
    }

    function hideImmediately() {
        if (pendingTooltip) {
            pendingTooltip.hideImmediately();
            pendingTooltip.destroy();
            pendingTooltip = null;
        }
        if (activeTooltip) {
            activeTooltip.hideImmediately();
            activeTooltip.destroy();
            activeTooltip = null;
        }
    }

    Component.onCompleted: {
        Logger.log("Tooltip", "Service initialized");
    }
}
