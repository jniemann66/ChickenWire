import QtQuick
import ChickenWire

Item {
    focus: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_F5) {
            tonnetzController.nrDistancesEnabled = !tonnetzController.nrDistancesEnabled;
            event.accepted = true;
            return;
        }
        var di = 0, dj = 0;
        var shift = event.modifiers & Qt.ShiftModifier;
        if (event.key === Qt.Key_Right) {
            di = 1;
        } else if (event.key === Qt.Key_Left) {
            di = -1;
        } else if (event.key === Qt.Key_Up) {
            if (shift) {
                di = -1;
                dj = 1;
            } else
                dj = 1;
        } else if (event.key === Qt.Key_Down) {
            if (shift) {
                di = 1;
                dj = -1;
            } else
                dj = -1;
        } else
            return;
        event.accepted = true;

        if (canvas.hasSelNode) {
            var ni = canvas.selNodeI + di;
            var nj = canvas.selNodeJ + dj;
            canvas.selNodeI = ni;
            canvas.selNodeJ = nj;
            canvas.scrollIntoView(canvas.nodePos(ni, nj));
            tonnetzController.selectNote(canvas.noteAt(ni, nj), ni, nj);
            canvas.nrDists = [];
            visualizerSwitcher.setNoteSelection(ni, nj);
            visualizerSwitcher.vpOriginX = canvas.originX;
            visualizerSwitcher.vpOriginY = canvas.originY;
            canvas.requestPaint();
        } else if (canvas.hasSelTriad) {
            var ti = canvas.selTriadI + di;
            var tj = canvas.selTriadJ + dj;
            canvas.selTriadI = ti;
            canvas.selTriadJ = tj;
            canvas.scrollIntoView(canvas.triadCenter(ti, tj, canvas.selTriadMajor));
            var root, third, fifth;
            if (canvas.selTriadMajor) {
                root = canvas.noteAt(ti, tj);
                third = canvas.noteAt(ti, tj + 1);
                fifth = canvas.noteAt(ti + 1, tj);
            } else {
                root = canvas.noteAt(ti, tj + 1);
                third = canvas.noteAt(ti + 1, tj);
                fifth = canvas.noteAt(ti + 1, tj + 1);
            }
            tonnetzController.selectTriad(root, third, fifth, canvas.selTriadMajor);
            canvas.nrDists = tonnetzController.nrDistancesEnabled ? tonnetzController.computeTriadDistances(root, canvas.selTriadMajor) : [];
            visualizerSwitcher.setTriadSelection(ti, tj, canvas.selTriadMajor);
            visualizerSwitcher.vpOriginX = canvas.originX;
            visualizerSwitcher.vpOriginY = canvas.originY;
            canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        property var noteNames: tonnetzController.noteNames
        property var majorRootNoteNames: tonnetzController.majorRootNoteNames
        property var minorRootNoteNames: tonnetzController.minorRootNoteNames
        property int activeNotes: tonnetzController.activeNotes
        property bool showAugmented: visualizerSwitcher.showAugmented
        onNoteNamesChanged: requestPaint()
        onMajorRootNoteNamesChanged: requestPaint()
        onMinorRootNoteNamesChanged: requestPaint()
        onActiveNotesChanged: requestPaint()
        onShowAugmentedChanged: requestPaint()

        // NR distances from the currently selected triad (empty when none selected).
        // Layout: indices 0–11 = major(root), 12–23 = minor(root).
        property var nrDists: []

        function isAct(s) {
            return !!((activeNotes >> s) & 1);
        }
        function isAug(s) {
            return showAugmented && isAct(s) && isAct((s + 4) % 12) && isAct((s + 8) % 12);
        }

        // Viewport state — restored from / saved to visualizerSwitcher on each change
        property real originX: width / 2
        property real originY: height / 2
        property real scale: 1.75

        Component.onCompleted: {
            if (visualizerSwitcher.vpScale > 0) {
                originX = visualizerSwitcher.vpOriginX;
                originY = visualizerSwitcher.vpOriginY;
                scale = visualizerSwitcher.vpScale;
            }
        }

        // Sync selection state from the shared switcher (set by either visualizer).
        // Guards prevent redundant repaints when the change originated here.
        Connections {
            target: visualizerSwitcher
            function onSelectionChanged() {
                var t = visualizerSwitcher.selType;
                var ni = visualizerSwitcher.selI, nj = visualizerSwitcher.selJ;
                var maj = visualizerSwitcher.selIsMajor;
                if (t === 1) {
                    if (canvas.hasSelNode && canvas.selNodeI === ni && canvas.selNodeJ === nj)
                        return;
                    canvas.hasSelNode = true;
                    canvas.selNodeI = ni;
                    canvas.selNodeJ = nj;
                    canvas.hasSelTriad = false;
                    canvas.nrDists = [];
                } else if (t === 2) {
                    if (canvas.hasSelTriad && canvas.selTriadI === ni && canvas.selTriadJ === nj && canvas.selTriadMajor === maj)
                        return;
                    canvas.hasSelTriad = true;
                    canvas.selTriadI = ni;
                    canvas.selTriadJ = nj;
                    canvas.selTriadMajor = maj;
                    canvas.hasSelNode = false;
                    canvas.nrDists = tonnetzController.nrDistancesEnabled ? tonnetzController.computeTriadDistances(maj ? canvas.noteAt(ni, nj) : canvas.noteAt(ni, nj + 1), maj) : [];
                } else {
                    if (!canvas.hasSelNode && !canvas.hasSelTriad)
                        return;
                    canvas.hasSelNode = false;
                    canvas.hasSelTriad = false;
                    canvas.nrDists = [];
                }
                canvas.requestPaint();
            }
        }

        // Keep this canvas in sync with the other visualizer while both are
        // visible during the cross-fade.  Only reads here — writes stay in the
        // input handlers to avoid feedback loops.
        Connections {
            target: visualizerSwitcher
            function onVpOriginXChanged() {
                if (canvas.originX !== visualizerSwitcher.vpOriginX) {
                    canvas.originX = visualizerSwitcher.vpOriginX;
                    canvas.requestPaint();
                }
            }
            function onVpOriginYChanged() {
                if (canvas.originY !== visualizerSwitcher.vpOriginY) {
                    canvas.originY = visualizerSwitcher.vpOriginY;
                    canvas.requestPaint();
                }
            }
            function onVpScaleChanged() {
                if (canvas.scale !== visualizerSwitcher.vpScale) {
                    canvas.scale = visualizerSwitcher.vpScale;
                    canvas.requestPaint();
                }
            }
        }

        // Recompute / clear NR distances when the enabled flag is toggled live.
        Connections {
            target: tonnetzController
            function onNrDistancesEnabledChanged() {
                if (!tonnetzController.nrDistancesEnabled) {
                    canvas.nrDists = [];
                } else if (canvas.hasSelTriad) {
                    var root = canvas.selTriadMajor ? canvas.noteAt(canvas.selTriadI, canvas.selTriadJ) : canvas.noteAt(canvas.selTriadI, canvas.selTriadJ + 1);
                    canvas.nrDists = tonnetzController.computeTriadDistances(root, canvas.selTriadMajor);
                }
                canvas.requestPaint();
            }
        }

        // Base geometry (at scale = 1)
        readonly property real baseDx: 72
        readonly property real baseDy: baseDx * Math.sqrt(3) / 2
        readonly property real baseRadius: 15

        // Selection state
        property bool hasSelNode: false
        property int selNodeI: 0
        property int selNodeJ: 0

        property bool hasSelTriad: false
        property int selTriadI: 0
        property int selTriadJ: 0
        property bool selTriadMajor: true

        // coordinate helpers

        function nodePos(i, j) {
            var dx = baseDx * scale;
            var dy = baseDy * scale;
            return Qt.point(originX + i * dx + j * dx / 2, originY - j * dy);
        }

        function noteAt(i, j) {
            return ((i * 7 + j * 4) % 12 + 12) % 12;
        }

        // Chord label matching ChickenWire's vertex labels: "C", "Am", "F♯m" …
        function chordLabel(i, j, isMajor) {
            var root = isMajor ? noteAt(i, j) : noteAt(i, j + 1);
            var names = isMajor ? majorRootNoteNames : minorRootNoteNames;
            return names[root] + (isMajor ? "" : "m");
        }

        function visibleRange() {
            var dx = baseDx * scale;
            var dy = baseDy * scale;
            var margin = 2;
            var corners = [Qt.point(0, 0), Qt.point(width, 0), Qt.point(0, height), Qt.point(width, height)];
            var iMin = 1e9, iMax = -1e9;
            var jMin = 1e9, jMax = -1e9;
            for (var c = 0; c < 4; c++) {
                var sx = corners[c].x - originX;
                var sy = corners[c].y - originY;
                var j = -sy / dy;
                var i = sx / dx - j / 2;
                if (i < iMin)
                    iMin = i;
                if (i > iMax)
                    iMax = i;
                if (j < jMin)
                    jMin = j;
                if (j > jMax)
                    jMax = j;
            }
            return {
                iMin: Math.floor(iMin) - margin,
                iMax: Math.ceil(iMax) + margin,
                jMin: Math.floor(jMin) - margin,
                jMax: Math.ceil(jMax) + margin
            };
        }

        // hit testing

        // Convert screen (px,py) → fractional lattice coords
        function toLattice(px, py) {
            var dx = baseDx * scale;
            var dy = baseDy * scale;
            var sx = px - originX;
            var sy = py - originY;
            var jf = -sy / dy;
            var if_ = sx / dx - jf / 2;
            return Qt.point(if_, jf);
        }

        function hitTest(px, py) {
            var lc = toLattice(px, py);
            var if_ = lc.x;
            var jf = lc.y;
            var r = Math.max(5, baseRadius * scale);

            // 1. Node hit — check the four nearest lattice points
            var ci = Math.round(if_);
            var cj = Math.round(jf);
            for (var di = -1; di <= 1; di++) {
                for (var dj = -1; dj <= 1; dj++) {
                    var np = nodePos(ci + di, cj + dj);
                    var dist = Math.sqrt((px - np.x) * (px - np.x) + (py - np.y) * (py - np.y));
                    if (dist <= r) {
                        return {
                            type: "note",
                            i: ci + di,
                            j: cj + dj,
                            semitone: noteAt(ci + di, cj + dj)
                        };
                    }
                }
            }

            // 2. Triangle hit — oblique floor + diagonal test
            // u + v ≤ 1  →  lower-left "major" triangle at (fi, fj)
            //                vertices (fi,fj), (fi+1,fj), (fi,fj+1)
            // u + v > 1  →  upper-right "minor" triangle at (fi, fj)
            //                vertices (fi+1,fj), (fi,fj+1), (fi+1,fj+1)
            var fi = Math.floor(if_);
            var fj = Math.floor(jf);
            var u = if_ - fi;
            var v = jf - fj;

            if (u + v <= 1) {
                // Major: root=(fi,fj), M3=(fi,fj+1), P5=(fi+1,fj)
                return {
                    type: "triad",
                    i: fi,
                    j: fj,
                    isMajor: true,
                    root: noteAt(fi, fj),
                    third: noteAt(fi, fj + 1),
                    fifth: noteAt(fi + 1, fj)
                };
            } else {
                // Minor: root=(fi,fj+1), m3=(fi+1,fj), P5=(fi+1,fj+1)
                return {
                    type: "triad",
                    i: fi,
                    j: fj,
                    isMajor: false,
                    root: noteAt(fi, fj + 1),
                    third: noteAt(fi + 1, fj),
                    fifth: noteAt(fi + 1, fj + 1)
                };
            }
        }

        // paint

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);   // clear to transparent; background is in Main.qml

            var range = visibleRange();
            var iMin = range.iMin, iMax = range.iMax;
            var jMin = range.jMin, jMax = range.jMax;

            var r = Math.max(5, baseRadius * scale);
            var fontSize = Math.max(1, 13 * scale);

            // active note-set: filled triangles (drawn first, behind everything)
            if (activeNotes !== 0) {
                ctx.fillStyle = Theme.hlFaceFill;
                for (var i = iMin; i <= iMax; i++) {
                    for (var j = jMin; j <= jMax; j++) {
                        // Major triangle: (i,j)–(i+1,j)–(i,j+1)
                        if (isAct(noteAt(i, j)) && isAct(noteAt(i + 1, j)) && isAct(noteAt(i, j + 1))) {
                            var tp0 = nodePos(i, j), tp1 = nodePos(i + 1, j), tp2 = nodePos(i, j + 1);
                            ctx.beginPath();
                            ctx.moveTo(tp0.x, tp0.y);
                            ctx.lineTo(tp1.x, tp1.y);
                            ctx.lineTo(tp2.x, tp2.y);
                            ctx.closePath();
                            ctx.fill();
                        }
                        // Minor triangle: (i+1,j)–(i,j+1)–(i+1,j+1)
                        if (isAct(noteAt(i + 1, j)) && isAct(noteAt(i, j + 1)) && isAct(noteAt(i + 1, j + 1))) {
                            var tp0 = nodePos(i + 1, j), tp1 = nodePos(i, j + 1), tp2 = nodePos(i + 1, j + 1);
                            ctx.beginPath();
                            ctx.moveTo(tp0.x, tp0.y);
                            ctx.lineTo(tp1.x, tp1.y);
                            ctx.lineTo(tp2.x, tp2.y);
                            ctx.closePath();
                            ctx.fill();
                        }
                    }
                }
            }

            // edges
            ctx.lineWidth = Math.max(0.5, 1.5 * scale);
            for (var i = iMin; i <= iMax; i++) {
                for (var j = jMin; j <= jMax; j++) {
                    var p = nodePos(i, j);
                    if (i + 1 <= iMax)
                        drawEdge(ctx, p, nodePos(i + 1, j), Theme.edgeP);
                    if (j + 1 <= jMax)
                        drawEdge(ctx, p, nodePos(i, j + 1), Theme.edgeR);
                    if (i + 1 <= iMax && j - 1 >= jMin)
                        drawEdge(ctx, p, nodePos(i + 1, j - 1), Theme.edgeL);
                }
            }

            if (activeNotes !== 0)
                drawActiveEdgeOverlay(ctx, range, isAct, Theme.hlEdge);

            // triad labels: faint drawn now; active collected and deferred to after nodes
            var activeLabels = [];
            if (r > 10) {
                var triadFontSize = Math.max(1, 11 * scale);
                ctx.font = triadFontSize + "px sans-serif";
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillStyle = Theme.labelFaint;
                for (var ti = iMin; ti <= iMax; ti++) {
                    for (var tj = jMin; tj <= jMax; tj++) {
                        var majActive = isActiveTriad(ti, tj, true);
                        var cMaj = triadCenter(ti, tj, true);
                        if (majActive)
                            activeLabels.push({
                                text: chordLabel(ti, tj, true),
                                x: cMaj.x,
                                y: cMaj.y
                            });
                        else
                            ctx.fillText(chordLabel(ti, tj, true), cMaj.x, cMaj.y);
                        var minActive = isActiveTriad(ti, tj, false);
                        var cMin = triadCenter(ti, tj, false);
                        if (minActive)
                            activeLabels.push({
                                text: chordLabel(ti, tj, false),
                                x: cMin.x,
                                y: cMin.y
                            });
                        else
                            ctx.fillText(chordLabel(ti, tj, false), cMin.x, cMin.y);
                    }
                }
            }

            // NR distance: coloured triangle fills and outlines
            if (nrDists.length > 0) {
                var nrC = [Theme.nrDist0, Theme.nrDist1, Theme.nrDist2, Theme.nrDist3, Theme.nrDist4, Theme.nrDist5, Theme.nrDist6];
                ctx.lineWidth = Math.max(1, 2 * scale);
                for (var dti = iMin; dti <= iMax; dti++) {
                    for (var dtj = jMin; dtj <= jMax; dtj++) {
                        // Major triad at (dti, dtj): root = noteAt(dti, dtj)
                        var majD = nrDists[noteAt(dti, dtj)];
                        if (majD >= 0 && majD < nrC.length) {
                            var mc = nrC[majD];
                            var dtp0 = nodePos(dti, dtj), dtp1 = nodePos(dti + 1, dtj), dtp2 = nodePos(dti, dtj + 1);
                            ctx.beginPath();
                            ctx.moveTo(dtp0.x, dtp0.y);
                            ctx.lineTo(dtp1.x, dtp1.y);
                            ctx.lineTo(dtp2.x, dtp2.y);
                            ctx.closePath();
                            ctx.fillStyle = Qt.rgba(mc.r, mc.g, mc.b, 0.25);
                            ctx.fill();
                            ctx.strokeStyle = Qt.rgba(mc.r, mc.g, mc.b, 0.75);
                            ctx.stroke();
                        }
                        // Minor triad at (dti, dtj): root = noteAt(dti, dtj+1)
                        var minD = nrDists[noteAt(dti, dtj + 1) + 12];
                        if (minD >= 0 && minD < nrC.length) {
                            var mc = nrC[minD];
                            var dtp0 = nodePos(dti + 1, dtj), dtp1 = nodePos(dti, dtj + 1), dtp2 = nodePos(dti + 1, dtj + 1);
                            ctx.beginPath();
                            ctx.moveTo(dtp0.x, dtp0.y);
                            ctx.lineTo(dtp1.x, dtp1.y);
                            ctx.lineTo(dtp2.x, dtp2.y);
                            ctx.closePath();
                            ctx.fillStyle = Qt.rgba(mc.r, mc.g, mc.b, 0.25);
                            ctx.fill();
                            ctx.strokeStyle = Qt.rgba(mc.r, mc.g, mc.b, 0.75);
                            ctx.stroke();
                        }
                    }
                }
            }

            // active triads (playing or selected) — drawn after edges so stroke is visible
            if (hasSelTriad || activeNotes !== 0) {
                ctx.fillStyle = Theme.selFill;
                ctx.strokeStyle = Theme.selTriadStroke;
                ctx.lineWidth = Math.max(1, 2 * scale);
                for (var i = iMin; i <= iMax; i++) {
                    for (var j = jMin; j <= jMax; j++) {
                        for (var m = 0; m < 2; m++) {
                            var isMaj = (m === 0);
                            if (!isActiveTriad(i, j, isMaj))
                                continue;
                            var p0, p1, p2;
                            if (isMaj) {
                                p0 = nodePos(i, j);
                                p1 = nodePos(i + 1, j);
                                p2 = nodePos(i, j + 1);
                            } else {
                                p0 = nodePos(i + 1, j);
                                p1 = nodePos(i, j + 1);
                                p2 = nodePos(i + 1, j + 1);
                            }
                            ctx.beginPath();
                            ctx.moveTo(p0.x, p0.y);
                            ctx.lineTo(p1.x, p1.y);
                            ctx.lineTo(p2.x, p2.y);
                            ctx.closePath();
                            ctx.fill();
                            ctx.stroke();
                        }
                    }
                }
            }

            // nodes
            ctx.font = "bold " + fontSize + "px sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";

            for (var ni = iMin; ni <= iMax; ni++) {
                for (var nj = jMin; nj <= jMax; nj++) {
                    var np = nodePos(ni, nj);
                    if (np.x < -r || np.x > width + r || np.y < -r || np.y > height + r)
                        continue;
                    var isActive = (hasSelNode && ni === selNodeI && nj === selNodeJ) || isAct(noteAt(ni, nj));
                    var isAugmented = isAug(noteAt(ni, nj));

                    ctx.beginPath();
                    ctx.arc(np.x, np.y, r, 0, Math.PI * 2);
                    if (isAugmented) {
                        ctx.fillStyle = Theme.selFill;
                        ctx.strokeStyle = Theme.selStroke;
                        ctx.lineWidth = Math.max(0.5, 2.5 * scale);
                    } else if (isActive) {
                        ctx.fillStyle = Theme.hlNodeFill;
                        ctx.strokeStyle = Theme.hlColor;
                        ctx.lineWidth = Math.max(0.5, 2.5 * scale);
                    } else {
                        ctx.fillStyle = Theme.nodeFill;
                        ctx.strokeStyle = Theme.nodeStroke;
                        ctx.lineWidth = Math.max(0.5, 1.5 * scale);
                    }
                    ctx.fill();
                    ctx.stroke();

                    if (r > 10) {
                        ctx.fillStyle = isActive ? Theme.hlColor : Theme.nodeText;
                        ctx.fillText(noteNames[noteAt(ni, nj)] + (isAugmented ? "+" : ""), np.x, np.y);
                    }
                }
            }

            // active triad labels — drawn last so opaque fills don't paint over them
            if (activeLabels.length > 0) {
                ctx.font = "bold " + Math.max(1, 11 * scale) + "px sans-serif";
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillStyle = Theme.labelActive;
                for (var al = 0; al < activeLabels.length; al++)
                    ctx.fillText(activeLabels[al].text, activeLabels[al].x, activeLabels[al].y);
            }
        }

        function triadCenter(i, j, isMajor) {
            var p0, p1, p2;
            if (isMajor) {
                p0 = nodePos(i, j);
                p1 = nodePos(i + 1, j);
                p2 = nodePos(i, j + 1);
            } else {
                p0 = nodePos(i + 1, j);
                p1 = nodePos(i, j + 1);
                p2 = nodePos(i + 1, j + 1);
            }
            return Qt.point((p0.x + p1.x + p2.x) / 3, (p0.y + p1.y + p2.y) / 3);
        }

        // Pan just enough to keep screenPt inside the comfortable margin
        function scrollIntoView(screenPt) {
            var margin = 120;
            if (screenPt.x < margin)
                originX += margin - screenPt.x;
            else if (screenPt.x > width - margin)
                originX -= screenPt.x - (width - margin);
            if (screenPt.y < margin)
                originY += margin - screenPt.y;
            else if (screenPt.y > height - margin)
                originY -= screenPt.y - (height - margin);
        }

        function drawActiveEdgeOverlay(ctx, rng, fn, color) {
            ctx.lineWidth = Math.max(1, 3 * scale);
            for (var i = rng.iMin; i <= rng.iMax; i++) {
                for (var j = rng.jMin; j <= rng.jMax; j++) {
                    if (!fn(noteAt(i, j)))
                        continue;
                    var p = nodePos(i, j);
                    if (i + 1 <= rng.iMax && fn(noteAt(i + 1, j)))
                        drawEdge(ctx, p, nodePos(i + 1, j), color);
                    if (j + 1 <= rng.jMax && fn(noteAt(i, j + 1)))
                        drawEdge(ctx, p, nodePos(i, j + 1), color);
                    if (i + 1 <= rng.iMax && j - 1 >= rng.jMin && fn(noteAt(i + 1, j - 1)))
                        drawEdge(ctx, p, nodePos(i + 1, j - 1), color);
                }
            }
        }

        function isActiveTriad(i, j, isMajor) {
            if (isMajor)
                return (hasSelTriad && i === selTriadI && j === selTriadJ && selTriadMajor) || (isAct(noteAt(i, j)) && isAct(noteAt(i + 1, j)) && isAct(noteAt(i, j + 1)));
            else
                return (hasSelTriad && i === selTriadI && j === selTriadJ && !selTriadMajor) || (isAct(noteAt(i + 1, j)) && isAct(noteAt(i, j + 1)) && isAct(noteAt(i + 1, j + 1)));
        }

        function drawEdge(ctx, p1, p2, color) {
            ctx.strokeStyle = color;
            ctx.beginPath();
            ctx.moveTo(p1.x, p1.y);
            ctx.lineTo(p2.x, p2.y);
            ctx.stroke();
        }

        // input

        MouseArea {
            anchors.fill: parent

            property real lastX: 0
            property real lastY: 0
            property real pressX: 0
            property real pressY: 0
            property bool didDrag: false

            onPressed: mouse => {
                lastX = mouse.x;
                lastY = mouse.y;
                pressX = mouse.x;
                pressY = mouse.y;
                didDrag = false;
            }

            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                var dx = mouse.x - lastX;
                var dy = mouse.y - lastY;
                if (Math.abs(mouse.x - pressX) > 4 || Math.abs(mouse.y - pressY) > 4)
                    didDrag = true;
                canvas.originX += dx;
                canvas.originY += dy;
                lastX = mouse.x;
                lastY = mouse.y;
                visualizerSwitcher.vpOriginX = canvas.originX;
                visualizerSwitcher.vpOriginY = canvas.originY;
                canvas.requestPaint();
            }

            onReleased: mouse => {
                parent.parent.forceActiveFocus();  // keep keyboard focus on root Item
                if (didDrag)
                    // was a pan, not a click

                    return;
                var hit = canvas.hitTest(mouse.x, mouse.y);

                if (hit.type === "note") {
                    if (canvas.hasSelNode && canvas.selNodeI === hit.i && canvas.selNodeJ === hit.j) {
                        // toggle off
                        canvas.hasSelNode = false;
                        canvas.nrDists = [];
                        visualizerSwitcher.clearSelection();
                    } else {
                        canvas.hasSelTriad = false;
                        canvas.hasSelNode = true;
                        canvas.selNodeI = hit.i;
                        canvas.selNodeJ = hit.j;
                        canvas.nrDists = [];
                        tonnetzController.selectNote(hit.semitone, hit.i, hit.j);
                        visualizerSwitcher.setNoteSelection(hit.i, hit.j);
                    }
                } else {
                    if (canvas.hasSelTriad && canvas.selTriadI === hit.i && canvas.selTriadJ === hit.j && canvas.selTriadMajor === hit.isMajor) {
                        // toggle off
                        canvas.hasSelTriad = false;
                        canvas.nrDists = [];
                        visualizerSwitcher.clearSelection();
                    } else {
                        canvas.hasSelNode = false;
                        canvas.hasSelTriad = true;
                        canvas.selTriadI = hit.i;
                        canvas.selTriadJ = hit.j;
                        canvas.selTriadMajor = hit.isMajor;
                        canvas.nrDists = tonnetzController.nrDistancesEnabled ? tonnetzController.computeTriadDistances(hit.root, hit.isMajor) : [];
                        tonnetzController.selectTriad(hit.root, hit.third, hit.fifth, hit.isMajor);
                        visualizerSwitcher.setTriadSelection(hit.i, hit.j, hit.isMajor);
                    }
                }

                canvas.requestPaint();
            }

            onWheel: wheel => {
                var factor = wheel.angleDelta.y > 0 ? 1.12 : (1.0 / 1.12);
                canvas.originX = wheel.x + (canvas.originX - wheel.x) * factor;
                canvas.originY = wheel.y + (canvas.originY - wheel.y) * factor;
                canvas.scale *= factor;
                visualizerSwitcher.vpOriginX = canvas.originX;
                visualizerSwitcher.vpOriginY = canvas.originY;
                visualizerSwitcher.vpScale = canvas.scale;
                canvas.requestPaint();
            }
        }

        Connections {
            target: visualizerSwitcher
            function onSelectionsCleared() {
                hasSelNode = false;
                hasSelTriad = false;
                nrDists = [];
                requestPaint();
            }
        }
    }
}
