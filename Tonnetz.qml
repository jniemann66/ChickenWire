import QtQuick

Item {
    focus: true

    Keys.onPressed: (event) => {
        var di = 0, dj = 0
        var shift = event.modifiers & Qt.ShiftModifier
        if      (event.key === Qt.Key_Right) { di =  1 }
        else if (event.key === Qt.Key_Left)  { di = -1 }
        else if (event.key === Qt.Key_Up)    { if (shift) { di = -1; dj =  1 } else dj =  1 }
        else if (event.key === Qt.Key_Down)  { if (shift) { di =  1; dj = -1 } else dj = -1 }
        else return
        event.accepted = true

        if (canvas.hasSelNode) {
            var ni = canvas.selNodeI + di
            var nj = canvas.selNodeJ + dj
            canvas.selNodeI = ni
            canvas.selNodeJ = nj
            canvas.scrollIntoView(canvas.nodePos(ni, nj))
            tonnetzController.selectNote(canvas.noteAt(ni, nj), ni, nj)
            visualizerSwitcher.vpOriginX = canvas.originX
            visualizerSwitcher.vpOriginY = canvas.originY
            canvas.requestPaint()
        } else if (canvas.hasSelTriad) {
            var ti = canvas.selTriadI + di
            var tj = canvas.selTriadJ + dj
            canvas.selTriadI = ti
            canvas.selTriadJ = tj
            canvas.scrollIntoView(canvas.triadCenter(ti, tj, canvas.selTriadMajor))
            var root, third, fifth
            if (canvas.selTriadMajor) {
                root  = canvas.noteAt(ti,   tj  )
                third = canvas.noteAt(ti,   tj+1)
                fifth = canvas.noteAt(ti+1, tj  )
            } else {
                root  = canvas.noteAt(ti,   tj+1)
                third = canvas.noteAt(ti+1, tj  )
                fifth = canvas.noteAt(ti+1, tj+1)
            }
            tonnetzController.selectTriad(root, third, fifth, canvas.selTriadMajor)
            visualizerSwitcher.vpOriginX = canvas.originX
            visualizerSwitcher.vpOriginY = canvas.originY
            canvas.requestPaint()
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        readonly property var noteNames: ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"]
        readonly property int startNote: 0

        // Viewport state — restored from / saved to visualizerSwitcher on each change
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

        // Base geometry (at scale = 1)
        readonly property real baseDx:     72
        readonly property real baseDy:     baseDx * Math.sqrt(3) / 2
        readonly property real baseRadius: 22

        // Selection state
        property bool hasSelNode:   false
        property int  selNodeI:     0
        property int  selNodeJ:     0

        property bool hasSelTriad:  false
        property int  selTriadI:    0
        property int  selTriadJ:    0
        property bool selTriadMajor: true

        // ── coordinate helpers ──────────────────────────────────

        function nodePos(i, j) {
            var dx = baseDx * scale
            var dy = baseDy * scale
            return Qt.point(originX + i * dx + j * dx / 2,
                            originY - j * dy)
        }

        function noteAt(i, j) {
            return ((startNote + i * 7 + j * 4) % 12 + 12) % 12
        }

        function visibleRange() {
            var dx  = baseDx * scale
            var dy  = baseDy * scale
            var margin = 2
            var corners = [
                Qt.point(0,     0      ),
                Qt.point(width, 0      ),
                Qt.point(0,     height ),
                Qt.point(width, height )
            ]
            var iMin =  1e9, iMax = -1e9
            var jMin =  1e9, jMax = -1e9
            for (var c = 0; c < 4; c++) {
                var sx = corners[c].x - originX
                var sy = corners[c].y - originY
                var j  = -sy / dy
                var i  = sx / dx - j / 2
                if (i < iMin) iMin = i
                if (i > iMax) iMax = i
                if (j < jMin) jMin = j
                if (j > jMax) jMax = j
            }
            return {
                iMin: Math.floor(iMin) - margin,
                iMax: Math.ceil (iMax) + margin,
                jMin: Math.floor(jMin) - margin,
                jMax: Math.ceil (jMax) + margin
            }
        }

        // ── hit testing ─────────────────────────────────────────

        // Convert screen (px,py) → fractional lattice coords
        function toLattice(px, py) {
            var dx = baseDx * scale
            var dy = baseDy * scale
            var sx = px - originX
            var sy = py - originY
            var jf = -sy / dy
            var if_ = sx / dx - jf / 2
            return Qt.point(if_, jf)
        }

        function hitTest(px, py) {
            var lc = toLattice(px, py)
            var if_ = lc.x
            var jf  = lc.y
            var r   = Math.max(5, baseRadius * scale)

            // 1. Node hit — check the four nearest lattice points
            var ci = Math.round(if_)
            var cj = Math.round(jf)
            for (var di = -1; di <= 1; di++) {
                for (var dj = -1; dj <= 1; dj++) {
                    var np   = nodePos(ci + di, cj + dj)
                    var dist = Math.sqrt((px - np.x) * (px - np.x) +
                                        (py - np.y) * (py - np.y))
                    if (dist <= r) {
                        return { type: "note",
                                 i: ci + di, j: cj + dj,
                                 semitone: noteAt(ci + di, cj + dj) }
                    }
                }
            }

            // 2. Triangle hit — oblique floor + diagonal test
            // u + v ≤ 1  →  lower-left "major" triangle at (fi, fj)
            //                 vertices (fi,fj), (fi+1,fj), (fi,fj+1)
            // u + v > 1  →  upper-right "minor" triangle at (fi, fj)
            //                 vertices (fi+1,fj), (fi,fj+1), (fi+1,fj+1)
            var fi = Math.floor(if_)
            var fj = Math.floor(jf)
            var u  = if_ - fi
            var v  = jf  - fj

            if (u + v <= 1) {
                // Major: root=(fi,fj), M3=(fi,fj+1), P5=(fi+1,fj)
                return { type: "triad",
                         i: fi, j: fj, isMajor: true,
                         root:  noteAt(fi,   fj  ),
                         third: noteAt(fi,   fj+1),
                         fifth: noteAt(fi+1, fj  ) }
            } else {
                // Minor: root=(fi,fj+1), m3=(fi+1,fj), P5=(fi+1,fj+1)
                return { type: "triad",
                         i: fi, j: fj, isMajor: false,
                         root:  noteAt(fi,   fj+1),
                         third: noteAt(fi+1, fj  ),
                         fifth: noteAt(fi+1, fj+1) }
            }
        }

        // ── paint ───────────────────────────────────────────────

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)   // clear to transparent; background is in Main.qml

            var range = visibleRange()
            var iMin = range.iMin, iMax = range.iMax
            var jMin = range.jMin, jMax = range.jMax

            var r        = Math.max(5, baseRadius * scale)
            var fontSize = Math.max(1, 13 * scale)

            // ── edges ──
            ctx.lineWidth = Math.max(0.5, 1.5 * scale)
            for (var i = iMin; i <= iMax; i++) {
                for (var j = jMin; j <= jMax; j++) {
                    var p = nodePos(i, j)
                    if (i + 1 <= iMax)
                        drawEdge(ctx, p, nodePos(i+1, j  ), "#4a9eff")
                    if (j + 1 <= jMax)
                        drawEdge(ctx, p, nodePos(i,   j+1), "#ff9f43")
                    if (i + 1 <= iMax && j - 1 >= jMin)
                        drawEdge(ctx, p, nodePos(i+1, j-1), "#ff6b9d")
                }
            }

            // ── selected triad highlight (drawn before nodes so they sit below) ──
            if (hasSelTriad) {
                var p0, p1, p2
                var si = selTriadI, sj = selTriadJ
                if (selTriadMajor) {
                    p0 = nodePos(si,   sj  )
                    p1 = nodePos(si+1, sj  )
                    p2 = nodePos(si,   sj+1)
                } else {
                    p0 = nodePos(si+1, sj  )
                    p1 = nodePos(si,   sj+1)
                    p2 = nodePos(si+1, sj+1)
                }
                ctx.beginPath()
                ctx.moveTo(p0.x, p0.y)
                ctx.lineTo(p1.x, p1.y)
                ctx.lineTo(p2.x, p2.y)
                ctx.closePath()
                ctx.fillStyle = "rgba(255, 210, 60, 0.28)"
                ctx.fill()
                ctx.strokeStyle = "rgba(255, 210, 60, 0.7)"
                ctx.lineWidth   = Math.max(1, 2 * scale)
                ctx.stroke()
            }

            // ── nodes ──
            ctx.font = "bold " + fontSize + "px sans-serif"
            ctx.textAlign    = "center"
            ctx.textBaseline = "middle"

            for (var ni = iMin; ni <= iMax; ni++) {
                for (var nj = jMin; nj <= jMax; nj++) {
                    var np = nodePos(ni, nj)
                    if (np.x < -r || np.x > width  + r ||
                        np.y < -r || np.y > height + r)
                        continue

                    var isSelected = hasSelNode && ni === selNodeI && nj === selNodeJ

                    ctx.beginPath()
                    ctx.arc(np.x, np.y, r, 0, Math.PI * 2)
                    ctx.fillStyle   = isSelected ? "#b8860b" : "#16213e"
                    ctx.fill()
                    ctx.strokeStyle = isSelected ? "#ffd700" : "#e0e0e0"
                    ctx.lineWidth   = Math.max(0.5, (isSelected ? 2.5 : 1.5) * scale)
                    ctx.stroke()

                    if (r > 10) {
                        ctx.fillStyle = isSelected ? "#fff8dc" : "#f0f0f0"
                        ctx.fillText(noteNames[noteAt(ni, nj)], np.x, np.y)
                    }
                }
            }
        }

        function triadCenter(i, j, isMajor) {
            var p0, p1, p2
            if (isMajor) {
                p0 = nodePos(i,   j  )
                p1 = nodePos(i+1, j  )
                p2 = nodePos(i,   j+1)
            } else {
                p0 = nodePos(i+1, j  )
                p1 = nodePos(i,   j+1)
                p2 = nodePos(i+1, j+1)
            }
            return Qt.point((p0.x + p1.x + p2.x) / 3,
                            (p0.y + p1.y + p2.y) / 3)
        }

        // Pan just enough to keep screenPt inside the comfortable margin
        function scrollIntoView(screenPt) {
            var margin = 120
            if (screenPt.x < margin)               originX += margin - screenPt.x
            else if (screenPt.x > width  - margin) originX -= screenPt.x - (width  - margin)
            if (screenPt.y < margin)               originY += margin - screenPt.y
            else if (screenPt.y > height - margin) originY -= screenPt.y - (height - margin)
        }

        function drawEdge(ctx, p1, p2, color) {
            ctx.strokeStyle = color
            ctx.beginPath()
            ctx.moveTo(p1.x, p1.y)
            ctx.lineTo(p2.x, p2.y)
            ctx.stroke()
        }

        // ── input ───────────────────────────────────────────────

        MouseArea {
            anchors.fill: parent

            property real lastX:     0
            property real lastY:     0
            property real pressX:    0
            property real pressY:    0
            property bool didDrag:   false

            onPressed: (mouse) => {
                lastX   = mouse.x; lastY   = mouse.y
                pressX  = mouse.x; pressY  = mouse.y
                didDrag = false
            }

            onPositionChanged: (mouse) => {
                if (!pressed) return
                var dx = mouse.x - lastX
                var dy = mouse.y - lastY
                if (Math.abs(mouse.x - pressX) > 4 ||
                    Math.abs(mouse.y - pressY) > 4)
                    didDrag = true
                canvas.originX += dx
                canvas.originY += dy
                lastX = mouse.x
                lastY = mouse.y
                visualizerSwitcher.vpOriginX = canvas.originX
                visualizerSwitcher.vpOriginY = canvas.originY
                canvas.requestPaint()
            }

            onReleased: (mouse) => {
                parent.parent.forceActiveFocus()  // keep keyboard focus on root Item
                if (didDrag) return   // was a pan, not a click

                var hit = canvas.hitTest(mouse.x, mouse.y)

                if (hit.type === "note") {
                    canvas.hasSelTriad = false
                    canvas.hasSelNode  = true
                    canvas.selNodeI    = hit.i
                    canvas.selNodeJ    = hit.j
                    tonnetzController.selectNote(hit.semitone, hit.i, hit.j)
                } else {
                    canvas.hasSelNode  = false
                    canvas.hasSelTriad = true
                    canvas.selTriadI   = hit.i
                    canvas.selTriadJ   = hit.j
                    canvas.selTriadMajor = hit.isMajor
                    tonnetzController.selectTriad(hit.root, hit.third, hit.fifth, hit.isMajor)
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
