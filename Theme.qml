pragma Singleton
import QtQuick

// Central colour palette for ChickenWire.
// Edit values here to retheme the entire application.
QtObject {

    // ── Canvas background ────────────────────────────────────────────────────
    readonly property color background:     "#1a1a2e"

    // ── Tonnetz: default note vertices ───────────────────────────────────────
    readonly property color nodeFill:       "#16213e"
    readonly property color nodeStroke:     "#e0e0e0"
    readonly property color nodeText:       "#f0f0f0"

    // ── Neo-Riemannian edges (Tonnetz edges / ChickenWire edges) ─────────────
    //    L = leading-tone exchange   R = relative   P = parallel
    readonly property color edgeL:          "#4a9eff"   // blue
    readonly property color edgeR:          "#ff9f43"   // orange
    readonly property color edgeP:          "#ff6b9d"   // pink

    // ── Faint labels (triad names in Tonnetz triangles; note names in ChickenWire faces) ──
    readonly property color labelFaint:     "#8888aa"

    // ── ChickenWire: default triad-vertex styles ─────────────────────────────
    readonly property color majorFill:      "#221830"
    readonly property color majorStroke:    "#e8a045"   // warm amber
    readonly property color minorFill:      "#182030"
    readonly property color minorStroke:    "#5a9fd4"   // cool blue
    readonly property color triadText:      "#e8e8f0"

    // ── Selection (gold) — the single user-selected note or triad ────────────
    readonly property color selFill:        "#b8860b"
    readonly property color selStroke:      "#ffd700"
    readonly property color selText:        "#fff8dc"
    // Tonnetz: filled triangle when a triad is selected
    readonly property color selTriadFill:   Qt.rgba(1.000, 0.824, 0.235, 0.28)
    readonly property color selTriadStroke: Qt.rgba(1.000, 0.824, 0.235, 0.70)
    // ChickenWire: filled hexagon when a note is selected
    readonly property color selHexFill:     Qt.rgba(1.000, 0.824, 0.235, 0.18)
    readonly property color selHexStroke:   Qt.rgba(1.000, 0.824, 0.235, 0.60)

    // ── Neo-Riemannian triad distance colours ───────────────────────────────────
    //    Used when a triad is selected; each colour represents the minimum number
    //    of P/R/L steps to reach that triad.  Max reachable distance is 5.
    readonly property color nrDist0: "#ffd700"   // d=0: selected (gold)
    readonly property color nrDist1: "#22cc55"   // d=1: green
    readonly property color nrDist2: "#00cccc"   // d=2: cyan
    readonly property color nrDist3: "#3355ff"   // d=3: blue
    readonly property color nrDist4: "#9933ff"   // d=4: violet
    readonly property color nrDist5: "#cc2222"   // d=5: red
    readonly property color nrDist6: "#885522"   // d=6: brown (unreachable — diameter is 5)

    // ── Highlight (white) — arbitrary note-set via setHighlightedNotes() ─────
    readonly property color hlFaceFill:     Qt.rgba(1, 1, 1, 0.12)   // Tonnetz triangle / CW hex face interior
    readonly property color hlEdge:         Qt.rgba(1, 1, 1, 0.85)   // Tonnetz edge overlay
    readonly property color hlHexStroke:    Qt.rgba(1, 1, 1, 0.75)   // ChickenWire hex face border
    readonly property color hlNodeFill:     "#1e1e30"                 // node / vertex background
    readonly property color hlColor:        "#ffffff"                 // node ring and label text

    // ── MIDI playback: currently sounding notes ──────────────────────────────
    // Green (neon)
    readonly property color playColor:     "#39ff14"
    readonly property color playFaceFill:  Qt.rgba(0.224, 1.0, 0.078, 0.15)
    readonly property color playHexStroke: Qt.rgba(0.224, 1.0, 0.078, 0.70)
    readonly property color playNodeFill:  "#0d1f0a"
    readonly property color playNodeText:  "#39ff14"

    // White
    // readonly property color playColor:     "#ffffff"
    // readonly property color playFaceFill:  Qt.rgba(1, 1, 1, 0.12)
    // readonly property color playHexStroke: Qt.rgba(1, 1, 1, 0.75)
    // readonly property color playNodeFill:  "#1e1e30"
    // readonly property color playNodeText:  "#ffffff"
}
