#!/usr/bin/env Rscript

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
for (path in c(
  "R/utils.R",
  "R/circuit.R",
  "R/gates.R",
  "R/simulate.R",
  "R/visualize.R",
  "R/bloch.R",
  "R/export.R",
  "R/animate.R"
)) {
  source(file.path(root, path), chdir = FALSE)
}

gallery <- file.path(root, "docs", "gallery")
dir.create(gallery, recursive = TRUE, showWarnings = FALSE)

render_gallery_png <- function(
    file,
    width,
    height,
    theme,
    draw,
    pointsize = 10,
    resolution = 150) {
  palette <- qv_palette(theme)
  device <- if (requireNamespace("ragg", quietly = TRUE)) {
    ragg::agg_png(
      file,
      width = width,
      height = height,
      units = "px",
      res = resolution,
      pointsize = pointsize,
      background = palette$background
    )
  } else {
    grDevices::png(
      file,
      width = width,
      height = height,
      res = resolution,
      pointsize = pointsize,
      bg = palette$background,
      type = if (isTRUE(capabilities("cairo"))) "cairo-png" else getOption("bitmapType")
    )
  }
  device_number <- grDevices::dev.cur()
  on.exit({
    if (device_number %in% grDevices::dev.list()) {
      grDevices::dev.off(device_number)
    }
  }, add = TRUE)
  graphics::par(ps = pointsize)
  draw()
  grDevices::dev.off(device_number)
  if (!file.exists(file) || file.info(file)$size <= 0) {
    stop("Failed to render gallery figure: ", file, call. = FALSE)
  }
  invisible(file)
}

bell <- quantum_circuit(2, name = "Bell state") |>
  gate_h(1) |>
  gate_cx(1, 2) |>
  measure_all()
result <- simulate_quantum(
  bell,
  shots = 1000,
  seed = 42,
  backend = "reference",
  record = TRUE
)

orbit <- quantum_circuit(1, name = "Exact phase orbit")
for (index in seq_len(24L)) {
  orbit <- gate_rz(orbit, 1, 2 * pi / 24)
}
orbit_result <- simulate_quantum(
  orbit,
  initial_state = c(1, 1) / sqrt(2),
  backend = "reference",
  record = TRUE
)

phase_circuit <- quantum_circuit(2, name = "Phase-encoded superposition") |>
  gate_h(1) |>
  gate_h(2) |>
  gate_rz(1, pi / 2) |>
  gate_rz(2, pi / 3)
phase_result <- simulate_quantum(
  phase_circuit,
  backend = "reference",
  record = TRUE
)

ghz <- quantum_circuit(3, name = "Three-qubit GHZ state") |>
  gate_h(1) |>
  gate_cx(1, 2) |>
  gate_cx(2, 3)
ghz_result <- simulate_quantum(
  ghz,
  backend = "reference",
  record = TRUE
)

rotation <- quantum_circuit(1, name = "Coherent single-qubit control") |>
  gate_h(1) |>
  gate_rz(1, pi / 2) |>
  gate_ry(1, pi / 3)
rotation_result <- simulate_quantum(
  rotation,
  backend = "reference",
  record = TRUE
)

circuit_path <- file.path(gallery, "bell-circuit.png")
render_gallery_png(circuit_path, 1200, 520, "nature", function() {
  plot_circuit(bell, highlight = 2)
})

state_path <- file.path(gallery, "bell-state.png")
render_gallery_png(state_path, 1200, 760, "nature", function() {
  plot_state(result, engine = "base")
})

execution_path <- file.path(gallery, "bell-execution.png")
render_gallery_png(execution_path, 1200, 1000, "npj", function() {
  plot_execution(result, step = 2, theme = "npj")
})

bloch_path <- file.path(gallery, "bell-bloch.png")
save_quantum_plot(
  result,
  bloch_path,
  view = "bloch",
  size = "single",
  dpi = 300,
  theme = "nature",
  overwrite = TRUE
)

orbit_path <- file.path(gallery, "bloch-orbit.png")
save_quantum_plot(
  trajectory_bloch(orbit_result, qubit = 1),
  orbit_path,
  view = "bloch",
  size = "single",
  dpi = 300,
  theme = "npj",
  main = expression("Exact phase orbit under " * italic(R)[z]),
  subtitle = expression(italic(q)[1] %.% "24 simulated steps"),
  overwrite = TRUE
)

phase_path <- file.path(gallery, "phase-superposition.png")
render_gallery_png(phase_path, 1200, 760, "npj", function() {
  plot_state(
    phase_result,
    engine = "base",
    theme = "npj",
    subtitle = expression(
      "Equal probabilities" %.% "phase encoded by" ~ arg(psi)
    )
  )
})

ghz_path <- file.path(gallery, "ghz-execution.png")
render_gallery_png(ghz_path, 1200, 1050, "nature", function() {
  plot_execution(ghz_result, step = 3, theme = "nature")
})

rotation_path <- file.path(gallery, "rotation-execution-dark.png")
render_gallery_png(rotation_path, 1200, 1000, "dark", function() {
  plot_execution(rotation_result, step = 3, theme = "dark")
})

presets_path <- file.path(gallery, "theme-presets.png")
render_gallery_png(
  presets_path,
  1800,
  1040,
  "nature",
  pointsize = 9,
  draw = function() {
    old_parameters <- graphics::par(no.readonly = TRUE)
    on.exit(graphics::par(old_parameters), add = TRUE)
    graphics::par(mfrow = c(2, 3))
    for (preset in c("nature", "npj", "colorblind", "dark", "light", "mono")) {
      .qv_plot_state_base(
        .qv_plot_data(phase_result, NULL),
        qv_palette(preset),
        main = if (preset == "npj") "npj" else tools::toTitleCase(preset),
        subtitle = NULL,
        show_legend = FALSE,
        restore_par = FALSE
      )
    }
  }
)

cat(normalizePath(circuit_path, winslash = "/"), "\n")
cat(normalizePath(state_path, winslash = "/"), "\n")
cat(normalizePath(execution_path, winslash = "/"), "\n")
cat(normalizePath(bloch_path, winslash = "/"), "\n")
cat(normalizePath(orbit_path, winslash = "/"), "\n")
cat(normalizePath(phase_path, winslash = "/"), "\n")
cat(normalizePath(ghz_path, winslash = "/"), "\n")
cat(normalizePath(rotation_path, winslash = "/"), "\n")
cat(normalizePath(presets_path, winslash = "/"), "\n")

if (!requireNamespace("gifski", quietly = TRUE)) {
  stop(
    "Gallery GIF generation requires gifski; install it before refreshing tracked assets.",
    call. = FALSE
  )
}

animation <- animate_state(
  result,
  file.path(gallery, "bell-state.gif"),
  fps = 2,
  width = 960,
  height = 600,
  theme = "npj",
  progress = FALSE
)
print(animation)
bloch_animation <- animate_bloch(
  result,
  file.path(gallery, "bell-bloch.gif"),
  qubit = 1,
  fps = 2,
  width = 720,
  height = 720,
  theme = "nature",
  progress = FALSE
)
print(bloch_animation)
orbit_animation <- animate_bloch(
  orbit_result,
  file.path(gallery, "bloch-orbit.gif"),
  qubit = 1,
  fps = 8,
  width = 720,
  height = 720,
  theme = "npj",
  progress = FALSE
)
print(orbit_animation)
