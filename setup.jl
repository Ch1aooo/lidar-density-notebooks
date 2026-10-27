import Pkg
Pkg.activate(@__DIR__)
ENV["JULIA_NUM_PRECOMPILE_TASKS"] = "1"
ENV["JULIA_IMAGE_THREADS"] = "1"
Pkg.instantiate()
Pkg.precompile()
println("Setup complete. Start the notebook with: include(\"launch.jl\")")
