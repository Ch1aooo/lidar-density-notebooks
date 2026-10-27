### A Pluto.jl notebook ###
# v1.0.4

using Markdown
using InteractiveUtils

# ╔═╡ a8250000-2026-4025-8000-000000000001
begin
    import Pkg
    Pkg.activate(@__DIR__; io=devnull)
    book = Base.include(Module(gensym(:BookWorkspace)), joinpath(@__DIR__, "src", "BookUI.jl"))
end;

# ╔═╡ a8250000-2026-4025-8000-000000000002
book.styles()

# ╔═╡ a8250000-2026-4025-8000-000000000003
book.navigation("introduction.jl")

# ╔═╡ a8250000-2026-4025-8000-000000000004
md"""
# From 3D Point Clouds to Persistent Tracks

*An interactive research notebook on density, localization and shared human–robot spaces.*

**Introduction** · [Background](#Background) · [Observation](#Observation) ·
[Representation](#Representation) · [Density](#Density) · [Questions](#Questions) · [Summary](#Summary) · [References](#References)
"""

# ╔═╡ a8250000-2026-4025-8000-000000000005
book.contents()

# ╔═╡ a8250000-2026-4025-8000-000000000006
md"""
## Background

This project builds on **Yiyun's single-person localization work**. The inherited workflow
removes background returns and estimates one person's position across frames. The project
starting point is high-precision single-person tracking; the replay below does not independently
measure that accuracy.

My focus is the next step: **separating people from robots, separating people from one another,
and maintaining their identities over time** in a shared human–robot interaction space.
Multi-target separation and persistent association remain research goals.
"""

# ╔═╡ a8250000-2026-4025-8000-000000000007
book.note("Research objective", "Turn 3D returns into useful XY positions while preserving which object each position belongs to, frame after frame.")

# ╔═╡ a8250000-2026-4025-8000-000000000008
md"""
## Observation

### A person moving through 3D space

The available **L-shaped single-person recording**, measured by **Yiyun Xu** in the inherited
localization work [6](#References), is our starting example. Move the frame control
**beside the figure**, rotate the 3D view, and compare the representative point with its XY footprint.
The lower view shows the planar localization result. Select **XY × frame** to make ordering visible
as a plotted axis.

There are **203 saved frames, 202 with returns**. Choose the **head centroid** (mean of returns
in the **1.4–1.6 m height band**) or the **whole-body centroid** (mean of all saved foreground returns).
Enable **Compare both centroids** to see both paths together. These are estimates from visible returns,
not anatomical ground truth. A view you rotate stays fixed while the recorded points move.
"""

# ╔═╡ a8250000-2026-4025-8000-000000000009
book.viewer(:walk)

# ╔═╡ a8250000-2026-4025-8000-00000000000a
book.note("Keep time explicit", "A cumulative XY image overlays several frames on the same plane. It can show the route while hiding when each position occurred. Scrubbing a frame index restores the sequence; it does not recover missing observations.")

