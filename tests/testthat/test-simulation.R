bell_circuit <- function() {
  quantum_circuit(2, name = "Bell state") |>
    gate_h(1) |>
    gate_cx(1, 2) |>
    measure_all()
}

test_that("Bell state amplitudes and probabilities are correct", {
  result <- simulate_quantum(bell_circuit(), backend = "reference")
  expected <- c(1 / sqrt(2), 0, 0, 1 / sqrt(2)) + 0i

  expect_equal(result$state, expected, tolerance = 1e-12)
  expect_equal(sum(result$probabilities), 1, tolerance = 1e-12)
  populated <- state_data(result, include_zero = FALSE)
  expect_equal(populated$basis, c("00", "11"))
  expect_equal(populated$probability, c(0.5, 0.5), tolerance = 1e-12)
})

test_that("shot sampling is seeded and uses measured bit order", {
  first <- simulate_quantum(
    bell_circuit(),
    shots = 2000,
    seed = 42,
    backend = "reference"
  )
  second <- simulate_quantum(
    bell_circuit(),
    shots = 2000,
    seed = 42,
    backend = "reference"
  )

  expect_identical(first$counts, second$counts)
  expect_setequal(first$counts$basis, c("00", "11"))
  expect_true(all(abs(first$counts$probability - 0.5) < 0.06))
})

test_that("qubit order works in both directions", {
  result <- quantum_circuit(2) |>
    gate_x(2) |>
    gate_cx(control = 2, target = 1) |>
    simulate_quantum(backend = "reference")

  expect_equal(result$state, c(0, 0, 0, 1) + 0i)
})

test_that("native and reference backends agree", {
  if ("qvivid" %in% loadedNamespaces()) {
    expect_true(
      .qv_native_available(),
      info = "An installed qvivid package must load its registered native backend."
    )
  } else {
    skip_if_not(
      .qv_native_available(),
      "Native DLL is unavailable in a source-only test session."
    )
  }
  circuit <- quantum_circuit(4) |>
    gate_h(1) |>
    gate_rx(2, 0.37) |>
    gate_ry(3, -0.91) |>
    gate_cx(1, 4) |>
    gate_cz(3, 2) |>
    gate_swap(1, 3)

  native <- simulate_quantum(circuit, backend = "native")
  reference <- simulate_quantum(circuit, backend = "reference")
  expect_equal(native$state, reference$state, tolerance = 1e-12)
})

