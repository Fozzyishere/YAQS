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
                top: Math.round(Settings.data.bar.marginTop * scaling)
                left: Math.round(Settings.data.bar.marginSide * scaling)
                right: Math.round(Settings.data.bar.marginSide * scaling)
                bottom: Math.round(Settings.data.bar.marginBottom * scaling)
            }

            implicitHeight: Math.round(Settings.data.bar.height * scaling)

            WlrLayershell.namespace: "YAQS"

            Component.onCompleted: {
                Logger.log("Bar", `Created on "${modelData.name}" (${modelData.width}x${modelData.height}, scale=${scaling})`);
                Logger.log("Bar", "Loaded with",
                    Settings.data.bar.widgets.left.length, "left,",
                    Settings.data.bar.widgets.center.length, "center,",
                    Settings.data.bar.widgets.right.length, "right widgets");
            }

            Item {
                anchors.fill: parent
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: Color.mSurface
                    border.color: Color.mOutlineVariant
                    border.width: 2
                    radius: Style.radiusM

                    // Left and right sections in RowLayout
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(Style.spacingM * scaling)
                        anchors.rightMargin: Math.round(Style.spacingM * scaling)
                        spacing: Math.round(Style.spacingM * scaling)

                        RowLayout {
                            id: leftSection
                            Layout.alignment: Qt.AlignLeft
                            spacing: Math.round(Style.spacingS * scaling)

                            Repeater {
                                model: Settings.data.bar.widgets.left

                                delegate: BarComponents.BarWidgetLoader {
                                    required property var modelData
                                    required property int index

                                    widgetId: modelData.id || ""
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
                            spacing: Math.round(Style.spacingS * scaling)

                            Repeater {
                                model: Settings.data.bar.widgets.right

                                delegate: BarComponents.BarWidgetLoader {
                                    required property var modelData
                                    required property int index

                                    widgetId: modelData.id || ""
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
                        spacing: Math.round(Style.spacingXs * scaling)

                        Repeater {
                            model: Settings.data.bar.widgets.center

                            delegate: BarComponents.BarWidgetLoader {
                                required property var modelData
                                required property int index

                                widgetId: modelData.id || ""
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
