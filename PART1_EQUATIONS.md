# Part I — equation register and derivations

Numbering resets on each notebook page. This page uses **(1.1)–(1.22)**; another chapter starts its own prefix.
Numbers are fixed source labels, independent of viewport size or rerun count. Introduction analogies are unnumbered.
Edit this Markdown file to change the folded derivations rendered by `chapter1_density.jl`.

| Equations | Subject | Scope |
|:--|:--|:--|
| 1.1–1.5 | Points, chart, counts and measures | Current selected support; counts are observed returns |
| 1.6–1.10 | Gaussian smoothing, scale, dB and quantization | Finite-grid viewer; physical bandwidth independent of resolution |
| 1.11–1.18 | Modes, centroid limit, asymmetry and bounds | Full-space equal-bandwidth model; no reflected boundary |
| 1.19 | Two-peak merging example | Two ideal equal Gaussian components, not a universal target-separation rule |
| 1.20 | Displayed mode–centroid distance | Independent full-space XY sweep |
| 1.21–1.22 | 1D/3D measures and density colour | Original world XYZ positions preserved |

<!-- BEGIN CONSTRUCTION -->
### Two routes through the construction

| Route | From input to a candidate |
|:--|:--|
| No input binning | XYZ → choose coordinates → retain XY → sum point Gaussians → continuous density → mode |
| Six-panel grid route | XYZ → choose coordinates → cell counts → divide by measure → count-preserving smoothing / measure → grid peaks |
| Binned full-space study | XYZ → XY → weighted cell centres → sum weighted Gaussians → continuous mode |

Input binning and output-grid sampling are different choices. The independent study compares
original points against weighted centres using the same full-space Gaussian model (1.11).
It does not inherit the six-panel plot's reflected edges or its grid-only maximum.

### From points to a density mountain

We retain the current frame and the stated support (all foreground, or the 1.4–1.6 m head band):

```math
\mathcal P_t=\{p_i=(x_i,y_i,z_i)\}_{i=1}^{N_t}. \tag{1.1}
```

Let the ceiling sensor be s=(s_x,s_y,s_z). In the cylindrical/spherical examples, φ is azimuth from +X,
and β is inclination from the **downward** axis. At the axis, azimuth is assigned zero by convention.

```math
\begin{aligned}
\rho_i&=\sqrt{(x_i-s_x)^2+(y_i-s_y)^2},\quad
R_i=\sqrt{\rho_i^2+(s_z-z_i)^2},\\
\phi_i&=\operatorname{atan2}(y_i-s_y,x_i-s_x),\quad
\beta_i=\operatorname{atan2}(\rho_i,s_z-z_i),\\
C(p_i)&=(x_i,y_i,z_i),\ (\rho_i,\phi_i,z_i),\ \text{or }(R_i,\phi_i,\beta_i),\quad
u_i=\pi(C(p_i)).
\end{aligned}\tag{1.2}
```

The chosen two coordinates are retained; another coordinate is accumulated out. These are different
marginals, so their peak heights and locations need not be equivalent.

```math
N_j=\sum_{i=1}^{N_t}\mathbf 1[u_i\in B_j],\qquad
B_j=[a_j,a_{j+1})\times[b_j,b_{j+1}).\tag{1.3}
```

The last nonperiodic upper edge is included in implementation. Azimuth wraps over a complete turn.
The cell measure is determined by the selected representation:

```math
V_j=\begin{cases}
\Delta a\,\Delta b,&XY,XZ,YZ,\text{ or the }(\rho,z)\text{ parameter plane},\\
\frac12(\rho_{j+1}^2-\rho_j^2)\Delta\phi,&(\rho,\phi)\text{ annular sector},\\
\Delta\phi\,(\cos\beta_j-\cos\beta_{j+1}),&(\phi,\beta)\text{ solid angle}.
\end{cases}\tag{1.4}
```

The ρ–Z marginal is a parameter-plane density, not cylindrical volume density. The angular map is
points/sr, not points/m². Annular-sector areas refer to horizontal distance ρ, not slant distance R.

