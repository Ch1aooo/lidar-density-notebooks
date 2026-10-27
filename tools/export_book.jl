include(joinpath(@__DIR__, "..", "src", "BookUI.jl"))
destination = isempty(ARGS) ? joinpath(@__DIR__, "..", "exports") : abspath(first(ARGS))
BookUI.export_viewers(destination)
println("Standalone interactive views exported to: ", destination)
