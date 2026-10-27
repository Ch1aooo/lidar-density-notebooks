### A Pluto.jl notebook ###
# v1.0.4
using Markdown
using InteractiveUtils

# ╔═╡ a8253000-2026-4025-8000-000000000001
book = Base.include(Module(gensym(:BookWorkspace)), joinpath(@__DIR__, "src", "BookUI.jl"));

# ╔═╡ a8253000-2026-4025-8000-000000000002
book.styles()

# ╔═╡ a8253000-2026-4025-8000-000000000003
book.navigation("chapter3_single_person.jl")

# ╔═╡ a8253000-2026-4025-8000-000000000004
md"""
# III · Single-person Tracking
*Chapter outline · content to be added.*

## Summary
Examine density-based representatives and their behaviour across a single-person sequence.

## Question
Which representative remains useful when sampling, pose and visible support change?

## Input
The recorded single-person sequence and, when available, independent reference positions.

## Representation
Per-frame density, candidate points and their XY trajectories.

## Experiment
Reserved for baseline comparisons, bandwidth sensitivity and temporal behaviour.

## Evidence
To be added. Separate position accuracy, coverage and temporal stability; do not use smoothness alone as accuracy.
"""

# ╔═╡ a8253000-2026-4025-8000-000000000005
book.footer("chapter3_single_person.jl")

# ╔═╡ Cell order:
# ╟─a8253000-2026-4025-8000-000000000001
# ╟─a8253000-2026-4025-8000-000000000002
# ╟─a8253000-2026-4025-8000-000000000003
# ╟─a8253000-2026-4025-8000-000000000004
# ╟─a8253000-2026-4025-8000-000000000005
