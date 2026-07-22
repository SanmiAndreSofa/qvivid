\name{animate_state}
\alias{animate_state}
\alias{print.qv_animation}
\title{Animate Quantum State Evolution}
\usage{
animate_state(
  result,
  file,
  fps = 3,
  width = 960,
  height = 760,
  top = NULL,
  theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
  include_circuit = TRUE,
  loop = TRUE,
  progress = interactive()
)

\method{print}{qv_animation}(x, ...)
}
\arguments{
  \item{result}{A \code{qv_result} created with \code{record = TRUE}.}
  \item{file}{Destination path ending in \code{.gif}.}
  \item{fps}{Positive frames per second.}
  \item{width, height}{Output dimensions in pixels.}
  \item{top}{Maximum basis states shown in every frame.}
  \item{theme}{Nature-style, npj-inspired, colorblind, dark, light, or monochrome preset.}
  \item{include_circuit}{Include a synchronized circuit execution playhead.}
  \item{loop}{Repeat the GIF indefinitely.}
  \item{progress}{Display encoder progress interactively.}
  \item{x}{A \code{qv_animation}.}
  \item{...}{Additional arguments reserved for methods.}
}
\value{A \code{qv_animation} containing the normalized GIF path and metadata.}
\description{
Renders a gate-by-gate probability and phase trajectory and encodes it with the
optional \code{gifski} package.
}
\examples{
\dontrun{
result <- quantum_circuit(1) |>
  gate_h(1) |>
  measure_all() |>
  simulate_quantum(record = TRUE)
animate_state(result, "hadamard.gif")
}
}
