.qv_ggplot_globals <- utils::globalVariables(c(
  "basis",
  "phase_for_fill",
  "probability"
))

.qv_plot_data <- function(x, top, indices = NULL) {
  state <- if (inherits(x, "qv_result")) x$state else x
  .qv_state_nqubits(state)
  state <- as.complex(state)
  if (!is.null(indices)) {
    if (!is.numeric(indices) || any(!is.finite(indices)) ||
        any(indices < 0L | indices >= length(state)) ||
        any(abs(indices - round(indices)) >= sqrt(.Machine$double.eps)) ||
        anyDuplicated(indices)) {
      .qv_abort("Internal plot indices must be unique valid zero-based state indices.")
    }
    data <- .qv_state_data_indices(state, sort(as.integer(indices)), tolerance = 1e-14)
    rownames(data) <- NULL
    return(data)
  }
  if (is.null(top)) {
    top <- min(32L, length(state))
  }
  if (!.qv_is_whole_number(top) || top < 1L) {
    .qv_abort("`top` must be NULL or one positive whole number.")
  }
  top <- min(as.integer(top), length(state))
  probability <- Mod(state)^2
  selected <- if (top < length(state)) {
    sort(order(probability, decreasing = TRUE)[seq_len(top)] - 1L)
  } else {
    seq_along(state) - 1L
  }
  data <- .qv_state_data_indices(state, selected, tolerance = 1e-14)
  rownames(data) <- NULL
  data
}

.qv_state_upper <- function(probability) {
  maximum <- max(probability, 1e-12)
  min(1.08, max(0.05, maximum * 1.12))
}

.qv_phase_colors <- function(phase, palette, levels = 256L) {
  color_function <- grDevices::colorRampPalette(palette$phase)
  colors <- color_function(levels)
  phase <- ifelse(is.na(phase), 0, phase)
  indices <- floor((phase + pi) / (2 * pi) * (levels - 1L)) + 1L
  colors[pmax(1L, pmin(levels, indices))]
}

.qv_plot_state_base <- function(
    data,
    palette,
    main,
    subtitle = NULL,
    upper = NULL,
    show_legend = TRUE,
    restore_par = TRUE,
    compact = FALSE) {
  count <- nrow(data)
  if (is.null(upper)) upper <- .qv_state_upper(data$probability)
  upper <- max(upper, .qv_state_upper(data$probability))
  if (isTRUE(restore_par)) {
    old_parameters <- graphics::par(no.readonly = TRUE)
    on.exit(graphics::par(old_parameters), add = TRUE)
  }
  state_margins <- if (isTRUE(compact)) {
    c(if (count > 8L) 4.2 else 3.25, 3.35, 2.8, 3.05)
  } else {
    c(if (count > 8L) 6.2 else 4.8, 4.25, 3.55, 4.15)
  }
  graphics::par(
    bg = palette$background,
    fg = palette$foreground,
    col.axis = palette$muted,
    col.lab = palette$foreground,
    col.main = palette$foreground,
    mar = state_margins,
    family = palette$font_family
  )
  graphics::plot.new()
  graphics::plot.window(xlim = c(0.4, count + 0.6), ylim = c(0, upper), xaxs = "i")
  .qv_fill_figure(palette$background)

  ticks <- pretty(c(0, upper), n = 5L)
  ticks <- ticks[ticks >= 0 & ticks <= upper]
  if (isTRUE(palette$grid_visible)) {
    graphics::abline(h = ticks, col = palette$grid, lwd = 0.8)
  }
  fills <- .qv_phase_colors(data$phase, palette)
  graphics::rect(
    xleft = seq_len(count) - 0.37,
    ybottom = 0,
    xright = seq_len(count) + 0.37,
    ytop = data$probability,
    col = fills,
    border = NA
  )
  graphics::axis(
    1,
    at = seq_len(count),
    labels = .qv_ket_expression(data$basis),
    las = if (count > 8L) 2 else 1,
    tick = palette$axis_ticks,
    tck = -0.012,
    col.axis = palette$muted,
    cex.axis = if (count > 20L) 0.58 else palette$label_cex
  )
  graphics::axis(
    2,
    at = ticks,
    labels = format(ticks, trim = TRUE, digits = 3),
    las = 1,
    tick = palette$axis_ticks,
    tck = -0.012,
    col.axis = palette$muted
  )
  graphics::box(bty = "l", col = palette$foreground, lwd = 0.7)
  graphics::mtext(
    "Probability",
    side = 2,
    line = if (isTRUE(compact)) 2.05 else 2.65,
    col = palette$foreground,
    cex = palette$label_cex
  )
  graphics::mtext(
    "Basis state",
    side = 1,
    line = if (isTRUE(compact)) {
      if (count > 8L) 3.35 else 2.15
    } else if (count > 8L) {
      4.95
    } else {
      3.05
    },
    col = palette$foreground,
    cex = palette$label_cex
  )
  .qv_title(main, subtitle, palette, line = if (isTRUE(compact)) 1.05 else 1.45)

  if (count <= 16L) {
    labels <- ifelse(data$probability >= 0.0005, formatC(data$probability, 3, format = "f"), "")
    graphics::text(
      seq_len(count),
      pmin(data$probability + upper * 0.022, upper * 0.975),
      labels,
      col = palette$foreground,
      cex = palette$annotation_cex,
      xpd = NA
    )
  }

  if (isTRUE(show_legend)) {
    legend_colors <- .qv_phase_colors(c(-pi, -pi / 2, 0, pi / 2, pi), palette)
    graphics::legend(
      x = graphics::par("usr")[[2L]] + graphics::xinch(0.06),
      y = upper,
      legend = .qv_phase_expression(),
      fill = legend_colors,
      border = NA,
      title = "Phase",
      text.col = palette$muted,
      col = palette$muted,
      bty = "n",
      cex = palette$annotation_cex,
      xjust = 0,
      yjust = 1,
      xpd = NA
    )
  }
  invisible(data)
}

