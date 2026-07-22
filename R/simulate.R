.qv_native_available <- function() {
  is.loaded("qv_apply_1q", PACKAGE = "qvivid") &&
    is.loaded("qv_apply_2q", PACKAGE = "qvivid")
}

.qv_format_memory <- function(bytes) {
  units <- c("bytes", "KiB", "MiB", "GiB", "TiB")
  if (!is.finite(bytes)) {
    return("unlimited")
  }
  if (bytes <= 0) {
    return("0 bytes")
  }
  unit <- min(floor(log(bytes, base = 1024)), length(units) - 1L)
  value <- bytes / 1024^unit
  digits <- if (value < 10 && unit > 0) 2L else 1L
  sprintf(paste0("%.", digits, "f %s"), value, units[unit + 1L])
}

.qv_simulation_memory <- function(circuit, backend, record, shots) {
  # Keep all arithmetic in doubles. The estimate therefore cannot overflow an
  # R integer before the guard has a chance to reject a large simulation.
  dimension <- 2^as.double(circuit$n_qubits)
  state_bytes <- dimension * 16
  unitary_count <- sum(vapply(
    circuit$operations,
    function(operation) identical(operation$type, "unitary"),
    logical(1)
  ))

  # Recording retains one additional state for each unitary. Measurement
  # frames share their preceding state and therefore do not require another
  # full statevector.
  trajectory_bytes <- if (isTRUE(record)) {
    state_bytes * as.double(unitary_count)
  } else {
    0
  }

  # Constructing the default state can briefly retain its zero-filled tail and
  # assembled vector. Native kernels likewise duplicate the current state
  # once. The readable R backend also constructs index, amplitude,
  # matrix-product, and copy-on-write temporaries; four state-equivalents is a
  # deliberately conservative bound when it applies gates.
  workspace_states <- if (unitary_count == 0L || identical(backend, "native")) {
    1
  } else {
    4
  }
  workspace_bytes <- state_bytes * workspace_states
  # Computing Mod(state)^2 can briefly retain both the modulus and the final
  # double probability vector.
  probability_bytes <- dimension * 16

  # Sampling currently materializes sampled indices, a classical-bit matrix,
  # and character labels. This deliberately overestimates their live peak.
  sampling_bytes <- if (is.null(shots)) {
    0
  } else {
    as.double(shots) * (64 + 8 * as.double(circuit$n_clbits))
  }
  metadata_bytes <- if (isTRUE(record)) {
    512 * (as.double(length(circuit$operations)) + 1)
  } else {
    0
  }

  components <- c(
    state = state_bytes,
    workspace = workspace_bytes,
    trajectory = trajectory_bytes,
    probabilities = probability_bytes,
    sampling = sampling_bytes,
    metadata = metadata_bytes
  )
  list(
    total = sum(components),
    components = components,
    dimension = dimension
  )
}

.qv_check_simulation_memory <- function(
    circuit,
    backend,
    record,
    shots,
    memory_limit_gib) {
  if (!is.numeric(memory_limit_gib) || length(memory_limit_gib) != 1L ||
      is.na(memory_limit_gib) || memory_limit_gib <= 0) {
    .qv_abort("`memory_limit_gib` must be one positive number or `Inf`.")
  }

  estimate <- .qv_simulation_memory(circuit, backend, record, shots)
  limit_bytes <- as.double(memory_limit_gib) * 1024^3
  if (estimate$total > limit_bytes) {
    components <- estimate$components
    suggested_limit_gib <- ceiling(estimate$total / 1024^3)
    .qv_abort(
      paste0(
        "Simulation is estimated to require %s, above `memory_limit_gib = %s`. ",
        "The raw %d-qubit statevector is %s; initialization/backend workspace is %s; ",
        "recorded trajectory is %s; probabilities and sampling are %s. ",
        "Reduce `n_qubits` or `shots`, use `record = FALSE`, or explicitly ",
        "raise the guard to at least `memory_limit_gib = %s` for this estimate. ",
        "Use `Inf` only after confirming that enough memory is available."
      ),
      .qv_format_memory(estimate$total),
      format(memory_limit_gib, scientific = FALSE, trim = TRUE),
      circuit$n_qubits,
      .qv_format_memory(components[["state"]]),
      .qv_format_memory(components[["workspace"]]),
      .qv_format_memory(components[["trajectory"]]),
      .qv_format_memory(
        components[["probabilities"]] + components[["sampling"]]
      ),
      format(suggested_limit_gib, scientific = FALSE, trim = TRUE)
    )
  }
  invisible(estimate)
}

.qv_apply_1q_reference <- function(state, gate, qubit) {
  stride <- 2^(qubit - 1L)
  block_starts <- seq.int(0, length(state) - 1L, by = 2L * stride)
  indices0 <- rep(block_starts, each = stride) +
    rep(seq.int(0, stride - 1L), times = length(block_starts)) + 1L
  indices1 <- indices0 + stride

  amplitude0 <- state[indices0]
  amplitude1 <- state[indices1]
  state[indices0] <- gate[1L, 1L] * amplitude0 + gate[1L, 2L] * amplitude1
  state[indices1] <- gate[2L, 1L] * amplitude0 + gate[2L, 2L] * amplitude1
  state
}

