import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import "../Commons" as QsCommons
import "../Components" as QsComponents

RowLayout {
  id: root

  // === Public Properties ===
  property string currentPath: ""
  property string dialogTitle: "Select File"
  property var nameFilters: ["All Files (*)"]
  property bool selectFolder: false

  // === Signals ===
  signal fileSelected(string path)

  // === Layout ===
  spacing: QsCommons.Style.marginM
  Layout.fillWidth: true

  // === Child Components ===
  QsComponents.CTextInput {
    id: pathInput
    Layout.fillWidth: true
    text: root.currentPath
    placeholderText: selectFolder ? "Choose folder..." : "Choose file..."
    readOnly: true
  }

  QsComponents.CButton {
    text: "Browse"
    icon: "folder"
    onClicked: fileDialog.open()
  }

  FileDialog {
    id: fileDialog
    title: root.dialogTitle
    nameFilters: root.nameFilters
    fileMode: root.selectFolder ? FileDialog.OpenDirectory : FileDialog.OpenFile

    onAccepted: {
      var path = selectedFile.toString()
      if (path.startsWith("file://")) {
        path = path.substring(7)
      }
      root.currentPath = path
      root.fileSelected(root.currentPath)
    }
  }
}
