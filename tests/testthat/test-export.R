test_that("journal presets export vector state figures at exact widths", {
  result <- quantum_circuit(1, name = "Hadamard") |>
    gate_h(1) |>
    simulate_quantum(backend = "reference")
  output <- tempfile(fileext = ".pdf")

  artifact <- save_quantum_plot(
    result,
    output,
    view = "state",
    size = "single"
  )
  expect_s3_class(artifact, "qv_export")
  expect_identical(artifact$format, "pdf")
  expect_identical(artifact$view, "state")
  expect_equal(artifact$width_mm, 89)
  expect_equal(artifact$height_mm, 89 * 0.62)
  expect_true(is.na(artifact$dpi))
  expect_gt(file.info(output)$size, 0)
})

test_that("export infers recorded executions and renders raster Bloch views", {
  result <- quantum_circuit(2, name = "Bell") |>
    gate_h(1) |>
    gate_cx(1, 2) |>
    simulate_quantum(backend = "reference", record = TRUE)

  execution_file <- tempfile(fileext = ".pdf")
  execution <- save_quantum_plot(result, execution_file, size = "single")
  expect_identical(execution$view, "execution")
  expect_gt(file.info(execution_file)$size, 0)

  circuit_file <- tempfile(fileext = ".pdf")
  circuit <- save_quantum_plot(
    result$circuit,
    circuit_file,
    view = "circuit",
    size = "single",
    subtitle = "Custom circuit subtitle"
  )
  expect_identical(circuit$view, "circuit")
  expect_gt(file.info(circuit_file)$size, 0)

  bloch_file <- tempfile(fileext = ".png")
  bloch <- save_quantum_plot(
    result,
    bloch_file,
    view = "bloch",
    width = 2.5,
    height = 2.5,
    units = "in",
    dpi = 120,
    theme = "npj"
  )
  expect_identical(bloch$view, "bloch")
  expect_equal(bloch$width_mm, 63.5)
  expect_equal(bloch$height_mm, 63.5)
  expect_equal(bloch$dpi, 120)
  expect_gt(file.info(bloch_file)$size, 0)
})

test_that("export protects existing files and rejects unsupported formats", {
  state <- c(1, 0)
  output <- tempfile(fileext = ".pdf")
  save_quantum_plot(state, output, view = "state")

  expect_error(
    save_quantum_plot(state, output, view = "state"),
    "already exists"
  )
  expect_s3_class(
    save_quantum_plot(state, output, view = "state", overwrite = TRUE),
    "qv_export"
  )
  expect_error(
    save_quantum_plot(state, tempfile(fileext = ".jpg"), view = "state"),
    "must end"
  )
})