.qv_apply_2q_reference <- function(state, gate, qubit1, qubit2) {
  mask1 <- as.integer(2^(qubit1 - 1L))
  mask2 <- as.integer(2^(qubit2 - 1L))
  indices <- seq_len(length(state)) - 1L
  bases <- indices[bitwAnd(indices, mask1) == 0L & bitwAnd(indices, mask2) == 0L]

  index00 <- bases + 1L
  index01 <- bases + mask2 + 1L
  index10 <- bases + mask1 + 1L
  index11 <- bases + mask1 + mask2 + 1L
  amplitudes <- rbind(
    state[index00],
    state[index01],
    state[index10],
    state[index11]
  )
  updated <- gate %*% amplitudes

  state[index00] <- updated[1L, ]
  state[index01] <- updated[2L, ]
  state[index10] <- updated[3L, ]
  state[index11] <- updated[4L, ]
  state
}

.qv_apply_gate <- function(state, matrix, qubits, backend) {
  if (identical(backend, "native")) {
    if (length(qubits) == 1L) {
      return(.Call(
        "qv_apply_1q",
        state,
        matrix,
        as.integer(qubits),
        PACKAGE = "qvivid"
      ))
    }
    return(.Call(
      "qv_apply_2q",
      state,
      matrix,
      as.integer(qubits[1L]),
      as.integer(qubits[2L]),
      PACKAGE = "qvivid"
    ))
  }

  if (length(qubits) == 1L) {
    .qv_apply_1q_reference(state, matrix, qubits)
  } else {
    .qv_apply_2q_reference(state, matrix, qubits[1L], qubits[2L])
  }
}

.qv_measurement_map <- function(circuit) {
  measurements <- Filter(
    function(operation) identical(operation$type, "measure"),
    circuit$operations
  )
  if (!length(measurements)) {
    count <- min(circuit$n_qubits, circuit$n_clbits)
    return(data.frame(qubit = seq_len(count), clbit = seq_len(count)))
  }
  data.frame(
    qubit = measurements[[1L]]$qubits,
    clbit = measurements[[1L]]$clbits
  )
}

