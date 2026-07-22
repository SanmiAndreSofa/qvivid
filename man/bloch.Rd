\name{bloch_vector}
\alias{bloch_vector}
\alias{trajectory_bloch}
\alias{plot_bloch}
\alias{plot.qv_bloch}
\alias{print.qv_bloch}
\title{Bloch Vectors, Spheres, and Trajectories}
\usage{
bloch_vector(x, qubit = 1L)

trajectory_bloch(result, qubit = 1L)

plot_bloch(
  x,
  qubit = 1L,
  theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
  view = c("perspective", "xy", "xz", "yz"),
  trajectory = FALSE,
  main = NULL,
  subtitle = NULL
)

\method{plot}{qv_bloch}(x, ...)

\method{print}{qv_bloch}(x, ...)
}
\arguments{
  \item{x}{A complex statevector, \code{qv_result}, \code{qv_bloch}, or
  \code{qv_bloch_trajectory}.}
  \item{result}{A \code{qv_result} created with \code{record = TRUE}.}
  \item{qubit}{A one-based qubit index.}
  \item{theme}{Nature-style, npj-inspired, colorblind, dark, light, or
  monochrome preset.}
  \item{view}{Perspective sphere or the xy, xz, or yz planar projection.}
  \item{trajectory}{Draw the complete recorded path for a result.}
  \item{main, subtitle}{Optional title and subtitle.}
  \item{...}{Arguments passed to \code{plot_bloch()}; additional print
  arguments are reserved.}
}
\value{
\code{bloch_vector()} returns a \code{qv_bloch} object.
\code{trajectory_bloch()} returns a data frame with one vector per step.
\code{plot_bloch()} returns the plotted vector invisibly.
}
\description{
Computes a reduced single-qubit state directly from a statevector and renders
it as a publication-oriented Bloch sphere. Entanglement and other mixing appear
as contraction of the vector inside the unit sphere.
}
\examples{
result <- quantum_circuit(2, name = "Bell state") |>
  gate_h(1) |>
  gate_cx(1, 2) |>
  simulate_quantum(record = TRUE, backend = "reference")

bloch_vector(result, qubit = 1)
plot_bloch(result, qubit = 1, trajectory = TRUE)
}
