.qv_abort <- function(message, ...) {
  stop(sprintf(message, ...), call. = FALSE)
}

.qv_is_whole_number <- function(x) {
  is.numeric(x) && length(x) == 1L && is.finite(x) &&
    abs(x - round(x)) < sqrt(.Machine$double.eps)
}

.qv_validate_n_qubits <- function(n_qubits) {
  if (!.qv_is_whole_number(n_qubits) || n_qubits < 1L || n_qubits > 30L) {
    .qv_abort("`n_qubits` must be one whole number between 1 and 30.")
  }
  as.integer(n_qubits)
}

.qv_validate_qubits <- function(qubits, n_qubits, argument = "qubits") {
  if (!is.numeric(qubits) || length(qubits) < 1L || any(!is.finite(qubits)) ||
      any(abs(qubits - round(qubits)) >= sqrt(.Machine$double.eps))) {
    .qv_abort("`%s` must contain one or more whole-number qubit indices.", argument)
  }

  qubits <- as.integer(qubits)
  if (any(qubits < 1L | qubits > n_qubits)) {
    .qv_abort(
      "`%s` must use one-based indices between 1 and %d.",
      argument,
      n_qubits
    )
  }
  if (anyDuplicated(qubits)) {
    .qv_abort("`%s` cannot contain duplicate indices.", argument)
  }
  qubits
}

.qv_validate_matrix <- function(matrix, n_qubits, tolerance = 1e-10) {
  dimension <- 2^n_qubits
  if (!is.matrix(matrix) || !all(dim(matrix) == c(dimension, dimension)) ||
      !(is.numeric(matrix) || is.complex(matrix))) {
    .qv_abort(
      "A %d-qubit unitary must be a numeric or complex %d x %d matrix.",
      n_qubits,
      dimension,
      dimension
    )
  }

  matrix <- matrix(as.complex(matrix), nrow = dimension, ncol = dimension)
  identity <- diag(as.complex(1), dimension)
  error <- max(Mod(Conj(t(matrix)) %*% matrix - identity))
  if (!is.finite(error) || error > tolerance) {
    .qv_abort(
      "Gate matrix is not unitary within tolerance %.3g (error %.3g).",
      tolerance,
      error
    )
  }
  matrix
}

.qv_gate_matrix <- function(name, theta = NULL) {
  name <- toupper(name)
  switch(
    name,
    H = matrix(c(1, 1, 1, -1), 2L, 2L, byrow = TRUE) / sqrt(2),
    X = matrix(c(0, 1, 1, 0), 2L, 2L, byrow = TRUE),
    Y = matrix(c(0, -1i, 1i, 0), 2L, 2L, byrow = TRUE),
    Z = matrix(c(1, 0, 0, -1), 2L, 2L, byrow = TRUE),
    S = matrix(c(1, 0, 0, 1i), 2L, 2L, byrow = TRUE),
    T = matrix(c(1, 0, 0, exp(1i * pi / 4)), 2L, 2L, byrow = TRUE),
    RX = {
      ctheta <- cos(theta / 2)
      stheta <- sin(theta / 2)
      matrix(c(ctheta, -1i * stheta, -1i * stheta, ctheta), 2L, 2L, byrow = TRUE)
    },
    RY = {
      ctheta <- cos(theta / 2)
      stheta <- sin(theta / 2)
      matrix(c(ctheta, -stheta, stheta, ctheta), 2L, 2L, byrow = TRUE)
    },
    RZ = matrix(
      c(exp(-1i * theta / 2), 0, 0, exp(1i * theta / 2)),
      2L,
      2L,
      byrow = TRUE
    ),
    CX = matrix(
      c(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 0, 1,
        0, 0, 1, 0
      ),
      4L,
      4L,
      byrow = TRUE
    ),
    CZ = diag(as.complex(c(1, 1, 1, -1))),
    SWAP = matrix(
      c(
        1, 0, 0, 0,
        0, 0, 1, 0,
        0, 1, 0, 0,
        0, 0, 0, 1
      ),
      4L,
      4L,
      byrow = TRUE
    ),
    .qv_abort("Unknown gate `%s`.", name)
  )
}

.qv_state_nqubits <- function(state) {
  if (!is.atomic(state) || length(state) < 2L ||
      !(is.numeric(state) || is.complex(state))) {
    .qv_abort("A state must be a numeric or complex vector with at least two amplitudes.")
  }
  n_qubits <- log2(length(state))
  if (abs(n_qubits - round(n_qubits)) > sqrt(.Machine$double.eps)) {
    .qv_abort("Statevector length must be an exact power of two.")
  }
  as.integer(round(n_qubits))
}

