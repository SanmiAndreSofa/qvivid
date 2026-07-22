\name{save_quantum_plot}
\alias{save_quantum_plot}
\alias{print.qv_export}
\title{Export a Publication-Ready Quantum Figure}
\usage{
save_quantum_plot(
  x,
  file,
  view = c("auto", "state", "circuit", "execution", "bloch"),
  size = c("double", "single"),
  width = NULL,
  height = NULL,
  units = c("mm", "in", "cm"),
  dpi = 450,
  theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
  step = NULL,
  top = NULL,
  qubit = 1L,
  main = NULL,
  subtitle = NULL,
  overwrite = FALSE
)

\method{print}{qv_export}(x, ...)
}
\arguments{
  \item{x}{A circuit, statevector, simulation result, Bloch vector, or Bloch
  trajectory.}
  \item{file}{Destination ending in \code{.pdf}, \code{.svg},
  \code{.png}, or \code{.tiff}.}
  \item{view}{Figure view. \code{"auto"} infers it from \code{x}.}
  \item{size}{Double-column (183 mm) or single-column (89 mm) width preset.}
  \item{width, height}{Optional custom dimensions interpreted in
  \code{units}.}
  \item{units}{Millimetres, inches, or centimetres.}
  \item{dpi}{Raster resolution for PNG and TIFF.}
  \item{theme}{Nature-style, npj-inspired, colorblind, dark, light, or
  monochrome preset.}
  \item{step}{Recorded step for an execution view.}
  \item{top}{Maximum basis states shown in state views.}
  \item{qubit}{One-based qubit index for a Bloch view.}
  \item{main, subtitle}{Optional figure title and subtitle.}
  \item{overwrite}{Replace an existing destination.}
  \item{...}{Additional print arguments reserved for future use.}
}
\value{A \code{qv_export} describing the created artifact.}
\description{
Opens a correctly sized vector or high-resolution raster device, draws a qvivid
view with a consistent preset, and writes the destination only after rendering
has completed successfully.
}
\details{
The journal presets follow Nature's public final-figure widths of 89 mm and
183 mm. PDF and SVG preserve vector artwork; PNG and TIFF default to 450 dpi.
}
\examples{
result <- quantum_circuit(1) |>
  gate_h(1) |>
  simulate_quantum(backend = "reference")
file <- tempfile(fileext = ".pdf")
save_quantum_plot(result, file, view = "state", size = "single")
}
