// cubeDance.qml — fixed graph of 24 triads + 4 augmented chord nodes arranged
// into 4 hexatonic cycles (Richard Cohn's "Cube Dance" representation).
//
// Each hexatonic cycle contains 6 triads (3 major + 3 minor) connected by
// alternating P and L neo-Riemannian transformations, arranged as a 2×3 grid.
// The 4 augmented chord nodes sit at the cardinal points and each connect via
// semitone voice-leading to 3 major triads (from their own hexatonic cycle) and
// 3 minor triads (from an adjacent cycle).  R-transformation edges cross between
// adjacent hexatonic cycles.
//
// Edge colour coding matches Tonnetz / ChickenWire:
//   P (parallel)             pink
//   L (leading-tone exchange) blue
//   R (relative)             orange
//   augmented-chord edges    grey  (semitone voice leading, not a NR transformation)

import QtQuick
import ChickenWire

Item {
    id: root
    focus: true

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_F5) {
            canvas.showDistances = !canvas.showDistances
            if (canvas.showDistances && canvas.selNode >= 0) {
                canvas.nodeDists = canvas.computeDistances(canvas.selNode)
            } else {
                canvas.nodeDists = []
            }
            canvas.requestPaint()
            event.accepted = true
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        property var noteNames:          tonnetzController.noteNames
        property var majorRootNoteNames: tonnetzController.majorRootNoteNames
        property var minorRootNoteNames: tonnetzController.minorRootNoteNames
        property int  activeNotes:   tonnetzController.activeNotes
        property bool showAugmented: visualizerSwitcher.showAugmented

        onNoteNamesChanged:          requestPaint()
        onMajorRootNoteNamesChanged: requestPaint()
        onMinorRootNoteNamesChanged: requestPaint()
        onActiveNotesChanged:        requestPaint()
        onShowAugmentedChanged:      requestPaint()

        // Viewport — independent of Tonnetz / ChickenWire coordinate system.
        property real originX: width  / 2
        property real originY: height / 2
        property real scale:   1.0

        // Currently selected node index, or -1.
        property int selNode: -1

        // NR distance from selected node to every other node.
        // Empty when no node is selected or distance mode is off.
        property bool showDistances: false
        property var  nodeDists: []

        // Base size: 1 layout unit = baseUnit px at scale 1.
        readonly property real baseUnit: 58.0

        // Largest extent of the layout in layout units (the 4 augmented
        // chords sit at ±5 along the cardinal axes), used to auto-fit the
        // figure on resize.  Outermost shapes are the augmented squares with
        // half-width 17 px at scale = 1, so we add that to the figure extent
        // so the squares' outer edges (not their centres) are what fit.
        readonly property real figureRadius: 5.0
        readonly property real nodeExtentPx: 17

        function fitToWindow() {
            if (width <= 0 || height <= 0) return
            var avail = Math.min(width, height) / 2 - 20
            var fr    = baseUnit * figureRadius + nodeExtentPx
            if (fr < 1) return
            scale   = Math.max(0.1, avail / fr)
            originX = width / 2
            originY = height / 2
            requestPaint()
        }
        onWidthChanged:        fitToWindow()
        onHeightChanged:       fitToWindow()
        Component.onCompleted: fitToWindow()

        // BFS over the explicit edge table.  Returns an array of length
        // nodes.length where each entry is the shortest-path distance from
        // startIdx, or -1 if unreachable (every node IS reachable here).
        function computeDistances(startIdx) {
            var dist = []
            var i
            for (i = 0; i < nodes.length; i++) dist[i] = -1
            dist[startIdx] = 0
            var queue = [startIdx]
            var head  = 0
            while (head < queue.length) {
                var cur = queue[head++]
                for (var ei = 0; ei < edges.length; ei++) {
                    var e   = edges[ei]
                    var nbr = -1
                    if      (e[0] === cur) nbr = e[1]
                    else if (e[1] === cur) nbr = e[0]
                    if (nbr >= 0 && dist[nbr] < 0) {
                        dist[nbr] = dist[cur] + 1
                        queue.push(nbr)
                    }
                }
            }
            return dist
        }

        function isAct(s) { return !!((activeNotes >> s) & 1) }

        function nodeIsActive(idx) {
            var n = nodes[idx]
            return isAct(n.s0) && isAct(n.s1) && isAct(n.s2)
        }

        function nodePos(idx) {
            var n = nodes[idx]
            return Qt.point(
                originX + n.lx * baseUnit * scale,
                originY - n.ly * baseUnit * scale
            )
        }

        function nodeLabel(idx) {
            var n = nodes[idx]
            if (n.type === "aug")
                return majorRootNoteNames[n.root] + "+"
            if (n.type === "major")
                return majorRootNoteNames[n.root]
            return minorRootNoteNames[n.root] + "m"
        }

        // ── Node table ────────────────────────────────────────────────────────
        //   lx, ly  : layout coordinates (y up; 1 unit ≈ baseUnit px at scale 1)
        //   type    : "aug" | "major" | "minor"
        //   s0..s2  : three semitones (root, third, fifth)
        //   root    : root semitone used for label lookup
        //
        //   Augmented chord nodes (indices 0–3) — cardinal positions
        //   Db+ cycle cluster (indices 4–9)  — upper-left
        //   C+  cycle cluster (indices 10–15) — upper-right
        //   D+  cycle cluster (indices 16–21) — lower-left
        //   Eb+ cycle cluster (indices 22–27) — lower-right
        property var nodes: [
            // ── Augmented chords ──────────────────────────────────────────
            // 0  C+
            { lx:  0.00, ly:  5.0, type: "aug",   s0:  0, s1:  4, s2:  8, root:  0 },
            // 1  Db+
            { lx: -5.00, ly:  0.0, type: "aug",   s0:  1, s1:  5, s2:  9, root:  1 },
            // 2  Eb+
            { lx:  5.00, ly:  0.0, type: "aug",   s0:  3, s1:  7, s2: 11, root:  3 },
            // 3  D+
            { lx:  0.00, ly: -5.0, type: "aug",   s0:  2, s1:  6, s2: 10, root:  2 },

            // ── Db+ hexatonic cycle (upper-left, rotated +45°) ───────────
            // Horizontal edges: F–Am, C#m–Db  (shared ly)
            // Vertical edges:   Am–A, Db–Fm   (shared lx)
            // Diagonal edges:   A–C#m, Fm–F   (Δlx = Δly = 0.85)
            // 4  F
            { lx: -3.275, ly:  2.425, type: "major", s0:  5, s1:  9, s2:  0, root:  5 },
            // 5  Am
            { lx: -1.575, ly:  2.425, type: "minor", s0:  9, s1:  0, s2:  4, root:  9 },
            // 6  Fm
            { lx: -2.425, ly:  3.275, type: "minor", s0:  5, s1:  8, s2:  0, root:  5 },
            // 7  A
            { lx: -1.575, ly:  0.725, type: "major", s0:  9, s1:  1, s2:  4, root:  9 },
            // 8  Db
            { lx: -2.425, ly:  1.575, type: "major", s0:  1, s1:  5, s2:  8, root:  1 },
            // 9  C#m
            { lx: -0.725, ly:  1.575, type: "minor", s0:  1, s1:  4, s2:  8, root:  1 },

            // ── C+ hexatonic cycle (upper-right, rotated −45°) ───────────
            // Horizontal edges: Cm–Ab, E–Em   (shared ly)
            // Vertical edges:   Ab–Abm, Em–C  (shared lx)
            // Diagonal edges:   C–Cm, Abm–E   (Δlx = Δly = 0.85)
            // 10  C
            { lx:  2.425, ly:  3.275, type: "major", s0:  0, s1:  4, s2:  7, root:  0 },
            // 11  Cm
            { lx:  3.275, ly:  2.425, type: "minor", s0:  0, s1:  3, s2:  7, root:  0 },
            // 12  Em
            { lx:  2.425, ly:  1.575, type: "minor", s0:  4, s1:  7, s2: 11, root:  4 },
            // 13  Ab
            { lx:  1.575, ly:  2.425, type: "major", s0:  8, s1:  0, s2:  3, root:  8 },
            // 14  E
            { lx:  0.725, ly:  1.575, type: "major", s0:  4, s1:  8, s2: 11, root:  4 },
            // 15  Abm
            { lx:  1.575, ly:  0.725, type: "minor", s0:  8, s1: 11, s2:  3, root:  8 },

            // ── D+ hexatonic cycle (lower-left, rotated −45°) ────────────
            // Horizontal edges: Bbm–F#, D–Dm  (shared ly)
            // Vertical edges:   Dm–Bb, F#–F#m (shared lx)
            // Diagonal edges:   Bb–Bbm, F#m–D (Δlx = Δly = 0.85)
            // 16  Dm
            { lx: -2.425, ly: -1.575, type: "minor", s0:  2, s1:  5, s2:  9, root:  2 },
            // 17  Bb
            { lx: -2.425, ly: -3.275, type: "major", s0: 10, s1:  2, s2:  5, root: 10 },
            // 18  D
            { lx: -0.725, ly: -1.575, type: "major", s0:  2, s1:  6, s2:  9, root:  2 },
            // 19  Bbm
            { lx: -3.275, ly: -2.425, type: "minor", s0: 10, s1:  1, s2:  5, root: 10 },
            // 20  F#m
            { lx: -1.575, ly: -0.725, type: "minor", s0:  6, s1:  9, s2:  1, root:  6 },
            // 21  F#
            { lx: -1.575, ly: -2.425, type: "major", s0:  6, s1: 10, s2:  1, root:  6 },

            // ── Eb+ hexatonic cycle (lower-right, rotated +45°) ──────────
            // Horizontal edges: Bm–G, Eb–Ebm  (shared ly)
            // Vertical edges:   B–Bm, Gm–Eb   (shared lx)
            // Diagonal edges:   Ebm–B, G–Gm   (Δlx = Δly = 0.85)
            // 22  Ebm
            { lx:  0.725, ly: -1.575, type: "minor", s0:  3, s1:  6, s2: 10, root:  3 },
            // 23  B
            { lx:  1.575, ly: -0.725, type: "major", s0: 11, s1:  3, s2:  6, root: 11 },
            // 24  Eb
            { lx:  2.425, ly: -1.575, type: "major", s0:  3, s1:  7, s2: 10, root:  3 },
            // 25  Bm
            { lx:  1.575, ly: -2.425, type: "minor", s0: 11, s1:  2, s2:  6, root: 11 },
            // 26  Gm
            { lx:  2.425, ly: -3.275, type: "minor", s0:  7, s1: 10, s2:  2, root:  7 },
            // 27  G
            { lx:  3.275, ly: -2.425, type: "major", s0:  7, s1: 11, s2:  2, root:  7 }
        ]

        // ── Edge table ────────────────────────────────────────────────────────
        // [nodeA, nodeB, type]
        property var edges: [
            // Db+ hexatonic cycle  (F –L– Am –P– A –L– C#m –P– Db –L– Fm –P– F)
            [4,  5,  "L"], [5,  7,  "P"], [7,  9,  "L"],
            [9,  8,  "P"], [8,  6,  "L"], [6,  4,  "P"],

            // C+ hexatonic cycle   (C –P– Cm –L– Ab –P– Abm –L– E –P– Em –L– C)
            [10, 11, "P"], [11, 13, "L"], [13, 15, "P"],
            [15, 14, "L"], [14, 12, "P"], [12, 10, "L"],

            // D+ hexatonic cycle   (Dm –L– Bb –P– Bbm –L– F# –P– F#m –L– D –P– Dm)
            [16, 17, "L"], [17, 19, "P"], [19, 21, "L"],
            [21, 20, "P"], [20, 18, "L"], [18, 16, "P"],

            // Eb+ hexatonic cycle  (Ebm –L– B –P– Bm –L– G –P– Gm –L– Eb –P– Ebm)
            [22, 23, "L"], [23, 25, "P"], [25, 27, "L"],
            [27, 26, "P"], [26, 24, "L"], [24, 22, "P"],

            // C+  augmented → its 3 major triads (own cycle) + 3 minor triads (Db+ cycle)
            [0, 10, "aug"], [0, 13, "aug"], [0, 14, "aug"],
            [0,  5, "aug"], [0,  6, "aug"], [0,  9, "aug"],

            // Db+ augmented → its 3 major triads (own cycle) + 3 minor triads (D+ cycle)
            [1,  4, "aug"], [1,  7, "aug"], [1,  8, "aug"],
            [1, 16, "aug"], [1, 19, "aug"], [1, 20, "aug"],

            // Eb+ augmented → its 3 major triads (own cycle) + 3 minor triads (C+ cycle)
            [2, 23, "aug"], [2, 24, "aug"], [2, 27, "aug"],
            [2, 11, "aug"], [2, 12, "aug"], [2, 15, "aug"],

            // D+  augmented → its 3 major triads (own cycle) + 3 minor triads (Eb+ cycle)
            [3, 17, "aug"], [3, 18, "aug"], [3, 21, "aug"],
            [3, 22, "aug"], [3, 25, "aug"], [3, 26, "aug"],

        ]

        // ── Hit testing ───────────────────────────────────────────────────────

        function hitTest(px, py) {
            var r2 = Math.pow(Math.max(6, 16 * scale), 2)
            var bestDist2 = r2
            var best = -1
            for (var i = 0; i < nodes.length; i++) {
                var p  = nodePos(i)
                var d2 = (px - p.x) * (px - p.x) + (py - p.y) * (py - p.y)
                if (d2 < bestDist2) { bestDist2 = d2; best = i }
            }
            return best
        }

        function scrollIntoView(screenPt) {
            var margin = 100
            if      (screenPt.x < margin)          originX += margin - screenPt.x
            else if (screenPt.x > width  - margin) originX -= screenPt.x - (width  - margin)
            if      (screenPt.y < margin)          originY += margin - screenPt.y
            else if (screenPt.y > height - margin) originY -= screenPt.y - (height - margin)
        }

        // ── Paint ─────────────────────────────────────────────────────────────

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var r        = Math.max(5,  15 * scale)
            var augHW    = Math.max(6,  17 * scale)   // augmented square half-width
            var fontSize = Math.max(1,  11 * scale)
            var augFont  = Math.max(1,  10 * scale)

            ctx.lineCap = "round"

            // ── Edges ─────────────────────────────────────────────────────
            for (var ei = 0; ei < edges.length; ei++) {
                var e  = edges[ei]
                var pa = nodePos(e[0])
                var pb = nodePos(e[1])

                if (e[2] === "aug") {
                    ctx.lineWidth   = Math.max(0.5, 0.9 * scale)
                    ctx.strokeStyle = "#707070"
                } else {
                    ctx.lineWidth   = Math.max(0.5, 1.8 * scale)
                    ctx.strokeStyle = e[2] === "P" ? Theme.edgeP : Theme.edgeL
                }
                ctx.beginPath()
                ctx.moveTo(pa.x, pa.y)
                ctx.lineTo(pb.x, pb.y)
                ctx.stroke()
            }

            // ── Highlight active edges ─────────────────────────────────────
            if (activeNotes !== 0) {
                ctx.lineWidth   = Math.max(1, 3 * scale)
                ctx.strokeStyle = Theme.hlEdge
                for (var hi = 0; hi < edges.length; hi++) {
                    var he = edges[hi]
                    if (he[2] === "aug") continue   // skip aug-chord spokes
                    if (nodeIsActive(he[0]) && nodeIsActive(he[1])) {
                        var ha = nodePos(he[0])
                        var hb = nodePos(he[1])
                        ctx.beginPath(); ctx.moveTo(ha.x, ha.y); ctx.lineTo(hb.x, hb.y); ctx.stroke()
                    }
                }
            }

            // ── Nodes ─────────────────────────────────────────────────────
            var nrC = [Theme.nrDist0, Theme.nrDist1, Theme.nrDist2, Theme.nrDist3,
                       Theme.nrDist4, Theme.nrDist5, Theme.nrDist6]

            for (var ni = 0; ni < nodes.length; ni++) {
                var n       = nodes[ni]
                var np      = nodePos(ni)
                var active  = nodeIsActive(ni)
                var sel     = (ni === selNode)
                var augGlow = (n.type === "aug") && active && showAugmented
                var nrD     = (nodeDists.length > 0) ? nodeDists[ni] : -1

                if (n.type === "aug") {
                    // Square node for augmented chord
                    ctx.beginPath()
                    ctx.rect(np.x - augHW, np.y - augHW, augHW * 2, augHW * 2)
                    if (sel || augGlow) {
                        ctx.fillStyle   = Theme.selFill
                        ctx.strokeStyle = Theme.selStroke
                        ctx.lineWidth   = Math.max(0.5, 2.5 * scale)
                    } else if (nrD >= 0 && nrD < nrC.length) {
                        var nrClrA = nrC[nrD]
                        ctx.fillStyle   = Qt.rgba(nrClrA.r, nrClrA.g, nrClrA.b, 0.35)
                        ctx.strokeStyle = nrClrA
                        ctx.lineWidth   = Math.max(0.5, 2.5 * scale)
                    } else {
                        ctx.fillStyle   = Theme.nodeFill
                        ctx.strokeStyle = Theme.nodeStroke
                        ctx.lineWidth   = Math.max(0.5, 1.5 * scale)
                    }
                    ctx.fill()
                    ctx.stroke()

                    ctx.font         = "bold " + augFont + "px sans-serif"
                    ctx.textAlign    = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillStyle    = (sel || augGlow) ? Theme.selText
                                     : (nrD >= 0 && nrD < nrC.length) ? nrC[nrD]
                                     : Theme.nodeText
                    ctx.fillText(nodeLabel(ni), np.x, np.y)

                } else {
                    // Circle node for triad
                    ctx.beginPath()
                    ctx.arc(np.x, np.y, r, 0, Math.PI * 2)

                    if (sel) {
                        ctx.fillStyle   = Theme.selFill
                        ctx.strokeStyle = Theme.selStroke
                        ctx.lineWidth   = Math.max(0.5, 2.5 * scale)
                    } else if (active) {
                        ctx.fillStyle   = Theme.hlNodeFill
                        ctx.strokeStyle = Theme.hlColor
                        ctx.lineWidth   = Math.max(0.5, 2.5 * scale)
                    } else if (nrD >= 0 && nrD < nrC.length) {
                        var nrClr = nrC[nrD]
                        ctx.fillStyle   = Qt.rgba(nrClr.r, nrClr.g, nrClr.b, 0.35)
                        ctx.strokeStyle = nrClr
                        ctx.lineWidth   = Math.max(0.5, 2.5 * scale)
                    } else if (n.type === "major") {
                        ctx.fillStyle   = Theme.majorFill
                        ctx.strokeStyle = Theme.majorStroke
                        ctx.lineWidth   = Math.max(0.5, 1.5 * scale)
                    } else {
                        ctx.fillStyle   = Theme.minorFill
                        ctx.strokeStyle = Theme.minorStroke
                        ctx.lineWidth   = Math.max(0.5, 1.5 * scale)
                    }
                    ctx.fill()
                    ctx.stroke()

                    if (r > 6) {
                        ctx.font         = "bold " + fontSize + "px sans-serif"
                        ctx.textAlign    = "center"
                        ctx.textBaseline = "middle"
                        ctx.fillStyle    = (active || sel) ? Theme.hlColor
                                         : (nrD >= 0 && nrD < nrC.length) ? nrC[nrD]
                                         : Theme.triadText
                        ctx.fillText(nodeLabel(ni), np.x, np.y)
                    }
                }
            }
        }

        // ── Input ─────────────────────────────────────────────────────────────

        MouseArea {
            anchors.fill: parent

            property real lastX:   0
            property real lastY:   0
            property real pressX:  0
            property real pressY:  0
            property bool didDrag: false

            onPressed: (mouse) => {
                lastX = mouse.x; lastY = mouse.y
                pressX = mouse.x; pressY = mouse.y
                didDrag = false
            }

            onPositionChanged: (mouse) => {
                if (!pressed) return
                if (Math.abs(mouse.x - pressX) > 4 || Math.abs(mouse.y - pressY) > 4)
                    didDrag = true
                canvas.originX += mouse.x - lastX
                canvas.originY += mouse.y - lastY
                lastX = mouse.x; lastY = mouse.y
                canvas.requestPaint()
            }

            onReleased: (mouse) => {
                parent.forceActiveFocus()
                if (didDrag) return
                var hit = canvas.hitTest(mouse.x, mouse.y)
                if (hit < 0) {
                    canvas.selNode   = -1
                    canvas.nodeDists = []
                } else if (hit === canvas.selNode) {
                    canvas.selNode   = -1   // toggle off
                    canvas.nodeDists = []
                } else {
                    canvas.selNode = hit
                    var n = canvas.nodes[hit]
                    if (n.type !== "aug")
                        tonnetzController.selectTriad(n.s0, n.s1, n.s2, n.type === "major")
                    if (canvas.showDistances)
                        canvas.nodeDists = canvas.computeDistances(hit)
                }
                canvas.requestPaint()
            }

            onWheel: (wheel) => {
                var factor = wheel.angleDelta.y > 0 ? 1.12 : (1.0 / 1.12)
                canvas.originX = wheel.x + (canvas.originX - wheel.x) * factor
                canvas.originY = wheel.y + (canvas.originY - wheel.y) * factor
                canvas.scale  *= factor
                canvas.requestPaint()
            }
        }
    }
}