.qv_validate_state <- function(state, n_qubits, tolerance = 1e-10) {
  if (.qv_state_nqubits(state) != n_qubits) {
    .qv_abort("Initial state length must equal 2^n_qubits (%d).", 2^n_qubits)
  }
  state <- as.complex(state)
  norm <- sum(Mod(state)^2)
  if (!is.finite(norm) || abs(norm - 1) > tolerance) {
    .qv_abort("Initial state must have unit norm; observed norm is %.12g.", norm)
  }
  state
}

.qv_basis_labels <- function(n_qubits, indices = seq.int(0, 2^n_qubits - 1)) {
  vapply(
    indices,
    function(index) {
      bits <- bitwAnd(bitwShiftR(as.integer(index), 0:(n_qubits - 1L)), 1L)
      paste0(rev(bits), collapse = "")
    },
    character(1)
  )
}

.qv_state_data_indices <- function(state, indices, tolerance) {
  n_qubits <- .qv_state_nqubits(state)
  state <- as.complex(state)
  indices <- as.integer(indices)
  amplitudes <- state[indices + 1L]
  probability <- Mod(amplitudes)^2
  data.frame(
    index = indices,
    basis = .qv_basis_labels(n_qubits, indices),
    real = Re(amplitudes),
    imaginary = Im(amplitudes),
    magnitude = Mod(amplitudes),
    probability = probability,
    phase = ifelse(probability > tolerance, Arg(amplitudes), NA_real_),
    stringsAsFactors = FALSE
  )
}

# Typography and mathematical-notation helpers shared by every renderer.
# Keeping these in one place prevents the static, animated, base, and ggplot2
# paths from quietly drifting apart.
.qv_ket <- function(label) {
  paste0("|", label, "\u27e9")
}

.qv_ket_expression <- function(label) {
  as.expression(lapply(label, function(value) {
    substitute(group("|", plain(state), rangle), list(state = value))
  }))
}

.qv_qubit_expression <- function(index) {
  as.expression(substitute(italic(q)[value], list(value = as.integer(index))))
}

.qv_qubit_text <- function(index) {
  digits <- strsplit(as.character(as.integer(index)), "", fixed = TRUE)[[1L]]
  subscripts <- c(
    "0" = "\u2080", "1" = "\u2081", "2" = "\u2082", "3" = "\u2083",
    "4" = "\u2084", "5" = "\u2085", "6" = "\u2086", "7" = "\u2087",
    "8" = "\u2088", "9" = "\u2089"
  )
  paste0("q", paste0(unname(subscripts[digits]), collapse = ""))
}

.qv_format_fixed <- function(x, digits = 3L) {
  threshold <- 0.5 * 10^(-digits)
  x[abs(x) < threshold] <- 0
  formatC(x, digits = digits, format = "f")
}

.qv_angle_plot_value <- function(theta, tolerance = 1e-10) {
  if (!is.numeric(theta) || length(theta) != 1L || !is.finite(theta)) {
    .qv_abort("Internal rotation angles must be one finite number.")
  }
  if (theta == 0) {
    return(0)
  }

  ratio <- theta / pi
  for (denominator in c(1L, 2L, 3L, 4L, 6L, 8L, 12L, 16L)) {
    candidate <- round(ratio * denominator)
    if (!is.finite(candidate) || candidate == 0 || abs(candidate) > 12) {
      next
    }
    numerator <- as.integer(candidate)
    close <- abs(theta - numerator * pi / denominator) <=
      tolerance * max(1, abs(theta))
    if (close) {
      numerator_expression <- if (numerator == 1L) {
        quote(pi)
      } else if (numerator == -1L) {
        quote(-pi)
      } else {
        substitute(coefficient * pi, list(coefficient = numerator))
      }
      if (denominator == 1L) {
        return(numerator_expression)
      }
      return(substitute(
        numerator_value / denominator_value,
        list(
          numerator_value = numerator_expression,
          denominator_value = denominator
        )
      ))
    }
  }

  magnitude <- abs(theta)
  if (magnitude < 1e-3 || magnitude >= 1e4) {
    exponent <- floor(log10(magnitude))
    mantissa <- signif(theta / 10^exponent, 3L)
    return(substitute(
      mantissa_value %*% 10^exponent_value,
      list(mantissa_value = mantissa, exponent_value = exponent)
    ))
  }
  signif(theta, 3L)
}

.qv_phase_labels <- function() {
  c("\u2212\u03c0", "\u2212\u03c0/2", "0", "\u03c0/2", "\u03c0")
}

