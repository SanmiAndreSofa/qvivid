# qvivid 0.1.0

## Simulation

- Added an R-native circuit API with standard one- and two-qubit gates,
  rotation gates, custom unitary gates, and terminal measurement mapping.
- Added interchangeable compiled and reference statevector backends with a
  common result schema.
- Added reproducible terminal-shot sampling and optional gate-by-gate state
  recording.

## Inspection and visualization

- Added tidy state, count, trajectory, and reduced Bloch-vector data.
- Added circuit, phase-aware state, synchronized execution, Bloch-sphere, and
  Bloch-trajectory figures.
- Added six visual presets and publication-sized PDF, SVG, PNG, and TIFF
  export.
- Added optional GIF export for state evolution and Bloch trajectories.

## Stability

- Established the public 0.1.x API and schema compatibility policy described
  in the Getting Started vignette and README.
- Added cross-platform checks and native/reference numerical parity tests.
