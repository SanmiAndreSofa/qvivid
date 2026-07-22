test_that("canonical one-qubit states have exact Bloch directions", {
  zero <- bloch_vector(c(1, 0))
  one <- bloch_vector(c(0, 1))
  plus <- bloch_vector(c(1, 1) / sqrt(2))
  plus_i <- bloch_vector(c(1, 1i) / sqrt(2))

  expect_equal(c(zero$x, zero$y, zero$z), c(0, 0, 1), tolerance = 1e-12)
  expect_equal(c(one$x, one$y, one$z), c(0, 0, -1), tolerance = 1e-12)
  expect_equal(c(plus$x, plus$y, plus$z), c(1, 0, 0), tolerance = 1e-12)
  expect_equal(c(plus_i$x, plus_i$y, plus_i$z), c(0, 1, 0), tolerance = 1e-12)
  expect_equal(c(zero$radius, plus$radius), c(1, 1), tolerance = 1e-12)
  expect_equal(c(zero$purity, plus$purity), c(1, 1), tolerance = 1e-12)
})

test_that("entanglement contracts the reduced Bloch vector", {
  result <- quantum_circuit(2, name = "Bell") |>
    gate_h(1) |>
    gate_cx(1, 2) |>
    simulate_quantum(backend = "reference", record = TRUE)

  final <- bloch_vector(result, qubit = 1)
  expect_equal(c(final$x, final$y, final$z), c(0, 0, 0), tolerance = 1e-12)
  expect_equal(final$radius, 0, tolerance = 1e-12)
  expect_equal(final$purity, 0.5, tolerance = 1e-12)

  trajectory <- trajectory_bloch(result, qubit = 1)
  expect_s3_class(trajectory, "qv_bloch_trajectory")
  expect_identical(trajectory$step, 0:2)
  expect_equal(
    unname(unlist(trajectory[1, c("x", "y", "z")])),
    c(0, 0, 1)
  )
  expect_equal(
    unname(unlist(trajectory[2, c("x", "y", "z")])),
    c(1, 0, 0),
    tolerance = 1e-12
  )
  expect_equal(trajectory$radius, c(1, 1, 0), tolerance = 1e-12)
  expect_equal(trajectory$purity, c(1, 1, 0.5), tolerance = 1e-12)
})

test_that("Bloch sphere and trajectory plots render", {
  result <- quantum_circuit(2, name = "Bell") |>
    gate_h(1) |>
    gate_cx(1, 2) |>
    simulate_quantum(backend = "reference", record = TRUE)

  output <- tempfile(fileext = ".pdf")
  grDevices::pdf(output, width = 5, height = 5)
  expect_invisible(plot_bloch(result, qubit = 1, trajectory = TRUE))
  grDevices::dev.off()
  expect_gt(file.info(output)$size, 0)

  planar <- tempfile(fileext = ".pdf")
  grDevices::pdf(planar, width = 5, height = 5)
  expect_invisible(plot_bloch(trajectory_bloch(result), view = "xz", theme = "npj"))
  grDevices::dev.off()
  expect_gt(file.info(planar)$size, 0)
})

test_that("Bloch GIF trajectories render when gifski is installed", {
  skip_if_not_installed("gifski")
  result <- quantum_circuit(1) |>
    gate_h(1) |>
    gate_rz(1, pi / 2) |>
    simulate_quantum(backend = "reference", record = TRUE)
  output <- tempfile(fileext = ".gif")

  animation <- animate_bloch(
    result,
    output,
    fps = 2,
    width = 480,
    height = 480,
    progress = FALSE
  )
  expect_s3_class(animation, "qv_animation")
  expect_identical(animation$kind, "bloch")
  expect_true(file.exists(output))
  expect_gt(file.info(output)$size, 0)
})
