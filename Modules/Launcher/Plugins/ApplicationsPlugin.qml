// Applications Plugin for YAQS Launcher
// Handles application search, launching, favorites, and usage tracking

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import "../../../Helpers/fuzzysort.js" as Fuzzysort

Item {
    // ===== Plugin Interface =====
    property var launcher: null
    property string name: "Applications"
    property bool handleSearch: true  // Participates in regular search

    // ===== State =====
    property var applications: []
    property bool sortByMostUsed: Settings.data.launcher.sortByMostUsed

    // ===== Usage Tracking =====
    property string usageFilePath: Settings.cacheDir + "launcher_app_usage.json"

    // Debounced saver to avoid excessive IO
    Timer {
        id: saveUsageTimer
        interval: 750
        repeat: false
        onTriggered: usageFile.writeAdapter()
    }

    FileView {
        id: usageFile
        path: usageFilePath
        printErrors: false
        watchChanges: false

        onLoadFailed: function (error) {
            if (error.toString().includes("No such file") || error === 2) {
                writeAdapter()
            }
        }

        onAdapterUpdated: saveUsageTimer.start()

        JsonAdapter {
            id: usageAdapter
            property var counts: ({})
        }
    }

    // ===== Plugin Lifecycle =====
    function init() {
        loadApplications()
    }

    function onOpened() {
        loadApplications()
    }

    // ===== Application Loading =====
    function loadApplications() {
        applications = []

        if (typeof DesktopEntries === 'undefined') {
            Logger.error("ApplicationsPlugin", "DesktopEntries not available")
            return
        }

        // DesktopEntries.applications is an ObjectModel<DesktopEntry>
        const allApps = DesktopEntries.applications.values || []

        // Filter out apps that shouldn't be displayed
        for (let i = 0; i < allApps.length; i++) {
            const app = allApps[i]
            if (app && !app.noDisplay && app.name) {
                applications.push(app)
            }
        }

        Logger.log("ApplicationsPlugin", "Loaded", applications.length, "applications")
    }

    // ===== Usage Tracking Helpers =====
    function getAppKey(app) {
        if (app && app.id)
            return String(app.id)
        if (app && app.command && app.command.join)
            return app.command.join(" ")
        return String(app && app.name ? app.name : "unknown")
    }

    function getUsageCount(app) {
        const key = getAppKey(app)
        const counts = usageAdapter && usageAdapter.counts ? usageAdapter.counts : null
        if (!counts)
            return 0
        const value = counts[key]
        return typeof value === 'number' && isFinite(value) ? value : 0
    }

    function recordUsage(app) {
        if (!sortByMostUsed) return // Only track if most-used sorting is enabled

        const key = getAppKey(app)
        if (!usageAdapter.counts)
            usageAdapter.counts = ({})
        const current = getUsageCount(app)
        usageAdapter.counts[key] = current + 1
        // Trigger save via debounced timer
        saveUsageTimer.restart()
        Logger.log("ApplicationsPlugin", "Recorded usage for", app.name, "- count:", current + 1)
    }

    function isFavorite(app) {
        const favoriteApps = Settings.data.launcher.favoriteApps || []
        return favoriteApps.includes(getAppKey(app))
    }

    function toggleFavorite(app) {
        const key = getAppKey(app)
        let favorites = (Settings.data.launcher.favoriteApps || []).slice() // Copy array
        const index = favorites.indexOf(key)

        if (index >= 0) {
            // Remove from favorites
            favorites.splice(index, 1)
            Logger.log("ApplicationsPlugin", "Removed from favorites:", app.name)
        } else {
            // Add to favorites
            favorites.push(key)
            Logger.log("ApplicationsPlugin", "Added to favorites:", app.name)
        }

        Settings.data.launcher.favoriteApps = favorites

        // Trigger launcher to update results
        if (launcher && launcher.updateResults) {
            launcher.updateResults()
        }
    }

    function toggleSortMode() {
        sortByMostUsed = !sortByMostUsed
        Settings.data.launcher.sortByMostUsed = sortByMostUsed

        // Trigger launcher to update results
        if (launcher && launcher.updateResults) {
            launcher.updateResults()
        }

        Logger.log("ApplicationsPlugin", "Sort mode changed to:", sortByMostUsed ? "most-used" : "alphabetical")
    }

    // ===== Search & Filtering =====
    function getResults(query) {
        if (!applications || applications.length === 0) {
            return []
        }

        const q = query.trim()
        const favoriteApps = Settings.data.launcher.favoriteApps || []

        if (!q) {
            // Show all apps, sorted based on user preference
            let sorted
            if (sortByMostUsed) {
                sorted = applications.slice().sort((a, b) => {
                    // Favorites first
                    const aFav = favoriteApps.includes(getAppKey(a))
                    const bFav = favoriteApps.includes(getAppKey(b))
                    if (aFav !== bFav)
                        return aFav ? -1 : 1

                    // Then by usage count
                    const usageA = getUsageCount(a)
                    const usageB = getUsageCount(b)
                    if (usageB !== usageA)
                        return usageB - usageA // Most used first

                    // Finally alphabetically
                    return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
                })
            } else {
                sorted = applications.slice().sort((a, b) => {
                    // Favorites first even in alphabetical mode
                    const aFav = favoriteApps.includes(getAppKey(a))
                    const bFav = favoriteApps.includes(getAppKey(b))
                    if (aFav !== bFav)
                        return aFav ? -1 : 1

                    return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
                })
            }
            return sorted.map(app => createResultEntry(app))
        } else {
            // Fuzzy search
            try {
                // Search across multiple fields
                const results = Fuzzysort.go(q, applications, {
                    keys: ['name', 'genericName', 'keywords', 'comment'],
                    limit: Settings.data.launcher.maxResults,
                    threshold: -10000
                })

                return results.length > 0 ? results.map(result => createResultEntry(result.obj)) : []
            } catch (e) {
                Logger.error("ApplicationsPlugin", "Fuzzysort failed:", e)
                return simpleSearch(q).map(app => createResultEntry(app))
            }
        }
    }

    // Fallback simple search if fuzzysort fails
    function simpleSearch(query) {
        const lowerQuery = String(query || '').toLowerCase()

        return applications.filter(app => {
            const name = String(app.name || '').toLowerCase()
            const genericName = String(app.genericName || '').toLowerCase()
            const keywords = String(app.keywords || '').toLowerCase()
            const comment = String(app.comment || '').toLowerCase()

            return name.includes(lowerQuery) ||
                   genericName.includes(lowerQuery) ||
                   keywords.includes(lowerQuery) ||
                   comment.includes(lowerQuery)
        }).sort((a, b) => {
            const aName = String(a.name || '').toLowerCase()
            const bName = String(b.name || '').toLowerCase()
            return aName.localeCompare(bName)
        })
    }

    // ===== Result Entry Creation =====
    function createResultEntry(app) {
        return {
            name: app.name || "Unknown",
            description: app.comment || app.genericName || "",
            icon: app.icon || "application-x-executable",
            isImage: false,
            appId: getAppKey(app),
            isFavorite: isFavorite(app),
            onActivate: function() {
                launchApp(app)
            },
            onToggleFavorite: function() {
                toggleFavorite(app)
            }
        }
    }

    // ===== Launch Application =====
    function launchApp(app) {
        if (!app) return

        try {
            Logger.log("ApplicationsPlugin", "Launching:", app.name)

            // Record usage for most-used sorting
            recordUsage(app)

            if (Settings.data.launcher.useApp2Unit && app.id) {
                // Use app2unit for systemd unit launching
                Logger.log("ApplicationsPlugin", "Using app2unit for:", app.id)
                if (app.runInTerminal) {
                    Quickshell.execDetached(["app2unit", "--", app.id + ".desktop"])
                } else {
                    Quickshell.execDetached(["app2unit", "--"].concat(app.command))
                }
            } else {
                // Fallback logic when app2unit is not used
                if (app.runInTerminal) {
                    // Handle terminal apps manually
                    Logger.log("ApplicationsPlugin", "Executing terminal app manually:", app.name)
                    const terminal = Settings.data.launcher.terminalCommand.split(" ")
                    const command = terminal.concat(app.command)
                    Quickshell.execDetached({
                        command: command,
                        workingDirectory: app.workingDirectory
                    })
                } else if (app.execute) {
                    // Default execution for GUI apps
                    app.execute()
                } else {
                    Logger.warn("ApplicationsPlugin", "Could not launch:", app.name, "- No valid launch method")
                }
            }

            // Close launcher
            if (launcher && launcher.close) {
                launcher.close()
            }
        } catch (e) {
            Logger.error("ApplicationsPlugin", "Failed to launch", app.name, ":", e)
        }
    }
}
