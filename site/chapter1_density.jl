### A Pluto.jl notebook ###
# v1.0.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ a8251000-2026-4025-8000-000000000001
begin
    import Pkg
    Pkg.activate(@__DIR__; io=devnull)
    using PlutoUI
    book = Base.include(Module(gensym(:BookWorkspace)), joinpath(@__DIR__, "src", "BookUI.jl"))
    density = Base.include(Module(gensym(:DensityWorkspace)), joinpath(@__DIR__, "src", "DensityPartI.jl"))
    page = Base.include(Module(gensym(:PageWorkspace)), joinpath(@__DIR__, "src", "PartIPage.jl"))
end;


# ╔═╡ a8251000-2026-4025-8000-000000000002
book.styles()


# ╔═╡ a8251000-2026-4025-8000-000000000009
page.styles()


# ╔═╡ a8251000-2026-4025-8000-000000000003
book.navigation("chapter1_density.jl")


# ╔═╡ a8251000-2026-4025-8000-000000000004
md"""
# I · Density Representations
*From observed returns to a density mountain and candidate positions.*

[Botanical analogy](#A-botanical-analogy-for-point-cloud-context) · [Six steps](#Build-the-mountain-in-six-steps) ·
[Scale and measure](#What-the-controls-mean) · [MSP and centroid](#MSP-and-the-centroid) · [Bandwidth trajectory](#Bandwidth-trajectory) ·
[Research scope](#What-this-could-help-with) · [Summary](#Summary) · [References](#References)

## A botanical analogy for point-cloud context
Two starting points guide this analogy: **(1) direct light follows straight paths and opaque
surfaces block it; (2) light carries energy**. One elevated source helps us picture visible
support, shadows and an uneven distribution.

Compare the Sun above plants with a ceiling LiDAR above targets. Scanner range and angles form
spherical coordinates; sunlight is approximately parallel. Brightness suggests point density,
which depends on angular resolution and visibility rather than measuring photon energy.
Photon arrivals and return-point samples provide a discrete-sampling analogy, not a one-to-one
physical correspondence. Optical intensity is proportional to electric-field amplitude squared,
whereas the project's density score is defined as density squared [8](#References). The shared
square form is an analogy; the quantities and units differ. The table also shows how connected
support can merge nearby targets in DBSCAN.
Self/external occlusion [6](#References) and density-connected clustering [7](#References) are
explained in the table, from simple to composite concepts.
"""


# ╔═╡ a8251000-2026-4025-8000-00000000000a
page.analogy()


# ╔═╡ a8251000-2026-4025-8000-00000000000b
md"""
## Build the mountain in six steps
**XYZ returns → coordinate chart → cell counts → density → Gaussian mountain → candidate peaks.**

Choose random ellipsoids, Yiyun's measured L-walk [1], or a local CSV (`x,y,z` in metres; optional
integer `frame`). The recording is the project's saved foreground cache after existing
background/sparse-return filtering. It is not a new raw-data release. All selected returns are
used; no acquisition simulator or downsampling stage is included.

Choose **coordinate family → retained dimensions → coordinate(s)**. Start with XY for ground-plane
localization, X alone for a 1D marginal, or full XYZ for a point cloud coloured by 3D density.
The **accumulation basis** specifies the coordinate family, retained coordinate(s), their dimension
and the cell resolution. Other coordinates are accumulated out. It determines both the information
retained and the cell measure used to define density; it is more than a choice of plotting axes.
Radial views follow the selected coordinates. A unit sphere/cylinder is explicitly a display
reference when range has been discarded, rather than reconstructed physical distance.
Cylindrical and spherical families offer their own single axes, pairs and complete triples. The
illustrative sensor origin is **(0, 0, 2.7 m)**; verify calibration before drawing sensor conclusions.
Head-band support is simply world Z ∈ [1.4, 1.6] m, rather than head detection or classification.
"""


# ╔═╡ a8251000-2026-4025-8000-000000000010
page.derivation(:construction)


