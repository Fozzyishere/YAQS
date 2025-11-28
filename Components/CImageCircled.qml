import QtQuick
import "../Commons" as QsCommons
import "../Components" as QsComponents

Rectangle {
  id: root

  // === Public Properties ===
  property alias source: image.source
  property alias status: image.status
  property bool showBorder: true
  property color borderColor: QsCommons.Color.mOutline

  // === Sizing (Self-contained) ===
  property real imageSize: QsCommons.Style.baseWidgetSize * 2 * QsCommons.Style.uiScaleRatio

  implicitWidth: imageSize
  implicitHeight: imageSize

  // Circular shape
  radius: width / 2
  color: QsCommons.Color.mSurfaceContainerLow
  
  // Optional border
  border.width: showBorder ? QsCommons.Style.borderS : 0
  border.color: showBorder ? borderColor : QsCommons.Color.transparent

  // Clipping mask for circular shape
  clip: true

  // Cached image
  QsComponents.CImageCached {
    id: image
    anchors.fill: parent
    anchors.margins: root.border.width
    fillMode: Image.PreserveAspectCrop
    showLoadingIndicator: true
    showErrorState: true
  }

  // Circular mask layer
  layer.enabled: true
  layer.effect: Item {
    Rectangle {
      anchors.fill: parent
      radius: width / 2
    }
  }
}

