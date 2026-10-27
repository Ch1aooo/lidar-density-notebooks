# LiDAR Density Research Notebook

[Open the shared website](https://ch1aooo.github.io/lidar-density-notebooks/)

Julia/Pluto research notebook by Yehao Chen. The website is a reading edition with browser-only explorers. Visitors do not need Julia. Live Julia-backed notebook controls are available locally, not on GitHub Pages.

## Run locally

Install Julia 1.12.6, then run `julia --project=. setup.jl` and `julia --project=. launch.jl`. Open Part I with `julia --project=. launch.jl chapter1_density.jl`.

## Update the shared edition

Commit updated Julia source/assets/data, then run **Actions → Rebuild website from Julia source → Run workflow**. This evaluates all five notebooks and deploys the new website at the same address. Failed notebook cells stop the build. Browser-only explorers use their configured input presets. Local unsaved/unpushed changes are not published.

Alternatively, rebuild locally with `tools/publish_book.jl chapter.jl site` for each chapter and `tools/publish_explorers.jl site`, run `python tools/finalize_site.py`, then commit/push `site`. The Publish notebook website workflow deploys those reviewed artifacts.

## Scientific scope and provenance

The synthetic ellipsoids illustrate density structure; they are not physical human/LiDAR simulation or evidence of tracking accuracy. Local peaks are candidates, not person IDs. Read SOFTWARE_SOURCES.md, PART1_EQUATIONS.md and data/measured_walk_metadata.json for definitions, attribution and measured-data provenance. Published measured coordinates are unchanged from the local saved foreground sequence; no verified timestamps, interpolation or anatomical ground truth is claimed.

Third-party software retains its own licences; Plotly notice is in assets/PLOTLY_LICENSE.txt. Research text/data are not assigned a new blanket software licence by this publication.