# ╔═╡ a8251000-2026-4025-8000-00000000000c
@bind settings page.controls()


# ╔═╡ a8251000-2026-4025-8000-00000000000d
part1_result = density.evaluate(settings, @__DIR__; study=false);


# ╔═╡ a8251000-2026-4025-8000-00000000000e
page.update(part1_result)


# ╔═╡ a8251000-2026-4025-8000-00000000000f
md"""
## What the controls mean

| Retained coordinates | Display | What density means |
|:--|:--|:--|
| 1D, such as X | A density-versus-coordinate curve | Other coordinates accumulated out; per metre or radian |
| 2D, such as XY | A 2D map / density-height mountain | Density height is a derived scalar, not physical Z |
| 3D, such as XYZ | Original XYZ points, coloured by density | A 3D cell-volume density in points/m³; original point positions remain unchanged |

Colour in 3D adds a derived scalar to three spatial coordinates; it is not another spatial axis.
The 3D views colour each return with its containing-cell value. They do not interpolate or move it.

| Choice | Interpretation |
|:--|:--|
| Grid cells | Numerical discretization; finer cells do not create new sensor information. |
| Spatial σ, in cm | Physical support scale on each retained length axis. **Keep it fixed when refining the grid.** |
| Angular σ, in degrees | Support in chart angles; the same angle spans different physical sizes at different ranges. |
| Counts / measure | 1D uses coordinate intervals; Cartesian pairs / ρ–Z use plane area; ρ–φ uses annular area; φ–β uses solid angle; other angular–length pairs use parameter measure. Complete triples use exact cell volume [3]. |
| Smoothing | Smooth **counts**, then divide by measure; this preserves mass on nonuniform-measure grids. |
| dB / linear | Display choice: 10 log₁₀(ρ/ρmax), clipped at −50 dB. Each panel peaks at 0 dB; use the linear readout for absolute density. |
| A peak | A maximum depending on support, projection, grid, bandwidth and boundaries. |

The separable Gaussian is truncated at four σ, with reflection at bounded axes and wrapping
at the azimuth seam [4]. A Gaussian in a chart is not generally isotropic in world space,
especially near spherical poles and the cylindrical axis. The historical **E = ρ²** adds no
peak positions for nonnegative density. Its derivation stays below; it is a pseudo-energy,
not measured optical energy.
"""


# ╔═╡ a8251000-2026-4025-8000-000000000011
md"""
## MSP and the centroid
Recent work separates three questions:

| Progress | What it clarifies |
|:--|:--|
| Gaussian proof · 16 October | Full-space mode, weighted fixed point, centroid limit and sufficient bounds |
| Bandwidth locus · 19 October | How a selected mode moves or switches as physical σ changes |
| Binning comparison · 20 October | Input binning shifts support; output-grid argmax separately quantizes the answer |

The **centroid averages all selected points equally**. A Gaussian **mode averages nearby
support with distance-dependent weights** at a fixed point. Mean shift is an established way
to follow this update [2]; a finer grid is not the only way to search for a summit.

The independent experiment below fixes its own point cloud and input-bin resolution. **Only σ
varies along the complete trajectory.** The local σ selector marks a sampled point; it does not
cut the rest of the curve away or change the six-panel experiment. Original-point and weighted-bin
models can be compared without an output raster or reflected edges.

The left plot shows the complete sampled XY mode locus; the right shows its distance to the
**raw-point centroid**. Colours encode σ. Ambiguous ties, failed verification and large sample-to-sample
moves break the solid line. Red markers and a short interval table expose possible switches,
especially below 1 cm. The reported settled range is an observed sampling diagnostic, not a
universal bandwidth threshold or a proof of branch continuity.

For a common Gaussian bandwidth, the full-space mode approaches the support centroid as σ
becomes large. Its leading offset depends on a third central moment; a sufficiently broad
kernel has a unique mode. The fold below states conditions and the conditional grid-error bound
from recent project notes [5]. **These theorems do not automatically apply to the finite reflected
grid above.** Distance to a centroid is not localization accuracy: visibility, pose and selected
height band can bias the centroid itself.

The binning comparison keeps physical σ fixed. Finer cells need not improve every selected peak
monotonically: grid origin and near-tied modes can change the winner. At large σ, binned support
approaches its **binned weighted centroid**, which need not equal the original-point centroid.
The old locus used a different 1,877-point cache; its numerical curves are not relabelled as the
current 1,863-point frame. The plots here recompute from the independently selected current support.
"""