# ╔═╡ a8250000-2026-4025-8000-00000000000b
md"""
## Representation

### My working view of dimensions

We are familiar with **three-dimensional space: x, y and z**. A changing scene adds **time t**:
**3 spatial coordinates + 1 time coordinate = 4** quantities. Our sensor records this evolution in **frames**;
timestamps or a verified sensor frame rate connect frame index to elapsed time.

My working display uses **three plotted axes and one adjustable variable**. A slider or animation lets us
inspect the fourth quantity through our own viewing time. Reassigning an axis to temperature, density or
frame index gives other representations.

**Viewing time and acquisition time are different.** The slider preserves frame order; a static accumulation
hides it. Playback speed is chosen for viewing. Without verified timestamps or frame rate, the animation
cannot establish the original event intervals or physical speed.

The six examples are sorted by count. **Dimensions** gives the total; **Components** lists its contributions
and coordinates.

| # | Representation | Dimensions | Components | Meaning |
|:--|:--|:--|:--|:--|
| 1 | One XY view | 2 | 2 spatial + 0 ordering = 2: (x, y) | Planar positions at one selected frame |
| 2 | Cumulative XY path | 2 | 2 spatial + 0 explicit ordering = 2: (x, y) | A route on one plane; order and speed are not explicit |
| 3 | One XYZ cloud | 3 | 3 spatial + 0 ordering = 3: (x, y, z) | Spatial shape at one selected frame |
| 4 | XY × frame | 3 | 2 spatial + 1 ordering = 3: (x, y, frame) | Planar motion with frame order on the third axis |
| 5 | One XYZ representative per frame | 4 | 3 spatial + 1 ordering = 4: (x, y, z, frame) | A position sequence; most body shape is summarized away |
| 6 | XYZ sequence + frame control | 4 | 3 spatial + 1 ordering = 4: (x, y, z, frame) | A moving cloud explored with three axes and a slider |

Here **frame index** stands in for the time coordinate; it supplies order but has no verified conversion
to seconds. Counts describe the represented coordinates and ordering variable. A trajectory may still be
parameterized by one variable, and **an ID is a categorical label**.

**Related method.** Wang et al. use multiple 2D LiDARs and **3D region growing in (x, y, t)**
to associate observations over a sliding time window [1](#References). Their third coordinate is time,
not physical height. Our **XY × frame** display illustrates that coordinate choice; it does not
implement their association method, and frame index is not a verified time interval.
"""

# ╔═╡ a8250000-2026-4025-8000-00000000000c
book.viewer(:field)

# ╔═╡ a8250000-2026-4025-8000-000000000012
md"""
### Reading a scalar through height, colour and shading

A screen displays a **2D image**. The examples below represent **three quantities: x, y and height h**.
Height may be mapped to colour, perceived through shading, or shown using both cues.
These channels do not add independent data dimensions.

Todd's review illustrates shading, texture and contour cues in its Figure 1, then demonstrates the
ambiguity of shading in Figure 2: depth can be stretched or sheared while preserving the image [4](#References).
It supports a distinction between **perceiving shape** and **recovering exact geometry**.
False colour is an explicit value mapping [3](#References); shading depends on surface orientation and lighting,
so brightness alone is not a calibrated height measurement [2](#References).

For a scalar field **s(x, y)** placed on Z, the display scale **α** sets **z_display = α · s(x, y)**.
Colour continues to encode the original **s**, using the same colour limits while α changes.
The two new X/Y examples apply that scaling to the chosen scalar axis instead.

| Quantity / setting | Interpretation |
|:--|:--|
| α = 0 (dimensionless) | A flat XY surface; colour retains the scalar variation |
| 0 < α < 1 | Reduced vertical displacement; scalar values and colours are unchanged |
| α = 1 | Full displayed height; colour and height redundantly encode the same scalar |
| Temperature on X | X carries T; Y and Z remain spatial coordinates |
| Density on Y | Y carries rho; X and Z remain spatial coordinates |
| Uniform colour, shading retained | Light and dark can still reveal shape, without a colour-to-value mapping |
| Uniform colour, no shading | Some depth cues are removed; contour and perspective may still convey structure |

**One field, five appearances.** Figures 3–6 use identical geometry, limits and camera; Figure 7 flattens
the same field onto XY. All use arbitrary units: X and Y from −2 to 2, h from 0 to 1.
The shared colour limits make the coloured panels comparable. These original teaching renders connect
Rheingans and Landreth's redundant mappings [3](#References) with Todd's discussion of shape cues [4](#References).
"""

# ╔═╡ a8250000-2026-4025-8000-000000000013
book.encoding_gallery()

