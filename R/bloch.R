.qv_clean_bloch_value <- function(x, tolerance = 1e-14) {
  x[abs(x) < tolerance] <- 0
  x
}

#' Calculate the Bloch vector of one qubit
#'
#' For a qubit inside a multi-qubit pure state, this function computes the
#' reduced single-qubit state without materializing a density matrix. The
#' Bloch-vector radius contracts below one when the selected qubit is mixed,
#' including when it is entangled with the rest of the register.
#'
#' @param x A complex statevector or a `qv_result`.
#' @param qubit A one-based qubit index.
#' @return A `qv_bloch` object with Cartesian coordinates, radius, and purity.
#' @export
bloch_vector <- function(x, qubit = 1L) {
  result <- if (inherits(x, "qv_result")) x else NULL
  state <- if (is.null(result)) x else result$state
  n_qubits <- .qv_state_nqubits(state)
  state <- .qv_validate_state(state, n_qubits)
  qubit <- .qv_validate_qubits(qubit, n_qubits, argument = "qubit")
  if (length(qubit) != 1L) {
    .qv_abort("`qubit` must be a one-based qubit index.")
  }

  stride <- 2^(qubit - 1L)
  block_starts <- seq.int(0, length(state) - 1L, by = 2L * stride)
  indices0 <- rep(block_starts, each = stride) +
    rep(seq.int(0, stride - 1L), times = length(block_starts)) + 1L
  indices1 <- indices0 + stride
  amplitude0 <- state[indices0]
  amplitude1 <- state[indices1]
  coherence <- sum(Conj(amplitude0) * amplitude1)

  coordinates <- .qv_clean_bloch_value(c(
    x = 2 * Re(coherence),
    y = 2 * Im(coherence),
    z = sum(Mod(amplitude0)^2) - sum(Mod(amplitude1)^2)
  ))
  radius <- sqrt(sum(coordinates^2))
  if (radius > 1 && radius < 1 + 1e-10) {
    radius <- 1
  }
  purity <- (1 + radius^2) / 2

  label <- if (!is.null(result) && !is.null(result$circuit$name)) {
    result$circuit$name
  } else {
    sprintf("q%d", qubit)
  }
  structure(
    list(
      x = unname(coordinates[["x"]]),
      y = unname(coordinates[["y"]]),
      z = unname(coordinates[["z"]]),
      radius = unname(radius),
      purity = unname(purity),
      qubit = as.integer(qubit),
      n_qubits = n_qubits,
      label = label
    ),
    class = "qv_bloch"
  )
}

#' Calculate a recorded Bloch trajectory
#'
#' @param result A `qv_result` created with `record = TRUE`.
#' @param qubit A one-based qubit index.
#' @return A data frame with one Bloch vector per recorded execution step.
#' @export
trajectory_bloch <- function(result, qubit = 1L) {
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

  pieces <- lapply(result$trajectory, function(frame) {
    vector <- bloch_vector(frame$state, qubit = qubit)
    data.frame(
      step = frame$step,
      label = frame$label,
      qubit = vector$qubit,
      n_qubits = vector$n_qubits,
      x = vector$x,
      y = vector$y,
      z = vector$z,
      radius = vector$radius,
      purity = vector$purity,
      stringsAsFactors = FALSE
    )
  })
  output <- do.call(rbind, pieces)
  rownames(output) <- NULL
  class(output) <- c("qv_bloch_trajectory", "data.frame")
  output
}

.qv_bloch_from_trajectory <- function(x) {
  if (!nrow(x)) {
    .qv_abort("A Bloch trajectory must contain at least one row.")
  }
  row <- x[nrow(x), , drop = FALSE]
  structure(
    list(
      x = row$x[[1L]],
      y = row$y[[1L]],
      z = row$z[[1L]],
      radius = row$radius[[1L]],
      purity = row$purity[[1L]],
      qubit = row$qubit[[1L]],
      n_qubits = row$n_qubits[[1L]],
      label = row$label[[1L]]
    ),
    class = "qv_bloch"
  )
}

