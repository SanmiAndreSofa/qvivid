\name{quantum_circuit}
\alias{quantum_circuit}
\alias{circuit_depth}
\alias{print.qv_circuit}
\title{Create and Inspect Quantum Circuits}
\usage{
quantum_circuit(n_qubits, n_clbits = n_qubits, name = NULL)

circuit_depth(circuit)

\method{print}{qv_circuit}(x, ...)
}
\arguments{
  \item{n_qubits}{Number of qubits, using one-based R indices.}
  \item{n_clbits}{Number of classical bits.}
  \item{name}{Optional human-readable circuit name.}
  \item{circuit, x}{A \code{qv_circuit}.}
  \item{...}{Additional arguments reserved for methods.}
}
\value{
\code{quantum_circuit()} returns a named list with class \code{qv_circuit}.
Its stable 0.1.x fields are \code{name}, \code{n_qubits}, \code{n_clbits},
\code{operations}, and \code{schema_version}. Operation records expose
\code{type}, \code{name}, \code{label}, \code{qubits}, \code{clbits},
\code{matrix}, and \code{parameters}; treat these fields as read-only.
\code{circuit_depth()} returns one integer. The print method returns its input
invisibly.
}
\description{
Creates the validated circuit intermediate representation used by every
qvivid backend and visualization.
}
\examples{
circuit <- quantum_circuit(2, name = "Bell state")
circuit
circuit_depth(circuit)
}
