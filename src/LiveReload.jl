module LiveReload

using SHA

"""Files read by the research-book modules; ignore data and bundled vendor code."""
function source_files(root)
    files=String[]
    for dir in (joinpath(root,"src"),joinpath(root,"assets"))
        isdir(dir) || continue
        for (folder,_,names) in walkdir(dir), name in names
            path=joinpath(folder,name)
            if (endswith(name,".jl") || endswith(name,".html") || endswith(name,".js")) &&
               name!="plotly.min.js" && name!="LiveReload.jl"
                push!(files,path)
            end
        end
    end
    for name in ("PART1_EQUATIONS.md","DIMENSION_ANALOGY.md")
        path=joinpath(root,name);isfile(path)&&push!(files,path)
    end
    sort!(files)
end

function signature(root)
    [(p,stat(p).mtime,stat(p).size) for p in source_files(root)]
end

function fingerprint(root)
    io=IOBuffer()
    for path in source_files(root)
        write(io,path);write(io,0x00);write(io,sha256(read(path)))
    end
    bytes2hex(sha256(take!(io)))
end

mutable struct Monitor
    stopped::Bool
    task::Union{Nothing,Task}
    revisions::Int
    last_error::Union{Nothing,String}
end

"""Debounced source watcher. Unchanged file contents never trigger a reload."""
function start(onchange,root; interval=1.0)
    previous=signature(root);digest=fingerprint(root);pending=nothing
    monitor=Monitor(false,nothing,0,nothing)
    monitor.task=@async while !monitor.stopped
        sleep(interval)
        monitor.stopped && break
        try
            current=signature(root)
            if current!=previous
                # Wait for one stable poll to avoid reading a partially saved file.
                previous=current;pending=current
            elseif pending!==nothing
                pending=nothing;updated=fingerprint(root)
                if updated!=digest
                    digest=updated;onchange();monitor.revisions+=1;monitor.last_error=nothing
                end
            end
        catch error
            monitor.last_error=sprint(showerror,error)
            @warn "Live reload could not finish; fix the source and save again." exception=(error,catch_backtrace())
        end
    end
    monitor
end

stop(m::Monitor)=(m.stopped=true)

"""Reload only book notebooks opened in this launcher's own Pluto session."""
function attach(Pluto,session,root;interval=1.0)
    prefix=lowercase(normpath(abspath(root)))*string(Base.Filesystem.path_separator)
    start(root;interval) do
        for notebook in collect(values(session.notebooks))
            path=lowercase(normpath(abspath(notebook.path)))
            startswith(path,prefix) || continue
            isempty(notebook.cells) && continue
            occursin("Base.include",notebook.cells[1].code) || continue
            println("[Live reload] ",basename(notebook.path)," · shared source saved")
            Pluto.update_run!(session,notebook,[notebook.cells[1]];run_async=false)
        end
    end
end

end