.qv_project_bloch <- function(points, view = "perspective") {
  if (is.null(dim(points))) {
    points <- matrix(points, nrow = 1L)
  } else {
    points <- as.matrix(points)
  }
  if (ncol(points) != 3L) {
    .qv_abort("Internal Bloch coordinates must have three columns.")
  }
  x <- points[, 1L]
  y <- points[, 2L]
  z <- points[, 3L]

  if (identical(view, "xy")) {
    return(data.frame(u = x, v = y, depth = 0))
  }
  if (identical(view, "xz")) {
    return(data.frame(u = x, v = z, depth = 0))
  }
  if (identical(view, "yz")) {
    return(data.frame(u = y, v = z, depth = 0))
  }

  azimuth <- 40 * pi / 180
  elevation <- 25 * pi / 180
  data.frame(
    u = -sin(azimuth) * x + cos(azimuth) * y,
    v = -sin(elevation) * cos(azimuth) * x -
      sin(elevation) * sin(azimuth) * y +
      cos(elevation) * z,
    depth = cos(elevation) * cos(azimuth) * x +
      cos(elevation) * sin(azimuth) * y +
      sin(elevation) * z
  )
}

.qv_bloch_axes <- function() {
  list(
    X = rbind(c(-1, 0, 0), c(1, 0, 0)),
    Y = rbind(c(0, -1, 0), c(0, 1, 0)),
    Z = rbind(c(0, 0, -1), c(0, 0, 1))
  )
}

.qv_bloch_label <- function(axis_name, positive) {
  switch(
    axis_name,
    X = if (isTRUE(positive)) {
      expression(italic(x) ~~ group("|", "+", rangle))
    } else {
      expression(group("|", -phantom(0), rangle))
    },
    Y = if (isTRUE(positive)) {
      expression(italic(y) ~~ group("|", "+" * italic(i), rangle))
    } else {
      expression(group("|", "-" * italic(i), rangle))
    },
    Z = if (isTRUE(positive)) {
      expression(italic(z) ~~ group("|", 0, rangle))
    } else {
      expression(group("|", 1, rangle))
    }
  )
}

.qv_text_bbox <- function(label, x, y, adj, cex, padding = 0) {
  width <- max(graphics::strwidth(label, cex = cex, units = "user"))
  height <- max(graphics::strheight(label, cex = cex, units = "user"))
  c(
    left = x - adj[[1L]] * width - padding,
    right = x + (1 - adj[[1L]]) * width + padding,
    bottom = y - adj[[2L]] * height - padding,
    top = y + (1 - adj[[2L]]) * height + padding
  )
}

.qv_boxes_overlap <- function(first, second) {
  first[["left"]] < second[["right"]] &&
    first[["right"]] > second[["left"]] &&
    first[["bottom"]] < second[["top"]] &&
    first[["top"]] > second[["bottom"]]
}

