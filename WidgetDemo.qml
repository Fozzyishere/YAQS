import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC

import "./Commons"
import "./Widgets"

/**
 * WidgetDemo - Visual testing showcase for all 20 base widgets
 *
 * This file demonstrates all widgets from Phase 2.2 with various configurations.
 * Use this to visually verify widget appearance, behavior, and responsiveness.
 *
 * Usage:
 *   Launch this file in QuickShell to view all widgets in action
 */
Rectangle {
    id: root
    width: 1200
    height: 900
    color: Color.mBackground

    ScrollView {
        anchors.fill: parent
        anchors.margins: Style.spacingL

        ColumnLayout {
            width: parent.width - Style.spacingL * 2
            spacing: Style.spacingXL

            // Header
            Text {
                text: "YAQS Widget Library - 20 Base Components"
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize * 2
                font.weight: Font.Bold
                color: Color.mOnBackground
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Style.spacingL
            }

            Divider { Layout.fillWidth: true }

            // === Text & Display Widgets ===
            Card {
                title: "Text & Display"
                Layout.fillWidth: true
                Layout.preferredHeight: 200

                ColumnLayout {
                    spacing: Style.spacingM

                    FieldLabel {
                        label: "System Status"
                        description: "All systems operational. Last check: 2 minutes ago."
                    }

                    Divider { Layout.fillWidth: true; orientation: "horizontal" }

                    FieldLabel {
                        label: "Network Activity"
                        description: "Download: 1.2 MB/s | Upload: 320 KB/s"
                        labelColor: Color.mPrimary
                    }
                }
            }

            // === Input Widgets ===
            Card {
                title: "Input Controls"
                Layout.fillWidth: true
                Layout.preferredHeight: 350

                ColumnLayout {
                    spacing: Style.spacingL

                    TextFieldInput {
                        label: "Username"
                        placeholder: "Enter your username"
                        Layout.fillWidth: true
                    }

                    TextFieldInput {
                        label: "API Key"
                        placeholder: "sk-..."
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: Style.spacingL

                        Checkbox {
                            text: "Enable notifications"
                            checked: true
                        }

                        Toggle {
                            text: "Dark mode"
                            checked: true
                        }
                    }

                    RowLayout {
                        spacing: Style.spacingM

                        Text {
                            text: "Theme:"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize
                            color: Color.mOnSurface
                        }

                        QQC.ButtonGroup { id: themeGroup }

                        RadioButton {
                            text: "Auto"
                            checked: true
                            QQC.ButtonGroup.group: themeGroup
                        }

                        RadioButton {
                            text: "Light"
                            QQC.ButtonGroup.group: themeGroup
                        }

                        RadioButton {
                            text: "Dark"
                            QQC.ButtonGroup.group: themeGroup
                        }
                    }
                }
            }

            // === Selection & Dropdown ===
            Card {
                title: "Selection Controls"
                Layout.fillWidth: true
                Layout.preferredHeight: 150

                ColumnLayout {
                    spacing: Style.spacingM

                    ComboBox {
                        label: "Shell Theme"
                        Layout.fillWidth: true
                        model: [
                            {key: "gruvbox", name: "Gruvbox Dark"},
                            {key: "catppuccin", name: "Catppuccin Mocha"},
                            {key: "nord", name: "Nord"},
                            {key: "dracula", name: "Dracula"}
                        ]
                        selectedKey: "gruvbox"
                    }

                    ComboBox {
                        label: "Bar Position"
                        Layout.fillWidth: true
                        model: [
                            {key: "top", name: "Top"},
                            {key: "bottom", name: "Bottom"}
                        ]
                        selectedKey: "top"
                    }
                }
            }

            // === Sliders & Progress ===
            Card {
                title: "Range & Progress"
                Layout.fillWidth: true
                Layout.preferredHeight: 250

                ColumnLayout {
                    spacing: Style.spacingL

                    ColumnLayout {
                        spacing: Style.spacingS

                        Text {
                            text: "Volume: 75%"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize
                            color: Color.mOnSurface
                        }

                        Slider {
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: 75
                            stepSize: 1
                        }
                    }

                    ColumnLayout {
                        spacing: Style.spacingS

                        Text {
                            text: "Brightness: 50%"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize
                            color: Color.mOnSurface
                        }

                        Slider {
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: 50
                            stepSize: 5
                        }
                    }

                    ColumnLayout {
                        spacing: Style.spacingS

                        RowLayout {
                            Text {
                                text: "CPU Usage"
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontSize
                                color: Color.mOnSurface
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "45%"
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontSize * 0.9
                                color: Color.mOnSurfaceVariant
                            }
                        }

                        ProgressBar {
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: 45
                        }
                    }
                }
            }

            // === Buttons ===
            Card {
                title: "Buttons - All Variants"
                Layout.fillWidth: true
                Layout.preferredHeight: 400

                ColumnLayout {
                    spacing: Style.spacingL

                    // Button variants
                    ColumnLayout {
                        spacing: Style.spacingS

                        Text {
                            text: "Text Buttons (Medium)"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize
                            font.weight: Font.Medium
                            color: Color.mOnSurface
                        }

                        RowLayout {
                            spacing: Style.spacingM

                            Button {
                                text: "Primary"
                                variant: "primary"
                            }

                            Button {
                                text: "Secondary"
                                variant: "secondary"
                            }

                            Button {
                                text: "Outlined"
                                variant: "outlined"
                            }

                            Button {
                                text: "Text"
                                variant: "text"
                            }
                        }
                    }

                    // Button sizes
                    ColumnLayout {
                        spacing: Style.spacingS

                        Text {
                            text: "Button Sizes (Primary)"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize
                            font.weight: Font.Medium
                            color: Color.mOnSurface
                        }

                        RowLayout {
                            spacing: Style.spacingM
                            alignment: Qt.AlignLeft

                            Button {
                                text: "Small"
                                variant: "primary"
                                size: "small"
                            }

                            Button {
                                text: "Medium"
                                variant: "primary"
                                size: "medium"
                            }

                            Button {
                                text: "Large"
                                variant: "primary"
                                size: "large"
                            }
                        }
                    }

                    // Icon buttons
                    ColumnLayout {
                        spacing: Style.spacingS

                        Text {
                            text: "Icon Buttons (All Variants)"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize
                            font.weight: Font.Medium
                            color: Color.mOnSurface
                        }

                        RowLayout {
                            spacing: Style.spacingM

                            IconButton {
                                icon: "󰒲"
                                variant: "primary"
                            }

                            IconButton {
                                icon: "󰋩"
                                variant: "secondary"
                            }

                            IconButton {
                                icon: "󰍉"
                                variant: "outlined"
                            }

                            IconButton {
                                icon: "󰅖"
                                variant: "text"
                            }
                        }
                    }

                    // Icon button sizes
                    ColumnLayout {
                        spacing: Style.spacingS

                        Text {
                            text: "Icon Button Sizes (Primary)"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize
                            font.weight: Font.Medium
                            color: Color.mOnSurface
                        }

                        RowLayout {
                            spacing: Style.spacingM
                            alignment: Qt.AlignLeft

                            IconButton {
                                icon: "󰋩"
                                variant: "primary"
                                sizePreset: "small"
                            }

                            IconButton {
                                icon: "󰋩"
                                variant: "primary"
                                sizePreset: "medium"
                            }

                            IconButton {
                                icon: "󰋩"
                                variant: "primary"
                                sizePreset: "large"
                            }
                        }
                    }
                }
            }

            // === Images ===
            Card {
                title: "Images"
                Layout.fillWidth: true
                Layout.preferredHeight: 200

                RowLayout {
                    spacing: Style.spacingL

                    ColumnLayout {
                        spacing: Style.spacingS

                        Text {
                            text: "Rounded Image"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize
                            color: Color.mOnSurface
                        }

                        ImageRounded {
                            width: 120
                            height: 80
                            imagePath: ""
                            fallbackIcon: "󰋩"
                            borderColor: Color.mOutline
                            borderWidth: 1
                        }
                    }

                    ColumnLayout {
                        spacing: Style.spacingS

                        Text {
                            text: "Circular Image"
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize
                            color: Color.mOnSurface
                        }

                        ImageCircled {
                            width: 80
                            height: 80
                            imagePath: ""
                            fallbackIcon: "󰀄"
                            borderColor: Color.mPrimary
                            borderWidth: 2
                        }
                    }
                }
            }

            // === Lists ===
            Card {
                title: "List Items"
                Layout.fillWidth: true
                Layout.preferredHeight: 300

                ColumnLayout {
                    spacing: 0

                    ListItem {
                        icon: "󰌘"
                        title: "System Settings"
                        subtitle: "Display, sound, notifications"
                        trailing: IconButton {
                            icon: "›"
                            variant: "text"
                        }
                    }

                    Divider { Layout.fillWidth: true }

                    ListItem {
                        icon: "󰖩"
                        title: "Network"
                        subtitle: "WiFi, Ethernet, VPN"
                        trailing: Toggle {
                            checked: true
                        }
                    }

                    Divider { Layout.fillWidth: true }

                    ListItem {
                        icon: "󰂯"
                        title: "Bluetooth"
                        subtitle: "Connected to 2 devices"
                        trailing: IconButton {
                            icon: "›"
                            variant: "text"
                        }
                    }
                }
            }

            // === Collapsible ===
            Card {
                title: "Collapsible Sections"
                Layout.fillWidth: true
                Layout.preferredHeight: 350

                ColumnLayout {
                    spacing: Style.spacingM

                    Collapsible {
                        title: "Advanced Settings"
                        expanded: true

                        ColumnLayout {
                            spacing: Style.spacingM

                            Toggle {
                                text: "Enable experimental features"
                            }

                            Toggle {
                                text: "Hardware acceleration"
                                checked: true
                            }

                            TextFieldInput {
                                label: "Custom CSS"
                                placeholder: "Enter custom styles..."
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Collapsible {
                        title: "Developer Options"
                        expanded: false

                        ColumnLayout {
                            spacing: Style.spacingM

                            Checkbox {
                                text: "Show debug overlay"
                            }

                            Checkbox {
                                text: "Verbose logging"
                            }

                            Button {
                                text: "Clear Cache"
                                variant: "outlined"
                            }
                        }
                    }
                }
            }

            // === Loading States ===
            Card {
                title: "Loading Indicators"
                Layout.fillWidth: true
                Layout.preferredHeight: 150

                RowLayout {
                    spacing: Style.spacingXL

                    ColumnLayout {
                        spacing: Style.spacingS
                        Layout.alignment: Qt.AlignHCenter

                        BusyIndicator {
                            running: true
                            size: 40
                        }

                        Text {
                            text: "Loading..."
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize * 0.9
                            color: Color.mOnSurfaceVariant
                        }
                    }

                    ColumnLayout {
                        spacing: Style.spacingS
                        Layout.alignment: Qt.AlignHCenter

                        BusyIndicator {
                            running: true
                            size: 60
                            indicatorColor: Color.mSecondary
                        }

                        Text {
                            text: "Processing..."
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize * 0.9
                            color: Color.mOnSurfaceVariant
                        }
                    }
                }
            }

            // === Context Menu Demo ===
            Card {
                title: "Context Menu (Right-click the button)"
                Layout.fillWidth: true
                Layout.preferredHeight: 150

                Button {
                    text: "Right-click me"
                    variant: "outlined"

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: contextMenu.popup()
                    }

                    ContextMenu {
                        id: contextMenu
                        model: [
                            {icon: "󰆓", text: "Copy", action: "copy"},
                            {icon: "󰆒", text: "Paste", action: "paste"},
                            {icon: "", text: "", action: "separator"},
                            {icon: "󰩺", text: "Delete", action: "delete"}
                        ]
                        onItemClicked: (action) => {
                            console.log("Context menu action:", action)
                        }
                    }
                }
            }

            // Footer spacing
            Item { Layout.preferredHeight: Style.spacingL }
        }
    }
}
