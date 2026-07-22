\name{simulate_quantum}
\alias{simulate_quantum}
\alias{state_data}
\alias{trajectory_data}
\alias{print.qv_result}
\title{Simulate Quantum Circuits and Inspect State Data}
\usage{
simulate_quantum(
  circuit,
  shots = NULL,
  seed = NULL,
  initial_state = NULL,
  backend = c("auto", "native", "reference"),
  record = FALSE,
  memory_limit_gib = getOption("qvivid.memory_limit_gib", 2)
)

state_data(x, include_zero = TRUE, tolerance = 1e-14)

trajectory_data(result, include_zero = TRUE)

\method{print}{qv_result}(x, ...)
}
\arguments{
  \item{circuit}{A \code{qv_circuit}.}
  \item{shots}{Optional positive number of terminal measurement samples.}
  \item{seed}{Optional non-negative integer seed.}
  \item{initial_state}{Optional normalized complex statevector.}
  \item{backend}{The automatic, native, or readable reference backend.}
  \item{record}{Retain state after every operation for animation.}
  \item{memory_limit_gib}{Maximum estimated peak memory, in GiB. Defaults to
  option \code{qvivid.memory_limit_gib}, or 2 GiB when the option is unset.
  The estimate includes the statevector, initialization and backend workspace,
  probability temporaries, shot sampling, and a recorded trajectory.
  Explicitly raise the value when sufficient memory is available, or use
  \code{Inf} to disable the guard.}
  \item{x}{A complex statevector or \code{qv_result}.}
  \item{result}{A \code{qv_result} created with \code{record = TRUE}.}
  \item{include_zero}{Include effectively zero-probability basis states.}
  \item{tolerance}{Threshold used to classify zero probabilities.}
  \item{...}{Additional arguments reserved for methods.}
}
\value{
\code{simulate_quantum()} returns a \code{qv_result}. The following named
elements form the stable qvivid 0.1.x result schema:
\describe{
  \item{\code{circuit}}{The input \code{qv_circuit}.}
  \item{\code{state}}{The final complex statevector. Qubit 1 is the
  least-significant statevector bit; displayed basis strings put the
  highest-numbered qubit first.}
  \item{\code{probabilities}}{Exact probabilities in the same order as
  \code{state}.}
  \item{\code{counts}}{A data frame with character \code{basis}, integer
  \code{count}, and numeric \code{probability} columns. Basis strings put the
  highest-numbered classical bit first. With \code{shots = NULL}, this is a
  zero-row data frame with the same columns.}
  \item{\code{shots}, \code{seed}}{The integer sampling inputs, or
  \code{NULL}.}
  \item{\code{backend}}{The resolved backend name.}
  \item{\code{elapsed}}{Elapsed simulation time in seconds.}
  \item{\code{trajectory}}{\code{NULL}, or a list of frames containing
  integer \code{step}, character \code{label}, \code{operation}, and complex
  \code{state} fields.}
  \item{\code{schema_version}}{The integer result-schema version.}
}

\code{state_data()} returns stable columns \code{index}, \code{basis},
\code{real}, \code{imaginary}, \code{magnitude}, \code{probability}, and
\code{phase}. The index is zero-based; phase is \code{NA} below
\code{tolerance}. \code{trajectory_data()} appends integer \code{step} and
character \code{label} columns to those state columns.
}
\description{
Executes a validated circuit without constructing full-system gate matrices.
Exact state probabilities and optional reproducible shot counts share one
stable result schema. Before allocating the state, the function conservatively
estimates memory for initialization, backend workspace, probability
temporaries, shot sampling, and retained trajectory states. The default guard
is exactly 2 GiB unless option \code{qvivid.memory_limit_gib} is set; a
per-call \code{memory_limit_gib} value takes precedence.
}
\examples{
bell <- quantum_circuit(2) |>
  gate_h(1) |>
  gate_cx(1, 2) |>
  measure_all()

result <- simulate_quantum(
  bell,
  shots = 1000,
  seed = 42,
  backend = "reference",
  record = TRUE
)
state_data(result, include_zero = FALSE)
trajectory_data(result)
}