.qv_bloch_label_layout <- function(
    view,
    cex,
    xlim = c(-1.48, 1.48),
    ylim = c(-1.34, 1.34)) {
  axes <- .qv_bloch_axes()
  axes_to_draw <- switch(
    view,
    xy = c("X", "Y"),
    xz = c("X", "Z"),
    yz = c("Y", "Z"),
    names(axes)
  )
  placements <- list()
  boxes <- list()

  for (axis_name in axes_to_draw) {
    projected <- .qv_project_bloch(axes[[axis_name]], view)
    for (row in c(2L, 1L)) {
      endpoint <- c(projected$u[[row]], projected$v[[row]])
      endpoint_radius <- sqrt(sum(endpoint^2))
      direction <- endpoint / endpoint_radius
      adj <- c(
        if (direction[[1L]] > 0.16) 0 else if (direction[[1L]] < -0.16) 1 else 0.5,
        if (direction[[2L]] > 0.16) 0 else if (direction[[2L]] < -0.16) 1 else 0.5
      )
      label <- .qv_bloch_label(axis_name, positive = row == 2L)
      selected <- NULL
      pointsize <- max(1, graphics::par("ps"))
      minimum_scale <- min(1, max(0.88, 5 / pointsize / cex))
      scales <- unique(c(1, 0.96, 0.92, minimum_scale))
      scales <- scales[scales >= minimum_scale]
      tangent <- c(-direction[[2L]], direction[[1L]])
      for (scale in scales) {
        candidate_cex <- cex * scale
        for (attempt in 0:8) {
          label_radius <- 1.065 + attempt * 0.03
          for (offset in c(0, 0.04, -0.04, 0.08, -0.08, 0.12, -0.12)) {
            anchor <- direction * label_radius + tangent * offset
            box <- .qv_text_bbox(
              label,
              anchor[[1L]],
              anchor[[2L]],
              adj,
              candidate_cex,
              0.012
            )
            inside <- box[["left"]] >= xlim[[1L]] + 0.015 &&
              box[["right"]] <= xlim[[2L]] - 0.015 &&
              box[["bottom"]] >= ylim[[1L]] + 0.015 &&
              box[["top"]] <= ylim[[2L]] - 0.015
            collision <- any(vapply(
              boxes,
              function(other) .qv_boxes_overlap(box, other),
              logical(1)
            ))
            if (inside && !collision) {
              selected <- list(
                axis = axis_name,
                positive = row == 2L,
                label = label,
                endpoint = endpoint,
                leader = direction * 1.015,
                x = anchor[[1L]],
                y = anchor[[2L]],
                adj = adj,
                cex = candidate_cex,
                bbox = box
              )
              break
            }
          }
          if (!is.null(selected)) break
        }
        if (!is.null(selected)) break
      }
      if (is.null(selected)) {
        .qv_abort(
          "Could not place the %s Bloch-axis label without overlap; use a larger figure.",
          axis_name
        )
      }
      placements[[length(placements) + 1L]] <- selected
      boxes[[length(boxes) + 1L]] <- selected$bbox
    }
  }
  placements
}

.qv_draw_bloch_curve <- function(points, palette, view) {
  projected <- .qv_project_bloch(points, view)
  if (!identical(view, "perspective")) {
    graphics::lines(
      projected$u,
      projected$v,
      col = grDevices::adjustcolor(palette$muted, alpha.f = 0.46),
      lwd = 0.75,
      lty = 3
    )
    return(invisible(NULL))
  }

  from <- seq_len(nrow(projected) - 1L)
  depth <- (projected$depth[from] + projected$depth[from + 1L]) / 2
  back <- from[depth < 0]
  front <- from[depth >= 0]
  if (length(back)) {
    graphics::segments(
      projected$u[back],
      projected$v[back],
      projected$u[back + 1L],
      projected$v[back + 1L],
      col = grDevices::adjustcolor(palette$muted, alpha.f = 0.24),
      lwd = 0.7,
      lty = 3
    )
  }
  if (length(front)) {
    graphics::segments(
      projected$u[front],
      projected$v[front],
      projected$u[front + 1L],
      projected$v[front + 1L],
      col = grDevices::adjustcolor(palette$muted, alpha.f = 0.52),
      lwd = 0.85
    )
  }
  invisible(NULL)
}

