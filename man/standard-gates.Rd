\name{standard-gates}
\alias{standard-gates}
\alias{gate_h}
\alias{gate_x}
\alias{gate_y}
\alias{gate_z}
\alias{gate_s}
\alias{gate_t}
\alias{gate_rx}
\alias{gate_ry}
\alias{gate_rz}
\alias{gate_cx}
\alias{gate_cz}
\alias{gate_swap}
\alias{gate_unitary}
\title{Add Quantum Gates to a Circuit}
\usage{
gate_h(circuit, qubit)
gate_x(circuit, qubit)
gate_y(circuit, qubit)
gate_z(circuit, qubit)
gate_s(circuit, qubit)
gate_t(circuit, qubit)
gate_rx(circuit, qubit, theta)
gate_ry(circuit, qubit, theta)
gate_rz(circuit, qubit, theta)
gate_cx(circuit, control, target)
gate_cz(circuit, control, target)
gate_swap(circuit, qubit1, qubit2)
gate_unitary(circuit, matrix, qubits, label = "U")
}
\arguments{
  \item{circuit}{A \code{qv_circuit}.}
  \item{qubit}{A one-based qubit index.}
  \item{theta}{Rotation angle in radians.}
  \item{control, target}{Distinct one-based control and target indices.}
  \item{qubit1, qubit2}{Distinct one-based qubit indices.}
  \item{matrix}{A numeric or complex 2 by 2 or 4 by 4 unitary matrix.}
  \item{qubits}{One or two one-based qubit indices.}
  \item{label}{A short circuit-diagram label for a custom unitary.}
}
\value{A modified \code{qv_circuit}.}
\description{
Adds standard or custom one- and two-qubit unitary operations. All functions
accept the circuit first and therefore compose with the base R pipe.
}
\details{
For a two-qubit custom gate on \code{c(q1, q2)}, the supplied matrix uses local
basis order \code{|00⟩, |01⟩, |10⟩, |11⟩} with \code{q1} as the first qubit.
}
\examples{
bell <- quantum_circuit(2) |>
  gate_h(1) |>
  gate_cx(1, 2)
}
