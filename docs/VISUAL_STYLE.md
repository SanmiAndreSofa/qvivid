# Visual style and export policy

qvivid applies the same visual rules to static plots and animation frames. A
theme preset supplies the background, structural colors, semantic accents,
cyclic phase palette, typography, axes, circuit marks, and frame styling. This
keeps a state or circuit visually consistent when it moves between a screen,
GIF, and manuscript figure.

## Presets

| Preset | Intended use | Appearance |
|---|---|---|
| `nature` | Manuscript figures and the default static output | White background, black text, visible axes and ticks, no background grid, and restrained accessible accents |
| `npj` | Digital figures and explanatory animations | White or soft-neutral background with teal, blue, magenta, and amber accents |
| `colorblind` | General accessible communication | Okabe-Ito-derived high-contrast accents and a restrained cyclic phase scale |
| `dark` | Lectures, presentations, and GIFs | Deep neutral background with high-luminance state and circuit colors |
| `light` | Reports, notebooks, and dashboards | Soft neutral background with subtle grid structure |
| `mono` | Grayscale printing and preprint review | Black, white, and gray with an explicit phase legend; a redundant non-color phase encoding remains planned |

Every plotting and animation function accepts the same `theme` argument:

```r
plot_state(result, theme = "nature")
plot_circuit(circuit, theme = "npj")
plot_execution(result, step = 2, theme = "colorblind")
animate_state(result, "run.gif", theme = "dark")
animate_bloch(result, "bloch.gif", theme = "npj")
```

`qv_palette()` returns the named colors and type settings used by a preset, so
additional plots can follow the package styling without copying internal
values.

## Typography and notation

Each figure uses one portable sans-serif family and explicit point sizes.
Nature-oriented exports target the public 5-7 point guidance at final size.
Screen and GIF text scales with the output dimensions, so print settings do not
make instructional graphics too small to read.

Mathematical labels use R plotmath when a portable mathematical glyph is
required. This includes:

- Dirac notation such as `|0⟩`, `|1⟩`, `|+⟩`, and `|-i⟩`;
- one-based qubit indices with subscripts;
- phase ticks at `-π`, `-π/2`, `0`, `π/2`, and `π`;
- the Bloch-vector norm `‖r‖₂` and purity `Tr(ρ²)`;
- rotation-gate labels with x, y, or z subscripts.

Values smaller than half the displayed precision are set to zero before text
formatting. This prevents labels such as `-0.000`.

## Layout requirements

- Title fitting uses measured rendered width rather than character count.
- Bloch-state labels sit on a measured annotation ring outside the sphere.
  Their bounding boxes must stay inside the safe figure area and must not
  overlap.
- Leader lines join external labels to projected three-dimensional axis
  endpoints without placing text over the sphere.
- Bloch coordinates and purity use two centered rows to avoid clipping on
  narrow devices.
- Phase legends use reserved space outside the data panel and never cover a
  bar.
- Gate boxes expand to fit measured labels while retaining a compact standard
  width for short gates. A label that cannot fit in one operation column is
  shortened before it can cross an adjacent gate.
- Perspective Bloch trails are split at the projected hemisphere boundary;
  rear segments are muted and front segments are emphasized.
- Circuit, state, execution, and Bloch renderers are tested at compact output
  sizes.

## Nature-oriented output

The `nature` preset follows the public [Nature research figure
specifications](https://research-figure-guide.nature.com/figures/preparing-figures-our-specifications/):

- portable sans-serif typography;
- axis lines, ticks, and explicit labels;
- no decorative grids, shadows, or patterns;
- high-contrast neutral text;
- a palette that does not depend on red-green contrast or a rainbow scale;
- RGB color and vector output where practical.

Nature lists final figure widths of 89 mm and 183 mm and recommends editable
vector artwork. `save_quantum_plot()` exposes those widths as the `single` and
`double` presets. PDF and SVG retain vector geometry; PNG and TIFF default to
450 dpi.

```r
save_quantum_plot(
  result,
  "figure.pdf",
  view = "execution",
  size = "double",
  theme = "nature"
)
```

The preset names describe visual conventions only. They do not imply
endorsement by or affiliation with Nature Portfolio journals. The `npj` preset
is described as npj-inspired because individual journals do not share one
universal data palette.

Raster output and GIF frames use the optional `ragg` device when available for
consistent font shaping and antialiasing. Cairo-backed base R devices are the
fallback. PDF and SVG preserve vector geometry, although the installed device
and font stack determine whether text remains editable text or becomes vector
outlines.

## Phase color

Complex phase is circular, so the color scale closes at its endpoints. qvivid
uses the same color at `-π` and `π`, labels phase explicitly, and encodes
probability separately as bar height. A redundant phase encoding that remains
legible without color is planned for stricter grayscale use.

## Animation requirements

- Frames share one scale, basis order, palette, canvas size, and set of text
  sizes.
- Motion must represent a state transition or execution step.
- Circuit highlighting and state evolution are synchronized by recorded
  operation index.
- GIFs are RGB presentation files; manuscript use should include a static
  vector companion.
- Resolution, frame rate, and duration are explicit function arguments.
- Bloch frames keep the same camera, unit sphere, axes, and scale. A trail may
  show earlier states without changing the encoding.

## Visual checks

The visual test suite has three parts:

1. Geometry tests inspect annotation bounds, pairwise label collisions, gate
   label fit, basis order, and shared animation limits.
2. Compact-device tests render every figure family at constrained dimensions.
3. The deterministic gallery script renders Bell, GHZ, phase-superposition,
   Bloch-orbit, dark-theme, and six-preset examples from exact simulations.

A change to a renderer, palette, device, font, or animation layout must pass
the geometry and compact-device tests before the gallery is rerun for visual
review. Pixel-reference regression tests remain planned; the current tests
cover geometry, successful rendering, and deterministic examples.
