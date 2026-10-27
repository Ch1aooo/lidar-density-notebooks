import Pkg
Pkg.activate(@__DIR__)
ENV["JULIA_NUM_PRECOMPILE_TASKS"] = "1"
ENV["JULIA_IMAGE_THREADS"] = "1"
using Pluto
include(joinpath(@__DIR__,"src","LiveReload.jl"))

notebook_name = isempty(ARGS) ? "introduction.jl" : first(ARGS)
notebook_path = isabspath(notebook_name) ? notebook_name : joinpath(@__DIR__, notebook_name)
isfile(notebook_path) || error("Notebook not found: " * notebook_path)

live_options=Pluto.Configuration.from_flat_kwargs(
    notebook=notebook_path,
    host="127.0.0.1",
    port=1234,
    launch_browser=true,
    auto_reload_from_file=true,
)
live_session=Pluto.ServerSession(;options=live_options)
live_monitor=LiveReload.attach(Pluto,live_session,@__DIR__)
println("Live reload enabled: save src / viewer HTML-JS / equation files; reload starts after about 2 seconds.")
try
    Pluto.run(live_session)
finally
    LiveReload.stop(live_monitor)
end
