# Software and presentation sources

## Photon / square-form analogy — 26 October 2026

- OpenStax, University Physics Volume 2 §16.3: https://openstax.org/books/university-physics-volume-2/pages/16-3-energy-carried-by-electromagnetic-waves — optical intensity is proportional to electric-field amplitude squared, not photon-count squared.
- OpenStax, College Physics 2e §29.3: https://openstax.org/books/college-physics-2e/pages/29-3-photon-energies-and-the-electromagnetic-spectrum — one photon has energy hν. The sample/photon correspondence is explanatory, not a one-to-one physical measurement model.
- Botanical table now has17 rows. DBSCAN merging follows density connectivity through core-point neighbourhoods at chosen ε/MinPts (Ester et al.,1996). It is a possible failure mode, not a guarantee for all close targets or evidence that MSP avoids merging. New SVG rays/bridge marks are original explanatory geometry.

- **Julia / Pluto / PlutoUI / CairoMakie:** versions resolved in `Manifest.toml`; the previous synthetic sandbox is preserved.
- **Plotly.js 4.1.1:** `assets/plotly.min.js` is the existing vendored bundle from the project's earlier offline Plotly visualization. Its embedded copyright and MIT notice are preserved. No CDN is required by either interactive graphic.
- **BMLIP course syllabus:** https://bmlip.github.io/course/lectures/Course%20Syllabus.html#Summary — presentation reference for linked chapters, section headings and concise summaries. No course prose or images copied.
- **Scientific visualization workflow:** Kassis, T., Agarwal, V., He, Y., Patel, D., & Brueckner, A. M. (2026). *Scientific Agent Skills: A Library of Procedural Knowledge for Research Agents*. https://doi.org/10.48550/arXiv.2609.00065 — consulted for explicit data provenance, units, missing frames, accumulation and representation semantics. Author metadata checked against the latest arXiv record on 25 October 2026; no published journal version was listed.

The measured foreground sequence is project data, not an example dataset supplied by these software libraries.
Its export provenance and exact source hashes are in `data/measured_walk_metadata.json`.

## Representation and perception references (verified 25 October 2026)

- Wang, W., Yan, B., Li, X., Tian, M., Jiao, R., & Zhang, H. (2024). *Multiple Pedestrian Tracking Using LiDAR Network in Complex Indoor Scenarios.* IEEE Sensors Journal, 24(8), 13175–13192. https://doi.org/10.1109/JSEN.2024.3369947 . Metadata: Crossref + the project's original paper PDF, pp. 13175 and 13181–13183. Stage 2 uses X–Y–time region growing, not XYZ height. The current viewer is a coordinate illustration, not a reproduction of their method.
- Ramachandran, V. S. (1988). *Perception of shape from shading.* Nature, 331, 163–166. https://doi.org/10.1038/331163a0 . Metadata checked against Crossref and the primary abstract at https://pubmed.ncbi.nlm.nih.gov/3340162/ . Supports the role of shading in shape perception; no claim that removing colour eliminates all depth cues.
- Rheingans, P., & Landreth, C. (1995). *Perceptual Principles for Effective Visualizations.* In G. Grinstein & H. Levkowitz (Eds.), Perceptual Issues in Visualization, pp. 59–73. https://doi.org/10.1007/978-3-642-79057-7_6 . Title/authors/year/pages/DOI checked against Crossref and Springer. The authors' illustrated page (https://userpages.cs.umbc.edu/rheingan/pubs/perception.html), Figure 5, compares colour, height and both for one scalar. That page labels the chapter pp.59–74; this book uses the publisher/Crossref pagination 59–73. Figures 3–5 in this project are original analytic renders, with no copied publication images.
- Plotly's public data-update API: https://plotly.com/javascript/plotlyjs-function-reference/ . Fixed trace slots use `restyle`; frame updates do not replace the layout. Complete camera state is retained separately for each coordinate view.

Crossref JSON responses and local PDF text extracts are retained in the independent `Check from Codex/julia_camera_cues_2026-10-25` audit folder.

## Perception and coordinate extension — 25 October 2026

- Todd, J. T. (2004). *The visual perception of 3D shape*. Trends in Cognitive Sciences, 8(3), 115–121. https://doi.org/10.1016/j.tics.2004.01.006 . User's article: https://www.sciencedirect.com/science/article/pii/S1364661304000233 . Metadata checked against Crossref, the publisher's indexed record and PubMed PMID15301751. The publisher page returned403 to direct fetching; the same published seven-page article was read from a university-hosted copy: https://faculty.runi.ac.il/arik/lodseminar/06shapeperception/todd_2004.pdf . Figure1 discusses shading, contour and texture cues; Figure2 and the conclusion describe ambiguity/distortion of perceived geometry. No publication images were reproduced. This review does not establish a four-dimensional maximum for human perception. The Summary formula is explicitly the author's informal display analogy.
- NIST Digital Library of Mathematical Functions: https://dlmf.nist.gov/1.5#ii (cylindrical/spherical conventions), https://dlmf.nist.gov/28.32#i (elliptical coordinates; extend with Z for elliptic cylindrical), https://dlmf.nist.gov/30.13#i (prolate spheroidal, dimensionless ξ/η convention), https://dlmf.nist.gov/14.19#i (toroidal). These definitions support the concise coordinate table. Scalar-axis reassignment and coordinate transformations are explicitly distinguished; no density/MSP equivalence is claimed.
- Original Figure3–7 geometry, lighting/colour choices, units and normalization are recorded in `assets/encoding/provenance.json`. Earlier Figure3–5 files were backed up before regeneration. Grey shading is based on surface lighting, not a grey scalar-height colourmap. All five panels represent x/y/h, with identical geometry/camera for the first four and matching scalar normalization for the coloured maps.

