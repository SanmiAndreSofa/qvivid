## Test environments

* GitHub Actions, Ubuntu 24.04.4 LTS, R Under development (unstable)
  (2026-06-21 r90185)
* GitHub Actions, Ubuntu 24.04.4 LTS, R 4.6.1 (2026-06-24)
* GitHub Actions, Microsoft Windows Server 2025,
  R 4.6.1 (2026-06-24 ucrt)
* GitHub Actions, macOS 26.4 (arm64), R 4.6.1 (2026-06-24)
* GitHub Actions, Ubuntu 22.04.5 LTS, R 4.2.3 (2023-03-15)

## R CMD check results

The `qvivid_0.1.0.tar.gz` source tarball was built with the current R
release. That exact tarball completed the full technical
`R CMD check --as-cran` with R-devel with:

0 errors | 0 warnings | 0 notes

A separate CRAN incoming feasibility check on the same source tarball
reported:

0 errors | 0 warnings | 1 note

* New submission

No other incoming diagnostics were reported. The cross-platform checks
completed with `Status: OK` on all five test environments.

## Submission notes

This is the first submission of qvivid.

## Downstream dependencies

There are currently no known downstream dependencies.
