// ShortcutOverlay.qml — semi-transparent panel listing the keyboard shortcuts
// active for the currently-selected visualizer, plus a Global section.
//
// Toggled from main.qml via an F1 Shortcut.  Closes on F1, Esc, or click
// outside the panel.  Grabs focus when shown so the underlying visualizer
// doesn't process key presses behind the overlay.

import QtQuick
import ChickenWire

Rectangle {
    id: overlay
    anchors.fill: parent
    color: "#cc000000"
    visible: false

    // Set by main.qml; selects which per-visualizer section to display.
    property string activeSource: ""

    function toggle() {
        visible = !visible;
        if (visible)
            forceActiveFocus();
    }

    // Per-visualizer shortcut tables.
    readonly property var sectionData: ({
            "tonnetz.qml": [
                {
                    key: "←/→/↑/↓",
                    desc: "Move selection"
                },
                {
                    key: "Shift+↑/↓",
                    desc: "Move along the alternate axis"
                },
                {
                    key: "F5",
                    desc: "Toggle NR distance highlight"
                },
                {
                    key: "Click",
                    desc: "Select note or triad"
                },
                {
                    key: "Drag",
                    desc: "Pan view"
                },
                {
                    key: "Wheel",
                    desc: "Zoom"
                }
            ],
            "chickenWire.qml": [
                {
                    key: "←/→/↑/↓",
                    desc: "Move selection"
                },
                {
                    key: "Shift+↑/↓",
                    desc: "Move along the alternate axis"
                },
                {
                    key: "F5",
                    desc: "Toggle NR distance highlight"
                },
                {
                    key: "Click",
                    desc: "Select face or chord vertex"
                },
                {
                    key: "Drag",
                    desc: "Pan view"
                },
                {
                    key: "Wheel",
                    desc: "Zoom"
                }
            ],
            "cubeDance.qml": [
                {
                    key: "F5",
                    desc: "Toggle NR distance highlight"
                },
                {
                    key: "F7",
                    desc: "Toggle 'actual cubes' mode (split each aug into 2 vertices, one per bordering cluster)"
                },
                {
                    key: "Click",
                    desc: "Select chord"
                },
                {
                    key: "Drag",
                    desc: "Pan view"
                },
                {
                    key: "Wheel",
                    desc: "Zoom"
                }
            ],
            "seventhChords.qml": [
                {
                    key: "F5",
                    desc: "Toggle distance highlight from selected chord"
                },
                {
                    key: "F6",
                    desc: "Toggle chromatic ↔ cycle-of-fourths root order"
                },
                {
                    key: "1 / 2 / 3 / 4",
                    desc: "Toggle P12 / P14 / P23 / P35 (parallel edges)"
                },
                {
                    key: "5 / 6 / 7",
                    desc: "Toggle R12 / R23 / R42 (relative edges)"
                },
                {
                    key: "8 / 9 / 0",
                    desc: "Toggle L13 / L15 / L42 (leading-tone edges)"
                },
                {
                    key: "-",
                    desc: "Toggle Q43 (special Q edge)"
                },
                {
                    key: "= or Backspace",
                    desc: "Restore all transformation classes"
                },
                {
                    key: "Click",
                    desc: "Focus a chord's incident edges"
                },
                {
                    key: "Drag",
                    desc: "Pan view"
                },
                {
                    key: "Wheel",
                    desc: "Zoom"
                }
            ]
        })

    readonly property var globalData: [
        {
            key: "F1",
            desc: "Show / hide this shortcut overlay"
        },
        {
            key: "F4",
            desc: "Next visualizer"
        },
        {
            key: "Shift+F4",
            desc: "Previous visualizer"
        },
        {
            key: "Escape",
            desc: "Clear all selections"
        }
    ]

    readonly property var titleFor: ({
            "tonnetz.qml": "Tonnetz",
            "chickenWire.qml": "Chicken Wire",
            "cubeDance.qml": "Cube Dance",
            "seventhChords.qml": "Seventh Chords"
        })

    focus: visible
    Keys.onPressed: event => {
        if (event.key === Qt.Key_F1 || event.key === Qt.Key_Escape)
            visible = false;
        event.accepted = true;   // swallow everything so the view behind doesn't react
    }

    MouseArea {
        anchors.fill: parent
        onClicked: overlay.visible = false
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 720)
        height: Math.min(parent.height - 80, contentCol.implicitHeight + 40)
        color: Theme.background
        border.color: Theme.nodeStroke
        border.width: 1
        radius: 6

        // Click on the panel itself shouldn't dismiss.
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            spacing: 16

            Text {
                text: "Keyboard Shortcuts"
                color: Theme.selStroke
                font.bold: true
                font.pixelSize: 18
            }

            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: "Global"
                    color: Theme.selStroke
                    font.bold: true
                    font.pixelSize: 13
                }

                Repeater {
                    model: overlay.globalData
                    delegate: Item {
                        width: contentCol.width
                        height: descText.implicitHeight + 2
                        Text {
                            id: keyText
                            width: 200
                            anchors.left: parent.left
                            text: modelData.key
                            color: Theme.nodeText
                            font.family: "monospace"
                            font.pixelSize: 12
                        }
                        Text {
                            id: descText
                            anchors.left: keyText.right
                            anchors.right: parent.right
                            text: modelData.desc
                            color: Theme.labelFaint
                            wrapMode: Text.Wrap
                            font.pixelSize: 12
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 4
                visible: overlay.titleFor[overlay.activeSource] !== undefined

                Text {
                    text: overlay.titleFor[overlay.activeSource] || ""
                    color: Theme.selStroke
                    font.bold: true
                    font.pixelSize: 13
                }

                Repeater {
                    model: overlay.sectionData[overlay.activeSource] || []
                    delegate: Item {
                        width: contentCol.width
                        height: descText2.implicitHeight + 2
                        Text {
                            id: keyText2
                            width: 200
                            anchors.left: parent.left
                            text: modelData.key
                            color: Theme.nodeText
                            font.family: "monospace"
                            font.pixelSize: 12
                        }
                        Text {
                            id: descText2
                            anchors.left: keyText2.right
                            anchors.right: parent.right
                            text: modelData.desc
                            color: Theme.labelFaint
                            wrapMode: Text.Wrap
                            font.pixelSize: 12
                        }
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Press F1, Esc, or click outside to close"
                color: Theme.labelFaint
                font.italic: true
                font.pixelSize: 11
            }
        }
    }
}
