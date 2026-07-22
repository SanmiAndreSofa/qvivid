.qv_figure_view <- function(x, view) {
  if (!identical(view, "auto")) {
    return(view)
  }
  if (inherits(x, "qv_circuit")) {
    return("circuit")
  }
  if (inherits(x, "qv_bloch") || inherits(x, "qv_bloch_trajectory")) {
    return("bloch")
  }
  if (inherits(x, "qv_result")) {
    return(if (is.null(x$trajectory)) "state" else "execution")
  }
  if (is.atomic(x) && (is.numeric(x) || is.complex(x))) {
    return("state")
  }
  .qv_abort(
    "Could not infer a figure view from `x`; select `view` explicitly."
  )
}

.qv_units_to_mm <- function(x, units) {
  switch(
    units,
    mm = x,
    cm = x * 10,
    `in` = x * 25.4
  )
}

.qv_mm_to_units <- function(x, units) {
  switch(
    units,
    mm = x,
    cm = x / 10,
    `in` = x / 25.4
  )
}

.qv_validate_figure_dimension <- function(x, argument) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0) {
    .qv_abort("`%s` must be NULL or one positive number.", argument)
  }
  unname(x)
}

.qv_open_pdf_device <- function(
    file,
    width_in,
    height_in,
    dpi,
    background,
    pointsize) {
  previous <- grDevices::dev.cur()
  cairo_device <- NA_integer_
  # The macOS R binary can report Cairo support even when its optional XQuartz
  # libraries are absent. Its native PDF device is the reliable vector path.
  try_cairo <- isTRUE(capabilities("cairo")) &&
    !identical(unname(Sys.info()[["sysname"]]), "Darwin")
  if (try_cairo) {
    cairo_device <- suppressWarnings(tryCatch(
      {
        grDevices::cairo_pdf(
          file,
          width = width_in,
          height = height_in,
          family = "sans",
          bg = background,
          pointsize = pointsize,
          onefile = FALSE,
          antialias = "subpixel",
          fallback_resolution = max(450, dpi)
        )
        as.integer(grDevices::dev.cur())
      },
      error = function(error) NA_integer_
    ))
  }
  if (is.finite(cairo_device) && cairo_device != as.integer(previous)) {
    return(grDevices::dev.cur())
  }

  current <- grDevices::dev.cur()
  if (as.integer(current) != as.integer(previous) && as.integer(current) > 1L) {
    suppressWarnings(try(grDevices::dev.off(current), silent = TRUE))
  }
  grDevices::pdf(
    file,
    width = width_in,
    height = height_in,
    family = "sans",
    bg = background,
    pointsize = pointsize,
    useDingbats = FALSE,
    paper = "special",
    onefile = FALSE
  )
  grDevices::dev.cur()
}

.qv_open_figure_device <- function(
    file,
    format,
    width_in,
    height_in,
    dpi,
    background,
    pointsize) {
  switch(
    format,
    pdf = .qv_open_pdf_device(
      file,
      width_in,
      height_in,
      dpi,
      background,
      pointsize
    ),
    svg = grDevices::svg(
      file,
      width = width_in,
      height = height_in,
      family = "sans",
      bg = background,
      pointsize = pointsize,
      onefile = FALSE
    ),
    png = if (requireNamespace("ragg", quietly = TRUE)) {
      ragg::agg_png(
        file,
        width = width_in,
        height = height_in,
        units = "in",
        res = dpi,
        pointsize = pointsize,
        background = background
      )
    } else {
      grDevices::png(
        file,
        width = width_in,
        height = height_in,
        units = "in",
        res = dpi,
        pointsize = pointsize,
        bg = background,
        type = if (isTRUE(capabilities("cairo"))) "cairo-png" else getOption("bitmapType")
      )
    },
    tiff = if (requireNamespace("ragg", quietly = TRUE)) {
      ragg::agg_tiff(
        file,
        width = width_in,
        height = height_in,
        units = "in",
        res = dpi,
        compression = "lzw",
        pointsize = pointsize,
        background = background
      )
    } else {
      grDevices::tiff(
        file,
        width = width_in,
        height = height_in,
        units = "in",
        res = dpi,
        compression = "lzw",
        pointsize = pointsize,
        bg = background,
        type = if (isTRUE(capabilities("cairo"))) "cairo" else getOption("bitmapType")
      )
    }
  )
  grDevices::dev.cur()
}

