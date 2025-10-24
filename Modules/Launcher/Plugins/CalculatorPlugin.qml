// Calculator Plugin for YAQS Launcher
// Provides mathematical expression evaluation with 50+ functions

import QtQuick
import qs.Commons
import qs.Services
import "../../../Helpers/MathEvaluator.js" as MathEvaluator

Item {
    // ===== Plugin Interface =====
    property var launcher: null
    property string name: "Calculator"
    property bool handleSearch: false  // Only command mode, not regular search

    // ===== Plugin Lifecycle =====
    function handleCommand(query) {
        // Handle >calc command or direct math expressions after >
        return query.startsWith(">calc") ||
               (query.startsWith(">") && query.length > 1 && MathEvaluator.isMathExpression(query.substring(1)))
    }

    function commands() {
        return [{
            "name": ">calc",
            "description": "Calculate mathematical expressions",
            "icon": "accessories-calculator",
            "isImage": false,
            "onActivate": function() {
                launcher.setSearchText(">calc ")
            }
        }]
    }

    function getResults(query) {
        var expression = ""

        // Extract expression from query
        if (query.startsWith(">calc")) {
            expression = query.substring(5).trim()
        } else if (query.startsWith(">")) {
            expression = query.substring(1).trim()
        } else {
            return []
        }

        // Show prompt if no expression entered
        if (!expression) {
            return [{
                "name": "Calculator",
                "description": "Enter a mathematical expression to calculate",
                "icon": "accessories-calculator",
                "isImage": false,
                "onActivate": function() {}
            }]
        }

        // Try to evaluate the expression
        try {
            var result = MathEvaluator.evaluate(expression.trim())
            var formattedResult = MathEvaluator.formatResult(result)

            return [{
                "name": formattedResult,
                "description": expression + " = " + result,
                "icon": "accessories-calculator",
                "isImage": false,
                "onActivate": function() {
                    // TODO: Copy result to clipboard when ClipboardService is ready
                    // For now, just close the launcher
                    launcher.close()
                }
            }]
        } catch (error) {
            // Show error message
            var errorMsg = error.message || "Invalid expression"

            return [{
                "name": "Error",
                "description": errorMsg,
                "icon": "dialog-error",
                "isImage": false,
                "onActivate": function() {}
            }]
        }
    }
}