Crossref JSON, the paper/text extraction and reading notes for this extension are in `Check from Codex/julia_perception_coordinates_2026-10-25`.

## Part I sources — 26 October 2026

- Xu, Yiyun (2026). *Continuous Indoor Localization through Lidar and IMU Sensor Fusion*. MSc thesis, Department of Electrical Engineering, Eindhoven University of Technology. Verified from the local primary PDF `Reference/final_report_with_cover_Yiyun.pdf`, cover/title pages. L-walk measurement attribution follows the author's request; foreground cache remains project processing, with unchanged source data. No verified public thesis URL is asserted.
- Comaniciu, D., & Meer, P. (2002). *Mean Shift: A Robust Approach Toward Feature Space Analysis*. IEEE TPAMI24(5),603–619. DOI https://doi.org/10.1109/34.1000236 . Crossref metadata and author's primary PDF https://comaniciu.net/Papers/MsRobustApproach.pdf checked. Supports Gaussian mean-shift background; project centroid asymptotics/bounds are separately attributed.
- NIST DLMF https://dlmf.nist.gov/1.5 supports coordinate changes/Jacobians. The notebook explicitly uses downward inclination; it states its convention rather than assuming the standard upward polar angle.
- SciPy https://docs.scipy.org/doc/scipy/reference/generated/scipy.ndimage.gaussian_filter.html supports half-sample reflect, wrap and explicit radius conventions. Julia uses radius ceil(4σcells), so the SciPy comparison passes this radius explicitly (not the library's default rounding).
- Gaussian/centroid derivations: project notes of16 and19 October2026, reconciled in `PART1_EQUATIONS.md`. Full-space assumptions are separated from the finite reflected viewer.
- Figure1.1 copies the project's `Graphs/density energy analogy.png` unchanged. Historical energy labels are marked as analogy; the new field is count density.
- New direct dependencies: CodecZlib0.7.9, HypertextLiteral1.0.0, JSON1.12.0 and Julia stdlibs. They were already cached; Pkg.resolve did not upgrade versions. Plotly remains the locally bundled MIT script. Numerical computation is Julia; JS only renders arrays and dB visual scaling.

## Botanical interaction / dense bandwidth sweep — 26 October 2026

- Xu, Q., Zhong, Y., & Neumann, U. (2022). *Behind the Curtain: Learning Occluded Shapes for 3D Object Detection*. Proceedings of the AAAI Conference on Artificial Intelligence36(3),2893–2901. DOI https://doi.org/10.1609/aaai.v36i3.20194 . Publisher metadata plus Crossref checked; primary PDF https://ojs.aaai.org/index.php/AAAI/article/download/20194/19953 , Section1.1/Figure1, explains self-occlusion, external occlusion and signal miss. It is used as an explanatory reference, not credited with originating self-occlusion.
- Ester, M., Kriegel, H.-P., Sander, J., & Xu, X. (1996). *A Density-Based Algorithm for Discovering Clusters in Large Spatial Databases with Noise*. KDD-96,226–231. Primary publisher PDF https://cdn.aaai.org/KDD/1996/KDD96-037.pdf . Section3 defines density reachability/connectivity using Eps and MinPts; this supports the conceptual last analogy row, not a new implementation or peak-count equivalence. The authors' university publication record corroborates authors/title/year.
- Current Figure1.1 is original code-native vector geometry generated in `src/BotanicalAnalogy.jl`. It replaces the static original-image display; the original PNG remains unchanged. SVG marks are explanatory, not measured photon/point data.
- Independent sweep: full-space equal-bandwidth XY Gaussian, original support or world-origin square-bin centres retaining counts. All original observations contribute; no output raster/reflection. Diagnostic lines are broken at ties/unverified modes/large steps. σ samples are logarithmic, default160 over0.03–1000cm; this increases actual numerical samples rather than applying a cosmetic spline.

## Curved chart rendering — 26 October 2026

Plotly surface API supports two-dimensional X/Y arrays for parametric surfaces and independent surfacecolor: https://plotly.com/javascript/reference/surface/ . Curved displays embed existing Julia coordinate-bin values; no new measured points or density information are generated. Synthetic directional volume mixtures are original pedagogical constructions, not literature-calibrated illumination models.

## Blurring and separation comparison — 27 October 2026

- Carreira-Perpiñán, M. Á. (2006). *Fast Nonparametric Clustering with Gaussian Blurring Mean-Shift*. ICML2006. Primary author PDF: https://faculty.ucmerced.edu/mcarreira-perpinan/papers/icml06.pdf . It supports the distinction between ordinary fixed-support mean shift and GBMS, the two early-compaction/late-merging phases, the moving-support update, and the fact that a broad Gaussian process ultimately collapses to coincident support. This project displays movement-entropy change as a diagnostic but does not copy the paper's stopping tolerance as a universal LiDAR threshold.
- Carreira-Perpiñán, M. Á. (2008). *Generalised Blurring Mean-Shift Algorithms for Nonparametric Clustering*. CVPR2008. Primary author PDF: https://faculty.ucmerced.edu/mcarreira-perpinan/papers/cvpr08c.pdf . It supports the optional step-size form. The page defaults to the original update eta=1 and labels eta as an exploratory control.
- DBSCAN follows Ester et al.(1996), already cited above. The new implementation is a small-scene reference implementation with Euclidean epsilon and minPts; it is not presented as an optimized library benchmark.
- The MSP water-level panel and discrete peak-to-saddle bottleneck calculation are original project code. A density superlevel component is a topographic candidate, not a verified person. The synthetic bridge generator is illustrative and not a physical LiDAR/contact simulator.