# ╔═╡ a8251000-2026-4025-8000-000000000018
md"""
## Bandwidth trajectory
The complete curve stays visible while its local selector marks one sampled σ.

```math
e(\sigma;\Delta)=\|c_{\sigma,\Delta}-\mu_{\rm raw}\|_2
=\sqrt{(x_{\sigma,\Delta}-\bar x)^2+(y_{\sigma,\Delta}-\bar y)^2}.\tag{1.20}
```

For no binning, Δ is absent. Displayed millimetres equal 1000 times this distance in metres.
This quantity measures agreement with a centroid, not error against localization ground truth.

"""


# ╔═╡ a8251000-2026-4025-8000-000000000015
@bind sweep_settings page.study_controls()


# ╔═╡ a8251000-2026-4025-8000-000000000016
sweep_result = density.study_evaluate(sweep_settings, @__DIR__);


# ╔═╡ a8251000-2026-4025-8000-000000000017
page.study_update(sweep_result)


# ╔═╡ a8251000-2026-4025-8000-000000000012
page.derivation(:centroid)


# ╔═╡ a8251000-2026-4025-8000-000000000019
page.derivation(:dimensions)


# ╔═╡ a8251000-2026-4025-8000-000000000013
md"""
## What this could help with

| Situation | What the construction offers | What remains unresolved |
|:--|:--|:--|
| One known person | A density-based candidate alongside the centroid | No demonstrated advantage or computational saving over averaging |
| Several targets | Several candidate hills may appear **before assigning every return a target label** | Candidate count and scale selection; a field is not yet reliable separation |
| Close / occluded targets | Shape and local maxima can be inspected | Peaks can merge, disappear, or come from one body; no proven occlusion robustness |
| People and robots over time | Candidate positions could become tracking observations | Classification, births/deaths, missed detections and persistent association |

My working idea is to construct a **derived density field**, then search and associate its
summits. “Secondary information” means a derived representation, not a statistical second-order
moment. Point clustering need not be the first operation, but smoothing and peak search have
their own costs and choices. Conventional clustering, including DBSCAN, remains a comparison
to evaluate rather than a method assumed to fail.

Broad smoothing can erase the separation we need. The two-Gaussian example in the derivation
explains a scale tradeoff, not a universal real-person resolution rule. Later chapters will test
person–robot separation, person–person separation and continuous association. No new multi-person
tracking result is claimed here.
"""


# ╔═╡ a8251000-2026-4025-8000-000000000005
HTML("<details class=\"part1-fold\"><summary>Previous implementation</summary><p>The original Python Part I and the <a href=\"$(book.notebook_url("part1.jl"))\">earlier Julia sandbox</a> remain available. This is a simplified migration with physical bandwidth and measure-preserving smoothing.</p></details>")


# ╔═╡ a8251000-2026-4025-8000-000000000014
md"""
## Summary
Construct a density field from observed support, then inspect its candidate summits. State the
coordinate measure, keep physical bandwidth separate from grid resolution, and distinguish a
mode from a centroid. The botanical analogy explains visibility; density remains a count-based
derived field. A broad Gaussian can approach a centroid while merging target evidence.
Multi-person / human–robot separation and persistent identity remain the questions to test.
"""


