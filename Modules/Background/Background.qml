import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Commons" as QsCommons
import "../../Services" as QsServices

Variants {
  id: backgroundVariants
  model: Quickshell.screens

  Component.onCompleted: {
    QsCommons.Logger.i("Background", "Module loaded, screens: " + Quickshell.screens.length)
  }

  delegate: Loader {
    id: backgroundLoader

    required property ShellScreen modelData

    active: modelData && QsCommons.Settings.data.wallpaper.enabled

    sourceComponent: PanelWindow {
      id: root

      // === Internal State ===
      property string currentSource: ""
      property string nextSource: ""
      property string futureWallpaper: ""
      property bool isTransitioning: false
      property real transitionProgress: 0

      // === Transition Settings (from Settings) ===
      readonly property string transitionType: QsCommons.Settings.data.wallpaper.transitionType
      readonly property int transitionDuration: QsCommons.Settings.data.wallpaper.transitionDuration

      // === Fill Mode ===
      readonly property int fillMode: getFillModeEnum()

      // === Lifecycle ===
      Component.onCompleted: {
        QsCommons.Logger.d("Background", "PanelWindow created for: " + modelData.name)
        setWallpaperInitial()
      }

      Component.onDestruction: {
        transitionAnimation.stop()
        debounceTimer.stop()
        currentWallpaper.source = ""
        nextWallpaper.source = ""
      }

      // === Panel Configuration ===
      screen: modelData
      color: QsCommons.Color.transparent

      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.namespace: "yaqs-wallpaper"
      WlrLayershell.exclusionMode: ExclusionMode.Ignore

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      // === Service Connections ===
      Connections {
        target: QsServices.WallpaperService
        function onWallpaperChanged(screenName, path) {
          if (screenName === modelData.name) {
            root.futureWallpaper = path
            debounceTimer.restart()
          }
        }
      }

      Connections {
        target: QsServices.CompositorService
        function onDisplayScalesChanged() {
          QsCommons.Logger.d("Background", "Display scales changed, recalculating for " + modelData.name)
          // Trigger re-calculation of source sizes
          if (currentWallpaper.status === Image.Ready) {
            currentWallpaper.recalculateSourceSize()
          }
          if (nextWallpaper.status === Image.Ready) {
            nextWallpaper.recalculateSourceSize()
          }
        }
      }

      Connections {
        target: QsCommons.Settings.data.wallpaper
        function onFillModeChanged() {
          // fillMode is a binding, will auto-update
        }
      }

      // === Debounce Timer ===
      Timer {
        id: debounceTimer
        interval: 200
        running: false
        repeat: false
        onTriggered: changeWallpaper()
      }

      // === Current Wallpaper (base layer) ===
      Image {
        id: currentWallpaper

        // Track if we've calculated optimal size
        property bool dimensionsCalculated: false

        anchors.fill: parent
        source: root.currentSource
        fillMode: root.fillMode
        asynchronous: true
        cache: false
        smooth: true
        mipmap: false
        sourceSize: undefined

        onStatusChanged: {
          if (status === Image.Error && source !== "") {
            QsCommons.Logger.w("Background", "Failed to load wallpaper: " + source)
          } else if (status === Image.Ready && !dimensionsCalculated) {
            dimensionsCalculated = true
            const optimalSize = calculateOptimalWallpaperSize(implicitWidth, implicitHeight)
            if (optimalSize) {
              sourceSize = optimalSize
            }
          }
        }

        onSourceChanged: {
          dimensionsCalculated = false
          sourceSize = undefined
        }

        function recalculateSourceSize() {
          if (status === Image.Ready && implicitWidth > 0 && implicitHeight > 0) {
            dimensionsCalculated = false
            const optimalSize = calculateOptimalWallpaperSize(implicitWidth, implicitHeight)
            if (optimalSize) {
              sourceSize = optimalSize
              dimensionsCalculated = true
            }
          }
        }
      }

      // === Next Wallpaper (transition layer) ===
      Image {
        id: nextWallpaper

        property bool dimensionsCalculated: false

        anchors.fill: parent
        source: root.nextSource
        fillMode: root.fillMode
        asynchronous: true
        cache: false
        smooth: true
        mipmap: false
        sourceSize: undefined
        opacity: root.transitionProgress
        visible: root.isTransitioning

        onStatusChanged: {
          if (status === Image.Error && source !== "") {
            QsCommons.Logger.w("Background", "Failed to load next wallpaper: " + source)
            root.isTransitioning = false
          } else if (status === Image.Ready) {
            // Calculate optimal size
            if (!dimensionsCalculated) {
              dimensionsCalculated = true
              const optimalSize = calculateOptimalWallpaperSize(implicitWidth, implicitHeight)
              if (optimalSize) {
                sourceSize = optimalSize
              }
            }
            // Start transition if we're waiting for it
            if (root.isTransitioning && !transitionAnimation.running) {
              transitionAnimation.start()
            }
          }
        }

        onSourceChanged: {
          dimensionsCalculated = false
          sourceSize = undefined
        }

        function recalculateSourceSize() {
          if (status === Image.Ready && implicitWidth > 0 && implicitHeight > 0) {
            dimensionsCalculated = false
            const optimalSize = calculateOptimalWallpaperSize(implicitWidth, implicitHeight)
            if (optimalSize) {
              sourceSize = optimalSize
              dimensionsCalculated = true
            }
          }
        }
      }

      // === Transition Animation ===
      NumberAnimation {
        id: transitionAnimation
        target: root
        property: "transitionProgress"
        from: 0.0
        to: 1.0
        duration: root.transitionType === "none" ? 0 : root.transitionDuration
        easing.type: Easing.InOutCubic

        onFinished: {
          // Swap sources: assign new to current BEFORE clearing to prevent flicker
          const tempSource = root.nextSource
          root.currentSource = tempSource
          root.transitionProgress = 0.0

          // Clear nextWallpaper after currentWallpaper has the new source
          Qt.callLater(() => {
            root.nextSource = ""
            root.isTransitioning = false
            Qt.callLater(() => {
              currentWallpaper.asynchronous = true
            })
          })
        }
      }

      // === Helper Functions ===

      // Calculate optimal wallpaper size based on screen and image dimensions
      function calculateOptimalWallpaperSize(wpWidth, wpHeight) {
        const compositorScale = QsServices.CompositorService.getDisplayScale(modelData.name)
        const screenWidth = modelData.width * compositorScale
        const screenHeight = modelData.height * compositorScale

        // Don't resize if wallpaper is smaller than screen or invalid
        if (wpWidth <= screenWidth || wpHeight <= screenHeight || wpWidth <= 0 || wpHeight <= 0) {
          return null
        }

        const imageAspectRatio = wpWidth / wpHeight
        var dim

        if (screenWidth >= screenHeight) {
          const w = Math.min(screenWidth, wpWidth)
          dim = Qt.size(w, w / imageAspectRatio)
        } else {
          const h = Math.min(screenHeight, wpHeight)
          dim = Qt.size(h * imageAspectRatio, h)
        }

        QsCommons.Logger.d("Background", 
          "Wallpaper resized on " + modelData.name + " " + 
          screenWidth + "x" + screenHeight + " @ " + compositorScale + "x | " +
          "src: " + wpWidth + "x" + wpHeight + " → dst: " + dim.width + "x" + dim.height)

        return dim
      }

      // Convert string fillMode to Image.FillMode enum
      function getFillModeEnum() {
        switch (QsCommons.Settings.data.wallpaper.fillMode) {
          case "center": return Image.Pad
          case "fit": return Image.PreserveAspectFit
          case "stretch": return Image.Stretch
          case "crop":
          default: return Image.PreserveAspectCrop
        }
      }

      // Initialize wallpaper on startup
      function setWallpaperInitial() {
        if (!QsServices.WallpaperService || !QsServices.WallpaperService.isInitialized) {
          Qt.callLater(setWallpaperInitial)
          return
        }

        const wallpaperPath = QsServices.WallpaperService.getWallpaper(modelData.name)
        if (wallpaperPath) {
          setWallpaperImmediate(wallpaperPath)
          QsCommons.Logger.d("Background", "Initial wallpaper for " + modelData.name + ": " + wallpaperPath)
        }
      }

      // Set wallpaper immediately without transition
      function setWallpaperImmediate(source) {
        transitionAnimation.stop()
        transitionProgress = 0.0
        isTransitioning = false

        // Clear with proper delay to allow GC
        nextSource = ""
        currentSource = ""

        Qt.callLater(() => {
          root.currentSource = source
        })
      }

      // Set wallpaper with transition effect
      function setWallpaperWithTransition(source) {
        if (source === currentSource) {
          return
        }

        if (isTransitioning) {
          // Interrupting a transition - handle cleanup properly
          transitionAnimation.stop()
          transitionProgress = 0

          // Assign nextWallpaper to currentWallpaper BEFORE clearing to prevent flicker
          const newCurrentSource = nextSource
          currentSource = newCurrentSource

          // Now clear and set up new transition
          Qt.callLater(() => {
            nextSource = ""
            Qt.callLater(() => {
              nextSource = source
              currentWallpaper.asynchronous = false
              isTransitioning = true
              // Animation starts when nextWallpaper.onStatusChanged fires with Ready
            })
          })
          return
        }

        nextSource = source
        currentWallpaper.asynchronous = false
        isTransitioning = true
        // Animation starts when nextWallpaper.onStatusChanged fires with Ready
      }

      // Main method triggered by debounce timer
      function changeWallpaper() {
        if (!futureWallpaper || futureWallpaper === "") {
          return
        }

        const transition = transitionType

        QsCommons.Logger.d("Background", "Changing wallpaper on " + modelData.name + " | transition: " + transition)

        switch (transition) {
          case "none":
            setWallpaperImmediate(futureWallpaper)
            break
          case "fade":
          default:
            setWallpaperWithTransition(futureWallpaper)
            break
        }

        futureWallpaper = ""
      }
    }
  }
}
