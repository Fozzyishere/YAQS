import "../Commons" as QsCommons
import "../Helpers/sha256.js" as Checksum
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
pragma Singleton

Singleton {
    // { id: { timestamp, duration, urgency, paused, pauseTime } }

    id: root

    // === Configuration ===
    property int maxVisible: 5
    property int maxHistory: 100
    property string historyFile: Quickshell.env("YAQS_NOTIF_HISTORY_FILE") || (QsCommons.Settings.cacheDir + "notifications.json")
    property string stateFile: QsCommons.Settings.cacheDir + "notifications-state.json"
    
    // === Utility Functions for Internal Notifications ===
    // These functions allow YAQS services to send notifications through the D-Bus system
    function sendNotification(summary, body, urgency) {
        const urgencyLevel = urgency === "critical" ? 2 : (urgency === "low" ? 0 : 1)
        Quickshell.execDetached(["notify-send", 
                                 "-a", "YAQS",
                                 "-u", urgency || "normal",
                                 summary,
                                 body || ""])
    }
    
    function showNotice(summary, body) {
        sendNotification(summary, body, "normal")
    }
    
    function showWarning(summary, body) {
        sendNotification(summary, body, "normal")
    }
    
    function showError(summary, body) {
        sendNotification(summary, body, "critical")
    }
    
    // === State ===
    property real lastSeenTs: 0
    // === Models ===
    property ListModel activeList

    activeList: ListModel {
    }

    property ListModel historyList

    historyList: ListModel {
    }

    // === Internal State ===
    property var activeMap: ({
    })
    property var imageQueue: []
    // === Performance Optimization: Track notification metadata separately ===
    // Can't store complex data in ListModel, so we'll be using parallel object
    property var notificationMetadata: ({
    })

    // === Signals & Connections ===
    signal animateAndRemove(string notificationId)

    // === Main Handler ===
    function handleNotification(notification) {
        QsCommons.Logger.d("Notifications", "Received notification:", notification.summary);
        const data = createData(notification);
        addToHistory(data);
        if (QsCommons.Settings.data.notifications && QsCommons.Settings.data.notifications.doNotDisturb)
            return ;

        activeMap[data.id] = notification;
        notification.tracked = true;
        notification.closed.connect(() => {
            return removeActive(data.id);
        });
        // Storing metadata. Respect expireTimeout setting
        const durations = [(QsCommons.Settings.data.notifications && QsCommons.Settings.data.notifications.lowUrgencyDuration) * 1000 || 3000, (QsCommons.Settings.data.notifications && QsCommons.Settings.data.notifications.normalUrgencyDuration) * 1000 || 8000, (QsCommons.Settings.data.notifications && QsCommons.Settings.data.notifications.criticalUrgencyDuration) * 1000 || 15000];
        let expire = 0;
        if (QsCommons.Settings.data.notifications && QsCommons.Settings.data.notifications.respectExpireTimeout) {
            if (data.expireTimeout === 0)
                expire = -1; // Never expire
            else if (data.expireTimeout > 0)
                expire = data.expireTimeout;
            else
                expire = durations[data.urgency];
        } else {
            expire = durations[data.urgency];
        }
        notificationMetadata[data.id] = {
            "timestamp": data.timestamp.getTime(),
            "duration": expire,
            "urgency": data.urgency,
            "paused": false,
            "pauseTime": 0
        };
        activeList.insert(0, data);
        QsCommons.Logger.d("Notifications", "Added to active list (count:", activeList.count + ")");
        while (activeList.count > maxVisible) {
            const last = activeList.get(activeList.count - 1);
            if (activeMap[last.id])
                activeMap[last.id].dismiss();

            activeList.remove(activeList.count - 1);
            delete notificationMetadata[last.id];
        }
    }

    function createData(n) {
        const time = new Date();
        const id = Checksum.sha256(JSON.stringify({
            "summary": n.summary,
            "body": n.body,
            "app": n.appName,
            "time": time.getTime()
        }));
        const image = n.image || getIcon(n.appIcon);
        const imageId = generateImageId(n, image);
        queueImage(image, imageId);
        return {
            "id": id,
            "summary": (n.summary || ""),
            "body": stripTags(n.body || ""),
            "appName": getAppName(n.appName || n.desktopEntry || ""),
            "urgency": n.urgency < 0 || n.urgency > 2 ? 1 : n.urgency,
            "expireTimeout": n.expireTimeout,
            "timestamp": time,
            "progress": 1,
            "originalImage": image,
            "cachedImage": imageId ? (QsCommons.Settings.cacheDirImagesNotifications + imageId + ".png") : image,
            "actionsJson": JSON.stringify((n.actions || []).map((a) => {
                return ({
                    "text": a.text || "Action",
                    "identifier": a.identifier || ""
                });
            }))
        };
    }

    function queueImage(path, imageId) {
        if (!path || !path.startsWith("image://") || !imageId)
            return ;

        const dest = QsCommons.Settings.cacheDirImagesNotifications + imageId + ".png";
        for (const req of imageQueue) {
            if (req.imageId === imageId)
                return ;

        }
        imageQueue.push({
            "src": path,
            "dest": dest,
            "imageId": imageId
        });
        if (imageQueue.length === 1)
            cacher.source = path;

    }

    function updateImagePath(id, path) {
        updateModel(activeList, id, "cachedImage", path);
        updateModel(historyList, id, "cachedImage", path);
        saveHistory();
    }

    function updateModel(model, id, prop, value) {
        for (var i = 0; i < model.count; i++) {
            if (model.get(i).id === id) {
                model.setProperty(i, prop, value);
                break;
            }
        }
    }

    function removeActive(id) {
        for (var i = 0; i < activeList.count; i++) {
            if (activeList.get(i).id === id) {
                activeList.remove(i);
                delete activeMap[id];
                delete notificationMetadata[id];
                break;
            }
        }
    }

    function updateAllProgress() {
        const now = Date.now();
        const toRemove = [];
        const updates = []; // Batch updates
        // Collect all updates first
        for (var i = 0; i < activeList.count; i++) {
            const notif = activeList.get(i);
            const meta = notificationMetadata[notif.id];
            if (!meta || meta.duration === -1 || meta.paused)
                continue;

            const elapsed = now - meta.timestamp;
            const progress = Math.max(1 - (elapsed / meta.duration), 0);
            if (progress <= 0)
                toRemove.push(notif.id);
            else if (Math.abs(notif.progress - progress) > 0.005)
                // Only update if change is significant (0.5% threshold)
                updates.push({
                    "index": i,
                    "progress": progress
                });
        }
        // Apply batch updates
        for (const update of updates) {
            activeList.setProperty(update.index, "progress", update.progress);
        }
        // Remove expired notifications (one at a time to allow animation)
        if (toRemove.length > 0)
            animateAndRemove(toRemove[0]);

    }

    // === History Management ===
    function addToHistory(data) {
        historyList.insert(0, data);
        while (historyList.count > maxHistory) {
            const old = historyList.get(historyList.count - 1);
            if (old.cachedImage && !old.cachedImage.startsWith("image://"))
                Quickshell.execDetached(["rm", "-f", old.cachedImage]);

            historyList.remove(historyList.count - 1);
        }
        saveHistory();
    }

    function saveHistory() {
        saveTimer.restart();
    }

    function performSaveHistory() {
        try {
            const items = [];
            for (var i = 0; i < historyList.count; i++) {
                const n = historyList.get(i);
                const copy = Object.assign({
                }, n);
                copy.timestamp = n.timestamp.getTime();
                items.push(copy);
            }
            adapter.notifications = items;
            historyFileView.writeAdapter();
        } catch (e) {
            QsCommons.Logger.e("Notifications", "Save history failed:", e);
        }
    }

    function loadHistory() {
        try {
            historyList.clear();
            
            for (const item of adapter.notifications || []) {
                const time = new Date(item.timestamp);
                const cachedImage = resolveCachedImagePath(item);
                
                historyList.append({
                    "id": item.id || "",
                    "summary": item.summary || "",
                    "body": item.body || "",
                    "appName": item.appName || "",
                    "urgency": item.urgency < 0 || item.urgency > 2 ? 1 : item.urgency,
                    "timestamp": time,
                    "originalImage": item.originalImage || "",
                    "cachedImage": cachedImage
                });
            }
        } catch (e) {
            QsCommons.Logger.e("Notifications", "Load failed:", e);
        }
    }
    
    function resolveCachedImagePath(item) {
        // Already has cached image path
        if (item.cachedImage)
            return item.cachedImage;
        
        // No original image or not an image:// URL
        const originalImage = item.originalImage || "";
        if (!originalImage.startsWith("image://"))
            return "";
        
        // Generate cache path for image:// URLs
        const imageId = generateImageId(item, originalImage);
        if (!imageId)
            return "";
        
        return QsCommons.Settings.cacheDirImagesNotifications + imageId + ".png";
    }

    function loadState() {
        try {
            root.lastSeenTs = stateAdapter.lastSeenTs || 0;
            // Migration: if state file is empty but settings has lastSeenTs, migrate it
            if (root.lastSeenTs === 0 && QsCommons.Settings.data.notifications && QsCommons.Settings.data.notifications.lastSeenTs) {
                root.lastSeenTs = QsCommons.Settings.data.notifications.lastSeenTs;
                saveState();
                QsCommons.Logger.i("Notifications", "Migrated lastSeenTs from settings to state file");
            }
        } catch (e) {
            QsCommons.Logger.e("Notifications", "Load state failed:", e);
        }
    }

    function saveState() {
        try {
            stateAdapter.lastSeenTs = root.lastSeenTs;
            stateFileView.writeAdapter();
        } catch (e) {
            QsCommons.Logger.e("Notifications", "Save state failed:", e);
        }
    }

    function updateLastSeenTs() {
        root.lastSeenTs = QsCommons.Time.timestamp * 1000;
        saveState();
    }

    // === Helper Functions ===
    function getAppName(name) {
        if (!name || name.trim() === "")
            return "Unknown";

        name = name.trim();
        // Handle reverse-DNS format (com.github.App, org.domain.App)
        if (name.includes(".") && (name.startsWith("com.") || name.startsWith("org.") || name.startsWith("io.") || name.startsWith("net."))) {
            const parts = name.split(".");
            let appPart = parts[parts.length - 1];
            // Skip generic suffixes
            if (!appPart || appPart === "app" || appPart === "desktop")
                appPart = parts[parts.length - 2] || parts[0];

            if (appPart)
                name = appPart;

        }
        // General cleanup for any dotted name
        if (name.includes(".")) {
            const parts = name.split(".");
            let displayName = parts[parts.length - 1];
            // Skip numeric suffixes
            if (!displayName || /^\d+$/.test(displayName))
                displayName = parts[parts.length - 2] || parts[0];

            if (displayName) {
                // Capitalize first letter
                displayName = displayName.charAt(0).toUpperCase() + displayName.slice(1);
                // Add spaces before capitals: "CamelCase" → "Camel Case"
                displayName = displayName.replace(/([a-z])([A-Z])/g, '$1 $2');
                // Remove common suffixes
                displayName = displayName.replace(/app$/i, '').trim();
                displayName = displayName.replace(/desktop$/i, '').trim();
                displayName = displayName.replace(/flatpak$/i, '').trim();
                if (!displayName)
                    displayName = parts[parts.length - 1].charAt(0).toUpperCase() + parts[parts.length - 1].slice(1);

            }
            return displayName || name;
        }
        // Simple name: just capitalize and format
        let displayName = name.charAt(0).toUpperCase() + name.slice(1);
        displayName = displayName.replace(/([a-z])([A-Z])/g, '$1 $2');
        displayName = displayName.replace(/app$/i, '').trim();
        displayName = displayName.replace(/desktop$/i, '').trim();
        return displayName || name;
    }

    function getIcon(icon) {
        if (!icon)
            return "";

        if (icon.startsWith("/") || icon.startsWith("file://"))
            return icon;

        return QsCommons.ThemeIcons.iconFromName(icon);
    }

    function stripTags(text) {
        return text.replace(/<[^>]*>?/gm, '');
    }

    function generateImageId(notification, image) {
        if (image && image.startsWith("image://")) {
            if (image.startsWith("image://qsimage/")) {
                // For qsimage URLs, use app + summary as key
                const key = (notification.appName || "") + "|" + (notification.summary || "");
                return Checksum.sha256(key);
            }
            // For other image:// URLs, hash the URL itself
            return Checksum.sha256(image);
        }
        return ""; // File paths don't need caching
    }

    function pauseTimeout(id) {
        const meta = notificationMetadata[id];
        if (meta && !meta.paused) {
            meta.paused = true;
            meta.pauseTime = Date.now();
        }
    }

    function resumeTimeout(id) {
        const meta = notificationMetadata[id];
        if (meta && meta.paused) {
            meta.timestamp += Date.now() - meta.pauseTime;
            meta.paused = false;
        }
    }

    // === Public API ===
    function dismissActiveNotification(id) {
        if (activeMap[id])
            activeMap[id].dismiss();

        removeActive(id);
    }

    function dismissOldestActive() {
        if (activeList.count > 0) {
            const lastNotif = activeList.get(activeList.count - 1);
            dismissActiveNotification(lastNotif.id);
        }
    }

    function dismissAllActive() {
        Object.values(activeMap).forEach((n) => {
            return n.dismiss();
        });
        activeList.clear();
        activeMap = {
        };
        notificationMetadata = {
        };
    }

    function invokeAction(id, actionId) {
        const n = activeMap[id];
        if (!n || !n.actions)
            return false;

        for (const action of n.actions) {
            if (action.identifier === actionId && action.invoke) {
                action.invoke();
                return true;
            }
        }
        return false;
    }

    function removeFromHistory(notificationId) {
        for (var i = 0; i < historyList.count; i++) {
            const notif = historyList.get(i);
            if (notif.id === notificationId) {
                if (notif.cachedImage && !notif.cachedImage.startsWith("image://"))
                    Quickshell.execDetached(["rm", "-f", notif.cachedImage]);

                historyList.remove(i);
                saveHistory();
                return true;
            }
        }
        return false;
    }

    function clearHistory() {
        try {
            Quickshell.execDetached(["sh", "-c", `rm -rf "${QsCommons.Settings.cacheDirImagesNotifications}"*`]);
        } catch (e) {
            QsCommons.Logger.e("Notifications", "Failed to clear cache directory:", e);
        }
        historyList.clear();
        saveHistory();
    }

    // === Initialization ===
    Component.onCompleted: {
        QsCommons.Logger.i("Notifications", "NotificationService initialized");
    }
    // === Offscreen Image Cacher ===
    // Uses invisible PanelWindow + Image.grabToImage() to cache image:// URLs
    PanelWindow {
        implicitHeight: 1
        implicitWidth: 1
        color: QsCommons.Color.transparent

        Image {
            id: cacher

            function processNextImage() {
                imageQueue.shift();
                if (imageQueue.length > 0)
                    source = imageQueue[0].src;
                else
                    source = "";
            }

            width: 64
            height: 64
            visible: true
            cache: false
            asynchronous: true
            mipmap: true
            antialiasing: true
            onStatusChanged: {
                if (imageQueue.length === 0)
                    return ;

                const req = imageQueue[0];
                if (status === Image.Ready) {
                    Quickshell.execDetached(["mkdir", "-p", QsCommons.Settings.cacheDirImagesNotifications]);
                    grabToImage((result) => {
                        if (result.saveToFile(req.dest))
                            updateImagePath(req.imageId, req.dest);

                        processNextImage();
                    });
                } else if (status === Image.Error) {
                    processNextImage();
                }
            }
        }

        mask: Region {
        }

    }

    // === Notification Server ===
    NotificationServer {
        keepOnReload: false
        imageSupported: true
        actionsSupported: true
        onNotification: (notification) => {
            return handleNotification(notification);
        }
    }

    // === Optimized Batch Progress Update ===
    // Reduced from 10ms to 50ms (20 updates/sec instead of 100)
    Timer {
        interval: 50
        repeat: true
        running: activeList.count > 0
        onTriggered: updateAllProgress()
    }

    // === Persistence - History ===
    FileView {
        id: historyFileView

        path: historyFile
        printErrors: false
        onLoaded: loadHistory()
        onLoadFailed: (error) => {
            if (error === 2)
                writeAdapter();

        }

        JsonAdapter {
            id: adapter

            property var notifications: []
        }

    }

    // === Persistence - State (lastSeenTs, etc.) ===
    FileView {
        id: stateFileView

        path: stateFile
        printErrors: false
        onLoaded: loadState()
        onLoadFailed: (error) => {
            if (error === 2)
                writeAdapter();

        }

        JsonAdapter {
            id: stateAdapter

            property real lastSeenTs: 0
        }

    }

    Timer {
        id: saveTimer

        interval: 200
        onTriggered: performSaveHistory()
    }

    Connections {
        function onDoNotDisturbChanged() {
            const enabled = QsCommons.Settings.data.notifications.doNotDisturb;
            QsCommons.Logger.i("Notifications", "Do Not Disturb:", enabled ? "enabled" : "disabled");
            root.showNotice(
                enabled ? "Do Not Disturb Enabled" : "Do Not Disturb Disabled",
                enabled ? "Notifications will be silenced" : "Notifications will be shown"
            );
        }

        target: QsCommons.Settings.data.notifications
    }

}
