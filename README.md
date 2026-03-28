# ChickenWire

An interactive music theory visualizer built with C++ and Qt 6/QML, displaying harmonic relationships as two synchronized geometric lattices.

## What It Shows

Two dual representations of the same harmonic space, switchable with **F4**:

- **Tonnetz** — triangular lattice where *vertices* are notes and *triangular faces* are triads
- **ChickenWire** — hexagonal lattice where *vertices* are triads and *hexagonal faces* are notes

Edges in both views represent neo-Riemannian transformations (P, R, L) between chords.

## Navigation

| Key | Action |
|-----|--------|
| Arrow keys | Pan the view |
| F4 | Switch between Tonnetz and ChickenWire |
| Click | Select a note or triad |

## Building

Requires Qt 6.8+ and CMake 3.16+.

```sh
cmake -B build
cmake --build build
```

## Architecture

- `TonnetzController` — C++ backend managing note names, selections, and highlighted pitch-class sets (12-bit bitmask)
- `VisualizerSwitcher` — shared viewport and selection state synchronized across both views
- `Tonnetz.qml` / `ChickenWire.qml` — QML front-ends with hit-testing and keyboard navigation
- `Theme.qml` — centralized color palette

Audio playback hooks are stubbed in `TonnetzController` and ready to be wired up.
