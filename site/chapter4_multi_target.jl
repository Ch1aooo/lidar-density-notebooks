### A Pluto.jl notebook ###
# v1.0.4
using Markdown
using InteractiveUtils

# ╔═╡ a8254000-2026-4025-8000-000000000001
book = Base.include(Module(gensym(:BookWorkspace)), joinpath(@__DIR__, "src", "BookUI.jl"));

# ╔═╡ a8254000-2026-4025-8000-000000000002
book.styles()

# ╔═╡ a8254000-2026-4025-8000-000000000003
book.navigation("chapter4_multi_target.jl")

# ╔═╡ a8254000-2026-4025-8000-000000000004
md"""
# IV · Multiple People and Robots
*Chapter outline · future research, not a demonstrated capability.*

## Summary
Move from one representative trajectory to target separation and persistent identity association.

## Question
How can we distinguish a person from a robot, separate nearby people, and preserve each identity?

## Input
Reserved for multi-target recordings and verified identity labels. The current introduction contains one recorded person only.

## Representation
Multiple candidate positions, object attributes, track identities and association uncertainty.

## Experiment
Reserved for crossings, close approaches, occlusion, disappearance and reappearance.

## Evidence
To be added. Report separation failures, identity switches and missing tracks alongside localization behaviour.
"""

# ╔═╡ a8254000-2026-4025-8000-000000000005
book.footer("chapter4_multi_target.jl")

# ╔═╡ Cell order:
# ╟─a8254000-2026-4025-8000-000000000001
# ╟─a8254000-2026-4025-8000-000000000002
# ╟─a8254000-2026-4025-8000-000000000003
# ╟─a8254000-2026-4025-8000-000000000004
# ╟─a8254000-2026-4025-8000-000000000005
