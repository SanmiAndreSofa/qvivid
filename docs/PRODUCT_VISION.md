# qvivid product direction

qvivid is intended to support quantum simulation work in R from circuit
construction through numerical execution, inspection, visualization, and
publication output. The package will grow in stages while keeping its circuit,
result, and plotting interfaces explicit and testable.

## Technical objectives

1. **Defined numerical behavior.** Qubit order, basis order, normalization,
   measurement mapping, random seeds, and numerical tolerances must be
   documented and covered by tests.
2. **Inspectable results.** Circuits, states, samples, and recorded execution
   steps must remain available as ordinary R objects rather than being hidden
   inside a plotting or execution layer.
3. **A conventional R interface.** The public API uses one-based indices, base
   pipes, data frames, S3 print and plot methods, and reproducible seeds.
4. **Efficient state updates.** Common gates should update the affected
   amplitudes directly instead of constructing a full-system operator.
5. **A small required dependency set.** Exact local simulation must work
   without Python, a browser session, an online account, or a large plotting
   framework.
6. **Replaceable execution backends.** Additional numerical methods must use
   the same validated circuit representation and return compatible result
   data.
7. **Reproducible figures.** Static plots and animations must be reconstructible
   from documented result data and explicit rendering arguments.

## Current foundation

The first release candidate includes:

- a `qv_circuit` object with one-based qubits, standard one- and two-qubit
  gates, rotation gates, custom unitaries, and terminal measurement mapping;
- exact statevector simulation through a readable R backend and compiled C
  kernels;
- normalized custom initial states, seeded terminal-shot sampling, optional
  gate-by-gate recording, and a pre-allocation memory guard;
- stable circuit, result, count, state-data, and trajectory schemas for the
  initial release series;
- circuit, state, synchronized execution, and reduced-state Bloch plots;
- six visual presets, manuscript-sized PDF/SVG/PNG/TIFF export, and optional
  state and Bloch GIF output;
- deterministic native-versus-reference comparisons, randomized circuit tests,
  compact-device visual tests, and cross-platform package checks.

Mid-circuit measurement, density matrices, noise models, large-unitary support,
specialized backends, remote execution, and interactive graphics are not part
of the first release.

## Visualization work

The current plots show state probability and phase, circuit structure,
execution position, and single-qubit reduced states. Planned additions are
driven by specific quantities that users need to inspect:

- real and imaginary amplitude views;
- entanglement entropy timelines, mutual-information matrices, and correlation
  networks;
- density-matrix magnitude and phase;
- contraction, fidelity loss, and state comparisons under noise;
- Hamiltonian spectra and time evolution;
- quantum-walk state over the source graph;
- side-by-side exact, noisy, sampled, and remote-hardware distributions;
- parameter-sweep and variational-optimization surfaces;
- MP4 and HTML output where those formats add information beyond the existing
  vector figures and GIFs.

Each view should be calculated from a documented data object. Static plots,
animations, and later interactive views should not implement separate numerical
interpretations of simulator state.

## Performance work

The current implementation has direct one- and two-qubit C kernels, a readable
reference backend, a memory estimator, and a benchmark script. Further work
will be accepted only with measured improvements and numerical agreement with
the reference implementation.

The planned order is:

1. establish repeatable runtime and memory baselines by qubit count and circuit
   type;
2. add specialized kernels for common fixed gates;
3. add parameter binding and gate fusion without rebuilding circuits;
4. tune memory access and evaluate SIMD and bounded multithreading;
5. batch parameter sweeps and observable calculations;
6. add stabilizer and sparse-state methods for circuits where they apply;
7. add tensor-network execution for suitable low-entanglement circuits;
8. evaluate GPU execution using end-to-end timings that include data transfer;
9. add remote execution through capability-checked service adapters.

Every optimized path must pass deterministic and randomized equivalence tests.
A speed improvement is not accepted if it changes basis ordering, measurement
semantics, or numerical tolerances without an explicit API change.

## Scope boundaries

Early releases will not:

- add broad gate and algorithm catalogues before their state semantics are
  tested;
- conceal the exponential memory cost of dense statevectors;
- require optional graphics packages for basic simulation or plotting;
- couple the core package to a single external quantum service;
- use screenshots in place of reusable result and plotting data.