.qv_bloch_trail_segments <- function(projected) {
  if (nrow(projected) < 2L) {
    return(data.frame(
      u0 = numeric(), v0 = numeric(), u1 = numeric(), v1 = numeric(),
      front = logical()
    ))
  }

  pieces <- vector("list", nrow(projected) - 1L)
  for (index in seq_len(nrow(projected) - 1L)) {
    first <- projected[index, , drop = FALSE]
    second <- projected[index + 1L, , drop = FALSE]
    crosses_surface <- first$depth[[1L]] * second$depth[[1L]] < 0
    if (!crosses_surface) {
      pieces[[index]] <- data.frame(
        u0 = first$u,
        v0 = first$v,
        u1 = second$u,
        v1 = second$v,
        front = mean(c(first$depth, second$depth)) >= 0
      )
      next
    }

    fraction <- first$depth[[1L]] /
      (first$depth[[1L]] - second$depth[[1L]])
    crossing_u <- first$u[[1L]] + fraction * (second$u[[1L]] - first$u[[1L]])
    crossing_v <- first$v[[1L]] + fraction * (second$v[[1L]] - first$v[[1L]])
    pieces[[index]] <- rbind(
      data.frame(
        u0 = first$u,
        v0 = first$v,
        u1 = crossing_u,
        v1 = crossing_v,
        front = first$depth[[1L]] >= 0
      ),
      data.frame(
        u0 = crossing_u,
        v0 = crossing_v,
        u1 = second$u,
        v1 = second$v,
        front = second$depth[[1L]] >= 0
      )
    )
  }
  output <- do.call(rbind, pieces)
  rownames(output) <- NULL
  output
}

.qv_draw_bloch_trail_layer <- function(projected, palette, view, layer) {
  layer <- match.arg(layer, c("back", "front"))
  if (!identical(view, "perspective") && identical(layer, "back")) {
    return(invisible(NULL))
  }

  segments <- .qv_bloch_trail_segments(projected)
  selected_segments <- if (identical(view, "perspective")) {
    segments$front == identical(layer, "front")
  } else {
    rep(TRUE, nrow(segments))
  }
  if (any(selected_segments)) {
    graphics::segments(
      segments$u0[selected_segments],
      segments$v0[selected_segments],
      segments$u1[selected_segments],
      segments$v1[selected_segments],
      col = grDevices::adjustcolor(
        palette$secondary,
        alpha.f = if (identical(layer, "front")) 0.72 else 0.25
      ),
      lwd = if (identical(layer, "front")) 1.7 else 0.9,
      lty = if (identical(layer, "front")) 1 else 3
    )
  }

  selected_points <- if (identical(view, "perspective")) {
    (projected$depth >= 0) == identical(layer, "front")
  } else {
    rep(TRUE, nrow(projected))
  }
  if (any(selected_points)) {
    graphics::points(
      projected$u[selected_points],
      projected$v[selected_points],
      pch = 21,
      bg = palette$background,
      col = grDevices::adjustcolor(
        palette$secondary,
        alpha.f = if (identical(layer, "front")) 0.82 else 0.30
      ),
      cex = if (identical(layer, "front")) 0.55 else 0.42,
      lwd = 0.8
    )
  }
  invisible(NULL)
}

