test_that("base state and circuit plots render", {
  circuit <- quantum_circuit(2, name = "Bell") |>
    gate_h(1) |>
    gate_cx(1, 2) |>
    measure_all()
  result <- simulate_quantum(circuit, backend = "reference")

  state_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(state_file)
  expect_invisible(plot_state(result, engine = "base"))
  grDevices::dev.off()
  expect_gt(file.info(state_file)$size, 0)

  circuit_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(circuit_file)
  expect_invisible(plot_circuit(circuit, highlight = 2))
  grDevices::dev.off()
  expect_gt(file.info(circuit_file)$size, 0)

  execution_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(execution_file, width = 8, height = 7)
  expect_invisible(plot_execution(
    simulate_quantum(circuit, backend = "reference", record = TRUE),
    step = 2
  ))
  grDevices::dev.off()
  expect_gt(file.info(execution_file)$size, 0)
})

test_that("state plot defaults have an installation-independent contract", {
  engine_choices <- c("base", "ggplot2", "auto")
  expect_identical(
    .qv_resolve_plot_engine(engine_choices, ggplot2_available = FALSE),
    "base"
  )
  expect_identical(
    .qv_resolve_plot_engine(engine_choices, ggplot2_available = TRUE),
    "base"
  )
  expect_identical(
    .qv_resolve_plot_engine("auto", ggplot2_available = FALSE),
    "base"
  )
  expect_identical(
    .qv_resolve_plot_engine("auto", ggplot2_available = TRUE),
    "base"
  )
  expect_error(
    .qv_resolve_plot_engine("ggplot2", ggplot2_available = FALSE),
    "requires the optional `ggplot2` package",
    fixed = TRUE
  )
  expect_identical(
    .qv_resolve_plot_engine("ggplot2", ggplot2_available = TRUE),
    "ggplot2"
  )

  result <- quantum_circuit(1, name = "Stable plotting contract") |>
    gate_h(1) |>
    simulate_quantum(backend = "reference")
  output <- tempfile(fileext = ".pdf")
  grDevices::pdf(output)
  on.exit({
    if (grDevices::dev.cur() > 1L) grDevices::dev.off()
  }, add = TRUE)

  direct <- withVisible(plot_state(result))
  expect_false(direct$visible)
  expect_s3_class(direct$value, "data.frame")

  method <- withVisible(plot(result))
  expect_false(method$visible)
  expect_s3_class(method$value, "data.frame")

  compatible <- withVisible(plot_state(result, engine = "auto"))
  expect_false(compatible$visible)
  expect_s3_class(compatible$value, "data.frame")

  grDevices::dev.off()
  expect_gt(file.info(output)$size, 0)
})

test_that("all visual presets expose a complete cyclic phase contract", {
  presets <- c("nature", "npj", "colorblind", "dark", "light", "mono")
  for (preset in presets) {
    palette <- qv_palette(preset)
    expect_identical(palette$name, preset)
    expect_true(all(c(
      "background", "foreground", "primary", "muted", "phase",
      "font_family", "grid_visible"
    ) %in% names(palette)))
    expect_identical(palette$phase[1L], palette$phase[length(palette$phase)])
  }
})

test_that("GIF trajectories render when gifski is installed", {
  skip_if_not_installed("gifski")
  result <- quantum_circuit(1) |>
    gate_h(1) |>
    measure_all() |>
    simulate_quantum(backend = "reference", record = TRUE)
  output <- tempfile(fileext = ".gif")

  animation <- animate_state(
    result,
    output,
    fps = 2,
    width = 480,
    height = 320,
    progress = FALSE
  )
  expect_s3_class(animation, "qv_animation")
  expect_true(file.exists(output))
  expect_gt(file.info(output)$size, 0)
})
