// seventhChords.qml — Cannas/Andreatta generalised Chicken-wire Torus
// for seventh chords (Bridges 2018, Fig. 3).
//
// 51 chord nodes + 132 edges, drawn in concentric rings of increasing
// "brightness" (dim → ø → m → dom → maj):
//   centre  °7 orbits  (squares — only 3 nodes, in a 120° triangle)
//           ø7         (circles)
//           min7       (rhombi)
//           dom7       (pentagons)
//   outer   maj7       (hexagons)
//
// After enharmonic reduction the paper's 17 transformations collapse to
// 11 distinct edge classes (12 instances each = 132 edges):
//
//   P12  dom ↔ min      same root, parallel
//   P14  dom ↔ maj
//   P23  min ↔ ø
//   P35  ø   ↔ °        same root (° orbit = root mod 3)
//   R12  dom ↔ min      min root = dom root − 3
//   R23  min ↔ ø
//   R42  maj ↔ min
//   L13  dom ↔ ø
//   L15  dom ↔ °
//   L42  maj ↔ min
//   Q43  maj ↔ ø        special Cannas/Andreatta Q map
//
// Edge colours:  P → pink   R → orange   L → blue   Q → green.
//
// Declutter aids:
//   F5             toggle distance highlighting from the selected chord
//   F6             toggle chromatic ↔ cycle-of-fourths root ordering
//                  (clockwise C, F, B♭, …; ii–V–I clusters at adjacent
//                  angles, with V→I always moving clockwise)
//   1..4           toggle P12, P14, P23, P35 (parallel edges)
//   5..7           toggle R12, R23, R42      (relative edges)
//   8, 9, 0        toggle L13, L15, L42      (leading-tone edges)
//   - (minus)      toggle Q43                (special Q edge)
//   = (or Backsp.) un-mute every class
//   click a node   focuses that chord's incident edges at full opacity;
//                  every other edge stays at the default ~20% (so by
//                  default, with no selection, all edges are unfocused)

import QtQuick
import ChickenWire

