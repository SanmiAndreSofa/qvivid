# Performance engineering

This document records qvivid's computational complexity, memory guard, and
benchmark conventions. Performance changes should be compared with the
readable reference backend and measured on representative circuits.

## Current complexity

A statevector stores `2^n` complex doubles, or approximately `16 * 2^n` bytes
before R object overhead and temporary allocations.

| Qubits | Amplitudes | Raw state memory |
|---:|---:|---:|
| 20 | 1,048,576 | 16 MiB |
| 24 | 16,777,216 | 256 MiB |
| 28 | 268,435,456 | 4 GiB |
| 30 | 1,073,741,824 | 16 GiB |

One- and two-qubit gates are `O(2^n)` and do not allocate a full-system operator.
Recorded trajectories deliberately trade memory for inspectability and should
remain opt-in.

`simulate_quantum()` performs a conservative peak-memory estimate before it
allocates the statevector. The default `memory_limit_gib = 2` guard includes
initialization/backend workspace, probability temporaries, shot sampling, and
unique recorded states. A request above the limit fails with a component-level
breakdown and a calculated minimum override; `Inf` disables the guard only when
the caller does so explicitly.

## Benchmark policy

- Keep the reference and native backend outputs within `1e-12` for ordinary
  small circuits unless a numerically justified tolerance is documented.
- Benchmark wall time, peak memory, allocation count, and throughput by gate
  family.
- Separate cold startup, circuit validation, execution, sampling, and visual
  rendering costs.
- Report CPU, compiler, BLAS, R version, backend, thread count, and seed.
- Track representative circuit families rather than one favorable microtest.
- Investigate statistically meaningful regressions and document any accepted
  correctness or maintainability tradeoff in the release notes.

Run the initial source benchmark from the package root with:

```sh
Rscript tools/benchmark.R
```

### Initial reference baseline

Measured on 2026-07-21 with R 4.2.0 on 64-bit Windows. These historical figures
exercise only the readable R reference backend. They do not measure or imply a
speedup from the current native backend.

| Qubits | Amplitudes | Gates | Raw state | Elapsed |
|---:|---:|---:|---:|---:|
| 8 | 256 | 60 | 0.004 MiB | 0.11 s |
| 12 | 4,096 | 90 | 0.063 MiB | 0.05 s |
| 16 | 65,536 | 120 | 1 MiB | 0.79 s |
| 20 | 1,048,576 | 150 | 16 MiB | 21.23 s |

Startup and timer resolution make the smallest values unsuitable for close
comparison. The table is retained as provenance for the reference benchmark,
not as a comparison between backends. The current `tools/benchmark.R` script
also selects the reference backend explicitly. Native/reference performance
should be reported only from a repeated benchmark that records the processor,
compiler, R version, operating system, and package revision.
