.qv_open_animation_frame <- function(filename, width, height, palette) {
  pointsize <- if (min(width, height) < 360L) {
    8
  } else if (min(width, height) < 600L) {
    9
  } else {
    palette$screen_pointsize
  }
  if (requireNamespace("ragg", quietly = TRUE)) {
    ragg::agg_png(
      filename,
      width = width,
      height = height,
      units = "px",
      res = 120,
      pointsize = pointsize,
      background = palette$background
    )
  } else {
    grDevices::png(
      filename,
      width = width,
      height = height,
      res = 120,
      pointsize = pointsize,
      bg = palette$background,
      type = if (isTRUE(capabilities("cairo"))) "cairo-png" else getOption("bitmapType")
    )
  }
  graphics::par(ps = pointsize)
  grDevices::dev.cur()
}

.qv_animation_state_contract <- function(result, top) {
  state_count <- length(result$trajectory[[1L]]$state)
  if (is.null(top)) top <- min(32L, state_count)
  if (!.qv_is_whole_number(top) || top < 1L) {
    .qv_abort("`top` must be NULL or one positive whole number.")
  }
  top <- min(as.integer(top), state_count)
  score <- numeric(state_count)
  for (frame in result$trajectory) {
    score <- pmax(score, Mod(frame$state)^2)
  }
  indices <- if (top < state_count) {
    sort(order(score, decreasing = TRUE)[seq_len(top)] - 1L)
  } else {
    seq_len(state_count) - 1L
  }
  list(
    indices = as.integer(indices),
    basis = .qv_basis_labels(log2(state_count), indices),
    upper = .qv_state_upper(score[indices + 1L])
  )
}

.qv_render_state_frames <- function(
    result,
    directory,
    width,
    height,
    top,
    theme,
    include_circuit) {
  palette <- qv_palette(theme)
  frames <- character(length(result$trajectory))
  circuit_name <- if (is.null(result$circuit$name)) "Quantum state evolution" else result$circuit$name
  contract <- .qv_animation_state_contract(result, top)

  for (index in seq_along(result$trajectory)) {
    frame <- result$trajectory[[index]]
    frame_label <- .qv_frame_plot_label(result, frame)
    label_value <- if (is.expression(frame_label)) frame_label[[1L]] else frame_label
    step_subtitle <- as.expression(substitute(
      "Step" ~ step ~ "of" ~ total %.% label,
      list(
        step = frame$step,
        total = length(result$trajectory) - 1L,
        label = label_value
      )
    ))
    filename <- file.path(directory, sprintf("frame-%05d.png", index))
    .qv_open_animation_frame(filename, width, height, palette)
    plotted <- FALSE
    tryCatch(
      {
        if (isTRUE(include_circuit)) {
          .qv_draw_execution(
            result,
            frame,
            top = NULL,
            theme = theme,
            main = NULL,
            subtitle = step_subtitle,
            state_indices = contract$indices,
            state_upper = contract$upper
          )
        } else {
          data <- .qv_plot_data(frame$state, NULL, indices = contract$indices)
          .qv_plot_state_base(
            data,
            palette,
            main = circuit_name,
            subtitle = step_subtitle,
            upper = contract$upper
          )
        }
        plotted <- TRUE
      },
      finally = {
        grDevices::dev.off()
      }
    )
    if (!plotted || !file.exists(filename)) {
      .qv_abort("Failed to render animation frame %d.", index)
    }
    frames[index] <- filename
  }
  frames
}