#' Export a publication-ready qvivid figure
#'
#' The `single` and `double` size presets use 89 mm and 183 mm widths,
#' matching Nature's public final-figure guidance. PDF and SVG preserve vector
#' artwork; PNG and TIFF default to 450 dpi.
#'
#' @param x A circuit, statevector, simulation result, Bloch vector, or Bloch
#'   trajectory.
#' @param file Destination ending in `.pdf`, `.svg`, `.png`, or `.tiff`.
#' @param view One of `"auto"`, `"state"`, `"circuit"`,
#'   `"execution"`, or `"bloch"`.
#' @param size Journal width preset: `"double"` (183 mm) or `"single"`
#'   (89 mm).
#' @param width,height Optional custom dimensions interpreted in `units`.
#' @param units Units for custom dimensions.
#' @param dpi Raster resolution for PNG and TIFF.
#' @param theme A qvivid visual preset.
#' @param step Recorded execution step for the execution view.
#' @param top Maximum number of basis states for state views.
#' @param qubit One-based qubit index for a Bloch view.
#' @param main,subtitle Optional figure title and subtitle.
#' @param overwrite Replace an existing destination.
#' @return A `qv_export` object describing the created file.
#' @export
save_quantum_plot <- function(
    x,
    file,
    view = c("auto", "state", "circuit", "execution", "bloch"),
    size = c("double", "single"),
    width = NULL,
    height = NULL,
    units = c("mm", "in", "cm"),
    dpi = 450,
    theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
    step = NULL,
    top = NULL,
    qubit = 1L,
    main = NULL,
    subtitle = NULL,
    overwrite = FALSE) {
  if (!is.character(file) || length(file) != 1L || is.na(file) || !nzchar(file)) {
    .qv_abort("`file` must be one non-empty output path.")
  }
  destination_directory <- dirname(file)
  if (!dir.exists(destination_directory)) {
    .qv_abort("Destination directory does not exist: %s", destination_directory)
  }
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    .qv_abort("`overwrite` must be TRUE or FALSE.")
  }
  if (file.exists(file) && !isTRUE(overwrite)) {
    .qv_abort(
      "Destination already exists; use `overwrite = TRUE` to replace it: %s",
      file
    )
  }

  view <- .qv_figure_view(x, match.arg(view))
  size <- match.arg(size)
  units <- match.arg(units)
  theme <- .qv_match_theme(theme)
  extension <- tolower(sub("^.*\\.", "", basename(file)))
  if (!extension %in% c("pdf", "svg", "png", "tiff")) {
    .qv_abort("`file` must end in `.pdf`, `.svg`, `.png`, or `.tiff`.")
  }
  if (!is.numeric(dpi) || length(dpi) != 1L || !is.finite(dpi) ||
      dpi < 72 || dpi > 2400) {
    .qv_abort("`dpi` must be one number between 72 and 2400.")
  }

  preset_width_mm <- c(double = 183, single = 89)[[size]]
  uses_preset_width <- is.null(width)
  if (is.null(width)) {
    width_mm <- preset_width_mm
    width <- .qv_mm_to_units(width_mm, units)
  } else {
    width <- .qv_validate_figure_dimension(width, "width")
    width_mm <- .qv_units_to_mm(width, units)
  }
  if (is.null(height)) {
    ratio <- switch(
      view,
      state = 0.62,
      circuit = 0.50,
      execution = 0.82,
      bloch = 1
    )
    height_mm <- width_mm * ratio
    if (uses_preset_width) {
      height_mm <- min(height_mm, 170)
    }
    height <- .qv_mm_to_units(height_mm, units)
  } else {
    height <- .qv_validate_figure_dimension(height, "height")
    height_mm <- .qv_units_to_mm(height, units)
  }
  .qv_validate_figure_dimension(width, "width")
  .qv_validate_figure_dimension(height, "height")

  temporary_file <- tempfile(
    "qvivid-figure-",
    fileext = paste0(".", extension)
  )
  on.exit(unlink(temporary_file, force = TRUE), add = TRUE)
  palette <- qv_palette(theme)
  device <- .qv_open_figure_device(
    temporary_file,
    extension,
    width_mm / 25.4,
    height_mm / 25.4,
    dpi,
    palette$background,
    palette$base_size
  )
  device_open <- TRUE
  graphics::par(ps = palette$base_size)
  on.exit({
    if (isTRUE(device_open) && device %in% grDevices::dev.list()) {
      grDevices::dev.off(device)
    }
  }, add = TRUE)

  if (identical(view, "state")) {
    plot_state(
      x,
      top = top,
      theme = theme,
      engine = "base",
      main = main,
      subtitle = subtitle
    )
  } else if (identical(view, "circuit")) {
    circuit <- if (inherits(x, "qv_result")) x$circuit else x
    plot_circuit(circuit, theme = theme, main = main, subtitle = subtitle)
  } else if (identical(view, "execution")) {
    plot_execution(
      x,
      step = step,
      top = top,
      theme = theme,
      main = main,
      subtitle = subtitle
    )
  } else {
    plot_bloch(
      x,
      qubit = qubit,
      theme = theme,
      main = main,
      subtitle = subtitle
    )
  }
  grDevices::dev.off(device)
  device_open <- FALSE

  copied <- file.copy(temporary_file, file, overwrite = isTRUE(overwrite))
  if (!isTRUE(copied) || !file.exists(file) || file.info(file)$size <= 0) {
    .qv_abort("Failed to create a valid figure at: %s", file)
  }

  structure(
    list(
      path = normalizePath(file, winslash = "/", mustWork = TRUE),
      view = view,
      format = extension,
      theme = theme,
      width_mm = unname(width_mm),
      height_mm = unname(height_mm),
      dpi = if (extension %in% c("png", "tiff")) unname(dpi) else NA_real_
    ),
    class = "qv_export"
  )
}

#' @export
print.qv_export <- function(x, ...) {
  resolution <- if (is.na(x$dpi)) "vector" else sprintf("%.0f dpi", x$dpi)
  cat("<qv_export>\n")
  cat(sprintf(
    "  %s %s | %.1f x %.1f mm | %s | %s\n",
    toupper(x$format),
    x$view,
    x$width_mm,
    x$height_mm,
    resolution,
    x$theme
  ))
  cat(sprintf("  %s\n", x$path))
  invisible(x)
}