.qv_phase_expression <- function() {
  expression(-pi, -pi / 2, 0, pi / 2, pi)
}

.qv_fit_cex <- function(
    label,
    available,
    cex = 1,
    minimum = 0.55,
    units = "user") {
  if (is.null(label) || !length(label)) {
    return(cex)
  }
  width <- suppressWarnings(graphics::strwidth(label, cex = cex, units = units))
  width <- max(width, na.rm = TRUE)
  if (!is.finite(width) || width <= available || width <= 0) {
    return(cex)
  }
  max(minimum, cex * available / width)
}

.qv_ellipsize_text <- function(label, available, cex, units = "user") {
  if (!is.character(label) || length(label) != 1L || is.na(label) ||
      !nzchar(label)) {
    return(label)
  }
  width <- suppressWarnings(graphics::strwidth(label, cex = cex, units = units))
  if (is.finite(width) && width <= available) {
    return(label)
  }

  characters <- strsplit(label, "", fixed = TRUE)[[1L]]
  for (keep in seq.int(length(characters) - 1L, 0L)) {
    prefix <- if (keep > 0L) {
      paste0(characters[seq_len(keep)], collapse = "")
    } else {
      ""
    }
    candidate <- paste0(prefix, "...")
    candidate_width <- suppressWarnings(
      graphics::strwidth(candidate, cex = cex, units = units)
    )
    if (is.finite(candidate_width) && candidate_width <= available) {
      return(candidate)
    }
  }
  ""
}

.qv_fill_figure <- function(background) {
  user <- graphics::par("usr")
  margins <- graphics::par("mai")
  graphics::rect(
    user[[1L]] - graphics::xinch(margins[[2L]]),
    user[[3L]] - graphics::yinch(margins[[1L]]),
    user[[2L]] + graphics::xinch(margins[[4L]]),
    user[[4L]] + graphics::yinch(margins[[3L]]),
    col = background,
    border = NA,
    xpd = NA
  )
  invisible(NULL)
}

.qv_title <- function(main, subtitle, palette, line = 1.55) {
  available <- diff(graphics::par("usr")[1:2]) * 0.94
  # Leave a small font-metric tolerance between devices. Cairo, Quartz, and
  # Windows can report slightly different widths for the same glyphs.
  fit_available <- available * 0.96
  pointsize <- max(1, graphics::par("ps"))
  title_minimum <- max(palette$title_cex * 0.78, 5 / pointsize)
  display_main <- .qv_ellipsize_text(main, fit_available, title_minimum)
  title_cex <- .qv_fit_cex(
    display_main,
    available = fit_available,
    cex = palette$title_cex,
    minimum = title_minimum
  )
  title_width <- suppressWarnings(
    max(graphics::strwidth(display_main, cex = title_cex, units = "user"), na.rm = TRUE)
  )
  if (is.finite(title_width) && title_width > available * (1 + 1e-8)) {
    .qv_abort(
      "The plotmath figure title is too wide for this device; shorten `main` or use a wider figure."
    )
  }
  graphics::title(
    main = display_main,
    line = line,
    font.main = 2,
    cex.main = title_cex
  )
  has_subtitle <- !is.null(subtitle) && length(subtitle) &&
    (!is.character(subtitle) || any(nzchar(subtitle)))
  if (has_subtitle) {
    subtitle_minimum <- max(palette$subtitle_cex * 0.86, 5 / pointsize)
    display_subtitle <- .qv_ellipsize_text(subtitle, fit_available, subtitle_minimum)
    subtitle_cex <- .qv_fit_cex(
      display_subtitle,
      available = fit_available,
      cex = palette$subtitle_cex,
      minimum = subtitle_minimum
    )
    subtitle_width <- suppressWarnings(
      max(
        graphics::strwidth(display_subtitle, cex = subtitle_cex, units = "user"),
        na.rm = TRUE
      )
    )
    if (is.finite(subtitle_width) && subtitle_width > available * (1 + 1e-8)) {
      .qv_abort(
        "The plotmath figure subtitle is too wide for this device; shorten `subtitle` or use a wider figure."
      )
    }
    graphics::mtext(
      display_subtitle,
      side = 3,
      line = 0.15,
      col = palette$muted,
      cex = subtitle_cex
    )
  }
  invisible(NULL)
}