.qv_plot_bloch_base <- function(
    bloch,
    trail,
    palette,
    view,
    main,
    subtitle,
    restore_par = TRUE) {
  if (isTRUE(restore_par)) {
    old_parameters <- graphics::par(no.readonly = TRUE)
    on.exit(graphics::par(old_parameters), add = TRUE)
  }
  graphics::par(
    bg = palette$background,
    fg = palette$foreground,
    col.main = palette$foreground,
    mar = c(3.25, 1.05, 3.65, 1.05),
    family = palette$font_family
  )
  graphics::plot.new()
  graphics::plot.window(
    xlim = c(-1.48, 1.48),
    ylim = c(-1.34, 1.34),
    xaxs = "i",
    yaxs = "i",
    asp = 1
  )
  .qv_fill_figure(palette$background)

  projected_trail <- NULL
  if (!is.null(trail) && nrow(trail)) {
    projected_trail <- .qv_project_bloch(
      as.matrix(trail[, c("x", "y", "z"), drop = FALSE]),
      view
    )
    .qv_draw_bloch_trail_layer(projected_trail, palette, view, "back")
  }

  theta <- seq(0, 2 * pi, length.out = 361L)
  graphics::polygon(
    cos(theta),
    sin(theta),
    col = grDevices::adjustcolor(palette$primary, alpha.f = 0.065),
    border = NA
  )

  curves <- list(
    cbind(cos(theta), sin(theta), 0),
    cbind(cos(theta), 0, sin(theta)),
    cbind(0, cos(theta), sin(theta))
  )
  for (curve in curves) {
    .qv_draw_bloch_curve(curve, palette, view)
  }

  axes <- .qv_bloch_axes()
  axes_to_draw <- switch(
    view,
    xy = c("X", "Y"),
    xz = c("X", "Z"),
    yz = c("Y", "Z"),
    names(axes)
  )
  for (axis_name in axes_to_draw) {
    projected <- .qv_project_bloch(axes[[axis_name]], view)
    for (row in seq_len(2L)) {
      front <- projected$depth[[row]] >= 0
      graphics::segments(
        0,
        0,
        projected$u[[row]],
        projected$v[[row]],
        col = grDevices::adjustcolor(
          palette$foreground,
          alpha.f = if (front) 0.44 else 0.22
        ),
        lwd = if (front) 0.75 else 0.6,
        lty = 3
      )
    }
  }

  user_bounds <- graphics::par("usr")
  label_layout <- .qv_bloch_label_layout(
    view,
    cex = palette$label_cex,
    xlim = user_bounds[1:2],
    ylim = user_bounds[3:4]
  )
  for (placement in label_layout) {
    graphics::segments(
      placement$endpoint[[1L]],
      placement$endpoint[[2L]],
      placement$leader[[1L]],
      placement$leader[[2L]],
      col = grDevices::adjustcolor(palette$muted, alpha.f = 0.34),
      lwd = 0.55
    )
    graphics::text(
      placement$x,
      placement$y,
      labels = placement$label,
      adj = placement$adj,
      col = palette$foreground,
      cex = placement$cex
    )
  }

  if (!is.null(projected_trail)) {
    .qv_draw_bloch_trail_layer(projected_trail, palette, view, "front")
  }

  endpoint <- .qv_project_bloch(c(bloch$x, bloch$y, bloch$z), view)
  if (bloch$radius > 1e-12) {
    graphics::arrows(
      0,
      0,
      endpoint$u,
      endpoint$v,
      length = 0.085,
      angle = 24,
      col = grDevices::adjustcolor(
        palette$primary,
        alpha.f = if (endpoint$depth[[1L]] >= 0) 1 else 0.68
      ),
      lwd = 2.35,
      lty = if (endpoint$depth[[1L]] >= 0) 1 else 3
    )
    graphics::points(
      endpoint$u,
      endpoint$v,
      pch = 21,
      bg = palette$primary,
      col = palette$foreground,
      cex = 0.95,
      lwd = 0.65
    )
    graphics::points(0, 0, pch = 16, col = palette$foreground, cex = 0.28)
  } else {
    graphics::symbols(
      0,
      0,
      circles = 0.038,
      inches = FALSE,
      add = TRUE,
      bg = palette$background,
      fg = palette$primary
    )
    graphics::points(0, 0, pch = 16, col = palette$foreground, cex = 0.23)
  }
  graphics::lines(cos(theta), sin(theta), col = palette$foreground, lwd = 0.9)

  .qv_title(main, subtitle, palette, line = 1.5)
  coordinates <- as.numeric(.qv_format_fixed(c(bloch$x, bloch$y, bloch$z)))
  radius <- as.numeric(.qv_format_fixed(bloch$radius))
  purity <- as.numeric(.qv_format_fixed(bloch$purity))
  graphics::mtext(
    substitute(
      bold(r) == group("(", list(x, y, z), ")"),
      list(
        x = formatC(coordinates[[1L]], format = "f", digits = 3),
        y = formatC(coordinates[[2L]], format = "f", digits = 3),
        z = formatC(coordinates[[3L]], format = "f", digits = 3)
      )
    ),
    side = 1,
    line = 0.45,
    col = palette$muted,
    cex = palette$caption_cex
  )
  graphics::mtext(
    substitute(
      "||" * bold(r) * "||"[2] == radius_value ~~
        plain(Tr) * group("(", rho^2, ")") == purity_value,
      list(
        radius_value = formatC(radius, format = "f", digits = 3),
        purity_value = formatC(purity, format = "f", digits = 3)
      )
    ),
    side = 1,
    line = 1.35,
    col = palette$muted,
    cex = palette$caption_cex
  )
  invisible(bloch)
}

