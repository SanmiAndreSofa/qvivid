#' Add standard quantum gates
#'
#' Gate functions accept a circuit first, which makes them compatible with the
#' base R pipe. Qubit indices are one-based.
#'
#' @param circuit A `qv_circuit`.
#' @param qubit A one-based qubit index.
#' @param control A one-based control-qubit index.
#' @param target A one-based target-qubit index.
#' @param qubit1,qubit2 Distinct one-based qubit indices.
#' @param theta Rotation angle in radians.
#' @return A modified `qv_circuit`.
#' @name standard-gates
NULL

#' @rdname standard-gates
#' @export
gate_h <- function(circuit, qubit) {
  .qv_add_gate(circuit, "H", qubit, .qv_gate_matrix("H"))
}

#' @rdname standard-gates
#' @export
gate_x <- function(circuit, qubit) {
  .qv_add_gate(circuit, "X", qubit, .qv_gate_matrix("X"))
}

#' @rdname standard-gates
#' @export
gate_y <- function(circuit, qubit) {
  .qv_add_gate(circuit, "Y", qubit, .qv_gate_matrix("Y"))
}

#' @rdname standard-gates
#' @export
gate_z <- function(circuit, qubit) {
  .qv_add_gate(circuit, "Z", qubit, .qv_gate_matrix("Z"))
}

#' @rdname standard-gates
#' @export
gate_s <- function(circuit, qubit) {
  .qv_add_gate(circuit, "S", qubit, .qv_gate_matrix("S"))
}

#' @rdname standard-gates
#' @export
gate_t <- function(circuit, qubit) {
  .qv_add_gate(circuit, "T", qubit, .qv_gate_matrix("T"))
}

#' @rdname standard-gates
#' @export
gate_rx <- function(circuit, qubit, theta) {
  if (!is.numeric(theta) || length(theta) != 1L || !is.finite(theta)) {
    .qv_abort("`theta` must be one finite numeric angle in radians.")
  }
  .qv_add_gate(
    circuit,
    "RX",
    qubit,
    .qv_gate_matrix("RX", theta),
    parameters = list(theta = theta),
    label = sprintf("Rx(%.3g)", theta)
  )
}

#' @rdname standard-gates
#' @export
gate_ry <- function(circuit, qubit, theta) {
  if (!is.numeric(theta) || length(theta) != 1L || !is.finite(theta)) {
    .qv_abort("`theta` must be one finite numeric angle in radians.")
  }
  .qv_add_gate(
    circuit,
    "RY",
    qubit,
    .qv_gate_matrix("RY", theta),
    parameters = list(theta = theta),
    label = sprintf("Ry(%.3g)", theta)
  )
}

#' @rdname standard-gates
#' @export
gate_rz <- function(circuit, qubit, theta) {
  if (!is.numeric(theta) || length(theta) != 1L || !is.finite(theta)) {
    .qv_abort("`theta` must be one finite numeric angle in radians.")
  }
  .qv_add_gate(
    circuit,
    "RZ",
    qubit,
    .qv_gate_matrix("RZ", theta),
    parameters = list(theta = theta),
    label = sprintf("Rz(%.3g)", theta)
  )
}

#' @rdname standard-gates
#' @export
gate_cx <- function(circuit, control, target) {
  .qv_add_gate(circuit, "CX", c(control, target), .qv_gate_matrix("CX"))
}

#' @rdname standard-gates
#' @export
gate_cz <- function(circuit, control, target) {
  .qv_add_gate(circuit, "CZ", c(control, target), .qv_gate_matrix("CZ"))
}

#' @rdname standard-gates
#' @export
gate_swap <- function(circuit, qubit1, qubit2) {
  .qv_add_gate(circuit, "SWAP", c(qubit1, qubit2), .qv_gate_matrix("SWAP"))
}

#' Add an arbitrary one- or two-qubit unitary gate
#'
#' The first qubit in a two-qubit gate is the most significant qubit in the
#' supplied matrix's `|00⟩, |01⟩, |10⟩, |11⟩` local basis.
#'
#' @param circuit A `qv_circuit`.
#' @param matrix A 2 x 2 or 4 x 4 unitary matrix.
#' @param qubits One or two one-based qubit indices.
#' @param label A short label for circuit diagrams.
#' @return A modified `qv_circuit`.
#' @export
gate_unitary <- function(circuit, matrix, qubits, label = "U") {
  .qv_add_gate(circuit, "U", qubits, matrix, label = label)
}