Item {
    id: root
    focus: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_F5) {
            canvas.showDistances = !canvas.showDistances;
            if (canvas.showDistances && canvas.selNode >= 0) {
                canvas.nodeDists = canvas.computeDistances(canvas.selNode);
            } else {
                canvas.nodeDists = [];
            }
            canvas.requestPaint();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_F6) {
            visualizerSwitcher.fifthsOrder = !visualizerSwitcher.fifthsOrder;
            canvas.requestPaint();
            event.accepted = true;
            return;
        }

        // Number-row keys: toggle one transformation class at a time.
        var idx = canvas.classKeyOrder.indexOf(event.key);
        if (idx >= 0) {
            var cls = canvas.classNames[idx];
            var hidden = (visualizerSwitcher.hiddenClasses || []).slice();
            var i = hidden.indexOf(cls);
            if (i >= 0)
                hidden.splice(i, 1);
            else
                hidden.push(cls);
            visualizerSwitcher.hiddenClasses = hidden;
            canvas.requestPaint();
            event.accepted = true;
            return;
        }

        // = / Backspace: restore all classes
        if (event.key === Qt.Key_Equal || event.key === Qt.Key_Backspace) {
            visualizerSwitcher.hiddenClasses = [];
            canvas.requestPaint();
            event.accepted = true;
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        property var noteNames: tonnetzController.noteNames
        property var majorRootNoteNames: tonnetzController.majorRootNoteNames
        property var minorRootNoteNames: tonnetzController.minorRootNoteNames
        property int activeNotes: tonnetzController.activeNotes

        onNoteNamesChanged: requestPaint()
        onMajorRootNoteNamesChanged: requestPaint()
        onMinorRootNoteNamesChanged: requestPaint()
        onActiveNotesChanged: {
            // Auto-follow: select the first fully-matching chord so edge focus
            // and F5 BFS distances track the music live.  Always clear the
            // previous selection when no full match exists — so a 7th-chord
            // selection does not linger into a subsequent triad or rest.
            var best = -1;
            if (activeNotes !== 0) {
                for (var i = 0; i < nodes.length; i++) {
                    if (nodeMatchCount(i) === 4) {
                        best = i;
                        break;
                    }
                }
            }
            if (best >= 0) {
                selNode = best;
                if (showDistances)
                    nodeDists = computeDistances(best);
            } else {
                selNode = -1;
                nodeDists = [];
            }
            requestPaint();
        }

        property real originX: width / 2
        property real originY: height / 2
        property real scale: 1.0
        property int selNode: -1
        property bool showDistances: false
        property var nodeDists: []

        readonly property real baseUnit: 45.0

        // Outermost-ring radius in layout units; the maj hexagons sit there.
        readonly property real figureRadius: rMaj
        // Scale-dependent half-extent of an outermost node, in pixels at
        // scale = 1.  This is what `nodeR = max(6, 15*scale)` evaluates to
        // when scale = 1, so the actual visual extent is `(figureRadius *
        // baseUnit + nodeExtentPx) * scale`.
        readonly property real nodeExtentPx: 15

        function fitToWindow() {
            if (width <= 0 || height <= 0)
                return;
            var avail = Math.min(width, height) / 2 - 20;   // 20 px breathing room
            var fr = baseUnit * figureRadius + nodeExtentPx;
            if (fr < 1)
                return;
            scale = Math.max(0.1, avail / fr);
            originX = width / 2;
            originY = height / 2;
            requestPaint();
        }
        onWidthChanged: fitToWindow()
        onHeightChanged: fitToWindow()
        Component.onCompleted: fitToWindow()

        // Ring radii (layout units).  Order from centre outward follows the
        // "darker → brighter" gradient of the seventh chords themselves
        // (°7 darkest, maj7 brightest).  rDim is wider than the natural
        // centroid (~0.85) so the three °7 squares form a roomy triangle —
        // this gives their incoming edges space without breaking the order.
        readonly property real rDim: 1.3
        readonly property real rHalfdim: 2.55
        readonly property real rMin: 3.9
        readonly property real rDom: 5.3
        readonly property real rMaj: 7.0

        //   Edge-class visibility
        readonly property var classNames: ["P12", "P14", "P23", "P35", "R12", "R23", "R42", "L13", "L15", "L42", "Q43"]
        // Number-row keys (in classNames order):  1 2 3 4 5 6 7 8 9 0 -
        readonly property var classKeyOrder: [Qt.Key_1, Qt.Key_2, Qt.Key_3, Qt.Key_4, Qt.Key_5, Qt.Key_6, Qt.Key_7, Qt.Key_8, Qt.Key_9, Qt.Key_0, Qt.Key_Minus]
        function allClassesVisible() {
            var v = {};
            for (var i = 0; i < classNames.length; i++)
                v[classNames[i]] = true;
            return v;
        }
        // Derived from visualizerSwitcher.hiddenClasses so the set survives
        // across sessions (and so VisualizerSwitcher remains the single
        // source of truth for persisted UI state).
        property var visibleClasses: {
            var v = {};
            var hidden = visualizerSwitcher.hiddenClasses || [];
            for (var i = 0; i < classNames.length; i++)
                v[classNames[i]] = hidden.indexOf(classNames[i]) === -1;
            return v;
        }
        onVisibleClassesChanged: requestPaint()

        // true  → cycle of fourths / descending fifths
        //         (C, F, B♭, E♭, ...) clockwise from the top — the jazz
        //         "cycle of fifths" direction, matching V→I motion (default)
        // false → chromatic (C, C♯, D, ...) clockwise from the top
        property bool useFifthsOrder: visualizerSwitcher.fifthsOrder
        onUseFifthsOrderChanged: requestPaint()

        // Node layout:  0–11 maj | 12–23 dom | 24–35 min | 36–47 ø | 48–50 °
        property var nodes: (function () {
                var arr = [];
                for (var r = 0; r < 12; r++)
                    arr.push({
                        type: "maj",
                        root: r
                    });
                for (var r = 0; r < 12; r++)
                    arr.push({
                        type: "dom",
                        root: r
                    });
                for (var r = 0; r < 12; r++)
                    arr.push({
                        type: "min",
                        root: r
                    });
                for (var r = 0; r < 12; r++)
                    arr.push({
                        type: "halfdim",
                        root: r
                    });
                for (var r = 0; r < 3; r++)
                    arr.push({
                        type: "dim",
                        root: r
                    });
                return arr;
            })()

        // Edge table — generated programmatically from the 11 transformation rules.
        // Each entry: [nodeA, nodeB, transformationLabel].
        property var edges: (function () {
                var e = [];
                for (var r = 0; r < 12; r++) {
                    e.push([12 + r, 24 + r, "P12"]);
                    e.push([12 + r, 0 + r, "P14"]);
                    e.push([24 + r, 36 + r, "P23"]);
                    e.push([36 + r, 48 + (r % 3), "P35"]);
                    e.push([12 + r, 24 + ((r + 9) % 12), "R12"]);
                    e.push([24 + r, 36 + ((r + 9) % 12), "R23"]);
                    e.push([0 + r, 24 + ((r + 9) % 12), "R42"]);
                    e.push([12 + r, 36 + ((r + 4) % 12), "L13"]);
                    e.push([12 + r, 48 + ((r + 1) % 3), "L15"]);
                    e.push([0 + r, 24 + ((r + 4) % 12), "L42"]);
                    e.push([0 + r, 36 + ((r + 1) % 12), "Q43"]);
                }
                return e;
            })()

        // Angular position of root r.  Multiplying the chromatic index by 5
        // (mod 12) walks the cycle of fourths (C, F, B♭, E♭, ...) — i.e. V→I
        // motion runs clockwise.  The same 12 angular slots are reused, so
        // edge angles, curving, and dim-orbit symmetry all keep working.
        function angleFor(r) {
            var pos = useFifthsOrder ? (r * 5) % 12 : r;
            return Math.PI / 2 - pos * Math.PI / 6;
        }
        function angleForDim(o) {
            return Math.PI / 2 - o * 2 * Math.PI / 3;
        }

        function posPolar(rad, ang) {
            return Qt.point(originX + rad * baseUnit * scale * Math.cos(ang), originY - rad * baseUnit * scale * Math.sin(ang));
        }

        function nodePos(idx) {
            var n = nodes[idx];
            if (n.type === "maj")
                return posPolar(rMaj, angleFor(n.root));
            if (n.type === "dom")
                return posPolar(rDom, angleFor(n.root));
            if (n.type === "min")
                return posPolar(rMin, angleFor(n.root));
            if (n.type === "halfdim")
                return posPolar(rHalfdim, angleFor(n.root));
            return posPolar(rDim, angleForDim(n.root));
        }

        function notesForNode(idx) {
            var n = nodes[idx];
            var r = n.root;
            if (n.type === "maj")
                return [r, (r + 4) % 12, (r + 7) % 12, (r + 11) % 12];
            if (n.type === "dom")
                return [r, (r + 4) % 12, (r + 7) % 12, (r + 10) % 12];
            if (n.type === "min")
                return [r, (r + 3) % 12, (r + 7) % 12, (r + 10) % 12];
            if (n.type === "halfdim")
                return [r, (r + 3) % 12, (r + 6) % 12, (r + 10) % 12];
            return [r, (r + 3) % 12, (r + 6) % 12, (r + 9) % 12];
        }

        function nodeLabel(idx) {
            var n = nodes[idx];
            if (n.type === "maj")
                return majorRootNoteNames[n.root] + "Δ";
            if (n.type === "dom")
                return majorRootNoteNames[n.root] + "7";
            if (n.type === "min")
                return minorRootNoteNames[n.root] + "m";
            if (n.type === "halfdim")
                return minorRootNoteNames[n.root] + "ø";
            return minorRootNoteNames[n.root] + "°";
        }

        function isAct(s) {
            return !!((activeNotes >> s) & 1);
        }
        function nodeMatchCount(idx) {
            var ns = notesForNode(idx);
            var n = 0;
            for (var k = 0; k < 4; k++)
                if (isAct(ns[k]))
                    n++;
            return n;
        }
        function nodeIsActive(idx) {
            return nodeMatchCount(idx) === 4;
        }

        // When exactly 3 notes are active and they form a standard triad,
        // return the index of the one seventh-chord node whose root/3rd/5th
        // match exactly — the 7th is simply absent from the MIDI.
        // Returns -1 for augmented triads (no node yet) or non-triad 3-note sets.
        function triadPartialNode() {
            var nbits = 0;
            for (var i = 0; i < 12; i++)
                if ((activeNotes >> i) & 1)
                    nbits++;
            if (nbits !== 3)
                return -1;
            for (var r = 0; r < 12; r++) {
                if (!((activeNotes >> r) & 1))
                    continue;
                var m3 = !!((activeNotes >> ((r + 3) % 12)) & 1);
                var m4 = !!((activeNotes >> ((r + 4) % 12)) & 1);
                var m6 = !!((activeNotes >> ((r + 6) % 12)) & 1);
                var m7 = !!((activeNotes >> ((r + 7) % 12)) & 1);
                if (m4 && m7)
                    return r;              // major triad  → maj7 (index r)
                if (m3 && m7)
                    return 24 + r;         // minor triad  → min7 (index 24+r)
                if (m3 && m6)
                    return 48 + (r % 3);  // dim triad    → dim7 (index 48+r%3)
                // augmented (m4 && m8): no node yet → falls through to return -1
            }
            return -1;
        }

        function edgeColour(etype) {
            var c = etype.charCodeAt(0);
            if (c === 80)
                return Theme.edgeP;           // 'P'
            if (c === 82)
                return Theme.edgeR;           // 'R'
            if (c === 76)
                return Theme.edgeL;           // 'L'
            return Theme.edgeQ;                          // 'Q'
        }

        // BFS distance over the edge table.
        function computeDistances(startIdx) {
            var dist = [];
            for (var i = 0; i < nodes.length; i++)
                dist[i] = -1;
            dist[startIdx] = 0;
            var queue = [startIdx], head = 0;
            while (head < queue.length) {
                var cur = queue[head++];
                for (var ei = 0; ei < edges.length; ei++) {
                    var ee = edges[ei];
                    var nbr = (ee[0] === cur) ? ee[1] : (ee[1] === cur ? ee[0] : -1);
                    if (nbr >= 0 && dist[nbr] < 0) {
                        dist[nbr] = dist[cur] + 1;
                        queue.push(nbr);
                    }
                }
            }
            return dist;
        }

        function hitTest(px, py) {
            var rad = Math.max(7, 15 * scale);
            var bestD2 = rad * rad;
            var best = -1;
            for (var i = 0; i < nodes.length; i++) {
                var p = nodePos(i);
                var d2 = (px - p.x) * (px - p.x) + (py - p.y) * (py - p.y);
                if (d2 < bestD2) {
                    bestD2 = d2;
                    best = i;
                }
            }
            return best;
        }

        // Regular polygon path, circumradius `rad`, first vertex at angle `phase`.
        function pathPolygon(ctx, cx, cy, rad, sides, phase) {
            ctx.beginPath();
            for (var k = 0; k < sides; k++) {
                var a = phase + k * 2 * Math.PI / sides;
                var x = cx + rad * Math.cos(a);
                var y = cy + rad * Math.sin(a);
                if (k === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.closePath();
        }

        // Distance from a node's centre at which to plant the schematic-style
        // junction dot — roughly the inradius of each shape so the dot sits
        // just inside the visible boundary.
        function boundaryOffset(type, nodeR, squareHW) {
            if (type === "halfdim")
                return nodeR * 0.78;
            if (type === "dim")
                return squareHW * 0.85;
            if (type === "maj")
                return nodeR * 0.78;    // hexagon inradius
            if (type === "dom")
                return nodeR * 0.72;    // pentagon inradius
            return nodeR * 0.70;                            // rhombus
        }

        // Angular separation (radians) between two nodes as seen from the
        // figure centre.  Used to decide whether to curve an edge.
        function angularSpan(idxA, idxB) {
            var na = nodes[idxA];
            var nb = nodes[idxB];
            var aa = (na.type === "dim") ? angleForDim(na.root) : angleFor(na.root);
            var ab = (nb.type === "dim") ? angleForDim(nb.root) : angleFor(nb.root);
            var d = Math.abs(aa - ab);
            if (d > Math.PI)
                d = 2 * Math.PI - d;
            return d;
        }

        // Quadratic-Bezier control point that bows the chord outward, away
        // from the figure centre.  Returns null for nearly-radial edges that
        // should stay straight.  For chords whose midpoint is on the centre
        // line, the cross product of (chord) × (midpoint−origin) breaks the
        // tie deterministically.
        function curveControlPoint(pa, pb, span) {
            if (span < Math.PI / 6)
                return null;   // < 30° → straight
            var mx = (pa.x + pb.x) / 2;
            var my = (pa.y + pb.y) / 2;
            var dx = pb.x - pa.x;
            var dy = pb.y - pa.y;
            var len = Math.sqrt(dx * dx + dy * dy);
            if (len < 1)
                return null;
            // Perpendicular unit vector.
            var px = -dy / len;
            var py = dx / len;
            // Midpoint relative to origin, used to pick the "outward" side.
            var rx = mx - originX;
            var ry = my - originY;
            var dot = rx * px + ry * py;
            if (Math.abs(dot) < 0.5) {
                // Chord (nearly) passes through origin — perpendicular is
                // perpendicular to the radius too, so dot ≈ 0.  Use the
                // signed area as a stable tiebreaker.
                var cross = dx * ry - dy * rx;
                if (cross < 0) {
                    px = -px;
                    py = -py;
                }
            } else if (dot < 0) {
                px = -px;
                py = -py;
            }
            // Curvature grows from 0 at 30° to ~0.18·len at 180°.
            var t = (span - Math.PI / 6) / (Math.PI - Math.PI / 6);
            var amount = len * 0.18 * t;
            return Qt.point(mx + px * amount, my + py * amount);
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var nodeR = Math.max(6, 15 * scale);
            var squareHW = Math.max(5, 13 * scale);
            var fontSize = Math.max(1, 10 * scale);

            ctx.lineCap = "round";

            var hasSel = (selNode >= 0);

            //   Edges
            for (var ei = 0; ei < edges.length; ei++) {
                var ed = edges[ei];
                if (!visibleClasses[ed[2]])
                    continue;
                var pa = nodePos(ed[0]);
                var pb = nodePos(ed[1]);
                var inc = hasSel && (ed[0] === selNode || ed[1] === selNode);
                ctx.globalAlpha = inc ? 1.0 : 0.2;

                var span = angularSpan(ed[0], ed[1]);
                var cp = curveControlPoint(pa, pb, span);

                ctx.lineWidth = Math.max(0.4, 1.2 * scale);
                ctx.strokeStyle = edgeColour(ed[2]);
                ctx.beginPath();
                ctx.moveTo(pa.x, pa.y);
                if (cp)
                    ctx.quadraticCurveTo(cp.x, cp.y, pb.x, pb.y);
                else
                    ctx.lineTo(pb.x, pb.y);
                ctx.stroke();
            }
            ctx.globalAlpha = 1.0;

            // Active-edge highlight: both endpoints fully sounding.
            // Skip muted classes so that hiding a class hides its highlight too.
            if (activeNotes !== 0) {
                ctx.lineWidth = Math.max(1, 2.6 * scale);
                ctx.strokeStyle = Theme.hlEdge;
                for (var hi = 0; hi < edges.length; hi++) {
                    var he = edges[hi];
                    if (!visibleClasses[he[2]])
                        continue;
                    if (nodeIsActive(he[0]) && nodeIsActive(he[1])) {
                        var ha = nodePos(he[0]);
                        var hb = nodePos(he[1]);
                        var hsp = angularSpan(he[0], he[1]);
                        var hcp = curveControlPoint(ha, hb, hsp);
                        ctx.beginPath();
                        ctx.moveTo(ha.x, ha.y);
                        if (hcp)
                            ctx.quadraticCurveTo(hcp.x, hcp.y, hb.x, hb.y);
                        else
                            ctx.lineTo(hb.x, hb.y);
                        ctx.stroke();
                    }
                }
            }

            // Nodes
            var nrC = [Theme.nrDist0, Theme.nrDist1, Theme.nrDist2, Theme.nrDist3, Theme.nrDist4, Theme.nrDist5, Theme.nrDist6];
            var partialNode = (activeNotes !== 0) ? triadPartialNode() : -1;

            for (var ni = 0; ni < nodes.length; ni++) {
                var n = nodes[ni];
                var np = nodePos(ni);
                var mc = nodeMatchCount(ni);
                var act = mc === 4;
                var partial = (ni === partialNode);
                var sel = (ni === selNode);
                var nrD = (nodeDists.length > 0) ? nodeDists[ni] : -1;
                if (nrD > nrC.length - 1)
                    nrD = nrC.length - 1;

                // Shape
                if (n.type === "maj")
                    pathPolygon(ctx, np.x, np.y, nodeR, 6, -Math.PI / 2);
                else if (n.type === "dom")
                    pathPolygon(ctx, np.x, np.y, nodeR, 5, -Math.PI / 2);
                else if (n.type === "min")
                    pathPolygon(ctx, np.x, np.y, nodeR * 1.05, 4, -Math.PI / 2);
                else if (n.type === "halfdim") {
                    ctx.beginPath();
                    ctx.arc(np.x, np.y, nodeR * 0.9, 0, Math.PI * 2);
                } else {
                    ctx.beginPath();
                    ctx.rect(np.x - squareHW, np.y - squareHW, squareHW * 2, squareHW * 2);
                }

                // Fill / stroke
                if (sel) {
                    ctx.fillStyle = Theme.selFill;
                    ctx.strokeStyle = Theme.selStroke;
                    ctx.lineWidth = Math.max(0.5, 2.5 * scale);
                } else if (act) {
                    ctx.fillStyle = Theme.hlNodeFill;
                    ctx.strokeStyle = Theme.hlColor;
                    ctx.lineWidth = Math.max(0.5, 2.5 * scale);
                } else if (partial) {
                    ctx.fillStyle = Qt.rgba(Theme.hlNodeFill.r, Theme.hlNodeFill.g, Theme.hlNodeFill.b, 0.3);
                    ctx.strokeStyle = Qt.rgba(Theme.hlColor.r, Theme.hlColor.g, Theme.hlColor.b, 0.55);
                    ctx.lineWidth = Math.max(0.5, 2.0 * scale);
                } else if (nrD >= 0) {
                    var c = nrC[nrD];
                    ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, 0.35);
                    ctx.strokeStyle = c;
                    ctx.lineWidth = Math.max(0.5, 2.5 * scale);
                } else if (n.type === "maj" || n.type === "dom") {
                    ctx.fillStyle = Theme.majorFill;
                    ctx.strokeStyle = Theme.majorStroke;
                    ctx.lineWidth = Math.max(0.5, 1.5 * scale);
                } else {
                    ctx.fillStyle = Theme.minorFill;
                    ctx.strokeStyle = Theme.minorStroke;
                    ctx.lineWidth = Math.max(0.5, 1.5 * scale);
                }
                ctx.fill();
                ctx.stroke();

                if (nodeR > 6) {
                    ctx.font = "bold " + fontSize + "px sans-serif";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.fillStyle = (act || sel) ? Theme.hlColor : partial ? Qt.rgba(Theme.hlColor.r, Theme.hlColor.g, Theme.hlColor.b, 0.6) : (nrD >= 0) ? nrC[nrD] : Theme.triadText;
                    ctx.fillText((partial && n.type === "maj") ? majorRootNoteNames[n.root] : nodeLabel(ni), np.x, np.y);
                }
            }

            // Junction dots
            // Schematic-style "the wire connects HERE" markers — one per edge
            // endpoint, just inside each node's boundary, in the direction of
            // the curve's tangent at that endpoint (so dots line up with their
            // edge even when the edge is bowed).  Coloured to match the edge
            // and faded along with non-incident edges when a node is selected.
            var dotR = Math.max(1.6, 2.6 * scale);
            for (var di = 0; di < edges.length; di++) {
                var edd = edges[di];
                if (!visibleClasses[edd[2]])
                    continue;
                var dpa = nodePos(edd[0]);
                var dpb = nodePos(edd[1]);
                var dsp = angularSpan(edd[0], edd[1]);
                var dcp = curveControlPoint(dpa, dpb, dsp);

                // Tangent direction at A points toward CP (or B if straight).
                var ax2 = (dcp ? dcp.x : dpb.x) - dpa.x;
                var ay2 = (dcp ? dcp.y : dpb.y) - dpa.y;
                var bx2 = (dcp ? dcp.x : dpa.x) - dpb.x;
                var by2 = (dcp ? dcp.y : dpa.y) - dpb.y;
                var alen = Math.sqrt(ax2 * ax2 + ay2 * ay2);
                var blen = Math.sqrt(bx2 * bx2 + by2 * by2);
                if (alen < 1 || blen < 1)
                    continue;
                var oa = boundaryOffset(nodes[edd[0]].type, nodeR, squareHW);
                var ob = boundaryOffset(nodes[edd[1]].type, nodeR, squareHW);

                var inc = hasSel && (edd[0] === selNode || edd[1] === selNode);
                ctx.globalAlpha = inc ? 1.0 : 0.2;
                ctx.fillStyle = edgeColour(edd[2]);
                ctx.beginPath();
                ctx.arc(dpa.x + ax2 / alen * oa, dpa.y + ay2 / alen * oa, dotR, 0, Math.PI * 2);
                ctx.fill();
                ctx.beginPath();
                ctx.arc(dpb.x + bx2 / blen * ob, dpb.y + by2 / blen * ob, dotR, 0, Math.PI * 2);
                ctx.fill();
            }
            ctx.globalAlpha = 1.0;
        }

        // Input

        MouseArea {
            anchors.fill: parent

            property real lastX: 0
            property real lastY: 0
            property real pressX: 0
            property real pressY: 0
            property bool didDrag: false

            onPressed: m => {
                lastX = m.x;
                lastY = m.y;
                pressX = m.x;
                pressY = m.y;
                didDrag = false;
            }

            onPositionChanged: m => {
                if (!pressed)
                    return;
                if (Math.abs(m.x - pressX) > 4 || Math.abs(m.y - pressY) > 4)
                    didDrag = true;
                canvas.originX += m.x - lastX;
                canvas.originY += m.y - lastY;
                lastX = m.x;
                lastY = m.y;
                canvas.requestPaint();
            }

            onReleased: m => {
                parent.forceActiveFocus();
                if (didDrag)
                    return;
                var hit = canvas.hitTest(m.x, m.y);
                if (hit < 0 || hit === canvas.selNode) {
                    canvas.selNode = -1;
                    canvas.nodeDists = [];
                    tonnetzController.clearHighlightedNotes();
                } else {
                    canvas.selNode = hit;
                    tonnetzController.setHighlightedNotes(canvas.notesForNode(hit));
                    if (canvas.showDistances)
                        canvas.nodeDists = canvas.computeDistances(hit);
                }
                canvas.requestPaint();
            }

            onWheel: w => {
                var factor = w.angleDelta.y > 0 ? 1.12 : (1.0 / 1.12);
                canvas.originX = w.x + (canvas.originX - w.x) * factor;
                canvas.originY = w.y + (canvas.originY - w.y) * factor;
                canvas.scale *= factor;
                canvas.requestPaint();
            }
        }

        Connections {
            target: visualizerSwitcher
            function onSelectionsCleared() {
                selNode = -1;
                nodeDists = [];
                requestPaint();
            }
        }

        Connections {
            target: Theme
            function onThemeChanged() { requestPaint(); }
        }
    }
}