#' Plot a Bloch sphere or planar Bloch view
#'
#' @param x A statevector, `qv_result`, `qv_bloch`, or
#'   `qv_bloch_trajectory`.
#' @param qubit A one-based qubit index when `x` contains a quantum state.
#' @param theme A qvivid visual preset.
#' @param view A perspective sphere or one of the `"xy"`, `"xz"`, and
#'   `"yz"` projections.
#' @param trajectory Draw the complete recorded path when `x` is a
#'   `qv_result`.
#' @param main,subtitle Optional title and subtitle.
#' @return The plotted `qv_bloch` object invisibly.
#' @export
plot_bloch <- function(
    x,
    qubit = 1L,
    theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
    view = c("perspective", "xy", "xz", "yz"),
    trajectory = FALSE,
    main = NULL,
    subtitle = NULL) {
  theme <- .qv_match_theme(theme)
  view <- match.arg(view)
  if (!is.logical(trajectory) || length(trajectory) != 1L || is.na(trajectory)) {
    .qv_abort("`trajectory` must be TRUE or FALSE.")
  }

  trail <- NULL
  if (inherits(x, "qv_bloch_trajectory")) {
    trail <- x
    bloch <- .qv_bloch_from_trajectory(x)
  } else if (inherits(x, "qv_bloch")) {
    bloch <- x
  } else {
    bloch <- bloch_vector(x, qubit = qubit)
    if (isTRUE(trajectory)) {
      if (!inherits(x, "qv_result")) {
        .qv_abort("`trajectory = TRUE` requires a recorded `qv_result`.")
      }
      trail <- trajectory_bloch(x, qubit = qubit)
    }
  }

  if (is.null(main)) {
    main <- if (inherits(x, "qv_result") && !is.null(x$circuit$name)) {
      x$circuit$name
    } else {
      "Bloch sphere"
    }
  }
  if (is.null(subtitle)) {
    subtitle <- if (inherits(x, "qv_result") && !is.null(x$circuit$name)) {
      as.expression(substitute(
        "Bloch sphere" %.% "reduced state of" ~ italic(q)[index],
        list(index = bloch$qubit)
      ))
    } else {
      as.expression(substitute(
        "Reduced state of" ~ italic(q)[index],
        list(index = bloch$qubit)
      ))
    }
  }
  .qv_plot_bloch_base(
    bloch,
    trail,
    qv_palette(theme),
    view,
    main,
    subtitle,
    restore_par = TRUE
  )
}

#' @export
plot.qv_bloch <- function(x, ...) {
  plot_bloch(x, ...)
}

#' @export
print.qv_bloch <- function(x, ...) {
  state_type <- if (x$radius > 1 - 1e-10) {
    "pure"
  } else if (x$radius < 1e-10) {
    "maximally mixed"
  } else {
    "mixed"
  }
  cat("<qv_bloch>\n")
  cat(sprintf("  q%d of %d | %s reduced state\n", x$qubit, x$n_qubits, state_type))
  cat(sprintf("  x %.6f | y %.6f | z %.6f\n", x$x, x$y, x$z))
  cat(sprintf("  radius %.6f | purity %.6f\n", x$radius, x$purity))
  invisible(x)
}
