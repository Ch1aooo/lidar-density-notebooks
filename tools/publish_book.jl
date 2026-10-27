# Build one chapter per Julia process; do not start or reuse an HTTP/Pluto server.
import Pkg
Pkg.activate(joinpath(@__DIR__,".."))
ENV["JULIA_BOOK_STATIC_EXPORT"]="true"
ENV["JULIA_NUM_PRECOMPILE_TASKS"]="1"
ENV["JULIA_PKG_PRECOMPILE_AUTO"]="0"
using Pluto
length(ARGS)==2 || error("Usage: julia --project=. tools/publish_book.jl chapter.jl output_directory")
chapter=ARGS[1];root=normpath(joinpath(@__DIR__,".."));destination=abspath(ARGS[2]);mkpath(destination)
options=Pluto.Configuration.from_flat_kwargs(;disable_writing_notebook_files=true,workspace_use_distributed=false,launch_browser=false)
session=Pluto.ServerSession(;options)
notebook=Pluto.load_notebook_nobackup(joinpath(root,chapter));session.notebooks[notebook.notebook_id]=notebook
try
    Pluto.update_run!(session,notebook,notebook.cells;run_async=false)
    failed=filter(c->c.errored,notebook.cells)
    for cell in failed;println(stderr,"Cell failed: ",cell.cell_id," ",cell.output.body);end
    isempty(failed) || error("Refusing to publish $(length(failed)) failed cells in $chapter")
    stem=replace(chapter,r"\.jl$"=>"")
    open(joinpath(destination,stem*".plutostate"),"w") do io
        Pluto.pack(io,Pluto.notebook_to_js(notebook))
    end
    html=Pluto.generate_html(;statefile_js=repr("./"*stem*".plutostate"),notebookfile_js=repr("./"*chapter),binder_url_js="undefined")
    banner="""<div style="position:sticky;top:0;z-index:1000;background:#edf4fb;border-bottom:1px solid #c1d6eb;padding:8px 16px;font:13px/1.5 system-ui;color:#234761"><a href="./index.html">Research notebook home</a> · Published reading edition. Embedded charts retain browser controls; Julia-backed controls require local Julia. <a href="https://github.com/Ch1aooo/lidar-density-notebooks">Source & updates</a></div>"""
    banner*="""<script data-published-control-lock>(()=>{const lock=()=>document.querySelectorAll('.part1-controls input,.part1-controls select,.part1-controls button').forEach(el=>{el.disabled=true;el.title='Published snapshot: use local Julia to recompute this control.';});new MutationObserver(lock).observe(document.body,{childList:true,subtree:true});lock();})();</script>"""
    html=replace(html,r"<body\b[^>]*>"=>(matched->matched*banner);count=1)
    write(joinpath(destination,stem*".html"),html)
    cp(joinpath(root,chapter),joinpath(destination,chapter);force=true)
    println("EXPORTED ",chapter," · ",length(notebook.cells)," cells · zero errors")
finally
    Pluto.SessionActions.shutdown(session,notebook;keep_in_session=false)
end
