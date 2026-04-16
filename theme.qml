pragma Singleton
import QtQuick

// Central colour palette for ChickenWire.
// Edit values here to retheme the entire application.
QtObject {

    // Canvas background
    readonly property color background:     "#1a1a2e"

    // Tonnetz: default note vertices
    readonly property color nodeFill:       "#16213e"
    readonly property color nodeStroke:     "#e0e0e0"
    readonly property color nodeText:       "#f0f0f0"

    // Neo-Riemannian edges (Tonnetz edges / ChickenWire edges)
    //    L = leading-tone exchange   R = relative   P = parallel
    readonly property color edgeL:          "#3daee9"   // blue   (was "#6a9fd4")
    readonly property color edgeR:          "#f67400"   // orange (was "#d4964a")
    readonly property color edgeP:          "#e93d9a"   // pink   (was "#d47a9b")

    // Labels: faint and active (ie when selected)
    readonly property color labelFaint:     "#8888aa"
    readonly property color labelActive:    "#ffffff"

    // ChickenWire: default triad-vertex styles
    readonly property color majorFill:      "#221830"
    readonly property color majorStroke:    "#e8a045"   // warm amber
    readonly property color minorFill:      "#182030"
    readonly property color minorStroke:    "#5a9fd4"   // cool blue
    readonly property color triadText:      "#e8e8f0"

    //  Selection (gold) — the single user-selected note or triad
    readonly property color selFill:        "#b8860b"
    readonly property color selStroke:      "#ffd700"
    readonly property color selText:        "#fff8dc"

    // Tonnetz: filled triangle when a triad is selected
    readonly property color selTriadFill:   Qt.rgba(1.000, 0.824, 0.235, 0.28)
    readonly property color selTriadStroke: Qt.rgba(1.000, 0.824, 0.235, 0.70)

    // ChickenWire: filled hexagon when a note is selected
    readonly property color selHexFill:     Qt.rgba(1.000, 0.824, 0.235, 0.18)
    readonly property color selHexStroke:   Qt.rgba(1.000, 0.824, 0.235, 0.60)

    // Neo-Riemannian triad distance colours
    // Used when a triad is selected; each colour represents the minimum number
    // of P/R/L steps to reach that triad.  Max reachable distance is 5.
    readonly property color nrDist0: "#ffd700"   // d=0: selected (gold)
    readonly property color nrDist1: "#22cc55"   // d=1: green
    readonly property color nrDist2: "#00cccc"   // d=2: cyan
    readonly property color nrDist3: "#3355ff"   // d=3: blue
    readonly property color nrDist4: "#9933ff"   // d=4: violet
    readonly property color nrDist5: "#cc2222"   // d=5: red
    readonly property color nrDist6: "#885522"   // d=6: brown (unreachable in Tonnetz/ChickenWire; reachable in Cube Dance)

    // Highlight — arbitrary note-set via setHighlightedNotes()
    readonly property color hlFaceFill:     selTriadFill    // Tonnetz triangle / CW hex face interior
    readonly property color hlEdge:         selTriadStroke  // Tonnetz edge overlay
    readonly property color hlHexStroke:    selHexStroke    // ChickenWire hex face border
    readonly property color hlNodeFill:     selFill         // node / vertex background
    readonly property color hlColor:        selStroke       // node ring and label text
}
