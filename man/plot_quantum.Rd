\name{plot_state}
\alias{plot_state}
\alias{plot_circuit}
\alias{plot_execution}
\alias{plot.qv_result}
\alias{plot.qv_circuit}
\alias{theme_quantum}
\alias{qv_palette}
\title{Visualize Quantum States and Circuits}
\usage{
plot_state(
  x,
  top = NULL,
  theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
  engine = c("base", "ggplot2", "auto"),
  main = NULL,
  subtitle = NULL
)

plot_circuit(
  circuit,
  highlight = NULL,
  theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
  main = NULL,
  subtitle = NULL
)

plot_execution(
  result,
  step = NULL,
  top = NULL,
  theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
  main = NULL,
  subtitle = NULL
)

theme_quantum(
  theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
  base_size = NULL
)

qv_palette(
  theme = c("nature", "npj", "colorblind", "dark", "light", "mono")
)

\method{plot}{qv_result}(x, ...)

\method{plot}{qv_circuit}(x, ...)
}
\arguments{
  \item{x}{A statevector, simulation result, or circuit for the method.}
  \item{top}{Maximum basis states selected by probability.}
  \item{theme}{Nature-style, npj-inspired, colorblind, dark, light, or monochrome preset.}
  \item{engine}{Rendering engine. \code{"base"} (the default) draws
  immediately and returns the plotted data invisibly. \code{"ggplot2"}
  returns a ggplot object for explicit printing or composition. \code{"auto"}
  is retained as a backward-compatible alias for \code{"base"} and never
  changes according to installed optional packages.}
  \item{main, subtitle}{Optional plot title and subtitle.}
  \item{circuit}{A \code{qv_circuit}.}
  \item{result}{A \code{qv_result}.}
  \item{step}{Optional recorded execution step.}
  \item{highlight}{Optional operation index emphasized in the circuit.}
  \item{base_size}{Optional base ggplot2 text size; the preset supplies a default.}
  \item{...}{Arguments passed from S3 methods.}
}
\value{
The ggplot2 state engine returns a ggplot object visibly. Base state plots
return a data frame containing their plotted state data invisibly; base circuit
plots return their circuit invisibly. Theme and palette functions return their
respective objects.
}
\description{
Plots phase-aware probability bars, themed circuit diagrams, and synchronized
circuit/state execution views. Probability is encoded by bar height and complex
phase by cyclic fill color. The default state-plot behavior does not depend on
ggplot2 or any other suggested package being installed.
}
