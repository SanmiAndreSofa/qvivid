# R quantum-simulation package landscape

**Research date:** 2026-07-21

**Purpose:** document the R packages located in this review and place qvivid's
current design in that context.

## Summary

Among the packages located in this audit, none combines the breadth of
established Python frameworks such as Qiskit, Cirq, PennyLane, or QuTiP with a
current, general-purpose R interface.

The closest current R-native comparison is
[`qsimulatR`](https://CRAN.R-project.org/package=qsimulatR). It provides a
statevector simulator, gates, measurement, several algorithms, plotting, and
simple stochastic errors. Its engine is written in R, its latest CRAN release
is from 2023, and its Qiskit export targets APIs that changed in Qiskit 1.0.

Other findings are:

- [`QCSimulator`](https://CRAN.R-project.org/package=QCSimulator) manipulates
  quantum states in a fixed, five-qubit teaching implementation from 2016.
- [`Unitary`](https://CRAN.R-project.org/package=Unitary) is recent and provides
  circuit construction and plotting. No state-evolution or measurement
  functions were identified in the published source examined for this audit.
- [`QuantumOps`](https://CRAN.R-project.org/web/packages/QuantumOps/index.html)
  contains a broad educational collection of algorithms and
  quantum-information operations. It is archived, has no shipped tests, and
  uses dense pure-R matrices.
- The remaining current CRAN packages focus on specialized applications,
  quantum-walk mathematics, or quantum-inspired classical algorithms rather
  than general circuit simulation.

These results define a useful scope for qvivid: an R-native circuit model,
registered C statevector kernels, explicit measurement and basis-ordering
semantics, reproducible sampling, validation, and integrated visualization.

## Scope and method

This inventory covers indexed packages and public repositories located by the
search. It does not claim to enumerate every personal or unpublished
repository.

The search covered:

1. The live CRAN package index and package metadata, searching names, titles, and descriptions for quantum computing, circuits, qubits, gates, entanglement, quantum walks, QKD, and quantum-inspired optimization.
2. Current [Bioconductor 3.23](https://www.bioconductor.org/news/bioc_3_23_release/) software and experiment-data indexes.
3. R-universe, using its documented [global package-search API](https://docs.r-universe.dev/browse/api.html).
4. GitHub and vendor ecosystems for R interfaces to
   [Qiskit](https://github.com/Qiskit/qiskit), Cirq, and quantum hardware.
5. CRAN archives for packages that remain technically or historically relevant.

The live CRAN metadata search produced 18 packages containing “quantum” in a package name, title, or description. Nine were relevant to quantum computing or quantum-mechanical simulation; the others used the word in unrelated scientific or metaphorical contexts. Package tarballs were then inspected for exported functions, implementation strategy, tests, and vignettes. This was a source audit rather than a runtime benchmark.

Versions and repository statuses below are snapshots from the research date.
Package links point to the corresponding CRAN, Bioconductor, documentation, or
source pages; implementation descriptions refer to the source versions named
in the tables. Status and API claims should be rechecked when this inventory is
updated.

The search found no relevant quantum-computing package in Bioconductor 3.23 and
did not locate a current official R SDK for IBM/Qiskit, Google/Cirq, AWS
Braket, Azure Quantum, D-Wave, or PennyLane.

## 1. General circuit and state simulators

| Package | Status | What it actually provides | Strengths | Weaknesses | Assessment |
|---|---|---|---|---|---|
| [`qsimulatR` 1.1.1](https://CRAN.R-project.org/package=qsimulatR) | Current CRAN; 2023-10-16 | S4 statevectors and gates, controlled gates, measurement, plotting, QFT, phase estimation, simple random error injection, Python-code export | Coherent object model; custom one-qubit gates; useful teaching vignettes | Pure-R dense statevectors; hard limit of 24 qubits; no density matrices or Kraus channels; no shipped tests; no OpenQASM; legacy Qiskit export | Closest current R-native comparison for general circuit simulation |
| [`QCSimulator` 0.0.1](https://CRAN.R-project.org/package=QCSimulator) | Current CRAN; 2016-07-02 | Dense basis vectors and matrices for one to five qubits, named gates, probabilities, measurement plots | Very simple educational entry point; permissive MIT license | Fixed five-qubit design; repetitive hard-coded matrices; writes many objects into the global environment; returns probabilities rather than sampled/collapsed measurements; no tests | Historical teaching implementation with a deliberately limited scope |
| [`Unitary` 0.3.11](https://CRAN.R-project.org/package=Unitary) | Current CRAN; 2026-07-06 | Pipe-friendly circuit construction and highly configurable circuit diagrams | Recent; pleasant circuit-building syntax; reusable custom gate descriptors; structural tests; strong plotting controls | The inspected source provides circuit structure and diagrams; no statevector execution, sampling, or measurement API was identified | Circuit construction and visualization rather than state simulation |
| [`QuantumOps` 3.0.1](https://CRAN.R-project.org/web/packages/QuantumOps/index.html) | Archived 2026-05-14; last release 2020-02-03 | Quantum linear algebra, state and density-matrix operations, measurement, noise, QFT, Shor, Grover, QAOA, VQC, teleportation, error correction, synthesis/decomposition | Broad educational feature catalogue covering algorithms and quantum-information concepts | No tests or development repository identified; dense pure-R matrices; inconsistent function/result conventions; exports short names such as `I`, `T`, `S`, and `norm`; no modern circuit/backend layer | Useful historical reference with a different architecture from current backend-oriented packages |
| [`Cirq`](https://github.com/turgut090/Cirq) | Experimental GitHub package; not CRAN; no releases | `reticulate` wrapper around Python Cirq | Potential access to the Python simulator and device ecosystem | Python/environment dependency; small project; no stable release; inspected examples use earlier Cirq APIs such as `cirq.google.Foxtail` | Experimental Python bridge rather than a stable R interface |

### Core feature comparison

| Capability | qsimulatR | QCSimulator | Unitary | QuantumOps | Cirq R wrapper |
|---|---:|---:|---:|---:|---:|
| Real state evolution | Yes | Yes | No | Yes | Through Python |
| Arbitrary-size circuit model | Limited by statevector | No; 1–5 qubits | Circuit structure only | Ad hoc operations | Through Python |
| Shot sampling and collapse | Yes | No; probabilities only | No | Yes | Through Python |
| Density matrix/open systems | No | No | No | Yes | Through Python |
| Noise | Random pure-state gate errors | No | No | Several educational channels | Through Python |
| Custom gates | Yes, mainly one-qubit/controlled | Limited | Descriptors only | Yes | Through Python |
| Algorithms | QFT, phase estimation | Minimal examples | No | Broad catalogue | Cirq ecosystem |
| OpenQASM | No | No | No | No | Not exposed as an R contract |
| Compiled simulation kernel | No | No | N/A | No | Python implementation |
| Meaningful physics tests shipped | No | No | No; structural tests only | No | No R-level suite found |

`qsimulatR::export2qiskit()` generates imports for `qiskit.execute` and `qiskit.Aer`. IBM’s official [Qiskit 1.0 migration guide](https://quantum.cloud.ibm.com/docs/migration-guides/qiskit-1.0-features) documents that both were removed from the top-level `qiskit` namespace, so that export path is not compatible with modern Qiskit without manual changes.

## 2. Specialized quantum simulators and mathematical packages

| Package | Status and scope | Strengths | Weaknesses |
|---|---|---|---|
| [`qwalkr` 0.1.0](https://CRAN.R-project.org/package=qwalkr) | Current CRAN; continuous-time quantum walks | Clean focused S3 API; unitary/mixing/average-mixing matrices; graph products; substantial tests and a vignette; MIT license | Dense eigendecompositions; only continuous-time walks; no gate circuits, shots, noise, or backend abstraction |
| [`QGameTheory` 0.1.2](https://CRAN.R-project.org/package=QGameTheory) | Current CRAN; quantum game-theory demonstrations | Ready-made Penny Flip, Prisoner’s Dilemma, duel, Hawk–Dove, Monty Hall, and related workflows; MIT license | Domain-specific; initializes a large global environment; dense matrices up to fixed sizes; no tests, noise model, circuit IR, or interoperability; last release 2020 |
| [`RQEntangle` 0.1.3](https://CRAN.R-project.org/package=RQEntangle) | Current CRAN; bipartite Schmidt decomposition and entanglement measures | Small, focused API for discrete and discretized continuous bipartite states; vignette; MIT license | No circuits; limited to bipartite pure-state workflows; old iterator dependencies; no tests identified in the published source |
| [`qtbi` 0.1.2](https://CRAN.R-project.org/package=qtbi) | Current CRAN; “Quantum Toxic Burden Index” | Recent; tested; includes a real statevector encoder and pairwise controlled-rotation kernels that avoid constructing full gate matrices | Hard-wired toxic-exposure model and circuit topology; no general gate/circuit API, shots, noise, or interchange; pure-R exponential statevector |
| [`qvirus` 0.0.6](https://CRAN.R-project.org/package=qvirus) | Current CRAN; HIV/CD4 models plus abstract BB84/E91 demonstrations | Recent; tested; useful educational QKD examples and application datasets; MIT license | QKD routines are classical stochastic abstractions rather than quantum-state simulation; narrow and conceptually mixed domain API |
| [`QWDAP` 1.1.20](https://CRAN.R-project.org/web/packages/QWDAP/index.html) | Archived 2026-07-15; continuous-time quantum-walk feature extraction for graph-associated time series | Compiled Rcpp/Eigen walk calculations; complete applied regression/prediction workflow; bundled paper and data | Archived because it requires archived `CORElearn`; heavy domain-specific dependency stack; not a general simulator |

`qwalkr` provides a useful specialist example: it combines a focused API with
tests and a vignette, although its mathematical domain differs from gate-based
simulation.

## 3. Adjacent packages that are not quantum simulators

| Package | Classification | Why it has a different scope |
|---|---|---|
| [`QGA` 1.0](https://CRAN.R-project.org/package=QGA) | Quantum-inspired genetic algorithm | Uses classically simulated alpha/beta “qubits,” stochastic observation, mutation, and rotation as an optimization heuristic; it does not model quantum circuits or physical evolution |
| [`qrandom` 1.2.6](https://CRAN.R-project.org/web/packages/qrandom/index.html) | Archived quantum-random-number API client | Fetches random data from the Australian National University service; it is not a simulator and was archived in 2023 |
| [`QuantumR`](https://github.com/JeanBertinR/QuantumR) | Experimental visualization repository | Described as visualizing quantum-computing simulations; it is not a current indexed package or established simulation engine |
| `qicR` | Conference presentation/prototype | A “Quantum Information & Computation in R” talk can be found, but no current installable package or maintained source repository was identified |
| `reticulate` + Qiskit/Cirq/PennyLane | General Python bridge | This provides an integration route rather than an R quantum package; users manage Python, versions, object conversion, and vendor API changes |

## 4. Observations across the reviewed packages

- **Teaching coverage is broad.** Existing packages cover statevectors,
  measurement, common algorithms, entanglement, walks, game theory, and QKD.
- **R-native composition works well.** `qsimulatR` demonstrates gate
  composition in R, while `Unitary` demonstrates pipe-friendly circuit
  construction and configurable plotting.
- **Several packages serve focused applications.** `qwalkr`, `QWDAP`, `qtbi`,
  and `QGameTheory` connect quantum models with statistical or domain-specific
  workflows.
- **Several implementations use permissive licenses.** QCSimulator, qwalkr,
  QGameTheory, RQEntangle, qtbi, and qvirus use MIT-style licensing. Any code
  reuse still requires review of the exact license files and provenance.

## 5. Common limitations in the reviewed packages

- **Performance:** nearly every R-native engine uses dense pure-R vectors or matrices. A statevector needs `2^n` complex amplitudes; full operators need `4^n` entries.
- **Test coverage:** several general simulators ship little or no
  physics-oriented regression or property testing.
- **No shared circuit representation:** packages mix states, matrices, gate functions, plots, and algorithms without a stable intermediate representation.
- **Weak semantics:** qubit order, endianness, measurement collapse, classical bits, random seeds, and result formats are not consistently specified.
- **Interoperability is limited:** the review found no maintained OpenQASM-first
  R package or vendor-neutral backend interface.
- **Backend interfaces differ:** the reviewed packages do not share an
  interface across statevectors, density matrices, tensor networks,
  stabilizers, accelerators, or remote services.
- **Maintenance varies:** the broadest package is archived, the closest current
  general simulator was last released in 2023, and the oldest current
  simulator dates to 2016.

## 6. qvivid design and current implementation

qvivid 0.1.0 implements a compact gate-based workflow rather than the larger
feature set described in the earlier planning notes. The package currently
connects circuit construction, pure-state simulation, terminal sampling, tidy
inspection, static figures, and GIF animation.

### Circuit and simulation

- `qv_circuit` stores validated operations, quantum-bit indices, classical-bit
  indices, labels, parameters, and a schema version. R-facing indices are
  one-based; qubit 1 is the least-significant statevector bit.
- The gate API includes standard one- and two-qubit gates and custom one- or
  two-qubit unitary matrices. Measurement maps qubits to classical bits and is
  terminal in the current release.
- The reference backend is implemented in R. The native backend uses R's C API
  without Rcpp or an external compiled library. Its one- and two-qubit
  routines are registered with `R_registerRoutines()` and called through
  `.Call`; dynamic symbol lookup is disabled.
- Both backends update amplitude pairs or quartets and avoid constructing a
  full-system operator for routine gates. `simulate_quantum()` returns exact
  probabilities, optional seeded shot counts, and an optional recorded
  trajectory.
- A pre-allocation estimate covers the statevector, working memory,
  probabilities, sampling, and recorded states. The configurable memory guard
  rejects estimates above its limit before the main state is allocated.
- Tests cover standard gates, custom unitaries, reversed qubit order,
  deterministic randomized circuits, terminal measurement mappings, seeded
  sampling, and native/reference agreement on installed builds.

### Data and visualization

- Circuit, result, count, state-data, Bloch-data, and trajectory schemas are
  documented for the 0.1.x series.
- The plotting layer includes circuit diagrams, phase-aware probability plots,
  synchronized execution views, Bloch spheres, and Bloch trajectories.
- Base graphics provide the dependency-free default. `ggplot2`, `ragg`, and
  `gifski` are optional dependencies for composition, raster output, and GIF
  encoding.
- Publication export supports PDF, SVG, PNG, and TIFF together with six visual
  presets and journal-width size presets.

### Current limits

The simulator currently represents pure statevectors, so memory and execution
time grow exponentially with qubit count. Measurement is terminal; the package
does not yet implement mid-circuit collapse, reset, conditional execution,
density matrices, noise channels, alternative simulator families, or remote
hardware. OpenQASM import and export are also outside 0.1.0; an implementation
would need to follow the official
[OpenQASM specification](https://openqasm.com/intro.html).

The repository includes a reference-backend benchmark script, but this audit
does not use it to claim a native speedup. Reproducible native/reference timing
results require a documented environment and repeated measurements.

## 7. Design lessons retained from the review

The current implementation draws on several useful ideas visible in the R
ecosystem:

- `qsimulatR`: approachable R-facing state and gate composition;
- `Unitary`: circuit construction and configurable diagrams;
- `qwalkr`: focused abstractions and test discipline;
- `qtbi`: amplitude updates that avoid full-system gate matrices;
- `QuantumOps`: a broad catalogue of quantum-information topics.

qvivid keeps circuit data separate from simulator state, does not write objects
to `.GlobalEnv`, documents qubit and basis ordering, validates normalization,
and avoids full-system matrices for routine gates. Code from other packages is
not incorporated without a separate license and provenance review.