.qv_plot_state_ggplot <- function(data, palette, main, subtitle, theme) {
  phase <- ifelse(is.na(data$phase), 0, data$phase)
  data$phase_for_fill <- phase
  data$basis <- factor(data$basis, levels = data$basis)

  ggplot2::ggplot(
    data,
    ggplot2::aes(x = basis, y = probability, fill = phase_for_fill)
  ) +
    ggplot2::geom_col(width = 0.78) +
    ggplot2::scale_fill_gradientn(
      colors = palette$phase,
      limits = c(-pi, pi),
      breaks = c(-pi, -pi / 2, 0, pi / 2, pi),
      labels = .qv_phase_expression(),
      name = expression("Phase, " * arg(psi))
    ) +
    ggplot2::scale_x_discrete(labels = .qv_ket_expression) +
    ggplot2::scale_y_continuous(
      limits = c(0, .qv_state_upper(data$probability)),
      expand = ggplot2::expansion(mult = c(0, 0.02))
    ) +
    ggplot2::labs(
      title = main,
      subtitle = subtitle,
      x = "Basis state",
      y = "Probability"
    ) +
    theme_quantum(theme) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = if (nrow(data) > 12L) 90 else 0,
        hjust = if (nrow(data) > 12L) 1 else 0.5,
        vjust = 0.5
      )
    )
}

# Resolve the state-plot engine without making the default depend on which
# suggested packages happen to be installed.  The availability argument keeps
# this small contract directly testable without altering the user's library.
.qv_resolve_plot_engine <- function(engine, ggplot2_available = NULL) {
  engine <- match.arg(engine, c("base", "ggplot2", "auto"))

  # `auto` selected ggplot2 in early development versions.  Keep accepting the
  # value for compatibility, but make it a deterministic alias for the stable
  # base-graphics contract.
  if (identical(engine, "auto")) engine <- "base"

  if (identical(engine, "ggplot2")) {
    if (is.null(ggplot2_available)) {
      ggplot2_available <- requireNamespace("ggplot2", quietly = TRUE)
    }
    if (!isTRUE(ggplot2_available)) {
      .qv_abort("The ggplot2 engine requires the optional `ggplot2` package.")
    }
  }

  engine
}

