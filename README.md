# ChickenWire

An interactive music theory visualizer which displays harmonic relationships on geometric lattices, driven by MIDI file playback or manual exploration.

## What It Shows

Two dual representations of the same harmonic space, switchable with **F4**:

- **Tonnetz** — triangular lattice where *vertices* are notes and *triangular faces* are triads
- **ChickenWire** — hexagonal lattice where *vertices* are triads and *hexagonal faces* are notes

(The ChickenWire Tonnetz is the geometric dual of the regular Tonnetz, meaning that the vertices of the Tonnetz correspond to the faces of the ChickenWire Tonnetz and vice versa)

The two views share a common coordinate system and stay in sync: panning, zooming, and selections in one view are immediately reflected in the other.

Edges represent neo-Riemannian transformations (P, R, L), colour-coded consistently:

| Transformation | Colour |
|----------------|--------|
| **P** (Parallel) | pink |
| **R** (Relative) | orange |
| **L** (Leading-tone exchange) | blue |

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

## Navigation

| Key | Action |
|-----|--------|
| **F4** | Toggle between Tonnetz and ChickenWire |
| **Arrow keys** | Move selection along perfect-5ths / major-3rds axes |
| **Shift + Up/Down** | Move selection along minor-3rds axis |
| **F5** | Toggle neo-Riemannian distance highlighting |
| **Click** | Select a note or triad; click again to deselect |
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
