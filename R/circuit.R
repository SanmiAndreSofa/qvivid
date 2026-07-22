.qv_validate_circuit <- function(circuit) {
  if (!inherits(circuit, "qv_circuit")) {
    .qv_abort("Expected a `qv_circuit`; create one with `quantum_circuit()`.")
  }
  invisible(circuit)
}

#' Create a quantum circuit
#'
#' @param n_qubits Number of quantum bits. Qubits use one-based R indices.
#' @param n_clbits Number of classical bits available for measurement.
#' @param name Optional human-readable circuit name.
#' @return A named list with class `qv_circuit`. Its stable 0.1.x fields are
#'   `name`, `n_qubits`, `n_clbits`, `operations`, and `schema_version`.
#'   Operation records expose `type`, `name`, `label`, `qubits`, `clbits`,
#'   `matrix`, and `parameters`; treat these fields as read-only.
#' @export
quantum_circuit <- function(n_qubits, n_clbits = n_qubits, name = NULL) {
  n_qubits <- .qv_validate_n_qubits(n_qubits)
  if (!.qv_is_whole_number(n_clbits) || n_clbits < 1L || n_clbits > 30L) {
    .qv_abort("`n_clbits` must be one whole number between 1 and 30.")
  }
  if (!is.null(name) && (!is.character(name) || length(name) != 1L || is.na(name))) {
    .qv_abort("`name` must be NULL or one non-missing character value.")
  }

  structure(
    list(
      name = name,
      n_qubits = n_qubits,
      n_clbits = as.integer(n_clbits),
      operations = list(),
      schema_version = 1L
    ),
    class = "qv_circuit"
  )
}

.qv_assert_unitary_appendable <- function(circuit) {
  measured <- vapply(
    circuit$operations,
    function(operation) identical(operation$type, "measure"),
    logical(1)
  )
  if (any(measured)) {
    .qv_abort(
      "Unitary gates cannot be appended after measurement; qvivid 0.1.x supports terminal measurement only."
    )
  }
}

.qv_add_gate <- function(circuit, name, qubits, matrix, parameters = list(), label = name) {
  .qv_validate_circuit(circuit)
  .qv_assert_unitary_appendable(circuit)
  qubits <- .qv_validate_qubits(qubits, circuit$n_qubits)
  if (length(qubits) > 2L) {
    .qv_abort("qvivid 0.1.x supports one- and two-qubit unitary gates.")
  }
  matrix <- .qv_validate_matrix(matrix, length(qubits))
  if (!is.character(label) || length(label) != 1L || is.na(label) || !nzchar(label)) {
    .qv_abort("`label` must be one non-empty character value.")
  }

  circuit$operations[[length(circuit$operations) + 1L]] <- list(
    type = "unitary",
    name = toupper(name),
    label = label,
    qubits = qubits,
    clbits = integer(),
    matrix = matrix,
    parameters = parameters
  )
  circuit
}

#' Add terminal measurements to a circuit
#'
#' @param circuit A `qv_circuit`.
#' @param qubits One-based qubit indices.
#' @param clbits One-based classical-bit indices receiving the measurements.
#' @return A modified `qv_circuit`.
#' @examples
#' circuit <- quantum_circuit(2, n_clbits = 3) |>
#'   gate_h(1) |>
#'   measure(qubits = c(1, 2), clbits = c(3, 1))
#' circuit
#' @export
measure <- function(circuit, qubits, clbits = qubits) {
  .qv_validate_circuit(circuit)
  if (any(vapply(circuit$operations, function(x) identical(x$type, "measure"), logical(1)))) {
    .qv_abort("This circuit already contains a measurement operation.")
  }
  qubits <- .qv_validate_qubits(qubits, circuit$n_qubits)
  clbits <- .qv_validate_qubits(clbits, circuit$n_clbits, argument = "clbits")
  if (length(qubits) != length(clbits)) {
    .qv_abort("`qubits` and `clbits` must have the same length.")
  }

  circuit$operations[[length(circuit$operations) + 1L]] <- list(
    type = "measure",
    name = "MEASURE",
    label = "M",
    qubits = qubits,
    clbits = clbits,
    matrix = NULL,
    parameters = list()
  )
  circuit
}

#' Measure every qubit into its matching classical bit
#'
#' @param circuit A `qv_circuit`.
#' @return A modified `qv_circuit`.
#' @export
measure_all <- function(circuit) {
  .qv_validate_circuit(circuit)
  if (circuit$n_clbits < circuit$n_qubits) {
    .qv_abort("`measure_all()` needs at least as many classical bits as qubits.")
  }
  measure(circuit, seq_len(circuit$n_qubits), seq_len(circuit$n_qubits))
}

#' Calculate circuit depth
#'
#' Independent gates are scheduled into the same layer.
#'
#' @param circuit A `qv_circuit`.
#' @return The integer circuit depth.
#' @export
circuit_depth <- function(circuit) {
  .qv_validate_circuit(circuit)
  layers <- integer(circuit$n_qubits)
  for (operation in circuit$operations) {
    next_layer <- max(layers[operation$qubits]) + 1L
    layers[operation$qubits] <- next_layer
  }
  if (length(layers)) max(layers) else 0L
}

#' @export
print.qv_circuit <- function(x, ...) {
  title <- if (is.null(x$name)) "<qv_circuit>" else sprintf("<qv_circuit: %s>", x$name)
  cat(title, "\n", sep = "")
  cat(
    sprintf(
      "  %d qubit%s | %d classical bit%s | %d operation%s | depth %d\n",
      x$n_qubits,
      if (x$n_qubits == 1L) "" else "s",
      x$n_clbits,
      if (x$n_clbits == 1L) "" else "s",
      length(x$operations),
      if (length(x$operations) == 1L) "" else "s",
      circuit_depth(x)
    )
  )

  if (length(x$operations)) {
    for (index in seq_along(x$operations)) {
      operation <- x$operations[[index]]
      qtext <- paste0("q", operation$qubits, collapse = ",")
      suffix <- if (identical(operation$type, "measure")) {
        paste0(" -> ", paste0("c", operation$clbits, collapse = ","))
      } else {
        ""
      }
      cat(sprintf("  %2d  %-8s %s%s\n", index, operation$label, qtext, suffix))
    }
  }
  invisible(x)
}
