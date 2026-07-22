\name{measure}
\alias{measure}
\alias{measure_all}
\title{Add Terminal Measurements}
\usage{
measure(circuit, qubits, clbits = qubits)

measure_all(circuit)
}
\arguments{
  \item{circuit}{A \code{qv_circuit}.}
  \item{qubits}{One-based qubit indices.}
  \item{clbits}{Matching one-based classical-bit indices.}
}
\value{A modified \code{qv_circuit}.}
\description{
Maps terminal computational-basis measurements from qubits to classical bits.
Measurements must be terminal in qvivid 0.1.x.
}
\examples{
circuit <- quantum_circuit(2, n_clbits = 3) |>
  gate_h(1) |>
  measure(qubits = c(1, 2), clbits = c(3, 1))
circuit
}