test_that("every standard gate preserves norm and agrees across backends", {
  one_qubit_gates <- list(
    H = function(circuit) gate_h(circuit, 1),
    X = function(circuit) gate_x(circuit, 1),
    Y = function(circuit) gate_y(circuit, 1),
    Z = function(circuit) gate_z(circuit, 1),
    S = function(circuit) gate_s(circuit, 1),
    T = function(circuit) gate_t(circuit, 1),
    RX = function(circuit) gate_rx(circuit, 1, 0.37),
    RY = function(circuit) gate_ry(circuit, 1, -0.91),
    RZ = function(circuit) gate_rz(circuit, 1, 1.23)
  )
  initial_one <- c(1 + 2i, -0.5 + 0.25i)
  initial_one <- initial_one / sqrt(sum(Mod(initial_one)^2))
  amplitude0 <- initial_one[1L]
  amplitude1 <- initial_one[2L]
  expected_one <- list(
    H = c(amplitude0 + amplitude1, amplitude0 - amplitude1) / sqrt(2),
    X = c(amplitude1, amplitude0),
    Y = c(-1i * amplitude1, 1i * amplitude0),
    Z = c(amplitude0, -amplitude1),
    S = c(amplitude0, 1i * amplitude1),
    T = c(amplitude0, exp(1i * pi / 4) * amplitude1),
    RX = c(
      cos(0.37 / 2) * amplitude0 - 1i * sin(0.37 / 2) * amplitude1,
      -1i * sin(0.37 / 2) * amplitude0 + cos(0.37 / 2) * amplitude1
    ),
    RY = c(
      cos(-0.91 / 2) * amplitude0 - sin(-0.91 / 2) * amplitude1,
      sin(-0.91 / 2) * amplitude0 + cos(-0.91 / 2) * amplitude1
    ),
    RZ = c(
      exp(-1i * 1.23 / 2) * amplitude0,
      exp(1i * 1.23 / 2) * amplitude1
    )
  )

  for (name in names(one_qubit_gates)) {
    circuit <- one_qubit_gates[[name]](quantum_circuit(1))
    reference <- simulate_quantum(
      circuit,
      initial_state = initial_one,
      backend = "reference"
    )
    expect_equal(reference$state, expected_one[[name]], tolerance = 1e-12, info = name)
    expect_equal(sum(Mod(reference$state)^2), 1, tolerance = 1e-12, info = name)
    if (.qv_native_available()) {
      native <- simulate_quantum(
        circuit,
        initial_state = initial_one,
        backend = "native"
      )
      expect_equal(native$state, reference$state, tolerance = 1e-12, info = name)
    }
  }

  two_qubit_gates <- list(
    CX = function(circuit) gate_cx(circuit, 1, 2),
    CZ = function(circuit) gate_cz(circuit, 1, 2),
    SWAP = function(circuit) gate_swap(circuit, 1, 2)
  )
  initial_two <- c(1 + 0.5i, -0.2i, 0.75 - 0.1i, -0.3 + 0.4i)
  initial_two <- initial_two / sqrt(sum(Mod(initial_two)^2))
  # Global state order is |q2 q1>; CX(q1 -> q2) maps
  # 00 -> 00, 01 -> 11, 10 -> 10, and 11 -> 01.
  expected_two <- list(
    CX = initial_two[c(1L, 4L, 3L, 2L)],
    CZ = initial_two * c(1, 1, 1, -1),
    SWAP = initial_two[c(1L, 3L, 2L, 4L)]
  )
  for (name in names(two_qubit_gates)) {
    circuit <- two_qubit_gates[[name]](quantum_circuit(2))
    reference <- simulate_quantum(
      circuit,
      initial_state = initial_two,
      backend = "reference"
    )
    expect_equal(reference$state, expected_two[[name]], tolerance = 1e-12, info = name)
    expect_equal(sum(Mod(reference$state)^2), 1, tolerance = 1e-12, info = name)
    if (.qv_native_available()) {
      native <- simulate_quantum(
        circuit,
        initial_state = initial_two,
        backend = "native"
      )
      expect_equal(native$state, reference$state, tolerance = 1e-12, info = name)
    }
  }
})

test_that("deterministic randomized circuits agree across backends", {
  skip_if_not(.qv_native_available(), "Native DLL is unavailable.")
  set.seed(20260722)

  for (trial in seq_len(6L)) {
    initial <- complex(real = rnorm(16), imaginary = rnorm(16))
    initial <- initial / sqrt(sum(Mod(initial)^2))
    circuit <- quantum_circuit(4)
    for (step in seq_len(18L)) {
      gate <- sample(c("H", "X", "Y", "Z", "S", "T", "RX", "RY", "RZ", "CX", "CZ", "SWAP"), 1L)
      qubits <- sample.int(4L, 2L, replace = FALSE)
      circuit <- switch(
        gate,
        H = gate_h(circuit, qubits[1L]),
        X = gate_x(circuit, qubits[1L]),
        Y = gate_y(circuit, qubits[1L]),
        Z = gate_z(circuit, qubits[1L]),
        S = gate_s(circuit, qubits[1L]),
        T = gate_t(circuit, qubits[1L]),
        RX = gate_rx(circuit, qubits[1L], runif(1L, -pi, pi)),
        RY = gate_ry(circuit, qubits[1L], runif(1L, -pi, pi)),
        RZ = gate_rz(circuit, qubits[1L], runif(1L, -pi, pi)),
        CX = gate_cx(circuit, qubits[1L], qubits[2L]),
        CZ = gate_cz(circuit, qubits[1L], qubits[2L]),
        SWAP = gate_swap(circuit, qubits[1L], qubits[2L])
      )
    }

    native <- simulate_quantum(circuit, initial_state = initial, backend = "native")
    reference <- simulate_quantum(circuit, initial_state = initial, backend = "reference")
    expect_equal(native$state, reference$state, tolerance = 2e-12, info = trial)
  }
})

