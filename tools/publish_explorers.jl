import Pkg
Pkg.activate(joinpath(@__DIR__,".."))
using JSON
include(joinpath(@__DIR__,"..","src","BookUI.jl"))
include(joinpath(@__DIR__,"..","src","DensityPartI.jl"))
include(joinpath(@__DIR__,"..","src","PartIPage.jl"))
out=abspath(only(ARGS));mkpath(out)
BookUI.export_viewers(out)
settings=(source="synthetic",frame=97,support="all",model="raw",delta_cm=1.,samples=96,min_cm=.03,max_cm=1000.,n=400,targets=3,separation=.7,seed=7,upload=nothing,csvframe=0)
payload=DensityPartI.study_evaluate(settings,normpath(joinpath(@__DIR__,"..")))
payload["empty"] && error(payload["message"])
write(joinpath(out,"peak_explorer.html"),PartIPage.study_document(payload=payload))
println("Browser-only walk, scalar-field and three-object peak explorers exported.")
