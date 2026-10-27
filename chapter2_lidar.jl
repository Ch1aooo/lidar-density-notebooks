### A Pluto.jl notebook ###
# v1.0.4
using Markdown
using InteractiveUtils

# ╔═╡ a8252000-2026-4025-8000-000000000001
book = Base.include(Module(gensym(:BookWorkspace)), joinpath(@__DIR__, "src", "BookUI.jl"));

# ╔═╡ a8252000-2026-4025-8000-000000000002
book.styles()

# ╔═╡ a8252000-2026-4025-8000-000000000003
book.navigation("chapter2_lidar.jl")

# ╔═╡ a8252000-2026-4025-8000-000000000004
md"""
# II · Ceiling-mounted LiDAR
*Chapter outline · content to be added.*

## Summary
Connect sensor geometry and acquisition parameters to the observed point cloud.

## Question
How do mounting height, field of view, angular sampling, range and occlusion change visible support?

## Input
Sensor metadata, coordinate conventions and recorded frames. Verify units and timestamps.

## Representation
World coordinates, sensor coordinates and explicit parameter definitions.

## Experiment
Reserved for parameter illustrations and controlled comparisons. Place each control beside its figure.

## Evidence
To be added. Distinguish a geometric illustration from a calibrated sensor model.
"""

# ╔═╡ a8252000-2026-4025-8000-000000000005
book.footer("chapter2_lidar.jl")

# ╔═╡ Cell order:
# ╟─a8252000-2026-4025-8000-000000000001
# ╟─a8252000-2026-4025-8000-000000000002
# ╟─a8252000-2026-4025-8000-000000000003
# ╟─a8252000-2026-4025-8000-000000000004
# ╟─a8252000-2026-4025-8000-000000000005
