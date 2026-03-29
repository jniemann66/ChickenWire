# ChickenWire

An interactive music theory visualizer built with C++ and Qt 6/QML, displaying harmonic relationships as two synchronized geometric lattices.

## What It Shows

Two dual representations of the same harmonic space, switchable with **F4**:

- **Tonnetz** — triangular lattice where *vertices* are notes and *triangular faces* are triads
- **ChickenWire** — hexagonal lattice where *vertices* are triads and *hexagonal faces* are notes

Edges in both views represent neo-Riemannian transformations (P, R, L) between chords, colour-coded consistently across both views:

| Transformation | Colour | Mnemonic |
|----------------|--------|----------|
| **P** (Parallel) | pink | **'P'** for **P**ink |
| **R** (Relative) | orange | **'R'** as in o**R**ange |
| **L** (Leading-tone exchange) | blue | **'L'** as in b**L**ue |

## Navigation

| Key | Action |
|-----|--------|
| Left/Right Arrow keys | Navigate along horizontal (perfect 5ths) axis |
| Up/Down Arrow keys | Navigate along major-3rds axis |
| Shift + Up/Down Arrow Keys | Navigate along minor-3rds axis | 
| F4 | Switch between Tonnetz and ChickenWire |
| D | Toggle neo-Riemannian distance highlighting |
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