test_that("reversed and custom two-qubit basis orders are exact", {
  reversed <- quantum_circuit(2) |>
    gate_x(2) |>
    gate_cx(control = 2, target = 1)
  expected_reversed <- c(0, 0, 0, 1) + 0i
  expect_equal(
    simulate_quantum(reversed, backend = "reference")$state,
    expected_reversed
  )
  if (.qv_native_available()) {
    expect_equal(
      simulate_quantum(reversed, backend = "native")$state,
      expected_reversed
    )
  }

  cycle <- matrix(0 + 0i, 4L, 4L)
  cycle[cbind(c(2L, 3L, 4L, 1L), seq_len(4L))] <- 1 + 0i
  transitions <- c("2" = 3L, "3" = 6L, "6" = 7L, "7" = 2L)
  custom <- quantum_circuit(3) |>
    gate_unitary(cycle, qubits = c(3, 1), label = "cycle")

  for (input in as.integer(names(transitions))) {
    initial <- rep(0 + 0i, 8L)
    initial[input + 1L] <- 1 + 0i
    expected <- rep(0 + 0i, 8L)
    expected[transitions[[as.character(input)]] + 1L] <- 1 + 0i
    reference <- simulate_quantum(
      custom,
      initial_state = initial,
      backend = "reference"
    )
    expect_equal(reference$state, expected, info = input)
    if (.qv_native_available()) {
      native <- simulate_quantum(custom, initial_state = initial, backend = "native")
      expect_equal(native$state, expected, info = input)
    }
  }
})

test_that("normalized initial states are accepted without mutation", {
  initial <- c(1 + 1i, 2 - 1i, -0.5i, 0.75 + 0i)
  initial <- initial / sqrt(sum(Mod(initial)^2))
  original <- initial
  result <- simulate_quantum(
    quantum_circuit(2),
    initial_state = initial,
    backend = "reference"
  )

  expect_equal(result$state, original, tolerance = 1e-12)
  expect_identical(initial, original)
  expect_error(
    simulate_quantum(quantum_circuit(2), initial_state = original * 2),
    "unit norm"
  )
})

test_that("partial permuted measurements map into classical bits", {
  circuit <- quantum_circuit(3, n_clbits = 4) |>
    gate_x(1) |>
    gate_x(3) |>
    measure(qubits = c(3, 1), clbits = c(1, 4))
  result <- simulate_quantum(
    circuit,
    shots = 32,
    seed = 9,
    backend = "reference"
  )

  expect_equal(result$counts$basis, "1001")
  expect_equal(result$counts$count, 32L)
  expect_equal(result$counts$probability, 1)
})