```math
\rho_j=\frac{N_j}{V_j},\qquad \sum_j\rho_jV_j=N_{\mathrm{included}}.\tag{1.5}
```

For axis spacings Δa and bandwidths σ_a, use a normalized discrete Gaussian, truncated at four
standard deviations per axis:

```math
k_a(\ell)=\frac{\exp[-(\ell\Delta a)^2/(2\sigma_a^2)]}
{\sum_{m=-L_a}^{L_a}\exp[-(m\Delta a)^2/(2\sigma_a^2)]},\quad
L_a=\left\lceil4\sigma_a/\Delta a\right\rceil.\tag{1.6}
```

Zero bandwidth means the identity operator. The main viewer smooths **counts**, then divides by measure.
Half-sample reflection at finite nonperiodic boundaries and wrapping in azimuth define W:

```math
\widetilde N_j=\sum_iW_{ji}N_i,\quad \sum_jW_{ji}=1,\qquad
\widetilde\rho_j=\frac{\widetilde N_j}{V_j},\quad
\sum_j\widetilde\rho_jV_j=\sum_iN_i.\tag{1.7}
```

On equal-area grids this is ordinary density smoothing. On nonuniform cells, it preserves count mass;
directly smoothing density as in the old Python chart is generally different. The kernel is Gaussian
in the chosen chart, not an isotropic physical-space or great-circle kernel. Reflection is a numerical
boundary rule, not a model of mirror objects.

```math
\sigma_{\mathrm{cells},a}=\frac{\sigma_a}{\Delta a},\qquad
\operatorname{FWHM}_a=2\sqrt{2\log2}\,\sigma_a\approx2.355\sigma_a.\tag{1.8}
```

Keep σ in metres/radians fixed while refining the grid. Using the same number of σ cells after changing
resolution changes the physical model. Grid spacing describes numerical resolution, not measurement accuracy.

```math
D_j=\max\!\left(D_{\min},10\log_{10}\frac{\widetilde\rho_j}{\max_k\widetilde\rho_k}\right),\qquad
\operatorname{Argmax}(\widetilde\rho^2)=\operatorname{Argmax}(\widetilde\rho).\tag{1.9}
```

Zeros are displayed at the stated −50 dB floor. This is **relative density dB**, not received optical power.
The linear maximum is always reported. Normalization to each field's maximum prevents comparing absolute
amplitudes using dB heights alone. If E=ρ² is selected as a pseudo-energy descriptor, its relative dB would
be 20 log10(ρ/ρmax), a different display stretch with the same maxima.

For equal-area XY bins, distinguish the raw point centroid and the count-weighted bin-centre centroid:

```math
\mu_{\rm raw}=\frac1N\sum_i u_i,\quad
\mu_b=\frac1N\sum_jN_jq_j,\qquad
\|\mu_b-\mu_{\rm raw}\|\le r_\Delta=\frac12\sqrt{\Delta x^2+\Delta y^2}.\tag{1.10}
```

This bounds centroid quantization. It is not automatically a bound on the distance between a grid maximum
and a continuous mode. Local candidate peaks in the viewer are field diagnostics: 15% of the linear maximum,
connected plateaus collapsed, then at least one-bandwidth separation. They are not counted people or IDs.
<!-- END CONSTRUCTION -->

<!-- BEGIN CENTROID -->
### Why a broad Gaussian mode approaches a centroid

This is a **separate full-space model**, with fixed finite support q_j and weights a_j>0 summing to1.
Original-point analysis uses q_j=u_j and a_j=1/N; the binned model uses bin centres and N_j/N.
No reflection, clipping of the density domain or angular coordinate is assumed.

```math
f_\sigma(x)=\frac1{2\pi\sigma^2}\sum_ja_j
\exp\!\left[-\frac{\|x-q_j\|^2}{2\sigma^2}\right],\qquad
c_\sigma\in\operatorname{Argmax}_{x\in\mathbb R^2} f_\sigma(x).\tag{1.11}
```

Normalize each contribution at the evaluation point:

