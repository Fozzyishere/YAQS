import QtQuick
import "../Commons" as QsCommons

Rectangle {
  id: root
  
  // === Properties ===
  property string orientation: "horizontal"
  // mOutlineVariant for subtle dividers (default), mOutline for emphasis
  property color dividerColor: QsCommons.Color.mOutlineVariant
  
  // Gradient for subtle fade on ends
  width: orientation === "horizontal" ? (parent ? parent.width : 100) : QsCommons.Style.borderS
  height: orientation === "horizontal" ? QsCommons.Style.borderS : (parent ? parent.height : 100)
  
  gradient: Gradient {
    orientation: root.orientation === "horizontal" ? Gradient.Horizontal : Gradient.Vertical
    GradientStop {
      position: 0.0
      color: QsCommons.Color.transparent
    }
    GradientStop {
      position: 0.1
      color: root.dividerColor
    }
    GradientStop {
      position: 0.9
      color: root.dividerColor
    }
    GradientStop {
      position: 1.0
      color: QsCommons.Color.transparent
    }
  }
}
