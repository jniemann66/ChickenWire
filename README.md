# ChickenWire

An interactive music theory visualizer which displays harmonic relationships on geometric lattices, driven by MIDI file playback or manual exploration.

## What It Shows

Four views of the same harmonic space, switchable with **F4** (next) and **Shift + F4** (previous):

- **Tonnetz** — triangular lattice where *vertices* are notes and *triangular faces* are triads
- **ChickenWire** — hexagonal lattice where *vertices* are triads and *hexagonal faces* are notes — the geometric dual of the Tonnetz, where vertices and faces are swapped
- **Cube Dance** — Douthett & Steinbach's graph of 24 triads plus 4 augmented chords, arranged in four hexatonic cycles joined through the augmented chords as shared pivots
- **Seventh Chords** — Cannas & Andreatta's generalised Chicken-wire Torus (Bridges 2018), with 63 seventh-chord nodes arranged in concentric rings (°7 at the centre, outward through ø7, m7, dom7, maj7 to Maj7♯5) linked by 14 classes of parsimonious voice-leading transformation

The Tonnetz and ChickenWire views share a common coordinate system and stay in sync: panning, zooming, and selections in one view are immediately reflected in the other.

Edges represent neo-Riemannian transformations, colour-coded consistently across every view:

| Transformation | Colour |
|----------------|--------|
| **P** (Parallel) | pink |
| **R** (Relative) | orange |
| **L** (Leading-tone exchange) | blue |
| **Q** (Cannas/Andreatta Q map, Seventh Chords only) | green |

## Features

### MIDI Playback
Load and play standard MIDI files via the **Transport** dock (bottom of the window). As notes play, the corresponding pitch classes light up in both views simultaneously.

### Neo-Riemannian Distance Highlighting
Press **D** (or use the keyboard shortcut) to enable distance colouring. When a triad is selected, every other triad is coloured by its minimum number of P/R/L steps from the selection, using a rainbow scale from green (1 step) through to red (5 steps).

### Augmented Chord Detection
When enabled via **View → Show Augmented Chords**, notes that form an augmented triad are given distinct visual treatment:
- **Tonnetz**: the note circle is filled gold and the label gains a **+** suffix (e.g. *A+*)
- **ChickenWire**: a gold circle is drawn around the note label inside the hexagon, and the label gains a **+** suffix

### Colour Controls
The **Color Scheme** menu provides:
- **Negative** — inverts all colours through a GLSL fragment shader applied as a Qt layer effect
- **Adjust Color…** — opens a dockable panel with sliders for hue rotation, saturation, brightness, and contrast; double-click any slider to reset it; all values are persisted across sessions

## Keyboard Shortcuts

Press **F1** at any time to show the in-app shortcut overlay.

### Global

| Key | Action |
|-----|--------|
| **F1** | Show / hide the shortcut overlay |
| **F4** | Next visualizer |
| **Shift + F4** | Previous visualizer |
| **Escape** | Clear all selections |

### Tonnetz and ChickenWire

| Key | Action |
|-----|--------|
| **← / → / ↑ / ↓** | Move selection (perfect-5ths / major-3rds axes) |
| **Shift + ↑ / ↓** | Move selection along the minor-3rds axis |
| **F5** | Toggle NR distance highlighting |
| **Click** | Select a note or triad; click again to deselect |
| **Drag** | Pan the view |
| **Scroll wheel** | Zoom |

### Cube Dance

| Key | Action |
|-----|--------|
| **F5** | Toggle NR distance highlighting |
| **F7** | Toggle "actual cubes" mode |
| **Click** | Select a chord |
| **Drag** | Pan the view |
| **Scroll wheel** | Zoom |

### Seventh Chords

| Key | Action |
|-----|--------|
| **F5** | Toggle distance highlighting from selected chord |
| **F6** | Toggle chromatic ↔ cycle-of-fourths root order |
| **1 / 2 / 3 / 4** | Toggle P12 / P14 / P23 / P35 (parallel edges) |
| **5 / 6 / 7** | Toggle R12 / R23 / R42 (relative edges) |
| **8 / 9 / 0** | Toggle L13 / L15 / L42 (leading-tone edges) |
| **-** | Toggle Q43 (special Q edge) |
| **= or Backspace** | Restore all transformation classes |
| **Click** | Focus a chord's incident edges |
| **Drag** | Pan the view |
| **Scroll wheel** | Zoom |

## Building

Requires Qt 6.8+ and CMake 3.16+.

```sh
cmake -B build
cmake --build build
```

## Architecture

| File | Role |
|------|------|
| `tonnetzController.h/.cpp` | Manages note names, active pitch-class bitmask, selections, and NR-distance BFS |
| `visualizerSwitcher.h` | Shared viewport state, selection, and display options (colour adjustments, augmented toggle) |
| `midiPlayer.h/.cpp` | MIDI file sequencer; emits `noteOn`/`noteOff` signals consumed by `TonnetzController` |
| `midiFile.h/.cpp` | Standard MIDI file parser |
| `midiAudio.h/.cpp` | Platform audio backend (ALSA/process on Linux, WinMM on Windows) |
| `transportWidget.h/.cpp` | Playback controls dock widget |
| `tonnetz.qml` | Tonnetz canvas: drawing, hit-testing, keyboard navigation |
| `chickenWire.qml` | ChickenWire canvas: drawing, hit-testing, keyboard navigation |
| `theme.qml` | Centralised colour palette singleton |
| `coloreffect.frag` | GLSL fragment shader for hue, saturation, brightness, contrast, and colour inversion |