#' Plot a quantum state
#'
#' Bar height represents probability and fill color represents complex phase.
#' The default base-graphics engine always draws immediately and returns the
#' plotted data invisibly, whether or not optional packages are installed.
#'
#' @param x A complex statevector or `qv_result`.
#' @param top Maximum number of basis states to display, selected by
#'   probability. Use `NULL` for an automatic limit.
#' @param theme A qvivid preset: `"nature"`, `"npj"`, `"colorblind"`,
#'   `"dark"`, `"light"`, or `"mono"`.
#' @param engine Rendering engine. `"base"` (the default) draws immediately
#'   and returns the plotted data invisibly. `"ggplot2"` returns a ggplot
#'   object for explicit printing or composition. `"auto"` is retained as a
#'   backward-compatible alias for `"base"`; it never changes according to
#'   the user's installed packages.
#' @param main Optional plot title.
#' @param subtitle Optional plot subtitle.
#' @return With `engine = "base"` (or `"auto"`), a data frame containing the
#'   plotted state data, invisibly. With `engine = "ggplot2"`, a ggplot object
#'   visibly; callers can print or compose it explicitly.
#' @export
plot_state <- function(
    x,
    top = NULL,
    theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
    engine = c("base", "ggplot2", "auto"),
    main = NULL,
    subtitle = NULL) {
  theme <- .qv_match_theme(theme)
  engine <- .qv_resolve_plot_engine(engine)

  data <- .qv_plot_data(x, top)
  palette <- qv_palette(theme)
  if (is.null(main)) {
    main <- if (inherits(x, "qv_result") && !is.null(x$circuit$name)) {
      x$circuit$name
    } else {
      "Quantum state"
    }
  }
  if (is.null(subtitle) && inherits(x, "qv_result")) {
    subtitle <- as.expression(substitute(
      qubits ~ "qubits" %.% backend ~ "backend" %.%
        "||" * psi * "||"^2 == state_norm,
      list(
        qubits = x$circuit$n_qubits,
        backend = x$backend,
        state_norm = formatC(sum(x$probabilities), format = "f", digits = 3)
      )
    ))
  }

  if (identical(engine, "ggplot2")) {
    return(.qv_plot_state_ggplot(data, palette, main, subtitle, theme))
  }
  .qv_plot_state_base(data, palette, main, subtitle)
}

#' A publication-oriented ggplot2 theme for quantum graphics
#'
#' @param theme A qvivid visual preset.
#' @param base_size Optional text size passed to ggplot2; the preset supplies
#'   its publication-oriented default when this is `NULL`.
#' @return A ggplot2 theme object.
#' @export
theme_quantum <- function(
    theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
    base_size = NULL) {
  theme <- .qv_match_theme(theme)
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    .qv_abort("`theme_quantum()` requires the optional `ggplot2` package.")
  }
  palette <- qv_palette(theme)
  if (is.null(base_size)) base_size <- palette$base_size
  if (!is.numeric(base_size) || length(base_size) != 1L || !is.finite(base_size) ||
      base_size <= 0) {
    .qv_abort("`base_size` must be NULL or one positive number.")
  }
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = palette$background, color = NA),
      panel.background = ggplot2::element_rect(fill = palette$background, color = NA),
      panel.grid.major = if (isTRUE(palette$grid_visible)) {
        ggplot2::element_line(color = palette$grid, linewidth = 0.35)
      } else {
        ggplot2::element_blank()
      },
      panel.grid.minor = ggplot2::element_blank(),
      axis.line = ggplot2::element_line(color = palette$foreground, linewidth = 0.35),
      axis.ticks = ggplot2::element_line(color = palette$foreground, linewidth = 0.35),
      text = ggplot2::element_text(color = palette$foreground, family = palette$font_family),
      plot.title = ggplot2::element_text(
        face = "bold",
        color = palette$foreground,
        size = base_size
      ),
      plot.subtitle = ggplot2::element_text(
        color = palette$muted,
        size = base_size * 0.88
      ),
      axis.text = ggplot2::element_text(
        color = palette$muted,
        size = base_size * 0.84
      ),
      axis.title = ggplot2::element_text(
        color = palette$foreground,
        size = base_size * 0.9
      ),
      legend.background = ggplot2::element_rect(fill = palette$background, color = NA),
      legend.key = ggplot2::element_rect(fill = palette$background, color = NA),
      legend.text = ggplot2::element_text(
        color = palette$muted,
        size = base_size * 0.78
      ),
      legend.title = ggplot2::element_text(
        color = palette$foreground,
        size = base_size * 0.84
      ),
      plot.margin = ggplot2::margin(12, 16, 12, 12)
    )
}

