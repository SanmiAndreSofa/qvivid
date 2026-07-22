#!/usr/bin/env Rscript

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source_order <- c(
  "R/utils.R",
  "R/circuit.R",
  "R/gates.R",
  "R/simulate.R",
  "R/visualize.R",
  "R/bloch.R",
  "R/export.R",
  "R/animate.R"
)
for (path in source_order) {
  source(file.path(root, path), chdir = FALSE)
}

assert_close <- function(observed, expected, tolerance = 1e-10, label = "values") {
  error <- max(Mod(observed - expected))
  if (!is.finite(error) || error > tolerance) {
    stop(sprintf("%s differ by %.12g", label, error), call. = FALSE)
  }
}

cat("qvivid source validation\n")

for (preset in c("nature", "npj", "colorblind", "dark", "light", "mono")) {
  palette <- qv_palette(preset)
  stopifnot(
    identical(palette$name, preset),
    length(palette$phase) >= 5L,
    identical(palette$phase[1L], palette$phase[length(palette$phase)])
  )
}

bell <- quantum_circuit(2, name = "Bell state") |>
  gate_h(1) |>
  gate_cx(1, 2) |>
  measure_all()

stopifnot(
  inherits(bell, "qv_circuit"),
  length(bell$operations) == 3L,
  circuit_depth(bell) == 3L
)

result <- simulate_quantum(
  bell,
  shots = 4096,
  seed = 20260721,
  backend = "reference",
  record = TRUE
)
expected <- c(1 / sqrt(2), 0, 0, 1 / sqrt(2)) + 0i
assert_close(result$state, expected, label = "Bell amplitudes")
assert_close(sum(Mod(result$state)^2), 1, label = "Bell norm")
assert_close(sum(result$probabilities), 1, label = "stored probabilities")
stopifnot(
  inherits(result, "qv_result"),
  identical(sort(result$counts$basis), c("00", "11")),
  length(result$trajectory) == 4L,
  all(abs(result$counts$probability - 0.5) < 0.05)
)

repeat_result <- simulate_quantum(
  bell,
  shots = 4096,
  seed = 20260721,
  backend = "reference"
)
stopifnot(identical(result$counts, repeat_result$counts))

reverse_control <- quantum_circuit(2) |>
  gate_x(2) |>
  gate_cx(control = 2, target = 1)
reverse_result <- simulate_quantum(reverse_control, backend = "reference")
assert_close(reverse_result$state, c(0, 0, 0, 1) + 0i, label = "reverse CX")

rotations <- quantum_circuit(3) |>
  gate_rx(1, 0.31) |>
  gate_ry(2, -0.73) |>
  gate_rz(3, 1.27) |>
  gate_swap(1, 3)
rotation_result <- simulate_quantum(rotations, backend = "reference")
assert_close(sum(Mod(rotation_result$state)^2), 1, label = "rotation norm")

trajectory <- trajectory_data(result)
stopifnot(
  nrow(trajectory) == 16L,
  identical(sort(unique(trajectory$step)), 0:3)
)

bloch <- bloch_vector(result, qubit = 1)
assert_close(c(bloch$x, bloch$y, bloch$z), c(0, 0, 0), label = "Bell Bloch vector")
assert_close(bloch$purity, 0.5, label = "Bell reduced purity")
bloch_trajectory <- trajectory_bloch(result, qubit = 1)
stopifnot(
  identical(bloch_trajectory$step, 0:3),
  all(abs(bloch_trajectory$radius - c(1, 1, 0, 0)) < 1e-10)
)

plot_file <- tempfile(fileext = ".png")
grDevices::png(plot_file, width = 960, height = 600, res = 120)
plot_state(result, engine = "base")
grDevices::dev.off()
stopifnot(file.exists(plot_file), file.info(plot_file)$size > 0)
unlink(plot_file)

circuit_file <- tempfile(fileext = ".png")
grDevices::png(circuit_file, width = 960, height = 420, res = 120)
plot_circuit(bell, highlight = 2)
grDevices::dev.off()
stopifnot(file.exists(circuit_file), file.info(circuit_file)$size > 0)
unlink(circuit_file)

execution_file <- tempfile(fileext = ".png")
grDevices::png(execution_file, width = 960, height = 800, res = 120)
plot_execution(result, step = 2)
grDevices::dev.off()
stopifnot(file.exists(execution_file), file.info(execution_file)$size > 0)
unlink(execution_file)

bloch_file <- tempfile(fileext = ".png")
grDevices::png(bloch_file, width = 720, height = 720, res = 120)
plot_bloch(result, qubit = 1, trajectory = TRUE, theme = "npj")
grDevices::dev.off()
stopifnot(file.exists(bloch_file), file.info(bloch_file)$size > 0)
unlink(bloch_file)

export_file <- tempfile(fileext = ".pdf")
export <- save_quantum_plot(
  result,
  export_file,
  view = "bloch",
  size = "single",
  theme = "nature"
)
stopifnot(
  inherits(export, "qv_export"),
  abs(export$width_mm - 89) < 1e-12,
  file.exists(export_file),
  file.info(export_file)$size > 0
)
unlink(export_file)

execution_export_file <- tempfile(fileext = ".pdf")
execution_export <- save_quantum_plot(
  result,
  execution_export_file,
  view = "execution",
  size = "single",
  theme = "nature"
)
stopifnot(
  inherits(execution_export, "qv_export"),
  file.exists(execution_export_file),
  file.info(execution_export_file)$size > 0
)
unlink(execution_export_file)

for (extension in c("svg", "png", "tiff")) {
  format_file <- tempfile(fileext = paste0(".", extension))
  artifact <- save_quantum_plot(
    result,
    format_file,
    view = "bloch",
    width = 2,
    height = 2,
    units = "in",
    dpi = 96,
    theme = "npj"
  )
  stopifnot(
    identical(artifact$format, extension),
    file.exists(format_file),
    file.info(format_file)$size > 0
  )
  unlink(format_file)
}

frame_directory <- tempfile("qvivid-validation-frames-")
dir.create(frame_directory)
frames <- .qv_render_state_frames(
  result,
  frame_directory,
  width = 480,
  height = 320,
  top = NULL,
  theme = "dark",
  include_circuit = TRUE
)
stopifnot(length(frames) == 4L, all(file.exists(frames)), all(file.info(frames)$size > 0))
unlink(frame_directory, recursive = TRUE, force = TRUE)

bloch_frame_directory <- tempfile("qvivid-bloch-validation-frames-")
dir.create(bloch_frame_directory)
bloch_frames <- .qv_render_bloch_frames(
  result,
  bloch_frame_directory,
  qubit = 1,
  width = 480,
  height = 480,
  theme = "npj",
  view = "perspective",
  trail = TRUE
)
stopifnot(
  length(bloch_frames) == 4L,
  all(file.exists(bloch_frames)),
  all(file.info(bloch_frames)$size > 0)
)
unlink(bloch_frame_directory, recursive = TRUE, force = TRUE)

cat("All reference-backend, sampling, trajectory, Bloch, export, and plotting checks passed.\n")