```math
\alpha_j(x)=\frac{a_j e^{-\|x-q_j\|^2/(2\sigma^2)}}
{\sum_ka_k e^{-\|x-q_k\|^2/(2\sigma^2)}},\qquad
T_\sigma(x)=\sum_j\alpha_j(x)q_j.\tag{1.12}
```

Differentiating the Gaussian gives the mean-shift fixed-point relation:

```math
\nabla\log f_\sigma(x)=\frac{T_\sigma(x)-x}{\sigma^2},\qquad
\nabla f_\sigma(c_\sigma)=0\ \Longrightarrow\ c_\sigma=T_\sigma(c_\sigma).\tag{1.13}
```

Stationary points lie in the support's convex hull. On this bounded set the distance-dependent weights
approach a_j uniformly as σ grows. Hence:

```math
\mu_a=\sum_ja_jq_j,\qquad \lim_{\sigma\to\infty}c_\sigma=\mu_a.\tag{1.14}
```

This is the arithmetic centroid for equal-weight original points, not a person's physical centre of mass
or localization ground truth. It does not imply monotonic mode motion at every bandwidth.
Let r_j=q_j−μ_a. Taylor expansion of the stationary equation yields:

```math
M_3=\sum_ja_jr_j\|r_j\|^2,\qquad
c_\sigma-\mu_a=-\frac{M_3}{2\sigma^2}+O(\sigma^{-4}).\tag{1.15}
```

The leading displacement depends on asymmetry. It is not generally directed toward the sensor.
The normalized Gaussian height decreases with increasing σ; distance-based **relative weights** become similar.

```math
\nabla^2\log f_\sigma(x)=-\frac I{\sigma^2}+
\frac{\operatorname{Cov}_{\alpha(x)}(q)}{\sigma^4},\quad
D=\max_{j,k}\|q_j-q_k\|,\quad \sigma>D/2\ \Longrightarrow\ \text{one global mode}.\tag{1.16}
```

The condition is sufficient, not necessary: Covα≼D²I/4 makes log f strongly concave. With
R=max‖r_j‖, S₃=Σa_j‖r_j‖³ and κ=1−D²/(4σ²)>0, the project derivation gives:

```math
\|c_\sigma-\mu_a\|\le B(\sigma)
=\frac{e^{R^2/(2\sigma^2)}S_3}{2(\sigma^2-D^2/4)},\qquad \sigma>D/2.\tag{1.17}
```

B decreases to0. Solving B(σ)≤ε gives a sufficient tolerance bandwidth, not the smallest necessary one.
For the binned support and a sampled full-space field, if the evaluation grid includes the point nearest
to its continuous mode, curvature bounds and (1.10) give:

```math
\|c_g-\mu_{\rm raw}\|\le
B(\sigma)+\frac{r_\Delta}{\sqrt\kappa}+b_\Delta,
\qquad b_\Delta=\|\mu_b-\mu_{\rm raw}\|.\tag{1.18}
```

This is a conditional upper bound. It is not an accuracy certificate for the main viewer's reflected field.
The nearest-grid-centre distance is a numerical output constraint, not the accuracy of the LiDAR.
Input binning (replacing points by weighted cell centres) and output-grid sampling are separate
operations. The 20 October comparison isolates input binning at fixed physical σ: a finer grid
need not reduce every selected mode's displacement monotonically, especially near ties or branch
switches. Changing the grid origin is another source of variation. At large σ, binned support
approaches μ_b rather than μ_raw. Its old 1,877-point cache is not the current 1,863-point frame97.

### Why centroid convergence can conflict with separation

For two ideal equal Gaussian components separated by d along one axis:

```math
f(x)=e^{-(x-d/2)^2/(2\sigma^2)}+e^{-(x+d/2)^2/(2\sigma^2)},\qquad
f''(0)=2e^{-d^2/(8\sigma^2)}\left(\frac{d^2}{4\sigma^4}-\frac1{\sigma^2}\right).\tag{1.19}
```

The midpoint switches from a minimum to a maximum as d crosses2σ. This illustrates merging for this
specific model. Real unequal, extended or occluded targets have no universal2σ separation rule.
Broad kernels can improve agreement with a centroid while merging target evidence.

