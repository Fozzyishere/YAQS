import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../../Commons"
import "../../Services"
import "../../Widgets"
import "Widgets"

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: panel

            required property var modelData

            property real scaling: Scaling.getScreenScale(modelData)

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
            }

            Item {
                anchors.fill: parent
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: Theme.bg_alt
                    border.color: Theme.fg_dim
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

                            // App launcher
                            AppLauncher {
                                scaling: panel.scaling
                            }

                            // Clock
                            Clock {
                                scaling: panel.scaling
                            }

                            // Separator
                            Rectangle {
                                width: 1
                                height: Math.round(Theme.bar_height * 0.5 * scaling)
                                color: Theme.fg_dim
                                opacity: 0.3
                            }

                            // Window title
                            WindowTitle {
                                screen: panel.modelData
                                scaling: panel.scaling
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            id: rightSection
                            Layout.alignment: Qt.AlignRight
                            spacing: Math.round(Theme.spacing_s * scaling)

                            // Power menu
                            PowerMenu {
                                scaling: panel.scaling
                            }
                        }
                    }

                    // Center section with absolute positioning for true centering
                    RowLayout {
                        id: centerSection
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(Theme.spacing_xs * scaling)

                        // Workspaces
                        Workspaces {
                            screen: panel.modelData
                            scaling: panel.scaling
                        }
                    }
                }
            }
        }
    }
}
