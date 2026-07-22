# qvivid roadmap

Development is staged so that each release has a testable numerical scope and a
documented interface. Future version assignments may move when correctness,
performance, or maintenance work needs priority.

## 0.1.0 - first CRAN release

### Implemented

- [x] Circuit objects with one-based qubits and classical bits.
- [x] H, X, Y, Z, S, T, Rx, Ry, Rz, CX, CZ, SWAP, and custom one- or
  two-qubit unitaries.
- [x] Readable R and compiled C statevector backends with a shared result
  schema.
- [x] Deterministic native-versus-reference tests for standard gates, custom
  unitaries, randomized circuits, initial states, and measurement mappings.
- [x] Terminal measurement sampling with explicit classical-bit mapping and
  reproducible seeds.
- [x] Pre-allocation memory estimates and interrupt checks in long native loops.
- [x] Gate-by-gate state recording and tidy state, count, trajectory, and Bloch
  data.
- [x] Circuit, phase-aware state, synchronized execution, Bloch-sphere, and
  Bloch-trajectory figures.
- [x] State and Bloch GIF output with fixed frame geometry.
- [x] Nature- and npj-inspired presets plus manuscript-sized vector and raster
  export.
- [x] A documented initial API contract, executable getting-started vignette,
  package manual, release notes, and MIT license.
- [x] Cross-platform package checks with native compilation on current and
  minimum-supported R versions.

### Before submission

- [ ] Build the exact source archive with current R-devel and obtain
  `0 errors | 0 warnings | 0 notes` from `R CMD check --as-cran`.
- [ ] Record the final check environments, R versions, and workflow link in
  `cran-comments.md`.
- [ ] Confirm that `qvivid` does not conflict with current CRAN packages, the
  CRAN archive, or current Bioconductor software.
- [ ] Review the installed vignette, help pages, examples, and PDF manual from
  the source archive.

## 0.1.x - maintenance and measurement

- Address CRAN feedback and correctness defects without breaking the
  documented initial-series schemas.
- Publish runtime and peak-memory baselines across representative gate mixes
  and qubit counts.
- Add performance regression limits for the compiled kernels.
- Expand compact-device and notation tests as new visual cases are reported.
- Add pixel-reference visual tests after cross-platform device tolerances are
  established.
- Publish a package website from the installed documentation and gallery.

## 0.2 - circuit execution and observables

- Specialized kernels for Clifford, phase, controlled, and swap gates.
- Multi-controlled gates and bounded arbitrary multi-qubit unitaries.
- Mid-circuit measurement, reset, conditional operations, and classical-state
  updates.
- Pauli strings, expectation values, variances, and batched observables.
- Parameter objects, fast parameter binding, and circuit composition and
  inversion.
- OpenQASM 2 and 3 parsing, validation, import, and export.
- Circuit folding, grouping, annotations, and scalable vector layout.

## 0.3 - quantum information and noise

- Density matrices, partial trace, entropy, fidelity, and concurrence.
- Kraus channels and configurable device-style noise models.
- Bloch views for mixed states and noisy trajectories.
- Density-matrix magnitude and phase views.
- Entanglement timelines, mutual-information matrices, and correlation
  networks.
- Exact, noisy, and sampled distribution comparisons.

## 0.4 - algorithms and parameter studies

- QFT, phase estimation, teleportation, Grover search, and quantum-walk
  examples.
- Parameter-shift gradients and batched parameter sweeps.
- VQE and QAOA building blocks that work with R optimization functions.
- Optimization histories, energy surfaces, and animated convergence.
- Reproducible teaching exercises and publication examples.

## 0.5 - larger simulations

- Gate fusion, cache tuning, SIMD evaluation, and bounded multithreading.
- Stabilizer and sparse-state backends.
- Tensor-network execution and contraction planning.
- GPU execution when end-to-end benchmarks show a useful gain.
- Backend selection guidance, cancellation, and progress callbacks.

## 0.6 - remote execution and interactive output

- A capability-checked remote execution interface.
- Separate adapters for Qiskit, Cirq, Amazon Braket, Azure Quantum, and direct
  hardware services where maintenance is practical.
- Persistent job metadata, calibration snapshots, and result caching.
- Shiny and HTML exploration with shareable experiment reports.

## 1.0 readiness

- Stable circuit, result, backend, plotting-data, and serialization interfaces.
- Clean cross-platform CRAN checks and repeatable native benchmarks.
- Independent randomized comparisons with at least two mature simulators.
- No unresolved basis-order, measurement, random-number, or numerical defects.
- Documentation for learners, analysts, researchers, backend implementers, and
  plot extension developers.
- Documented migration, deprecation, and release processes.