.qv_gate_plot_label <- function(operation) {
  if (identical(operation$type, "measure")) {
    return("measurement")
  }
  if (operation$name %in% c("RX", "RY", "RZ") &&
      !is.null(operation$parameters$theta)) {
    axis_symbol <- as.name(tolower(substring(operation$name, 2L, 2L)))
    theta <- .qv_angle_plot_value(operation$parameters$theta)
    return(as.expression(substitute(
      italic(R)[axis] * "(" * value * ")",
      list(axis = axis_symbol, value = theta)
    )))
  }
  operation$label
}

.qv_gate_display_label <- function(label, available, minimum_cex) {
  .qv_ellipsize_text(label, available, minimum_cex)
}

.qv_gate_box_geometry <- function(label, palette) {
  available <- 0.73
  minimum_cex <- 0.60
  display_label <- .qv_gate_display_label(label, available, minimum_cex)
  label_cex <- .qv_fit_cex(
    display_label,
    available = available,
    cex = palette$label_cex,
    minimum = minimum_cex
  )
  label_width <- max(graphics::strwidth(display_label, cex = label_cex, units = "user"))
  half_width <- min(0.42, max(0.13, label_width / 2 + 0.055))
  list(
    half_width = half_width,
    half_height = 0.21,
    label_cex = label_cex,
    label_width = label_width,
    display_label = display_label
  )
}

.qv_draw_gate_box <- function(x, y, label, color, palette) {
  geometry <- .qv_gate_box_geometry(label, palette)
  graphics::rect(
    x - geometry$half_width,
    y - geometry$half_height,
    x + geometry$half_width,
    y + geometry$half_height,
    col = palette$panel,
    border = color,
    lwd = 1.25
  )
  graphics::text(
    x,
    y,
    geometry$display_label,
    col = palette$foreground,
    cex = geometry$label_cex,
    font = if (is.character(geometry$display_label)) 2 else 1
  )
}

.qv_draw_measurement <- function(x, y, color, palette) {
  graphics::rect(
    x - 0.13,
    y - 0.21,
    x + 0.13,
    y + 0.21,
    col = palette$panel,
    border = color,
    lwd = 1.25
  )
  theta <- seq(0, pi, length.out = 61L)
  graphics::lines(
    x + 0.078 * cos(theta),
    y + 0.065 - 0.09 * sin(theta),
    col = palette$foreground,
    lwd = 1.05
  )
  graphics::segments(
    x,
    y + 0.06,
    x + 0.054,
    y - 0.012,
    col = palette$foreground,
    lwd = 1.05
  )
  graphics::points(x + 0.054, y - 0.012, pch = 16, cex = 0.18, col = palette$foreground)
  invisible(NULL)
}