# ╔═╡ a8251000-2026-4025-8000-000000000006
md"""
## References
1. **Xu, Yiyun (2026).** *Continuous Indoor Localization through Lidar and IMU Sensor Fusion.*
   MSc thesis, Department of Electrical Engineering, Eindhoven University of Technology.
   Local copy: `Reference/final_report_with_cover_Yiyun.pdf`. The measured L-walk is attributed
   to Yiyun; its saved foreground representation belongs to this project's processing.
2. **Comaniciu, D., & Meer, P. (2002).** Mean Shift: A Robust Approach Toward Feature Space Analysis.
   *IEEE TPAMI, 24*(5), 603–619. [doi:10.1109/34.1000236](https://doi.org/10.1109/34.1000236).
3. **NIST DLMF, §1.5.** [Coordinate transformations and Jacobians](https://dlmf.nist.gov/1.5).
4. **SciPy documentation.** [Gaussian filter conventions](https://docs.scipy.org/doc/scipy/reference/generated/scipy.ndimage.gaussian_filter.html).
   Computation here is Julia; SciPy is the numerical comparison reference.
5. **Project working notes (16, 19 and 20 October 2026).** Gaussian mode–centroid proof, bandwidth
   locus and input-binning comparison. Equation register: `PART1_EQUATIONS.md`, **(1.1)–(1.22)**.
   These are project derivations, not an external publication.
6. **Xu, Q., Zhong, Y., & Neumann, U. (2022).** Behind the Curtain: Learning Occluded Shapes for
   3D Object Detection. *AAAI,36*(3),2893–2901. [doi:10.1609/aaai.v36i3.20194](https://doi.org/10.1609/aaai.v36i3.20194).
   Section1.1 and Figure1 distinguish self-occlusion, external occlusion and signal miss.
7. **Ester, M., Kriegel, H.-P., Sander, J., & Xu, X. (1996).** A Density-Based Algorithm for
   Discovering Clusters in Large Spatial Databases with Noise. *KDD-96*,226–231.
   [Original paper](https://cdn.aaai.org/KDD/1996/KDD96-037.pdf).
8. **OpenStax, University Physics Volume 2, §16.3; College Physics 2e, §29.3.**
   [Wave intensity and field amplitude](https://openstax.org/books/university-physics-volume-2/pages/16-3-energy-carried-by-electromagnetic-waves);
   [photon energy](https://openstax.org/books/college-physics-2e/pages/29-3-photon-energies-and-the-electromagnetic-spectrum).
   Optical intensity scales with field amplitude squared; a single photon has energy hν.
"""


# ╔═╡ a8251000-2026-4025-8000-000000000007
book.footer("chapter1_density.jl")


# ╔═╡ Cell order:
# ╟─a8251000-2026-4025-8000-000000000001
# ╟─a8251000-2026-4025-8000-000000000002
# ╟─a8251000-2026-4025-8000-000000000009
# ╟─a8251000-2026-4025-8000-000000000003
# ╟─a8251000-2026-4025-8000-000000000004
# ╟─a8251000-2026-4025-8000-00000000000a
# ╟─a8251000-2026-4025-8000-00000000000b
# ╟─a8251000-2026-4025-8000-000000000010
# ╟─a8251000-2026-4025-8000-00000000000c
# ╟─a8251000-2026-4025-8000-00000000000d
# ╟─a8251000-2026-4025-8000-00000000000e
# ╟─a8251000-2026-4025-8000-00000000000f
# ╟─a8251000-2026-4025-8000-000000000011
# ╟─a8251000-2026-4025-8000-000000000018
# ╟─a8251000-2026-4025-8000-000000000015
# ╟─a8251000-2026-4025-8000-000000000016
# ╟─a8251000-2026-4025-8000-000000000017
# ╟─a8251000-2026-4025-8000-000000000012
# ╟─a8251000-2026-4025-8000-000000000019
# ╟─a8251000-2026-4025-8000-000000000013
# ╟─a8251000-2026-4025-8000-000000000005
# ╟─a8251000-2026-4025-8000-000000000014
# ╟─a8251000-2026-4025-8000-000000000006
# ╟─a8251000-2026-4025-8000-000000000007
