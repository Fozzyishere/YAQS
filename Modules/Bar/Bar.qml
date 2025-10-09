import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../../Commons"
import "../../Services"
import "." as BarComponents

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: panel

            required property var modelData

            property real scaling: Scaling.getScreenScale(modelData)

            // Widget layout configuration. Edit to change widget order.
            property var widgetLayout: ({
                "left": ["AppLauncher", "Clock", "WindowTitle"],
                "center": ["Workspaces"],
                "right": ["MediaMini", "WiFi", "Brightness", "Audio", "Battery", "PowerMenu"]
            })

            Connections {
                target: Scaling
                function onScaleChanged(screenName, scale) {
                    if (modelData && screenName === modelData.name) {
                        scaling = scale;
                    }
                }
            }

            screen: modelData
            visible: true
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: Math.round(Theme.bar_margin_top * scaling)
                left: Math.round(Theme.bar_margin_side * scaling)
                right: Math.round(Theme.bar_margin_side * scaling)
                bottom: Math.round(Theme.bar_margin_bottom * scaling)
            }

            implicitHeight: Math.round(Theme.bar_height * scaling)

            WlrLayershell.namespace: "YAQS"

            Component.onCompleted: {
                Logger.log("Bar", `Created on "${modelData.name}" (${modelData.width}x${modelData.height}, scale=${scaling})`);
                Logger.log("Bar", "Widget layout:", JSON.stringify(widgetLayout, null, 2));
            }

            Item {
                anchors.fill: parent
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: Theme.bg0_hard
                    border.color: Theme.fg3
                    border.width: 2
                    radius: Theme.radius_m

                    // Left and right sections in RowLayout
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(Theme.spacing_m * scaling)
                        anchors.rightMargin: Math.round(Theme.spacing_m * scaling)
                        spacing: Math.round(Theme.spacing_m * scaling)

                        RowLayout {
                            id: leftSection
                            Layout.alignment: Qt.AlignLeft
                            spacing: Math.round(Theme.spacing_s * scaling)

                            Repeater {
                                model: panel.widgetLayout.left

                                delegate: BarComponents.BarWidgetLoader {
                                    required property string modelData
                                    required property int index
                                    
                                    widgetId: modelData
                                    screen: panel.modelData
                                    scaling: panel.scaling
                                    section: "left"
                                    sectionIndex: index
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            id: rightSection
                            Layout.alignment: Qt.AlignRight
                            spacing: Math.round(Theme.spacing_s * scaling)

                            Repeater {
                                model: panel.widgetLayout.right

                                delegate: BarComponents.BarWidgetLoader {
                                    required property string modelData
                                    required property int index
                                    
                                    widgetId: modelData
                                    screen: panel.modelData
                                    scaling: panel.scaling
                                    section: "right"
                                    sectionIndex: index
                                }
                            }
                        }
                    }

                    // Center section with absolute positioning for true centering
                    RowLayout {
                        id: centerSection
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(Theme.spacing_xs * scaling)

                        Repeater {
                            model: panel.widgetLayout.center

                            delegate: BarComponents.BarWidgetLoader {
                                required property string modelData
                                required property int index
                                
                                widgetId: modelData
                                screen: panel.modelData
                                scaling: panel.scaling
                                section: "center"
                                sectionIndex: index
                            }
                        }
                    }
                }
            }
        }
    }
}