test_that("result and tidy-data schemas remain stable for 0.1.x", {
  result <- simulate_quantum(
    bell_circuit(),
    shots = 16,
    seed = 4,
    backend = "reference",
    record = TRUE
  )

  expect_named(
    result,
    c(
      "circuit", "state", "probabilities", "counts", "shots", "seed",
      "backend", "elapsed", "trajectory", "schema_version"
    ),
    ignore.order = FALSE
  )
  expect_named(
    result$counts,
    c("basis", "count", "probability"),
    ignore.order = FALSE
  )
  expect_s3_class(result$counts, "data.frame")
  expect_type(result$counts$basis, "character")
  expect_type(result$counts$count, "integer")
  expect_type(result$counts$probability, "double")
  expect_type(result$state, "complex")
  expect_type(result$probabilities, "double")
  expect_type(result$shots, "integer")
  expect_type(result$seed, "integer")
  expect_type(result$backend, "character")
  expect_type(result$elapsed, "double")
  expect_type(result$trajectory, "list")

  state <- state_data(result)
  expect_named(
    state,
    c(
      "index", "basis", "real", "imaginary", "magnitude", "probability",
      "phase"
    ),
    ignore.order = FALSE
  )
  expect_type(state$index, "integer")
  expect_type(state$basis, "character")
  for (column in c("real", "imaginary", "magnitude", "probability", "phase")) {
    expect_type(state[[column]], "double")
  }

  trajectory <- trajectory_data(result)
  expect_named(
    trajectory,
    c(
      "index", "basis", "real", "imaginary", "magnitude", "probability",
      "phase", "step", "label"
    ),
    ignore.order = FALSE
  )
  expect_type(trajectory$step, "integer")
  expect_type(trajectory$label, "character")
  expect_named(
    result$trajectory[[1L]],
    c("step", "label", "operation", "state"),
    ignore.order = FALSE
  )
  expect_type(result$trajectory[[1L]]$step, "integer")
  expect_type(result$trajectory[[1L]]$label, "character")
  expect_null(result$trajectory[[1L]]$operation)
  expect_type(result$trajectory[[1L]]$state, "complex")
  expect_identical(result$schema_version, 1L)

  unsampled <- simulate_quantum(bell_circuit(), backend = "reference")
  expect_s3_class(unsampled$counts, "data.frame")
  expect_named(
    unsampled$counts,
    c("basis", "count", "probability"),
    ignore.order = FALSE
  )
  expect_equal(nrow(unsampled$counts), 0L)
  expect_type(unsampled$counts$basis, "character")
  expect_type(unsampled$counts$count, "integer")
  expect_type(unsampled$counts$probability, "double")
})

test_that("memory guard rejects unsafe estimates before allocation", {
  estimated <- .qv_simulation_memory(
    quantum_circuit(3) |> gate_h(1) |> measure_all(),
    backend = "reference",
    record = TRUE,
    shots = 10
  )
  expect_equal(unname(estimated$components[["state"]]), 8 * 16)
  expect_equal(
    unname(estimated$components[["trajectory"]]),
    8 * 16,
    info = "Only the unitary, not terminal measurement, retains another state."
  )
  expect_equal(unname(estimated$components[["workspace"]]), 4 * 8 * 16)
  expect_gt(unname(estimated$components[["sampling"]]), 0)

  expect_error(
    simulate_quantum(
      quantum_circuit(30),
      backend = "reference",
      memory_limit_gib = 2
    ),
    paste0(
      "estimated to require.*raw 30-qubit statevector is 16.0 GiB.*",
      "memory_limit_gib = 48"
    )
  )
  expect_error(
    simulate_quantum(
      quantum_circuit(1),
      shots = 1,
      backend = "reference",
      memory_limit_gib = 1e-12
    ),
    "estimated to require"
  )
  expect_error(
    simulate_quantum(quantum_circuit(1), memory_limit_gib = 0),
    "positive number or `Inf`",
    fixed = TRUE
  )

  old_options <- options(qvivid.memory_limit_gib = 1e-12)
  on.exit(options(old_options), add = TRUE)
  expect_error(
    simulate_quantum(quantum_circuit(1), backend = "reference"),
    "estimated to require"
  )
  expect_s3_class(
    simulate_quantum(
      quantum_circuit(1),
      backend = "reference",
      memory_limit_gib = Inf
    ),
    "qv_result"
  )
})

test_that("recorded trajectories expose every operation", {
  result <- simulate_quantum(bell_circuit(), backend = "reference", record = TRUE)
  data <- trajectory_data(result)

  expect_length(result$trajectory, 4L)
  expect_equal(sort(unique(data$step)), 0:3)
  expect_equal(nrow(data), 16L)
})
