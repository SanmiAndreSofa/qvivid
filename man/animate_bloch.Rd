\name{animate_bloch}
\alias{animate_bloch}
\title{Animate a Bloch Trajectory}
\usage{
animate_bloch(
  result,
  file,
  qubit = 1L,
  fps = 3,
  width = 720,
  height = 720,
  theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
  view = c("perspective", "xy", "xz", "yz"),
  trail = TRUE,
  loop = TRUE,
  progress = interactive()
)
}
\arguments{
  \item{result}{A \code{qv_result} created with \code{record = TRUE}.}
  \item{file}{Destination path ending in \code{.gif}.}
  \item{qubit}{A one-based qubit index.}
  \item{fps}{Positive frames per second.}
  \item{width, height}{Output dimensions in pixels.}
  \item{theme}{Nature-style, npj-inspired, colorblind, dark, light, or
  monochrome preset.}
  \item{view}{Perspective sphere or a planar projection.}
  \item{trail}{Retain the path through earlier frames.}
  \item{loop}{Repeat the GIF indefinitely.}
  \item{progress}{Display encoder progress interactively.}
}
\value{A \code{qv_animation} containing the normalized GIF path and metadata.}
\description{
Reduces a selected qubit at every recorded execution step, renders consistent
Bloch-sphere frames, and encodes them with the optional \code{gifski} package.
}
\examples{
\dontrun{
result <- quantum_circuit(1) |>
  gate_h(1) |>
  gate_rz(1, pi / 2) |>
  simulate_quantum(record = TRUE)
animate_bloch(result, "bloch.gif", qubit = 1, theme = "npj")
}
}