#' Animate a recorded quantum state trajectory
#'
#' Each frame uses probability for bar height and complex phase for fill color.
#' Simulate with `record = TRUE` before calling this function.
#'
#' @param result A recorded `qv_result`.
#' @param file Destination GIF path.
#' @param fps Frames per second.
#' @param width,height Output dimensions in pixels.
#' @param top Maximum number of basis states shown in each frame.
#' @param theme A qvivid visual preset.
#' @param include_circuit Include a synchronized circuit execution playhead.
#' @param loop Repeat the GIF indefinitely.
#' @param progress Display encoder progress in interactive sessions.
#' @return A `qv_animation` object containing the normalized output path.
#' @export
animate_state <- function(
    result,
    file,
    fps = 3,
    width = 960,
    height = 760,
    top = NULL,
    theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
    include_circuit = TRUE,
    loop = TRUE,
    progress = interactive()) {
  if (!inherits(result, "qv_result")) {
    .qv_abort("`result` must be a `qv_result`.")
  }
  if (is.null(result$trajectory)) {
    .qv_abort("No trajectory was recorded; rerun with `record = TRUE`.")
  }
  if (!is.character(file) || length(file) != 1L || is.na(file) || !nzchar(file)) {
    .qv_abort("`file` must be one non-empty GIF path.")
  }
  if (!grepl("\\.gif$", file, ignore.case = TRUE)) {
    .qv_abort("`file` must end in `.gif`.")
  }
  if (!is.numeric(fps) || length(fps) != 1L || !is.finite(fps) || fps <= 0) {
    .qv_abort("`fps` must be one positive number.")
  }
  for (value in list(width = width, height = height)) {
    if (!.qv_is_whole_number(value) || value < 240L) {
      .qv_abort("`width` and `height` must be whole numbers of at least 240 pixels.")
    }
  }
  if (!is.logical(loop) || length(loop) != 1L || is.na(loop) ||
      !is.logical(progress) || length(progress) != 1L || is.na(progress) ||
      !is.logical(include_circuit) || length(include_circuit) != 1L ||
      is.na(include_circuit)) {
    .qv_abort("`include_circuit`, `loop`, and `progress` must each be TRUE or FALSE.")
  }
  theme <- .qv_match_theme(theme)
  if (!requireNamespace("gifski", quietly = TRUE)) {
    .qv_abort(
      "GIF export requires the optional `gifski` package; install it with install.packages('gifski')."
    )
  }

  destination_directory <- dirname(file)
  if (!dir.exists(destination_directory)) {
    .qv_abort("Destination directory does not exist: %s", destination_directory)
  }
  frame_directory <- tempfile("qvivid-frames-")
  dir.create(frame_directory, recursive = TRUE)
  on.exit(unlink(frame_directory, recursive = TRUE, force = TRUE), add = TRUE)
  frames <- .qv_render_state_frames(
    result,
    frame_directory,
    as.integer(width),
    as.integer(height),
    top,
    theme,
    include_circuit
  )

  gifski::gifski(
    png_files = frames,
    gif_file = file,
    width = as.integer(width),
    height = as.integer(height),
    delay = 1 / fps,
    loop = loop,
    progress = progress
  )
  if (!file.exists(file) || file.info(file)$size <= 0) {
    .qv_abort("GIF encoder did not create a valid output file.")
  }

  structure(
    list(
      path = normalizePath(file, winslash = "/", mustWork = TRUE),
      kind = "state",
      frames = length(frames),
      fps = fps,
      width = as.integer(width),
      height = as.integer(height),
      theme = theme
    ),
    class = "qv_animation"
  )
}

.qv_render_bloch_frames <- function(
    result,
    directory,
    qubit,
    width,
    height,
    theme,
    view,
    trail) {
  palette <- qv_palette(theme)
  trajectory <- trajectory_bloch(result, qubit = qubit)
  frames <- character(length(result$trajectory))
  main <- if (is.null(result$circuit$name)) {
    "Bloch trajectory"
  } else {
    result$circuit$name
  }

  for (index in seq_along(result$trajectory)) {
    frame <- result$trajectory[[index]]
    frame_label <- .qv_frame_plot_label(result, frame)
    label_value <- if (is.expression(frame_label)) frame_label[[1L]] else frame_label
    filename <- file.path(directory, sprintf("frame-%05d.png", index))
    .qv_open_animation_frame(filename, width, height, palette)
    plotted <- FALSE
    tryCatch(
      {
        vector <- bloch_vector(frame$state, qubit = qubit)
        frame_trail <- if (isTRUE(trail)) {
          trajectory[seq_len(index), , drop = FALSE]
        } else {
          NULL
        }
        .qv_plot_bloch_base(
          vector,
          frame_trail,
          palette,
          view,
          main,
          as.expression(substitute(
            "Bloch trajectory" %.% italic(q)[index] %.%
              "step" ~ step ~ "of" ~ total %.% label,
            list(
              index = qubit,
              step = frame$step,
              total = length(result$trajectory) - 1L,
              label = label_value
            )
          ))
        )
        plotted <- TRUE
      },
      finally = {
        grDevices::dev.off()
      }
    )
    if (!plotted || !file.exists(filename)) {
      .qv_abort("Failed to render Bloch animation frame %d.", index)
    }
    frames[index] <- filename
  }
  frames
}