# Draw a circuit while optionally preserving the current multi-figure layout.
.qv_plot_circuit_base <- function(
    circuit,
    highlight = NULL,
    theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
    main = NULL,
    restore_par = TRUE,
    compact = FALSE,
    subtitle = NULL) {
  .qv_validate_circuit(circuit)
  theme <- .qv_match_theme(theme)
  palette <- qv_palette(theme)
  operation_count <- length(circuit$operations)
  if (!is.null(highlight) &&
      (!.qv_is_whole_number(highlight) || highlight < 1L || highlight > operation_count)) {
    .qv_abort("`highlight` must be NULL or a valid one-based operation index.")
  }
  if (is.null(main)) {
    main <- if (is.null(circuit$name)) "Quantum circuit" else circuit$name
  }

  if (isTRUE(restore_par)) {
    old_parameters <- graphics::par(no.readonly = TRUE)
    on.exit(graphics::par(old_parameters), add = TRUE)
  }
  circuit_margins <- if (isTRUE(compact)) {
    c(1.45, 2.85, 2.75, 0.7)
  } else {
    c(2.05, 3.75, 3.45, 1.1)
  }
  graphics::par(
    bg = palette$background,
    fg = palette$foreground,
    col.axis = palette$muted,
    col.main = palette$foreground,
    mar = circuit_margins,
    family = palette$font_family
  )
  graphics::plot.new()
  xmax <- max(1L, operation_count)
  graphics::plot.window(
    xlim = c(0.15, xmax + 0.65),
    ylim = c(circuit$n_qubits + 0.82, 0.45),
    xaxs = "i",
    yaxs = "i"
  )
  .qv_fill_figure(palette$background)
  for (qubit in seq_len(circuit$n_qubits)) {
    graphics::segments(0.48, qubit, xmax + 0.45, qubit, col = palette$grid, lwd = 0.85)
    graphics::text(
      0.38,
      qubit,
      as.expression(substitute(italic(q)[index], list(index = qubit))),
      col = palette$muted,
      pos = 2,
      cex = palette$label_cex
    )
  }

  for (index in seq_along(circuit$operations)) {
    operation <- circuit$operations[[index]]
    color <- if (!is.null(highlight) && index == highlight) {
      palette$warm
    } else {
      palette$primary
    }
    qubits <- operation$qubits

    if (identical(operation$type, "measure")) {
      for (qubit in qubits) {
        .qv_draw_measurement(index, qubit, color, palette)
      }
    } else if (identical(operation$name, "CX")) {
      graphics::segments(index, min(qubits), index, max(qubits), col = color, lwd = 1.8)
      graphics::points(index, qubits[1L], pch = 16, col = color, cex = 1.05)
      graphics::symbols(
        index,
        qubits[2L],
        circles = 0.072,
        inches = FALSE,
        add = TRUE,
        bg = palette$background,
        fg = color
      )
      graphics::segments(index - 0.048, qubits[2L], index + 0.048, qubits[2L], col = color, lwd = 1.25)
      graphics::segments(index, qubits[2L] - 0.048, index, qubits[2L] + 0.048, col = color, lwd = 1.25)
    } else if (identical(operation$name, "CZ")) {
      graphics::segments(index, min(qubits), index, max(qubits), col = color, lwd = 1.8)
      graphics::points(rep(index, 2L), qubits, pch = 16, col = color, cex = 1.05)
    } else if (identical(operation$name, "SWAP")) {
      graphics::segments(index, min(qubits), index, max(qubits), col = color, lwd = 1.8)
      graphics::points(rep(index, 2L), qubits, pch = 4, col = color, cex = 1.2, lwd = 2)
    } else if (length(qubits) == 1L) {
      .qv_draw_gate_box(index, qubits, .qv_gate_plot_label(operation), color, palette)
    } else {
      graphics::segments(index, min(qubits), index, max(qubits), col = color, lwd = 1.4)
      for (qubit in qubits) {
        .qv_draw_gate_box(index, qubit, .qv_gate_plot_label(operation), color, palette)
      }
    }
    graphics::text(
      index,
      circuit$n_qubits + 0.62,
      index,
      col = palette$muted,
      cex = palette$annotation_cex
    )
  }

  graphics::mtext(
    "Operation",
    side = 1,
    line = if (isTRUE(compact)) 0.55 else 0.72,
    col = palette$muted,
    cex = palette$annotation_cex
  )

  if (is.null(subtitle)) {
    subtitle <- if (isTRUE(compact)) {
      sprintf(
        "%d q \u00b7 %d op%s \u00b7 depth %d",
        circuit$n_qubits,
        operation_count,
        if (operation_count == 1L) "" else "s",
        circuit_depth(circuit)
      )
    } else {
      sprintf(
        "%d qubits \u00b7 %d operations \u00b7 depth %d",
        circuit$n_qubits,
        operation_count,
        circuit_depth(circuit)
      )
    }
  }
  .qv_title(
    main,
    subtitle,
    palette,
    line = if (isTRUE(compact)) 1.02 else 1.4
  )
  invisible(circuit)
}

