import QtQuick
import "../Commons" as QsCommons

Rectangle {
  id: root
  
  // === Properties ===
  property string orientation: "horizontal"
  
  // Gradient for subtle fade on ends
  width: parent ? parent.width : 100
  height: QsCommons.Style.borderS
  
  gradient: Gradient {
    orientation: root.orientation === "horizontal" ? Gradient.Horizontal : Gradient.Vertical
    GradientStop {
      position: 0.0
      color: QsCommons.Color.transparent
    }
    GradientStop {
      position: 0.1
      color: QsCommons.Color.mOutline
    }
    GradientStop {
      position: 0.9
      color: QsCommons.Color.mOutline
    }
    GradientStop {
      position: 1.0
      color: QsCommons.Color.transparent
    }
  }
}
