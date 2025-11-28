import QtQuick
import "../Commons" as QsCommons
import "../Components" as QsComponents

Rectangle {
  id: root

  // === Public Properties ===
  property alias source: image.source
  property alias status: image.status
  property alias fillMode: image.fillMode

  // === Sizing (Self-contained) ===
  property real imageWidth: Math.round(200 * QsCommons.Style.uiScaleRatio)
  property real imageHeight: Math.round(150 * QsCommons.Style.uiScaleRatio)

  implicitWidth: imageWidth
  implicitHeight: imageHeight

  // radiusM (16px) for image containers
  radius: QsCommons.Style.radiusM
  color: QsCommons.Color.mSurfaceContainerLow
  
  // No border by default
  border.width: 0

  // Clipping for rounded corners
  clip: true

  // Cached image
  QsComponents.CImageCached {
    id: image
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    showLoadingIndicator: true
    showErrorState: true
  }

  // Apply rounded corner mask
  layer.enabled: true
  layer.effect: Item {
    Rectangle {
      anchors.fill: parent
      radius: root.radius
    }
  }
}