#' Animate a recorded Bloch trajectory
#'
#' The selected qubit is reduced from the full state at every recorded step, so
#' entanglement appears as contraction of the Bloch vector toward the origin.
#'
#' @param result A `qv_result` created with `record = TRUE`.
#' @param file Destination GIF path.
#' @param qubit A one-based qubit index.
#' @param fps Frames per second.
#' @param width,height Output dimensions in pixels.
#' @param theme A qvivid visual preset.
#' @param view A perspective sphere or planar projection.
#' @param trail Retain the path through earlier frames.
#' @param loop Repeat the GIF indefinitely.
#' @param progress Display encoder progress in interactive sessions.
#' @return A `qv_animation` object containing the normalized output path.
#' @export
animate_bloch <- function(
    result,
    file,
    qubit = 1L,
    fps = 3,
    width = 720,
    height = 720,
    theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
    view = c("perspective", "xy", "xz", "yz"),
    trail = TRUE,
    loop = TRUE,
    progress = interactive()) {
  if (!inherits(result, "qv_result")) {
    .qv_abort("`result` must be a `qv_result`.")
  }
  if (is.null(result$trajectory)) {
    .qv_abort("No trajectory was recorded; rerun with `record = TRUE`.")
  }
  qubit <- .qv_validate_qubits(
    qubit,
    result$circuit$n_qubits,
    argument = "qubit"
  )
  if (length(qubit) != 1L) {
    .qv_abort("`qubit` must be a one-based qubit index.")
  }
  if (!is.character(file) || length(file) != 1L || is.na(file) || !nzchar(file)) {
    .qv_abort("`file` must be one non-empty GIF path.")
  }
  if (!grepl("\\.gif$", file, ignore.case = TRUE)) {
    .qv_abort("`file` must end in `.gif`.")
  }
  if (!is.numeric(fps) || length(fps) != 1L || !is.finite(fps) || fps <= 0) {
    .qv_abort("`fps` must be one positive number.")
  }
  for (value in list(width = width, height = height)) {
    if (!.qv_is_whole_number(value) || value < 240L) {
      .qv_abort("`width` and `height` must be whole numbers of at least 240 pixels.")
    }
  }
  for (value in list(trail = trail, loop = loop, progress = progress)) {
    if (!is.logical(value) || length(value) != 1L || is.na(value)) {
      .qv_abort("`trail`, `loop`, and `progress` must each be TRUE or FALSE.")
    }
  }
  theme <- .qv_match_theme(theme)
  view <- match.arg(view)
  if (!requireNamespace("gifski", quietly = TRUE)) {
    .qv_abort(
      "GIF export requires the optional `gifski` package; install it with install.packages('gifski')."
    )
  }

  destination_directory <- dirname(file)
  if (!dir.exists(destination_directory)) {
    .qv_abort("Destination directory does not exist: %s", destination_directory)
  }
  frame_directory <- tempfile("qvivid-bloch-frames-")
  dir.create(frame_directory, recursive = TRUE)
  on.exit(unlink(frame_directory, recursive = TRUE, force = TRUE), add = TRUE)
  frames <- .qv_render_bloch_frames(
    result,
    frame_directory,
    as.integer(qubit),
    as.integer(width),
    as.integer(height),
    theme,
    view,
    trail
  )

  gifski::gifski(
    png_files = frames,
    gif_file = file,
    width = as.integer(width),
    height = as.integer(height),
    delay = 1 / fps,
    loop = loop,
    progress = progress
  )
  if (!file.exists(file) || file.info(file)$size <= 0) {
    .qv_abort("GIF encoder did not create a valid output file.")
  }

  structure(
    list(
      path = normalizePath(file, winslash = "/", mustWork = TRUE),
      kind = "bloch",
      qubit = as.integer(qubit),
      frames = length(frames),
      fps = fps,
      width = as.integer(width),
      height = as.integer(height),
      theme = theme,
      view = view
    ),
    class = "qv_animation"
  )
}

#' @export
print.qv_animation <- function(x, ...) {
  cat("<qv_animation>\n")
  kind <- if (is.null(x$kind)) "state" else x$kind
  cat(sprintf(
    "  %s | %d frames | %.3g fps | %d x %d px\n",
    kind,
    x$frames,
    x$fps,
    x$width,
    x$height
  ))
  cat(sprintf("  %s\n", x$path))
  invisible(x)
}