The plotted study evaluates every selected input point, using multiple-start Gaussian mean shift,
a stationary residual check and a negative-definite Hessian check. It reports the best verified mode
found at sampled bandwidths; it does not prove that all global modes/branches were enumerated.
<!-- END CENTROID -->

## Provenance

- Migrated and simplified from `Coding/density_landscape/core/definition.py` and `parts/part1_definition.py`.
- Project mathematical notes: `Check from Codex/msp_centroid_kernel_proof_2026-10-16/MSP_KERNEL_CENTROID_PROOF.md`, especially sections2–5; bandwidth-locus implementation/notes of19 October2026.
- Input-binning comparison: `Check from Codex/grid_effect_on_locus_2026-10-20/README.md`; distinguishes input support approximation from output argmax quantization.
- Mean shift background: Comaniciu & Meer (2002), DOI10.1109/34.1000236. Equations1.15–1.18 are the project's derivation, not claimed as that paper's results.
- Coordinate measures: NIST DLMF1.5(ii)/(vi). Reflection convention: SciPy `gaussian_filter` documentation.
- The old Python source and its user-authored THEORY were read, not overwritten. The new mass-preserving nonuniform-cell smoothing and density-dB convention are explicit migration changes.

## Direct distance shown beside the independent bandwidth plots

```math
e(\sigma;\Delta)=\|c_{\sigma,\Delta}-\mu_{\rm raw}\|_2
=\sqrt{(x_{\sigma,\Delta}-\bar x)^2+(y_{\sigma,\Delta}-\bar y)^2}.\tag{1.20}
```

The no-binning case omits Δ. Coordinates are metres; the viewer reports1000e in mm.
This is agreement with the raw-point centroid, not localization error against ground truth.

Sweep diagnostic (not a theorem): adjacent samples are flagged for unresolved modes, numerical
ties, or a step larger than max(5mm,0.35σ_previous expressed in mm). Solid lines stop at flags.
Grouped brackets are observed σ sample ranges; no exact transition or universal onset of continuity
is claimed. A reported settled terminal segment only means no more flags in that sampled suffix.


<!-- BEGIN DIMENSIONS -->
### Retain one, two or three coordinates

The six-step grid route can retain d=1,2,3 coordinates. A 1D marginal accumulates out the other
two coordinates; it cannot determine a unique XY/XYZ location. Cartesian 1D and angular 1D use
coordinate length / radians. Mixed angle–length pairs use parameter-product measure, except
the explicitly defined annular/solid-angle pairs in (1.4). Complete triples use physical volume:

```math
V_j^{(d)}=\begin{cases}
\Delta x,&\text{Cartesian 1D (similarly Y or Z)},\\
\Delta\phi\ \text{or }\Delta\beta,&\text{angular 1D parameter interval},\\
\Delta x\Delta y\Delta z,&XYZ,\\
\tfrac12(\rho_+^2-\rho_-^2)\Delta\phi\Delta z,&(\rho,\phi,z),\\
\tfrac13(R_+^3-R_-^3)\Delta\phi(\cos\beta_--\cos\beta_+),&(R,\phi,\beta).
\end{cases}\tag{1.21}
```

For an original return p_i in its containing cell b(i), colour encodes the cell's derived density.
All positions remain the original world XYZ, including for cylindrical/spherical density models:

```math
p_i^{\rm display}=p_i=(x_i,y_i,z_i),\qquad
\operatorname{colour}(p_i)=\mathcal C\!\left(\widetilde\rho_{b(i)}\right),\qquad
\widetilde\rho_j=\frac{\widetilde N_j}{V_j^{(3)}}.\tag{1.22}
```

The display may use the same relative-density dB transform(1.9). Density colour is a fourth
encoded quantity, not a fourth spatial coordinate. It differs from a 2D XY mountain where the
third plotting axis is density rather than physical height. No point is moved, discarded or
interpolated to make the colour plot; equal colours within a voxel reflect the selected grid.
<!-- END DIMENSIONS -->