#' Convert a quantum state or simulation result to tidy state data
#'
#' @param x A complex statevector or a `qv_result`.
#' @param include_zero Include amplitudes whose probability is effectively zero.
#' @param tolerance Numerical threshold used when identifying zero amplitudes.
#' @return A data frame whose columns are stable throughout qvivid 0.1.x:
#'   integer `index` (zero-based statevector index), character `basis`
#'   (highest-numbered qubit first), and numeric `real`, `imaginary`,
#'   `magnitude`, `probability`, and `phase`. `phase` is `NA` when probability
#'   does not exceed `tolerance`.
#' @export
state_data <- function(x, include_zero = TRUE, tolerance = 1e-14) {
  if (inherits(x, "qv_result")) {
    state <- x$state
  } else {
    state <- x
  }

  state <- as.complex(state)
  probability <- Mod(state)^2
  indices <- if (isTRUE(include_zero)) {
    seq_along(state) - 1L
  } else {
    which(probability > tolerance) - 1L
  }
  data <- .qv_state_data_indices(state, indices, tolerance)
  rownames(data) <- NULL
  data
}

.qv_theme_choices <- c("nature", "npj", "colorblind", "dark", "light", "mono")

.qv_match_theme <- function(theme) {
  match.arg(theme, .qv_theme_choices)
}

#' qvivid visual presets
#'
#' @param theme One of `"nature"`, `"npj"`, `"colorblind"`, `"dark"`,
#'   `"light"`, or `"mono"`.
#' @return A named style contract used by qvivid graphics and animations.
#' @export
qv_palette <- function(
    theme = c("nature", "npj", "colorblind", "dark", "light", "mono")) {
  theme <- .qv_match_theme(theme)
  shared <- list(
    name = theme,
    font_family = "sans",
    axis_ticks = TRUE,
    base_size = if (theme %in% c("nature", "mono")) 7 else if (theme == "npj") 8 else 9,
    screen_pointsize = if (theme %in% c("nature", "npj", "mono")) 10 else 11,
    title_cex = 1,
    subtitle_cex = 0.84,
    label_cex = 0.80,
    annotation_cex = 0.74,
    caption_cex = 0.74
  )
  style <- switch(
    theme,
    nature = list(
      background = "#FFFFFF",
      panel = "#FFFFFF",
      foreground = "#111111",
      muted = "#4D4D4D",
      grid = "#E6E6E6",
      grid_visible = FALSE,
      primary = "#3B6FB6",
      secondary = "#D55E00",
      accent = "#CC79A7",
      warm = "#E69F00",
      phase = c("#0072B2", "#6A51A3", "#CC79A7", "#E69F00", "#0072B2")
    ),
    npj = list(
      background = "#FFFFFF",
      panel = "#F7F9FA",
      foreground = "#152126",
      muted = "#52636B",
      grid = "#DCE4E7",
      grid_visible = FALSE,
      primary = "#008C95",
      secondary = "#3E5BA9",
      accent = "#B54891",
      warm = "#E69F00",
      phase = c("#007C91", "#4556A6", "#B54891", "#E69F00", "#007C91")
    ),
    colorblind = list(
      background = "#FFFFFF",
      panel = "#FFFFFF",
      foreground = "#111111",
      muted = "#525252",
      grid = "#E3E3E3",
      grid_visible = TRUE,
      primary = "#0072B2",
      secondary = "#E69F00",
      accent = "#CC79A7",
      warm = "#D55E00",
      phase = c("#0072B2", "#56B4E9", "#CC79A7", "#E69F00", "#0072B2")
    ),
    dark = list(
      background = "#080C18",
      panel = "#11182B",
      foreground = "#F7FAFC",
      muted = "#9AA7BE",
      grid = "#27324A",
      grid_visible = TRUE,
      primary = "#5EEAD4",
      secondary = "#A78BFA",
      accent = "#F472B6",
      warm = "#FBBF24",
      phase = c("#22D3EE", "#6366F1", "#EC4899", "#F59E0B", "#22D3EE")
    ),
    light = list(
      background = "#FFFFFF",
      panel = "#F5F7FB",
      foreground = "#101828",
      muted = "#667085",
      grid = "#D8DEE9",
      grid_visible = TRUE,
      primary = "#0F9F91",
      secondary = "#6D4BD1",
      accent = "#D12B7A",
      warm = "#B76E00",
      phase = c("#0891B2", "#4F46E5", "#DB2777", "#D97706", "#0891B2")
    ),
    mono = list(
      background = "#FFFFFF",
      panel = "#FFFFFF",
      foreground = "#111111",
      muted = "#5F5F5F",
      grid = "#D9D9D9",
      grid_visible = FALSE,
      primary = "#222222",
      secondary = "#666666",
      accent = "#999999",
      warm = "#444444",
      phase = c("#111111", "#686868", "#BEBEBE", "#686868", "#111111")
    )
  )
  c(shared, style)
}