#' Plot a quantum circuit
#'
#' @param circuit A `qv_circuit`.
#' @param highlight Optional one-based operation index to emphasize.
#' @param theme A qvivid visual preset.
#' @param main Optional title.
#' @param subtitle Optional subtitle; the default reports qubits, operations,
#'   and circuit depth.
#' @return The circuit invisibly.
#' @export
plot_circuit <- function(
    circuit,
    highlight = NULL,
    theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
    main = NULL,
    subtitle = NULL) {
  .qv_plot_circuit_base(
    circuit,
    highlight,
    theme,
    main,
    restore_par = TRUE,
    subtitle = subtitle
  )
}

.qv_frame_plot_label <- function(result, frame) {
  if (frame$step < 1L) return("Initial")
  operation <- result$circuit$operations[[frame$step]]
  .qv_gate_plot_label(operation)
}

.qv_execution_state_title <- function(result, frame) {
  label <- .qv_frame_plot_label(result, frame)
  if (frame$step < 1L) return("Initial state")
  if (is.expression(label)) {
    return(as.expression(substitute(
      "State after" ~~ gate,
      list(gate = label[[1L]])
    )))
  }
  paste("State after", label)
}

.qv_draw_execution <- function(
    result,
    frame,
    top,
    theme,
    main,
    subtitle,
    state_indices = NULL,
    state_upper = NULL) {
  old_parameters <- graphics::par(no.readonly = TRUE)
  on.exit({
    try(graphics::layout(1), silent = TRUE)
    try(graphics::par(old_parameters), silent = TRUE)
  }, add = TRUE)
  compact <- graphics::par("din")[[2L]] < 4.5
  panel_heights <- if (isTRUE(compact)) c(0.45, 0.55) else c(0.42, 0.58)
  graphics::layout(matrix(1:2, ncol = 1L), heights = panel_heights)
  .qv_plot_circuit_base(
    result$circuit,
    highlight = if (frame$step > 0L) frame$step else NULL,
    theme = theme,
    main = if (is.null(main)) {
      if (is.null(result$circuit$name)) "Circuit execution" else result$circuit$name
    } else {
      main
    },
    restore_par = FALSE,
    compact = compact
  )

  if (is.null(subtitle)) {
    subtitle <- sprintf(
      "Step %d of %d \u00b7 bar height = probability \u00b7 fill = phase",
      frame$step,
      length(result$circuit$operations)
    )
  }
  .qv_plot_state_base(
    .qv_plot_data(frame$state, top, indices = state_indices),
    qv_palette(theme),
    main = .qv_execution_state_title(result, frame),
    subtitle = subtitle,
    upper = state_upper,
    restore_par = FALSE,
    compact = compact
  )
  invisible(result)
}

#' Plot a circuit and its state at one execution step
#'
#' @param result A `qv_result`. A recorded trajectory is required when `step`
#'   selects anything other than the final state.
#' @param step Optional recorded step number. Defaults to the final step.
#' @param top Maximum number of basis states shown.
#' @param theme A qvivid visual preset.
#' @param main Optional title for the circuit panel.
#' @param subtitle Optional subtitle for the state panel.
#' @return The result invisibly.
#' @export
plot_execution <- function(
    result,
    step = NULL,
    top = NULL,
    theme = c("nature", "npj", "colorblind", "dark", "light", "mono"),
    main = NULL,
    subtitle = NULL) {
  if (!inherits(result, "qv_result")) {
    .qv_abort("`result` must be a `qv_result`.")
  }
  theme <- .qv_match_theme(theme)
  if (is.null(result$trajectory)) {
    if (!is.null(step)) {
      .qv_abort("Selecting `step` requires a simulation recorded with `record = TRUE`.")
    }
    frame <- list(
      step = length(result$circuit$operations),
      label = "Final",
      state = result$state
    )
  } else {
    maximum_step <- length(result$trajectory) - 1L
    if (is.null(step)) step <- maximum_step
    if (!.qv_is_whole_number(step) || step < 0L || step > maximum_step) {
      .qv_abort("`step` must be a recorded whole number between 0 and %d.", maximum_step)
    }
    frame <- result$trajectory[[as.integer(step) + 1L]]
  }

  .qv_draw_execution(result, frame, top, theme, main, subtitle)
}

#' @export
plot.qv_circuit <- function(x, ...) {
  plot_circuit(x, ...)
}

#' @export
plot.qv_result <- function(x, ...) {
  plot_state(x, ...)
}
