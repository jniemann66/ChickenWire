// ChickenWire.qml — hexagonal (honeycomb) lattice that is the geometric dual of Tonnetz.
//
// Duality:
//   Tonnetz node  (i,j)          ←→  hexagonal face  in ChickenWire  (labelled with the note)
//   Tonnetz triangle (i,j,major) ←→  ChickenWire vertex  major(i,j)  (labelled with the chord, e.g. "C")
//   Tonnetz triangle (i,j,minor) ←→  ChickenWire vertex  minor(i,j)  (labelled with the chord, e.g. "Am")
//
// Each ChickenWire vertex sits at the centroid of the corresponding Tonnetz triangle:
//   major(I,J) → offset 1/3 in both lattice axes
//   minor(I,J) → offset 2/3 in both lattice axes
//
// The three edges from each major vertex lead to: minor(I, J), minor(I-1, J), minor(I, J-1).
// These correspond to the three neo-Riemannian transformations P, R, L.

import QtQuick
import ChickenWire

Item {
    id: root
    focus: true

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_D) {
            tonnetzController.nrDistancesEnabled = !tonnetzController.nrDistancesEnabled
            event.accepted = true
            return
        }
        if (!canvas.hasSel && !canvas.hasSelNote) return
        var di = 0, dj = 0
        var shift = event.modifiers & Qt.ShiftModifier
        if      (event.key === Qt.Key_Right) { di =  1 }
        else if (event.key === Qt.Key_Left)  { di = -1 }
        else if (event.key === Qt.Key_Up)    { if (shift) { di = -1; dj =  1 } else dj =  1 }
        else if (event.key === Qt.Key_Down)  { if (shift) { di =  1; dj = -1 } else dj = -1 }
        else return
        event.accepted = true

        if (canvas.hasSelNote) {
            var ni = canvas.selNoteI + di
            var nj = canvas.selNoteJ + dj
            canvas.selNoteI = ni
            canvas.selNoteJ = nj
            canvas.scrollIntoView(canvas.hexCenter(ni, nj))
            tonnetzController.selectNote(canvas.noteAt(ni, nj), ni, nj)
            canvas.nrDists = []
            visualizerSwitcher.setNoteSelection(ni, nj)
        } else {
            var ni = canvas.selI + di
            var nj = canvas.selJ + dj
            canvas.selI = ni
            canvas.selJ = nj
            canvas.scrollIntoView(canvas.dualPos(ni, nj, canvas.selMajor))
            var t = canvas.triadNotes(ni, nj, canvas.selMajor)
            tonnetzController.selectTriad(t.root, t.third, t.fifth, canvas.selMajor)
            canvas.nrDists = tonnetzController.nrDistancesEnabled
                ? tonnetzController.computeTriadDistances(t.root, canvas.selMajor) : []
            visualizerSwitcher.setTriadSelection(ni, nj, canvas.selMajor)
        }
        visualizerSwitcher.vpOriginX = canvas.originX
        visualizerSwitcher.vpOriginY = canvas.originY
        canvas.requestPaint()
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        property var noteNames:          tonnetzController.noteNames
        property var majorRootNoteNames: tonnetzController.majorRootNoteNames
        property var minorRootNoteNames: tonnetzController.minorRootNoteNames
        property int  activeNotes:    tonnetzController.activeNotes
        property bool showAugmented: visualizerSwitcher.showAugmented
        onNoteNamesChanged:          requestPaint()
        onMajorRootNoteNamesChanged: requestPaint()
        onMinorRootNoteNamesChanged: requestPaint()
        onActiveNotesChanged:        requestPaint()
        onShowAugmentedChanged:      requestPaint()

        // NR distances from the currently selected triad (empty when none selected).
        // Layout: indices 0–11 = major(root), 12–23 = minor(root).
        property var nrDists: []

        function isAct(s) { return !!((activeNotes >> s) & 1) }
        function isAug(s) { return showAugmented && isAct(s) && isAct((s + 4) % 12) && isAct((s + 8) % 12) }

        // Viewport — same coordinate system as Tonnetz.qml; restored from / saved to visualizerSwitcher
        property real originX: width  / 2
        property real originY: height / 2
        property real scale:   1.0

        Component.onCompleted: {
            if (visualizerSwitcher.vpScale > 0) {
                originX = visualizerSwitcher.vpOriginX
                originY = visualizerSwitcher.vpOriginY
                scale   = visualizerSwitcher.vpScale
            }
        }

        // Sync selection from the shared switcher.
        Connections {
            target: visualizerSwitcher
            function onSelectionChanged() {
                var t  = visualizerSwitcher.selType
                var ni = visualizerSwitcher.selI, nj = visualizerSwitcher.selJ
                var maj = visualizerSwitcher.selIsMajor
                if (t === 1) {
                    if (canvas.hasSelNote && canvas.selNoteI === ni && canvas.selNoteJ === nj) return
                    canvas.hasSelNote = true; canvas.selNoteI = ni; canvas.selNoteJ = nj
                    canvas.hasSel = false
                    canvas.nrDists = []
                } else if (t === 2) {
                    if (canvas.hasSel && canvas.selI === ni && canvas.selJ === nj
                            && canvas.selMajor === maj) return
                    canvas.hasSel = true; canvas.selI = ni; canvas.selJ = nj; canvas.selMajor = maj
                    canvas.hasSelNote = false
                    canvas.nrDists = tonnetzController.nrDistancesEnabled
                        ? tonnetzController.computeTriadDistances(
                              maj ? canvas.noteAt(ni, nj) : canvas.noteAt(ni, nj + 1), maj) : []
                } else {
                    if (!canvas.hasSel && !canvas.hasSelNote) return
                    canvas.hasSel = false; canvas.hasSelNote = false
                    canvas.nrDists = []
                }
                canvas.requestPaint()
            }
        }

        // Keep this canvas in sync with the other visualizer while both are
        // visible during the cross-fade.  Only reads here — writes stay in the
        // input handlers to avoid feedback loops.
        Connections {
            target: visualizerSwitcher
            function onVpOriginXChanged() {
                if (canvas.originX !== visualizerSwitcher.vpOriginX) {
                    canvas.originX = visualizerSwitcher.vpOriginX
                    canvas.requestPaint()
                }
            }
            function onVpOriginYChanged() {
                if (canvas.originY !== visualizerSwitcher.vpOriginY) {
                    canvas.originY = visualizerSwitcher.vpOriginY
                    canvas.requestPaint()
                }
            }
            function onVpScaleChanged() {
                if (canvas.scale !== visualizerSwitcher.vpScale) {
                    canvas.scale = visualizerSwitcher.vpScale
                    canvas.requestPaint()
                }
            }
        }

        // Recompute / clear NR distances when the enabled flag is toggled live.
        Connections {
            target: tonnetzController
            function onNrDistancesEnabledChanged() {
                if (!tonnetzController.nrDistancesEnabled) {
                    canvas.nrDists = []
                } else if (canvas.hasSel) {
                    var t = canvas.triadNotes(canvas.selI, canvas.selJ, canvas.selMajor)
                    canvas.nrDists = tonnetzController.computeTriadDistances(t.root, canvas.selMajor)
                }
                canvas.requestPaint()
            }
        }

        // Same base spacing as Tonnetz so the two views feel comparable
        readonly property real baseDx:     72
        readonly property real baseDy:     baseDx * Math.sqrt(3) / 2
        // Dual-vertex radius is smaller: the honeycomb edges are ~42 px at scale=1,
        // versus 72 px in the Tonnetz, so we scale down accordingly.
        readonly property real baseRadius: 15

        // Selection: triad (dual vertex) or note (hex face / Tonnetz node)
        property bool hasSel:     false
        property int  selI:       0
        property int  selJ:       0
        property bool selMajor:   true
        property bool hasSelNote: false
        property int  selNoteI:   0
        property int  selNoteJ:   0

        //  coordinate helpers

        // Screen position of Tonnetz node (I,J) — the centre of a hexagonal face.
        function hexCenter(I, J) {
            var dx = baseDx * scale
            var dy = baseDy * scale
            return Qt.point(originX + I * dx + J * dx / 2,
                            originY - J * dy)
        }

        // Screen position of the dual lattice vertex (triad node).
        //   major(I,J): centroid of Tonnetz nodes (I,J),(I+1,J),(I,J+1)   → fractional offset 1/3
        //   minor(I,J): centroid of Tonnetz nodes (I+1,J),(I,J+1),(I+1,J+1) → fractional offset 2/3
        function dualPos(I, J, isMajor) {
            var dx  = baseDx * scale
            var dy  = baseDy * scale
            var off = isMajor ? (1.0 / 3.0) : (2.0 / 3.0)
            return Qt.point(
                originX + (I + off) * dx + (J + off) * dx / 2,
                originY - (J + off) * dy
            )
        }

        // Semitone of Tonnetz node (I,J) — used to label hexagonal faces.
        function noteAt(I, J) {
            return ((I * 7 + J * 4) % 12 + 12) % 12
        }

        // Root semitone of the triad at dual vertex (I,J).
        //   major: root is the Tonnetz node at (I,J)
        //   minor: root is the Tonnetz node at (I,J+1)
        function rootNote(I, J, isMajor) {
            return isMajor ? noteAt(I, J) : noteAt(I, J + 1)
        }

        // All three semitones of the triad (matches Tonnetz.qml's triangle definition).
        function triadNotes(I, J, isMajor) {
            if (isMajor)
                return { root: noteAt(I, J),   third: noteAt(I, J+1), fifth: noteAt(I+1, J)   }
            else
                return { root: noteAt(I, J+1), third: noteAt(I+1, J), fifth: noteAt(I+1, J+1) }
        }

        // Chord label: "C" for C major, "Am" for A minor.
        function chordLabel(I, J, isMajor) {
            var names = isMajor ? majorRootNoteNames : minorRootNoteNames
            return names[rootNote(I, J, isMajor)] + (isMajor ? "" : "m")
        }

        // Visible range in Tonnetz lattice coordinates (dual vertices lie inside same bounds).
        function visibleRange() {
            var dx = baseDx * scale
            var dy = baseDy * scale
            var margin  = 2
            var iMin =  1e9, iMax = -1e9
            var jMin =  1e9, jMax = -1e9
            var corners = [Qt.point(0,0), Qt.point(width,0), Qt.point(0,height), Qt.point(width,height)]
            for (var c = 0; c < 4; c++) {
                var sx  = corners[c].x - originX
                var sy  = corners[c].y - originY
                var jf  = -sy / dy
                var if_ = sx / dx - jf / 2
                if (if_ < iMin) iMin = if_;  if (if_ > iMax) iMax = if_
                if (jf  < jMin) jMin = jf;   if (jf  > jMax) jMax = jf
            }
            return {
                iMin: Math.floor(iMin) - margin, iMax: Math.ceil(iMax) + margin,
                jMin: Math.floor(jMin) - margin, jMax: Math.ceil(jMax) + margin
            }
        }

        //  hit testing

        // Returns { type:"triad", i, j, isMajor } if click is within a node radius
        // of a dual vertex, or { type:"note", i, j } for the enclosing hex face.
        function hitTest(px, py) {
            var dx  = baseDx * scale
            var dy  = baseDy * scale
            var sx  = px - originX
            var sy  = py - originY
            var jf  = -sy / dy
            var if_ = sx / dx - jf / 2
            var ci  = Math.round(if_)
            var cj  = Math.round(jf)
            var r   = Math.max(4, baseRadius * scale)
            var bestDist2 = 1e18
            var best = null
            for (var di = -2; di <= 2; di++) {
                for (var dj = -2; dj <= 2; dj++) {
                    for (var m = 0; m < 2; m++) {
                        var isMaj = (m === 0)
                        var p  = dualPos(ci + di, cj + dj, isMaj)
                        var d2 = (px - p.x) * (px - p.x) + (py - p.y) * (py - p.y)
                        if (d2 < bestDist2) {
                            bestDist2 = d2
                            best = { i: ci + di, j: cj + dj, isMajor: isMaj }
                        }
                    }
                }
            }
            if (bestDist2 <= r * r)
                return { type: "triad", i: best.i, j: best.j, isMajor: best.isMajor }
            // Click is inside a hex face → select the note at that face's centre
            return { type: "note", i: ci, j: cj }
        }

        function drawHexFace(ctx, I, J, fillColor, strokeColor) {
            var h0 = dualPos(I,     J,     true )
            var h1 = dualPos(I - 1, J,     false)
            var h2 = dualPos(I - 1, J,     true )
            var h3 = dualPos(I - 1, J - 1, false)
            var h4 = dualPos(I,     J - 1, true )
            var h5 = dualPos(I,     J - 1, false)
            ctx.beginPath()
            ctx.moveTo(h0.x, h0.y); ctx.lineTo(h1.x, h1.y)
            ctx.lineTo(h2.x, h2.y); ctx.lineTo(h3.x, h3.y)
            ctx.lineTo(h4.x, h4.y); ctx.lineTo(h5.x, h5.y)
            ctx.closePath()
            ctx.fillStyle   = fillColor
            ctx.fill()
            ctx.strokeStyle = strokeColor
            ctx.lineWidth   = Math.max(1, 2 * scale)
            ctx.stroke()
        }

        function isTriadActive(i, j, isMaj) {
            if (hasSel && i === selI && j === selJ && isMaj === selMajor) return true
            return isMaj
                ? (isAct(noteAt(i,j)) && isAct(noteAt(i,j+1)) && isAct(noteAt(i+1,j)))
                : (isAct(noteAt(i,j+1)) && isAct(noteAt(i+1,j)) && isAct(noteAt(i+1,j+1)))
        }

        function drawEdge(ctx, p1, p2, color) {
            ctx.strokeStyle = color
            ctx.beginPath()
            ctx.moveTo(p1.x, p1.y)
            ctx.lineTo(p2.x, p2.y)
            ctx.stroke()
        }

        // Pan just enough to keep screenPt inside the comfortable margin.
        function scrollIntoView(screenPt) {
            var margin = 120
            if      (screenPt.x < margin)               originX += margin - screenPt.x
            else if (screenPt.x > width  - margin)      originX -= screenPt.x - (width  - margin)
            if      (screenPt.y < margin)               originY += margin - screenPt.y
            else if (screenPt.y > height - margin)      originY -= screenPt.y - (height - margin)
        }

        //  paint

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)   // clear to transparent; background is in Main.qml

            var rng  = visibleRange()
            var iMin = rng.iMin, iMax = rng.iMax
            var jMin = rng.jMin, jMax = rng.jMax

            var r        = Math.max(4, baseRadius * scale)
            var fontSize = Math.max(1, Math.min(r * 0.72, 11 * scale))

            //  active hex faces; selected note drawn on top if applicable
            if (activeNotes !== 0 || hasSelNote) {
                for (var fi = iMin; fi <= iMax; fi++) {
                    for (var fj = jMin; fj <= jMax; fj++) {
                        if (isAct(noteAt(fi, fj)))
                            drawHexFace(ctx, fi, fj, Theme.hlFaceFill, Theme.hlHexStroke)
                        if (hasSelNote && fi === selNoteI && fj === selNoteJ)
                            drawHexFace(ctx, fi, fj, Theme.selHexFill, Theme.selHexStroke)
                    }
                }
            }

            //  1. Edges, coloured by neo-Riemannian transformation
            // From each major(I,J) vertex there are exactly three edges:
            //   L  (leading-tone exchange)  major(I,J) → minor(I,J)    blue
            //   R  (relative)               major(I,J) → minor(I-1,J)  orange
            //   P  (parallel)               major(I,J) → minor(I,J-1)  pink
            ctx.lineWidth = Math.max(1.5, 2.5 * scale)
            ctx.lineCap   = "round"
            for (var i = iMin; i <= iMax; i++) {
                for (var j = jMin; j <= jMax; j++) {
                    var pm = dualPos(i,   j,   true )
                    drawEdge(ctx, pm, dualPos(i,   j,   false), Theme.edgeL)  // L — blue
                    drawEdge(ctx, pm, dualPos(i-1, j,   false), Theme.edgeR)  // R — orange
                    drawEdge(ctx, pm, dualPos(i,   j-1, false), Theme.edgeP)  // P — pink
                }
            }

            //  2. Note names at hex face centres: faint now, active deferred to end
            var activeNoteLabels = []
            if (r > 9) {
                var faceFontSize = Math.max(1, 11 * scale)
                ctx.font         = faceFontSize + "px sans-serif"
                ctx.textAlign    = "center"
                ctx.textBaseline = "middle"
                ctx.fillStyle    = Theme.labelFaint
                for (var fi = iMin; fi <= iMax; fi++) {
                    for (var fj = jMin; fj <= jMax; fj++) {
                        var hc        = hexCenter(fi, fj)
                        var s         = noteAt(fi, fj)
                        var augmented = isAug(s)
                        var noteActive = (hasSelNote && fi === selNoteI && fj === selNoteJ)
                                      || isAct(s)
                        if (augmented) {
                            ctx.beginPath()
                            ctx.arc(hc.x, hc.y, r, 0, Math.PI * 2)
                            ctx.fillStyle   = Theme.selFill
                            ctx.strokeStyle = Theme.selStroke
                            ctx.lineWidth   = Math.max(0.5, 2.5 * scale)
                            ctx.fill()
                            ctx.stroke()
                            ctx.fillStyle = Theme.labelFaint
                        }
                        var label = noteNames[s] + (augmented ? "+" : "")
                        if (noteActive) activeNoteLabels.push({text: label, x: hc.x, y: hc.y})
                        else            ctx.fillText(label, hc.x, hc.y)
                    }
                }
            }

            //  3. Triad nodes
            ctx.font         = "bold " + fontSize + "px sans-serif"
            ctx.textAlign    = "center"
            ctx.textBaseline = "middle"

            for (var ni = iMin; ni <= iMax; ni++) {
                for (var nj = jMin; nj <= jMax; nj++) {
                    for (var nm = 0; nm < 2; nm++) {
                        var isMaj = (nm === 0)
                        var np    = dualPos(ni, nj, isMaj)

                        if (np.x < -r || np.x > width  + r ||
                            np.y < -r || np.y > height + r) continue

                        var active = isTriadActive(ni, nj, isMaj)
                        var nrRt = rootNote(ni, nj, isMaj)
                        var nrD  = nrDists.length > 0 ? (isMaj ? nrDists[nrRt] : nrDists[nrRt + 12]) : -1

                        ctx.beginPath()
                        ctx.arc(np.x, np.y, r, 0, Math.PI * 2)

                        if (active) {
                            ctx.fillStyle   = Theme.selFill
                            ctx.strokeStyle = Theme.selStroke
                            ctx.lineWidth   = Math.max(0.5, 2.5 * scale)
                        } else if (nrD >= 0) {
                            var nrClr = [Theme.nrDist0, Theme.nrDist1, Theme.nrDist2, Theme.nrDist3,
                                         Theme.nrDist4, Theme.nrDist5, Theme.nrDist6][nrD]
                            ctx.fillStyle   = Qt.rgba(nrClr.r, nrClr.g, nrClr.b, 0.35)
                            ctx.strokeStyle = nrClr
                            ctx.lineWidth   = Math.max(0.5, 2.5 * scale)
                        } else if (isMaj) {
                            // Major triads: warm amber border
                            ctx.fillStyle   = Theme.majorFill
                            ctx.strokeStyle = Theme.majorStroke
                            ctx.lineWidth   = Math.max(0.5, 1.5 * scale)
                        } else {
                            // Minor triads: cool blue border
                            ctx.fillStyle   = Theme.minorFill
                            ctx.strokeStyle = Theme.minorStroke
                            ctx.lineWidth   = Math.max(0.5, 1.5 * scale)
                        }

                        ctx.fill()
                        ctx.stroke()

                        if (r > 7) {
                            ctx.fillStyle = active ? Theme.selText : Theme.triadText
                            ctx.fillText(chordLabel(ni, nj, isMaj), np.x, np.y)
                        }
                    }
                }
            }

            // active note labels — drawn last so hex fills don't paint over them
            if (activeNoteLabels.length > 0) {
                ctx.font         = "bold " + Math.max(1, 11 * scale) + "px sans-serif"
                ctx.textAlign    = "center"
                ctx.textBaseline = "middle"
                ctx.fillStyle    = Theme.labelActive
                for (var al = 0; al < activeNoteLabels.length; al++)
                    ctx.fillText(activeNoteLabels[al].text, activeNoteLabels[al].x, activeNoteLabels[al].y)
            }
        }

        //  input

        MouseArea {
            anchors.fill: parent

            property real lastX:   0
            property real lastY:   0
            property real pressX:  0
            property real pressY:  0
            property bool didDrag: false

            onPressed: (mouse) => {
                lastX = mouse.x;  lastY = mouse.y
                pressX = mouse.x; pressY = mouse.y
                didDrag = false
            }

            onPositionChanged: (mouse) => {
                if (!pressed) return
                var ddx = mouse.x - lastX
                var ddy = mouse.y - lastY
                if (Math.abs(mouse.x - pressX) > 4 || Math.abs(mouse.y - pressY) > 4)
                    didDrag = true
                canvas.originX += ddx
                canvas.originY += ddy
                lastX = mouse.x
                lastY = mouse.y
                visualizerSwitcher.vpOriginX = canvas.originX
                visualizerSwitcher.vpOriginY = canvas.originY
                canvas.requestPaint()
            }

            onReleased: (mouse) => {
                parent.parent.forceActiveFocus()   // keep keyboard focus on root Item
                if (didDrag) return

                var hit = canvas.hitTest(mouse.x, mouse.y)
                if (!hit) return

                if (hit.type === "triad") {
                    if (canvas.hasSel && canvas.selI === hit.i
                            && canvas.selJ === hit.j && canvas.selMajor === hit.isMajor) {
                        // toggle off
                        canvas.hasSel  = false
                        canvas.nrDists = []
                        visualizerSwitcher.clearSelection()
                    } else {
                        canvas.hasSel     = true
                        canvas.selI       = hit.i
                        canvas.selJ       = hit.j
                        canvas.selMajor   = hit.isMajor
                        canvas.hasSelNote = false
                        var t = canvas.triadNotes(hit.i, hit.j, hit.isMajor)
                        tonnetzController.selectTriad(t.root, t.third, t.fifth, hit.isMajor)
                        canvas.nrDists = tonnetzController.nrDistancesEnabled
                            ? tonnetzController.computeTriadDistances(t.root, hit.isMajor) : []
                        visualizerSwitcher.setTriadSelection(hit.i, hit.j, hit.isMajor)
                    }
                } else {
                    if (canvas.hasSelNote && canvas.selNoteI === hit.i && canvas.selNoteJ === hit.j) {
                        // toggle off
                        canvas.hasSelNote = false
                        canvas.nrDists    = []
                        visualizerSwitcher.clearSelection()
                    } else {
                        canvas.hasSelNote = true
                        canvas.selNoteI   = hit.i
                        canvas.selNoteJ   = hit.j
                        canvas.hasSel     = false
                        canvas.nrDists    = []
                        tonnetzController.selectNote(canvas.noteAt(hit.i, hit.j), hit.i, hit.j)
                        visualizerSwitcher.setNoteSelection(hit.i, hit.j)
                    }
                }
                canvas.requestPaint()
            }

            onWheel: (wheel) => {
                var factor = wheel.angleDelta.y > 0 ? 1.12 : (1.0 / 1.12)
                canvas.originX = wheel.x + (canvas.originX - wheel.x) * factor
                canvas.originY = wheel.y + (canvas.originY - wheel.y) * factor
                canvas.scale  *= factor
                visualizerSwitcher.vpOriginX = canvas.originX
                visualizerSwitcher.vpOriginY = canvas.originY
                visualizerSwitcher.vpScale   = canvas.scale
                canvas.requestPaint()
            }
        }
    }
}