.qv_sample_counts <- function(state, circuit, shots, seed) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  probability <- Mod(state)^2
  sampled <- sample.int(length(state), size = shots, replace = TRUE, prob = probability) - 1L
  mapping <- .qv_measurement_map(circuit)
  classical <- matrix(0L, nrow = shots, ncol = circuit$n_clbits)

  for (index in seq_len(nrow(mapping))) {
    classical[, mapping$clbit[index]] <- bitwAnd(
      bitwShiftR(sampled, mapping$qubit[index] - 1L),
      1L
    )
  }
  labels <- apply(
    classical[, rev(seq_len(circuit$n_clbits)), drop = FALSE],
    1L,
    paste0,
    collapse = ""
  )
  observed <- sort(table(labels), decreasing = TRUE)
  data.frame(
    basis = names(observed),
    count = as.integer(observed),
    probability = as.integer(observed) / shots,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

#' Simulate a quantum circuit
#'
#' @param circuit A `qv_circuit`.
#' @param shots Optional positive number of terminal measurement samples.
#' @param seed Optional non-negative integer random seed.
#' @param initial_state Optional normalized complex statevector. Defaults to
#'   `|0...0>`.
#' @param backend One of `"auto"`, `"native"`, or `"reference"`.
#' @param record Retain a statevector after every circuit operation for
#'   visualization and animation.
#' @param memory_limit_gib Maximum estimated peak memory, in GiB. The default
#'   is option `qvivid.memory_limit_gib`, or 2 GiB when that option is unset.
#'   Raise this value only when the machine has sufficient memory, or use
#'   `Inf` to explicitly disable the guard. The estimate includes the raw
#'   statevector, initialization and backend workspace, probability
#'   temporaries, sampling, and any recorded trajectory.
#' @return A `qv_result`. Its named elements are stable throughout qvivid
#'   0.1.x: `circuit` (the input `qv_circuit`), `state` (the final complex
#'   statevector), `probabilities` (exact probabilities in statevector order),
#'   `counts` (a data frame with `basis`, `count`, and `probability` columns),
#'   `shots`, `seed`, `backend`, `elapsed` (seconds), `trajectory` (or `NULL`),
#'   and integer `schema_version`. Basis strings list the highest-numbered bit
#'   first. A trajectory frame contains stable `step`, `label`, `operation`,
#'   and `state` fields.
#' @export
simulate_quantum <- function(
    circuit,
    shots = NULL,
    seed = NULL,
    initial_state = NULL,
    backend = c("auto", "native", "reference"),
    record = FALSE,
    memory_limit_gib = getOption("qvivid.memory_limit_gib", 2)) {
  .qv_validate_circuit(circuit)
  backend <- match.arg(backend)
  if (!is.null(shots) &&
      (!.qv_is_whole_number(shots) || shots < 1L || shots > .Machine$integer.max)) {
    .qv_abort("`shots` must be NULL or one positive whole number.")
  }
  if (!is.null(seed) &&
      (!.qv_is_whole_number(seed) || seed < 0L || seed > .Machine$integer.max)) {
    .qv_abort("`seed` must be NULL or one non-negative integer.")
  }
  if (!is.logical(record) || length(record) != 1L || is.na(record)) {
    .qv_abort("`record` must be TRUE or FALSE.")
  }

  if (identical(backend, "auto")) {
    backend <- if (.qv_native_available()) "native" else "reference"
  }
  if (identical(backend, "native") && !.qv_native_available()) {
    .qv_abort(
      "The native backend is unavailable. Install the compiled package or use backend = 'reference'."
    )
  }

  .qv_check_simulation_memory(
    circuit,
    backend,
    record,
    shots,
    memory_limit_gib
  )

  dimension <- 2^circuit$n_qubits
  state <- if (is.null(initial_state)) {
    c(1 + 0i, rep(0 + 0i, dimension - 1L))
  } else {
    .qv_validate_state(initial_state, circuit$n_qubits)
  }

  trajectory <- if (isTRUE(record)) {
    list(list(step = 0L, label = "Initial", operation = NULL, state = state))
  } else {
    NULL
  }
  started <- proc.time()[["elapsed"]]
  for (index in seq_along(circuit$operations)) {
    operation <- circuit$operations[[index]]
    if (identical(operation$type, "unitary")) {
      state <- .qv_apply_gate(state, operation$matrix, operation$qubits, backend)
    }
    if (isTRUE(record)) {
      trajectory[[length(trajectory) + 1L]] <- list(
        step = as.integer(index),
        label = operation$label,
        operation = operation,
        state = state
      )
    }
  }
  elapsed <- proc.time()[["elapsed"]] - started

  norm <- sum(Mod(state)^2)
  if (!is.finite(norm) || abs(norm - 1) > 1e-9) {
    .qv_abort(
      "Simulation violated state normalization (norm %.12g). Please report this circuit.",
      norm
    )
  }

  counts <- if (is.null(shots)) {
    data.frame(
      basis = character(),
      count = integer(),
      probability = numeric(),
      stringsAsFactors = FALSE
    )
  } else {
    .qv_sample_counts(
      state,
      circuit,
      as.integer(shots),
      if (is.null(seed)) NULL else as.integer(seed)
    )
  }

  result <- structure(
    list(
      circuit = circuit,
      state = state,
      probabilities = Mod(state)^2,
      counts = counts,
      shots = if (is.null(shots)) NULL else as.integer(shots),
      seed = if (is.null(seed)) NULL else as.integer(seed),
      backend = backend,
      elapsed = unname(elapsed),
      trajectory = trajectory,
      schema_version = 1L
    ),
    class = "qv_result"
  )
  result
}

#' Convert a recorded simulation trajectory to tidy data
#'
#' @param result A `qv_result` created with `record = TRUE`.
#' @param include_zero Include basis states with zero probability.
#' @return A data frame with the stable 0.1.x state columns `index`, `basis`,
#'   `real`, `imaginary`, `magnitude`, `probability`, and `phase`, followed by
#'   integer `step` and character `label` columns for every recorded frame.
#' @export
trajectory_data <- function(result, include_zero = TRUE) {
  if (!inherits(result, "qv_result")) {
    .qv_abort("`result` must be a `qv_result`.")
  }
  if (is.null(result$trajectory)) {
    .qv_abort("No trajectory was recorded; rerun with `record = TRUE`.")
  }

  pieces <- lapply(result$trajectory, function(frame) {
    data <- state_data(frame$state, include_zero = include_zero)
    data$step <- frame$step
    data$label <- frame$label
    data
  })
  output <- do.call(rbind, pieces)
  rownames(output) <- NULL
  output
}

#' @export
print.qv_result <- function(x, ...) {
  cat("<qv_result>\n")
  cat(
    sprintf(
      "  %d qubits | %s backend | %.6f seconds\n",
      x$circuit$n_qubits,
      x$backend,
      x$elapsed
    )
  )
  populated <- state_data(x, include_zero = FALSE, tolerance = 1e-12)
  populated <- populated[order(populated$probability, decreasing = TRUE), , drop = FALSE]
  shown <- utils::head(populated, 8L)
  cat("  Exact state probabilities:\n")
  for (index in seq_len(nrow(shown))) {
    cat(sprintf("    |%s>  %.6f\n", shown$basis[index], shown$probability[index]))
  }
  if (nrow(populated) > nrow(shown)) {
    cat(sprintf("    ... and %d more populated states\n", nrow(populated) - nrow(shown)))
  }
  if (!is.null(x$shots)) {
    cat(sprintf("  %d shots", x$shots))
    if (!is.null(x$seed)) cat(sprintf(" | seed %d", x$seed))
    cat("\n")
    for (index in seq_len(min(8L, nrow(x$counts)))) {
      cat(sprintf("    %s  %d\n", x$counts$basis[index], x$counts$count[index]))
    }
  }
  invisible(x)
}
