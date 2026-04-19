pragma Singleton
import QtQuick

// Central colour palette for ChickenWire.
// Call Theme.apply("dark"|"light"|"contrast") to switch presets.
// Canvas elements must connect to onThemeChanged and call requestPaint().
QtObject {

    signal themeChanged()

    // Canvas background
    property color background: "#1a1a2e"

    // Tonnetz: default note vertices
    property color nodeFill: "#16213e"
    property color nodeStroke: "#e0e0e0"
    property color nodeText: "#f0f0f0"

    // Neo-Riemannian edges (Tonnetz edges / ChickenWire edges)
    //    L = leading-tone exchange   R = relative   P = parallel
    //    Q = special seventh-chord transformation (Cannas/Andreatta Q43)
    property color edgeL: "#3daee9"
    property color edgeR: "#f67400"
    property color edgeP: "#e93d9a"
    property color edgeQ: "#22cc55"

    // Labels: faint and active (ie when selected)
    property color labelFaint: "#8888aa"
    property color labelActive: "#ffffff"

    // ChickenWire: default triad-vertex styles
    property color majorFill: "#221830"
    property color majorStroke: "#e8a045"
    property color minorFill: "#182030"
    property color minorStroke: "#5a9fd4"
    property color triadText: "#e8e8f0"

    //  Selection (gold) — the single user-selected note or triad
    property color selFill: "#b8860b"
    property color selStroke: "#ffd700"
    property color selText: "#fff8dc"
    property color selTriadFill: Qt.rgba(1.000, 0.824, 0.235, 0.28)
    property color selTriadStroke: Qt.rgba(1.000, 0.824, 0.235, 0.70)
    property color selHexFill: Qt.rgba(1.000, 0.824, 0.235, 0.18)
    property color selHexStroke: Qt.rgba(1.000, 0.824, 0.235, 0.60)

    // Highlight — active (playing) notes / chords
    property color hlFaceFill: Qt.rgba(1.000, 0.824, 0.235, 0.28)
    property color hlEdge: Qt.rgba(1.000, 0.824, 0.235, 0.70)
    property color hlHexStroke: Qt.rgba(1.000, 0.824, 0.235, 0.60)
    property color hlNodeFill: "#b8860b"
    property color hlColor: "#ffd700"

    // Neo-Riemannian triad distance colours — fixed across all themes
    readonly property color nrDist0: "#ffd700"
    readonly property color nrDist1: "#22cc55"
    readonly property color nrDist2: "#00cccc"
    readonly property color nrDist3: "#3355ff"
    readonly property color nrDist4: "#9933ff"
    readonly property color nrDist5: "#cc2222"
    readonly property color nrDist6: "#885522"

    // ── Preset definitions ────────────────────────────────────────────────
    readonly property var presets: ({
        "dark": {
            background:      "#1a1a2e",
            nodeFill:        "#16213e",
            nodeStroke:      "#e0e0e0",
            nodeText:        "#f0f0f0",
            edgeL:           "#3daee9",
            edgeR:           "#f67400",
            edgeP:           "#e93d9a",
            edgeQ:           "#22cc55",
            labelFaint:      "#8888aa",
            labelActive:     "#ffffff",
            majorFill:       "#221830",
            majorStroke:     "#e8a045",
            minorFill:       "#182030",
            minorStroke:     "#5a9fd4",
            triadText:       "#e8e8f0",
            selFill:         "#b8860b",
            selStroke:       "#ffd700",
            selText:         "#fff8dc",
            selTriadFill:    Qt.rgba(1.000, 0.824, 0.235, 0.28),
            selTriadStroke:  Qt.rgba(1.000, 0.824, 0.235, 0.70),
            selHexFill:      Qt.rgba(1.000, 0.824, 0.235, 0.18),
            selHexStroke:    Qt.rgba(1.000, 0.824, 0.235, 0.60),
            hlFaceFill:      Qt.rgba(1.000, 0.824, 0.235, 0.28),
            hlEdge:          Qt.rgba(1.000, 0.824, 0.235, 0.70),
            hlHexStroke:     Qt.rgba(1.000, 0.824, 0.235, 0.60),
            hlNodeFill:      "#b8860b",
            hlColor:         "#ffd700"
        },
        "light": {
            // Monochrome white background; all edges the same grey;
            // yellow used only for selection/highlight.
            background:      "#ffffff",
            nodeFill:        "#f8f8f8",
            nodeStroke:      "#555555",
            nodeText:        "#222222",
            edgeL:           "#888888",
            edgeR:           "#888888",
            edgeP:           "#888888",
            edgeQ:           "#888888",
            labelFaint:      "#999999",
            labelActive:     "#111111",
            majorFill:       "#f8f8f8",
            majorStroke:     "#333333",
            minorFill:       "#e8e8e8",
            minorStroke:     "#666666",
            triadText:       "#333333",
            selFill:         "#b8860b",
            selStroke:       "#ffd700",
            selText:         "#000000",
            selTriadFill:    Qt.rgba(1.000, 0.843, 0.000, 0.25),
            selTriadStroke:  Qt.rgba(1.000, 0.843, 0.000, 0.70),
            selHexFill:      Qt.rgba(1.000, 0.843, 0.000, 0.18),
            selHexStroke:    Qt.rgba(1.000, 0.843, 0.000, 0.60),
            hlFaceFill:      Qt.rgba(1.000, 0.843, 0.000, 0.25),
            hlEdge:          Qt.rgba(1.000, 0.843, 0.000, 0.70),
            hlHexStroke:     Qt.rgba(1.000, 0.843, 0.000, 0.60),
            hlNodeFill:      "#b8860b",
            hlColor:         "#ffd700"
        },
        "contrast": {
            // Pure black background with fully-saturated edge colours.
            background:      "#000000",
            nodeFill:        "#0d0d1a",
            nodeStroke:      "#cccccc",
            nodeText:        "#ffffff",
            edgeL:           "#00aaff",
            edgeR:           "#ff6600",
            edgeP:           "#ff00cc",
            edgeQ:           "#00ff88",
            labelFaint:      "#aaaacc",
            labelActive:     "#ffffff",
            majorFill:       "#1a0d22",
            majorStroke:     "#ffcc00",
            minorFill:       "#0d1a22",
            minorStroke:     "#00ccff",
            triadText:       "#ffffff",
            selFill:         "#b8860b",
            selStroke:       "#ffd700",
            selText:         "#ffffff",
            selTriadFill:    Qt.rgba(1.000, 0.824, 0.235, 0.38),
            selTriadStroke:  Qt.rgba(1.000, 0.824, 0.235, 0.90),
            selHexFill:      Qt.rgba(1.000, 0.824, 0.235, 0.25),
            selHexStroke:    Qt.rgba(1.000, 0.824, 0.235, 0.80),
            hlFaceFill:      Qt.rgba(1.000, 0.824, 0.235, 0.38),
            hlEdge:          Qt.rgba(1.000, 0.824, 0.235, 0.90),
            hlHexStroke:     Qt.rgba(1.000, 0.824, 0.235, 0.80),
            hlNodeFill:      "#b8860b",
            hlColor:         "#ffd700"
        }
    })

    function apply(name) {
        var t = presets[name] || presets["dark"];
        background      = t.background;
        nodeFill        = t.nodeFill;
        nodeStroke      = t.nodeStroke;
        nodeText        = t.nodeText;
        edgeL           = t.edgeL;
        edgeR           = t.edgeR;
        edgeP           = t.edgeP;
        edgeQ           = t.edgeQ;
        labelFaint      = t.labelFaint;
        labelActive     = t.labelActive;
        majorFill       = t.majorFill;
        majorStroke     = t.majorStroke;
        minorFill       = t.minorFill;
        minorStroke     = t.minorStroke;
        triadText       = t.triadText;
        selFill         = t.selFill;
        selStroke       = t.selStroke;
        selText         = t.selText;
        selTriadFill    = t.selTriadFill;
        selTriadStroke  = t.selTriadStroke;
        selHexFill      = t.selHexFill;
        selHexStroke    = t.selHexStroke;
        hlFaceFill      = t.hlFaceFill;
        hlEdge          = t.hlEdge;
        hlHexStroke     = t.hlHexStroke;
        hlNodeFill      = t.hlNodeFill;
        hlColor         = t.hlColor;
        themeChanged();
    }
}
