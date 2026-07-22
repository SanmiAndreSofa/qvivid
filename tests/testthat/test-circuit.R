test_that("circuits compose with one-based qubit semantics", {
  circuit <- quantum_circuit(3, name = "parallel") |>
    gate_h(1) |>
    gate_x(2) |>
    gate_cx(1, 3) |>
    measure_all()

  expect_s3_class(circuit, "qv_circuit")
  expect_equal(length(circuit$operations), 4L)
  expect_equal(circuit_depth(circuit), 3L)
  printed <- capture.output(print(circuit))
  expect_true(any(grepl("3 qubits", printed, fixed = TRUE)))
  expect_true(any(grepl("depth 3", printed, fixed = TRUE)))
})

test_that("circuit and operation schemas remain stable for 0.1.x", {
  circuit <- quantum_circuit(2, n_clbits = 3, name = "schema") |>
    gate_ry(1, pi / 3) |>
    measure(qubits = c(2, 1), clbits = c(1, 3))

  expect_named(
    circuit,
    c("name", "n_qubits", "n_clbits", "operations", "schema_version"),
    ignore.order = FALSE
  )
  expect_identical(circuit$schema_version, 1L)
  for (operation in circuit$operations) {
    expect_named(
      operation,
      c("type", "name", "label", "qubits", "clbits", "matrix", "parameters"),
      ignore.order = FALSE
    )
  }
})

test_that("invalid circuits fail with actionable messages", {
  expect_error(quantum_circuit(0), "between 1 and 30")
  expect_error(gate_h(quantum_circuit(2), 0), "one-based")
  expect_error(gate_cx(quantum_circuit(2), 1, 1), "duplicate")

  measured <- quantum_circuit(1) |> measure_all()
  expect_error(gate_x(measured, 1), "after measurement")
})

test_that("custom gates are checked for unitarity", {
  circuit <- quantum_circuit(1)
  expect_error(
    gate_unitary(circuit, matrix(c(1, 1, 0, 1), 2), 1),
    "not unitary"
  )
  expect_s3_class(gate_unitary(circuit, diag(2), 1), "qv_circuit")
})