# ╔═╡ a8250000-2026-4025-8000-000000000014
md"""
### Coordinates for the same space

Changing **coordinates** describes the same physical position with different parameters.
Changing an **axis meaning**, as in the temperature example, displays a different quantity.
The six systems below all describe **three-dimensional space** [5](#References).

| Coordinate system | Three parameters and units | Geometric intuition |
|:--|:--|:--|
| Cartesian | x, y, z (m) | Distances along three perpendicular axes |
| Cylindrical | r (m), φ (rad), z (m) | Distance from an axis, angle around it, and height |
| Spherical | R (m), θ (rad), φ (rad) | Distance from an origin, polar angle from +Z, and azimuth |
| Elliptic cylindrical | u (dimensionless), v (rad), z (m) | Confocal ellipses in XY, extended along Z |
| Prolate spheroidal | ξ, η (dimensionless), φ (rad) | Elongated spheroids and hyperboloids sharing two foci |
| Toroidal | η (dimensionless), θ, φ (rad) | Coordinates adapted to a ring and its surroundings |

Elliptic, spheroidal and toroidal definitions also need a stated reference length;
angle conventions must be declared for each system.
Polar coordinates describe a 2D plane; adding height gives the cylindrical case.

**Bridge to Part I:** same space + a different coordinate grid = a different organization of point support.
Equal parameter bins can cover unequal physical areas or volumes. Part I will make the density measure,
bin sizes and any change-of-variable factors explicit before comparing MSP peaks.
"""

# ╔═╡ a8250000-2026-4025-8000-00000000000d
md"""
## Density

### From scattered points to a field

Instead of drawing every point, we can describe **how concentrated the point support is** near
each location. Over XY, this assigns a scalar value to each planar coordinate.
Plotting that value vertically produces a mountain-like surface: **two spatial coordinates plus
a density value**, rather than three physical spatial coordinates.

Part I will examine the coordinate choice, grid and smoothing scale. A density peak is a candidate
representative; it does not by itself establish the number or identity of objects.
"""

# ╔═╡ a8250000-2026-4025-8000-00000000000e
md"""
## Questions

1. **Separation:** which returns belong to a person, a robot, or another person?
2. **Localization:** which representative remains useful as shape and visible support change?
3. **Association:** how can the same identity persist through proximity, occlusion and reappearance?

Each later chapter will follow the same structure:
**Question → Input → Representation → Experiment → Evidence**.
Only the introduction is developed here; the remaining chapters provide an editable outline.
"""

# ╔═╡ a8250000-2026-4025-8000-00000000000f
md"""
## Summary

**The starting point is one recorded person.** The research target is multiple people and robots
with persistent data association. [↑ Jump to background](#Background)

**A representation makes some information explicit and hides other information.**
XY localization reduces spatial detail; a time control restores the order of observations.
[↑ Jump to representation](#Representation)

**A density mountain is an encoding, not a physical object.** It summarizes point support and
must be interpreted together with geometry and time. [↑ Jump to density](#Density)
"""

# ╔═╡ a8250000-2026-4025-8000-000000000015
book.perception_analogy()

