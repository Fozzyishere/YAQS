import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Commons" as QsCommons
import "../Components" as QsComponents

// Advanced panel component with:
// - Loader pattern for lazy loading and memory efficiency
// - Button-relative positioning (opens near triggering component)
// - Bar-aware positioning (respects bar margins)
// - Scale animations (smooth pop-in effect)
// - Draggable panels (optional)
// - Desktop dimming (focus attention)
// - Single-open enforcement via PanelService

Loader {
  id: root

  // === Required Properties ===
  property ShellScreen screen
  required property string objectName  // For PanelService registry

  // === Panel Configuration ===
  property bool useOverlay: QsCommons.Settings.data.ui?.panelsOverlayLayer ?? true

  // Panel content (set by inheriting components)
  property Component panelContent: null
  property real preferredWidth: 700
  property real preferredHeight: 900
  property real preferredWidthRatio  // Optional: dynamic width based on screen
  property real preferredHeightRatio  // Optional: dynamic height based on screen

  // Appearance
  property color panelBackgroundColor: QsCommons.Color.mSurface
  property color panelBorderColor: QsCommons.Color.mOutline
  property bool draggable: false

  // Button positioning (for opening panel near triggering widget)
  property var buttonItem: null
  property string buttonName: ""

  // Positioning anchors (fixed positioning)
  property bool panelAnchorHorizontalCenter: false
  property bool panelAnchorVerticalCenter: false
  property bool panelAnchorTop: false
  property bool panelAnchorBottom: false
  property bool panelAnchorLeft: false
  property bool panelAnchorRight: false

  // Button-relative positioning state
  property bool useButtonPosition: false
  property point buttonPosition: Qt.point(0, 0)
  property int buttonWidth: 0
  property int buttonHeight: 0

  // Behavior
  property bool panelKeyboardFocus: false
  property bool backgroundClickEnabled: true

  // Animation state
  readonly property real originalScale: 0.0
  property real scaleValue: originalScale
  property real dimmingOpacity: 0

  // === Signals ===
  signal opened
  signal closed

  // === Loader Configuration ===
  active: false  // Panel starts closed
  asynchronous: true  // Load in background for better performance

  // === Lifecycle ===
  Component.onCompleted: {
    QsServices.PanelService.registerPanel(root)
    QsCommons.Logger.d("CPanel", "Registered:", root.objectName)
  }

  // === Background Click Management ===
  // Temporarily disable background click during drag operations
  function disableBackgroundClick() {
    backgroundClickEnabled = false
  }

  function enableBackgroundClick() {
    // Add delay to prevent immediate close after drag release
    enableBackgroundClickTimer.restart()
  }

  Timer {
    id: enableBackgroundClickTimer
    interval: 100
    repeat: false
    onTriggered: backgroundClickEnabled = true
  }

  // === Panel Control Functions ===

  function toggle(buttonItem, buttonName) {
    if (!active) {
      open(buttonItem, buttonName)
    } else {
      close()
    }
  }

  function open(buttonItem, buttonName) {
    root.buttonItem = buttonItem
    root.buttonName = buttonName || ""

    setPosition()

    QsServices.PanelService.willOpenPanel(root)

    backgroundClickEnabled = true
    active = true
    root.opened()
  }

  function close() {
    dimmingOpacity = 0
    scaleValue = originalScale
    root.closed()
    active = false
    useButtonPosition = false
    backgroundClickEnabled = true
    QsServices.PanelService.closedPanel(root)
  }

  // === Position Calculation ===
  function setPosition() {
    // If we have a button name but no button item, look it up
    // This handles IPC calls where button name is provided
    if (buttonName !== "" && root.screen !== null && buttonItem === null) {
      // TODO: Integrate with BarService when implemented
      // buttonItem = BarService.lookupWidget(buttonName, root.screen.name)
      QsCommons.Logger.d("CPanel", "Button lookup not yet implemented:", buttonName)
    }

    // Calculate button position if button item provided
    if (buttonItem !== undefined && buttonItem !== null) {
      useButtonPosition = true
      var itemPos = buttonItem.mapToItem(null, 0, 0)
      buttonPosition = Qt.point(itemPos.x, itemPos.y)
      buttonWidth = buttonItem.width
      buttonHeight = buttonItem.height
    } else {
      useButtonPosition = false
    }
  }

  // === Panel Window Component ===
  sourceComponent: Component {
    PanelWindow {
      id: panelWindow

      // Bar configuration (for positioning awareness)
      readonly property string barPosition: QsCommons.Settings.data.bar?.position ?? "top"
      readonly property bool isVertical: barPosition === "left" || barPosition === "right"
      readonly property bool barIsVisible: {
        if (screen === null) return false
        const monitors = QsCommons.Settings.data.bar?.monitors ?? []
        return monitors.includes(screen.name) || monitors.length === 0
      }
      readonly property real verticalBarWidth: QsCommons.Style.barHeight

      Component.onCompleted: {
        QsCommons.Logger.d("CPanel", "Opened", root.objectName, "on", screen.name)
        dimmingOpacity = QsCommons.Style.opacityHeavy
      }

      Connections {
        target: panelWindow
        function onScreenChanged() {
          root.screen = screen

          // If called from IPC, reposition when screen updates
          if (buttonName) {
            setPosition()
          }
          QsCommons.Logger.d("CPanel", "OnScreenChanged", root.screen.name)
        }
      }

      visible: true
      color: QsCommons.Settings.data.general?.dimDesktop ?? false ? 
             Qt.alpha(QsCommons.Color.mShadow, dimmingOpacity) : 
             QsCommons.Color.transparent

      // Wayland layer configuration
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "yaqs-panel"
      WlrLayershell.layer: useOverlay ? WlrLayer.Overlay : WlrLayer.Top
      WlrLayershell.keyboardFocus: root.panelKeyboardFocus ? 
                                   WlrKeyboardFocus.OnDemand : 
                                   WlrKeyboardFocus.None

      // Smooth color transitions
      Behavior on color {
        ColorAnimation {
          duration: QsCommons.Style.animationNormal
        }
      }

      // Full screen anchors
      anchors.top: true
      anchors.left: true
      anchors.right: true
      anchors.bottom: true

      // Close panel with Escape key (no focus required)
      Shortcut {
        sequences: ["Escape"]
        enabled: root.active
        onActivated: root.close()
        context: Qt.WindowShortcut
      }

      // Background click to close
      MouseArea {
        anchors.fill: parent
        enabled: root.backgroundClickEnabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: root.close()
      }

      // === Panel Background (The Actual Panel) ===
      Rectangle {
        id: panelBackground
        color: panelBackgroundColor
        radius: QsCommons.Style.radiusL
        border.color: panelBorderColor
        border.width: QsCommons.Style.borderS

        // Dragging state
        property bool draggable: root.draggable
        property bool isDragged: false
        property real manualX: 0
        property real manualY: 0

        // Dynamic sizing with screen constraints
        width: {
          var w
          if (preferredWidthRatio !== undefined) {
            w = Math.round(Math.max(screen?.width * preferredWidthRatio, preferredWidth))
          } else {
            w = preferredWidth
          }
          // Never larger than screen minus margins
          return Math.min(w, (screen?.width ?? 1920) - QsCommons.Style.marginL * 2)
        }

        height: {
          var h
          if (preferredHeightRatio !== undefined) {
            h = Math.round(Math.max(screen?.height * preferredHeightRatio, preferredHeight))
          } else {
            h = preferredHeight
          }
          // Never larger than screen minus bar and margins
          return Math.min(h, (screen?.height ?? 1080) - QsCommons.Style.barHeight - QsCommons.Style.marginL * 2)
        }

        scale: root.scaleValue
        x: isDragged ? manualX : calculatedX
        y: isDragged ? manualY : calculatedY

        // === Bar-Aware Margins ===
        // Calculate margins based on bar position and floating state

        property real marginTop: {
          if (!barIsVisible) {
            return 0
          }
          switch (barPosition) {
          case "top":
            const floatingExtra = (QsCommons.Settings.data.bar?.floating ?? false) ? 
                                 (QsCommons.Settings.data.bar?.marginVertical ?? 0) * QsCommons.Style.marginXL : 
                                 0
            return (QsCommons.Style.barHeight + QsCommons.Style.marginS) + floatingExtra
          default:
            return QsCommons.Style.marginS
          }
        }

        property real marginBottom: {
          if (!barIsVisible) {
            return 0
          }
          switch (barPosition) {
          case "bottom":
            const floatingExtra = (QsCommons.Settings.data.bar?.floating ?? false) ? 
                                 (QsCommons.Settings.data.bar?.marginVertical ?? 0) * QsCommons.Style.marginXL : 
                                 0
            return (QsCommons.Style.barHeight + QsCommons.Style.marginS) + floatingExtra
          default:
            return QsCommons.Style.marginS
          }
        }

        property real marginLeft: {
          if (!barIsVisible) {
            return 0
          }
          switch (barPosition) {
          case "left":
            const floatingExtra = (QsCommons.Settings.data.bar?.floating ?? false) ? 
                                 (QsCommons.Settings.data.bar?.marginHorizontal ?? 0) * QsCommons.Style.marginXL : 
                                 0
            return (QsCommons.Style.barHeight + QsCommons.Style.marginS) + floatingExtra
          default:
            return QsCommons.Style.marginS
          }
        }

        property real marginRight: {
          if (!barIsVisible) {
            return 0
          }
          switch (barPosition) {
          case "right":
            const floatingExtra = (QsCommons.Settings.data.bar?.floating ?? false) ? 
                                 (QsCommons.Settings.data.bar?.marginHorizontal ?? 0) * QsCommons.Style.marginXL : 
                                 0
            return (QsCommons.Style.barHeight + QsCommons.Style.marginS) + floatingExtra
          default:
            return QsCommons.Style.marginS
          }
        }

        // === Smart Position Calculation ===

        property int calculatedX: {
          // Priority: Fixed anchoring
          if (panelAnchorHorizontalCenter) {
            // Center horizontally respecting bar margins
            var centerX = Math.round((panelWindow.width - panelBackground.width) / 2)
            var minX = marginLeft
            var maxX = panelWindow.width - panelBackground.width - marginRight
            return Math.round(Math.max(minX, Math.min(centerX, maxX)))
          } else if (panelAnchorLeft) {
            return marginLeft
          } else if (panelAnchorRight) {
            return Math.round(panelWindow.width - panelBackground.width - marginRight)
          }

          // No fixed anchoring - use smart positioning
          if (isVertical) {
            // Vertical bar (left or right)
            if (barPosition === "right") {
              // Panel to the left of right bar
              return Math.round(panelWindow.width - panelBackground.width - marginRight)
            } else {
              // Panel to the right of left bar
              return marginLeft
            }
          } else {
            // Horizontal bar (top or bottom)
            if (root.useButtonPosition) {
              // Position panel relative to triggering button
              var targetX = buttonPosition.x + (buttonWidth / 2) - (panelBackground.width / 2)
              // Keep within screen bounds
              var maxX = panelWindow.width - panelBackground.width - marginRight
              var minX = marginLeft
              return Math.round(Math.max(minX, Math.min(targetX, maxX)))
            } else {
              // Fallback: center horizontally
              return Math.round((panelWindow.width - panelBackground.width) / 2)
            }
          }
        }

        property int calculatedY: {
          // Priority: Fixed anchoring
          if (panelAnchorVerticalCenter) {
            // Center vertically respecting bar margins
            var centerY = Math.round((panelWindow.height - panelBackground.height) / 2)
            var minY = marginTop
            var maxY = panelWindow.height - panelBackground.height - marginBottom
            return Math.round(Math.max(minY, Math.min(centerY, maxY)))
          } else if (panelAnchorTop) {
            return marginTop
          } else if (panelAnchorBottom) {
            return Math.round(panelWindow.height - panelBackground.height - marginBottom)
          }

          // No fixed anchoring - use smart positioning
          if (isVertical) {
            // Vertical bar
            if (useButtonPosition) {
              // Position panel relative to triggering button
              var targetY = buttonPosition.y + (buttonHeight / 2) - (panelBackground.height / 2)
              // Keep within screen bounds
              var maxY = panelWindow.height - panelBackground.height - marginBottom
              var minY = marginTop
              return Math.round(Math.max(minY, Math.min(targetY, maxY)))
            } else {
              // Fallback: center vertically
              return Math.round((panelWindow.height - panelBackground.height) / 2)
            }
          } else {
            // Horizontal bar
            if (barPosition === "bottom") {
              // Panel above bottom bar
              return Math.round(panelWindow.height - panelBackground.height - marginBottom)
            } else {
              // Panel below top bar
              return marginTop
            }
          }
        }

        // Animate scale on creation (pop-in effect)
        Component.onCompleted: {
          root.scaleValue = 1.0
        }

        // Reset drag state when panel closes
        Connections {
          target: root
          function onClosed() {
            panelBackground.isDragged = false
          }
        }

        // Prevent background click propagation
        MouseArea {
          anchors.fill: parent
        }

        // === Animations ===

        Behavior on scale {
          NumberAnimation {
            duration: QsCommons.Style.animationNormal
            easing.type: Easing.OutExpo
          }
        }

        Behavior on opacity {
          NumberAnimation {
            duration: QsCommons.Style.animationNormal
            easing.type: Easing.OutQuad
          }
        }

        // === Panel Content Loader ===
        Loader {
          id: panelContentLoader
          anchors.fill: parent
          sourceComponent: root.panelContent
        }

        // === Drag Handler ===
        DragHandler {
          id: dragHandler
          target: null
          enabled: panelBackground.draggable
          property real dragStartX: 0
          property real dragStartY: 0

          onActiveChanged: {
            if (active) {
              // Capture current position before starting drag
              panelBackground.manualX = panelBackground.x
              panelBackground.manualY = panelBackground.y
              dragStartX = panelBackground.x
              dragStartY = panelBackground.y
              panelBackground.isDragged = true
              root.disableBackgroundClick()
            } else {
              // Keep isDragged true to preserve manual position
              root.enableBackgroundClick()
            }
          }

          onTranslationChanged: {
            // Calculate new position from drag origin
            var nx = dragStartX + translation.x
            var ny = dragStartY + translation.y

            // Calculate insets to avoid bar overlap
            var baseGap = QsCommons.Style.marginS
            var floatingH = (QsCommons.Settings.data.bar?.floating ?? false) ? 
                           (QsCommons.Settings.data.bar?.marginHorizontal ?? 0) * 2 * QsCommons.Style.marginXL : 
                           0
            var floatingV = (QsCommons.Settings.data.bar?.floating ?? false) ? 
                           (QsCommons.Settings.data.bar?.marginVertical ?? 0) * 2 * QsCommons.Style.marginXL : 
                           0

            var insetLeft = baseGap + ((barIsVisible && barPosition === "left") ? (QsCommons.Style.barHeight + floatingH) : 0)
            var insetRight = baseGap + ((barIsVisible && barPosition === "right") ? (QsCommons.Style.barHeight + floatingH) : 0)
            var insetTop = baseGap + ((barIsVisible && barPosition === "top") ? (QsCommons.Style.barHeight + floatingV) : 0)
            var insetBottom = baseGap + ((barIsVisible && barPosition === "bottom") ? (QsCommons.Style.barHeight + floatingV) : 0)

            // Clamp within bounds
            var maxX = panelWindow.width - panelBackground.width - insetRight
            var minX = insetLeft
            var maxY = panelWindow.height - panelBackground.height - insetBottom
            var minY = insetTop

            panelBackground.manualX = Math.round(Math.max(minX, Math.min(nx, maxX)))
            panelBackground.manualY = Math.round(Math.max(minY, Math.min(ny, maxY)))
          }
        }

        // === Drag Visual Indicator ===
        Rectangle {
          anchors.fill: parent
          anchors.margins: 0
          color: QsCommons.Color.transparent
          border.color: QsCommons.Color.mPrimary
          border.width: QsCommons.Style.borderL
          radius: parent.radius
          visible: panelBackground.isDragged && dragHandler.active
          opacity: 0.8
          z: 3000

          // Subtle glow effect
          Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: QsCommons.Color.transparent
            border.color: QsCommons.Color.mPrimary
            border.width: QsCommons.Style.borderS
            radius: parent.radius
            opacity: 0.3
          }
        }
      }
    }
  }
}
