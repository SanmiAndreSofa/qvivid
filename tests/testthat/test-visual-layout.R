test_that("quantum notation is device-safe plotmath", {
  ket <- .qv_ket_expression(c("0", "11"))
  expect_length(ket, 2L)
  expect_match(paste(deparse(ket[[1L]]), collapse = ""), "rangle")
  expect_false(grepl("[>]", paste(deparse(ket), collapse = "")))

  phases <- .qv_phase_expression()
  expect_length(phases, 5L)
  expect_match(paste(deparse(phases), collapse = ""), "pi")
  expect_identical(.qv_format_fixed(c(-1e-12, 0, 1)), c("0.000", "0.000", "1.000"))
})

test_that("Bloch annotation boxes stay outside the sphere and do not collide", {
  output <- tempfile(fileext = ".pdf")
  grDevices::pdf(output, width = 3.5, height = 3.5, pointsize = 7)
  on.exit({
    if (grDevices::dev.cur() > 1L) grDevices::dev.off()
  }, add = TRUE)

  for (view in c("perspective", "xy", "xz", "yz")) {
    graphics::par(mar = c(3.25, 1.05, 3.65, 1.05), family = "sans")
    graphics::plot.new()
    graphics::plot.window(
      xlim = c(-1.48, 1.48),
      ylim = c(-1.34, 1.34),
      xaxs = "i",
      yaxs = "i",
      asp = 1
    )
    bounds <- graphics::par("usr")
    layout <- .qv_bloch_label_layout(
      view,
      cex = qv_palette("nature")$label_cex,
      xlim = bounds[1:2],
      ylim = bounds[3:4]
    )
    expect_length(layout, if (view == "perspective") 6L else 4L)

    for (placement in layout) {
      expect_gte(sqrt(placement$x^2 + placement$y^2), 1.06)
      expect_gte(placement$bbox[["left"]], bounds[[1L]])
      expect_lte(placement$bbox[["right"]], bounds[[2L]])
      expect_gte(placement$bbox[["bottom"]], bounds[[3L]])
      expect_lte(placement$bbox[["top"]], bounds[[4L]])
    }
    if (length(layout) > 1L) {
      pairs <- utils::combn(seq_along(layout), 2L)
      for (column in seq_len(ncol(pairs))) {
        expect_false(.qv_boxes_overlap(
          layout[[pairs[1L, column]]]$bbox,
          layout[[pairs[2L, column]]]$bbox
        ))
      }
    }
  }
  expect_error(
    .qv_bloch_label_layout(
      "perspective",
      cex = 5,
      xlim = c(-1.48, 1.48),
      ylim = c(-1.34, 1.34)
    ),
    "without overlap"
  )
  grDevices::dev.off()
  expect_gt(file.info(output)$size, 0)
})

test_that("perspective Bloch trails split between rear and front hemispheres", {
  points <- rbind(c(-1, 0, 0), c(1, 0, 0))
  projected <- .qv_project_bloch(points, "perspective")
  segments <- .qv_bloch_trail_segments(projected)
  expect_equal(nrow(segments), 2L)
  expect_setequal(segments$front, c(FALSE, TRUE))
  expect_equal(segments$u1[[1L]], segments$u0[[2L]], tolerance = 1e-12)
  expect_equal(segments$v1[[1L]], segments$v0[[2L]], tolerance = 1e-12)
})

test_that("gate labels fit their measured boxes", {
  output <- tempfile(fileext = ".pdf")
  grDevices::pdf(output, width = 6, height = 3, pointsize = 8)
  on.exit({
    if (grDevices::dev.cur() > 1L) grDevices::dev.off()
  }, add = TRUE)
  graphics::plot.new()
  graphics::plot.window(c(0, 4), c(0, 2))

  palette <- qv_palette("nature")
  labels <- list(
    "H",
    "controlled phase",
    "A very long custom unitary gate label",
    expression(italic(R)[z] * "(1.57)")
  )
  for (label in labels) {
    geometry <- .qv_gate_box_geometry(label, palette)
    expect_lte(geometry$label_width, 2 * geometry$half_width)
    expect_gte(geometry$label_cex, 0.58)
    expect_lte(geometry$half_width, 0.42)
  }
  long_geometry <- .qv_gate_box_geometry(labels[[3L]], palette)
  expect_match(long_geometry$display_label, "\\.\\.\\.$")

  rotation_circuit <- quantum_circuit(1) |>
    gate_rx(1, 1e-6) |>
    gate_ry(1, pi / 2) |>
    gate_rz(1, 1e8)
  rotation_labels <- lapply(
    rotation_circuit$operations,
    .qv_gate_plot_label
  )
  expect_match(paste(deparse(rotation_labels[[1L]]), collapse = ""), "10")
  expect_false(grepl("0[.]00", paste(deparse(rotation_labels[[1L]]), collapse = "")))
  expect_match(paste(deparse(rotation_labels[[2L]]), collapse = ""), "pi")
  expect_match(paste(deparse(rotation_labels[[3L]]), collapse = ""), "10")
  very_small <- .qv_angle_plot_value(1e-12)
  very_large <- .qv_angle_plot_value(1e12)
  expect_match(paste(deparse(very_small), collapse = ""), "-12")
  expect_match(paste(deparse(very_large), collapse = ""), "12")
  expect_false(grepl("NA", paste(deparse(very_large), collapse = ""), fixed = TRUE))
  for (label in rotation_labels) {
    geometry <- .qv_gate_box_geometry(label, palette)
    expect_lte(geometry$label_width, 2 * geometry$half_width)
  }
  grDevices::dev.off()
})