# ╔═╡ a8250000-2026-4025-8000-000000000010
md"""
## References

1. **Wang, W., Yan, B., Li, X., Tian, M., Jiao, R., & Zhang, H. (2024).**
   *Multiple Pedestrian Tracking Using LiDAR Network in Complex Indoor Scenarios.*
   IEEE Sensors Journal, 24(8), 13175–13192. [DOI](https://doi.org/10.1109/JSEN.2024.3369947).
   See Section III-B and Figure 6 for X–Y–time region growing.
2. **Ramachandran, V. S. (1988).** *Perception of shape from shading.* Nature, 331, 163–166.
   [DOI](https://doi.org/10.1038/331163a0) · [Abstract](https://pubmed.ncbi.nlm.nih.gov/3340162/).
3. **Rheingans, P., & Landreth, C. (1995).** *Perceptual Principles for Effective Visualizations.*
   In G. Grinstein & H. Levkowitz (Eds.), Perceptual Issues in Visualization, pp. 59–73.
   [DOI](https://doi.org/10.1007/978-3-642-79057-7_6) ·
   [Authors' illustrated examples](https://userpages.cs.umbc.edu/rheingan/pubs/perception.html).
4. **Todd, J. T. (2004).** *The visual perception of 3D shape.* Trends in Cognitive Sciences, 8(3), 115–121.
   [DOI](https://doi.org/10.1016/j.tics.2004.01.006) ·
   [Article](https://www.sciencedirect.com/science/article/pii/S1364661304000233).
   Figures 1–2 and the conclusion inform the discussion of depth cues and perceptual ambiguity.
5. **NIST Digital Library of Mathematical Functions.** Coordinate-system definitions:
   [cylindrical and spherical](https://dlmf.nist.gov/1.5#ii),
   [elliptical](https://dlmf.nist.gov/28.32#i),
   [prolate spheroidal](https://dlmf.nist.gov/30.13#i),
   [toroidal](https://dlmf.nist.gov/14.19#i).

6. **Xu, Yiyun (2026).** *Continuous Indoor Localization through Lidar and IMU Sensor Fusion.*
   MSc thesis, Department of Electrical Engineering, Eindhoven University of Technology.
   Local project copy: `Reference/final_report_with_cover_Yiyun.pdf`.

### Sources and scope

- **Data:** the saved foreground world-coordinate frames in this project's measured L-walk cache.
  All **460,750** saved XYZ points are retained in the bundled replay; the selected frame is not resampled.
  Optional XY accumulation states its display step. Frame 1 stays missing. This page does not rerun
  background extraction, introduce a new tracker, or validate multi-target performance.
- **Project history and goals:** the author's account of the inherited single-person work and current research scope.
- **Figures 2–7:** analytic teaching examples, not sensor measurements. Figures 3–7 are original renders;
  no published figure has been copied. Geometry, camera and scalar limits are recorded in `assets/encoding/provenance.json`.
- **Informal formula:** the four-variable display analogy is the author's working interpretation.
  The cited perception research does not establish a four-dimensional maximum for human perception.
  Formal density/MSP derivations belong to Part I.
- **Presentation reference:** the [BMLIP course syllabus and Summary](https://bmlip.github.io/course/lectures/Course%20Syllabus.html#Summary)
  inspired the heading hierarchy, linked sections, chapter navigation and short summary. Its course text is not reproduced.
- **Editing:** introduction text lives in `introduction.jl`; graphics and neighbouring controls live in `assets/`.
  The editable source map and data provenance are described in `BOOK_GUIDE_zh.md`.
"""

# ╔═╡ a8250000-2026-4025-8000-000000000011
book.footer("introduction.jl")

# ╔═╡ Cell order:
# ╟─a8250000-2026-4025-8000-000000000001
# ╟─a8250000-2026-4025-8000-000000000002
# ╟─a8250000-2026-4025-8000-000000000003
# ╟─a8250000-2026-4025-8000-000000000004
# ╟─a8250000-2026-4025-8000-000000000005
# ╟─a8250000-2026-4025-8000-000000000006
# ╟─a8250000-2026-4025-8000-000000000007
# ╟─a8250000-2026-4025-8000-000000000008
# ╟─a8250000-2026-4025-8000-000000000009
# ╟─a8250000-2026-4025-8000-00000000000a
# ╟─a8250000-2026-4025-8000-00000000000b
# ╟─a8250000-2026-4025-8000-00000000000c
# ╟─a8250000-2026-4025-8000-000000000012
# ╟─a8250000-2026-4025-8000-000000000013
# ╟─a8250000-2026-4025-8000-000000000014
# ╟─a8250000-2026-4025-8000-00000000000d
# ╟─a8250000-2026-4025-8000-00000000000e
# ╟─a8250000-2026-4025-8000-00000000000f
# ╟─a8250000-2026-4025-8000-000000000015
# ╟─a8250000-2026-4025-8000-000000000010
# ╟─a8250000-2026-4025-8000-000000000011