test_that("oversized mathematical titles fail before they can clip", {
  output <- tempfile(fileext = ".pdf")
  grDevices::pdf(output, width = 3.5, height = 2.5, pointsize = 7)
  on.exit({
    if (grDevices::dev.cur() > 1L) grDevices::dev.off()
  }, add = TRUE)
  graphics::plot.new()
  graphics::plot.window(c(0, 1), c(0, 1))
  long_title <- as.expression(substitute(
    plain(value),
    list(value = paste(rep("mathematical-title", 20L), collapse = " "))
  ))
  expect_error(
    .qv_title(long_title, NULL, qv_palette("nature")),
    "too wide"
  )
  grDevices::dev.off()
})

test_that("animation state scaffold is fixed across every frame", {
  result <- quantum_circuit(3, name = "Changing support") |>
    gate_h(1) |>
    gate_x(3) |>
    gate_h(2) |>
    simulate_quantum(backend = "reference", record = TRUE)

  contract <- .qv_animation_state_contract(result, top = 4L)
  expect_length(contract$indices, 4L)
  expect_gt(contract$upper, 0)
  for (frame in result$trajectory) {
    data <- .qv_plot_data(frame$state, NULL, indices = contract$indices)
    expect_identical(data$basis, contract$basis)
    expect_lte(max(data$probability), contract$upper)
  }
})

test_that("minimum animation dimensions render the combined execution view", {
  result <- quantum_circuit(1, name = "Minimum frame") |>
    gate_h(1) |>
    simulate_quantum(backend = "reference", record = TRUE)
  directory <- tempfile("qvivid-minimum-frames-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE, force = TRUE), add = TRUE)

  frames <- .qv_render_state_frames(
    result,
    directory,
    width = 240,
    height = 240,
    top = NULL,
    theme = "nature",
    include_circuit = TRUE
  )
  expect_length(frames, length(result$trajectory))
  expect_true(all(file.exists(frames)))
  expect_true(all(file.info(frames)$size > 0))
})

test_that("compact devices render every visual family", {
  circuit <- quantum_circuit(2, name = "Compact visual QA") |>
    gate_h(1) |>
    gate_rz(2, pi / 3) |>
    gate_cx(1, 2)
  result <- simulate_quantum(circuit, backend = "reference", record = TRUE)

  cases <- list(
    list(width = 480, height = 280, draw = function() plot_circuit(circuit)),
    list(width = 480, height = 320, draw = function() plot_state(result, engine = "base")),
    list(width = 600, height = 520, draw = function() plot_execution(result, step = 3)),
    list(width = 360, height = 360, draw = function() plot_bloch(result, qubit = 1))
  )
  for (case in cases) {
    output <- tempfile(fileext = ".png")
    grDevices::png(
      output,
      width = case$width,
      height = case$height,
      res = 120,
      pointsize = 8
    )
    case$draw()
    grDevices::dev.off()
    expect_gt(file.info(output)$size, 0)
  }
})

test_that("every visual preset renders a complete state figure", {
  state <- c(1, 1i) / sqrt(2)
  for (theme in c("nature", "npj", "colorblind", "dark", "light", "mono")) {
    output <- tempfile(fileext = ".png")
    grDevices::png(output, width = 480, height = 320, res = 120, pointsize = 8)
    tryCatch(
      plot_state(state, theme = theme, engine = "base"),
      finally = grDevices::dev.off()
    )
    expect_gt(file.info(output)$size, 0)
  }
})

test_that("ggplot state figures use the same mathematical notation contract", {
  skip_if_not_installed("ggplot2")
  state <- c(1, 1i) / sqrt(2)
  figure <- plot_state(state, engine = "ggplot2", theme = "npj")
  expect_s3_class(figure, "ggplot")

  x_scale <- figure$scales$get_scales("x")
  ket_labels <- x_scale$labels(c("0", "1"))
  expect_true(is.expression(ket_labels))
  expect_false(grepl(">", paste(deparse(ket_labels), collapse = "")))

  phase_scale <- figure$scales$get_scales("fill")
  expect_true(is.expression(phase_scale$labels))

  output <- tempfile(fileext = ".png")
  grDevices::png(output, width = 480, height = 320, res = 120, pointsize = 8)
  print(figure)
  grDevices::dev.off()
  expect_gt(file.info(output)$size, 0)
})

test_that("ragg devices honor qvivid point sizes when available", {
  skip_if_not_installed("ragg")
  output <- tempfile(fileext = ".png")
  device <- .qv_open_figure_device(
    output,
    format = "png",
    width_in = 3.5,
    height_in = 2.5,
    dpi = 120,
    background = "white",
    pointsize = 7
  )
  on.exit({
    if (device %in% grDevices::dev.list()) grDevices::dev.off(device)
  }, add = TRUE)
  expect_equal(graphics::par("ps"), 7)
  expect_lt(graphics::par("csi"), 0.15)
  graphics::plot.new()
  grDevices::dev.off(device)
  expect_gt(file.info(output)$size, 0)
})
