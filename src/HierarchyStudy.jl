module HierarchyStudy
using JSON
include("PeakHierarchy.jl")
using .PeakHierarchy

export payload, markup, script

# All hierarchy/metric/scale data delivered to the browser are computed in Julia.
function payload(S)
    scenes=Any[]
    for kind in ("two_targets","head_shoulders","arms_open","three_targets")
        base=S.synthetic_scene()
        if kind=="two_targets"
            P=base.points; truth=2; name="Two targets · original bridge regression"
        else
            rng=S.StudyRNG(27); pts=Vector{Float64}[]
            specs=kind=="head_shoulders" ? [(120,0.,0.,.065,.085),(50,-.15,-.06,.045,.07),(50,.15,-.06,.045,.07)] :
                kind=="arms_open" ? [(140,0.,0.,.08,.12),(40,-.32,0.,.055,.045),(40,.32,0.,.055,.045)] :
                [(110,-.42,0.,.065,.10),(100,-.08,0.,.065,.10),(80,.40,0.,.065,.10)]
            for (n,cx,cy,sx,sy) in specs, _ in 1:n
                push!(pts,[cx+sx*S.normal!(rng),cy+sy*S.normal!(rng)])
            end
            P=reduce(vcat,permutedims.(pts)); truth=kind=="three_targets" ? 3 : 1
            name=kind=="head_shoulders" ? "Single target · head and shoulders" :
                kind=="arms_open" ? "Single target · arms open" : "Three targets · nested merging"
        end
        frames=Any[]
        for sigma in (.045,.06,.08,.10,.115,.15,.20,.24)
            f=S.gaussian_field(P;sigma=sigma)
            area=(f.x[2]-f.x[1])*(f.y[2]-f.y[1])
            fields=Dict{String,Any}()
            for (field,values) in (("density",f.rho),("energy",f.rho.^2))
                t=merge_tree(values;cellarea=area)
                ps=Any[]
                for p in t.peaks
                    m=p[:metrics]
                    # Original measurements are mapped to nearest grid node; outside-domain points stay unassigned.
                    mask=m===nothing ? Set{Int}() : Set(m.cells)
                    support=count(axes(P,1)) do k
                        x,y=P[k,1],P[k,2]
                        first(f.x)<=x<=last(f.x) && first(f.y)<=y<=last(f.y) || return false
                        i=clamp(round(Int,(x-first(f.x))/(f.x[2]-f.x[1]))+1,1,length(f.x))
                        j=clamp(round(Int,(y-first(f.y))/(f.y[2]-f.y[1]))+1,1,length(f.y))
                        j+(i-1)*length(f.y) in mask
                    end
                    push!(ps,Dict("id"=>p[:id],"x"=>f.x[p[:col]],"y"=>f.y[p[:row]],
                        "birth"=>p[:birth],"death"=>p[:death],"parent"=>p[:parent],
                        "height"=>p[:relative_height],"metrics"=>m,"raw_support"=>m===nothing ? nothing : support))
                end
                fields[field]=Dict("peaks"=>ps,"events"=>t.events)
            end
            push!(frames,Dict("sigma"=>sigma,"rho"=>[collect(r) for r in eachrow(f.rho)],"fields"=>fields))
        end
        push!(scenes,Dict("id"=>kind,"name"=>name,"truth"=>truth,"points"=>S.rows(P),
            "x"=>collect(range(-.72,.72;length=82)),"y"=>collect(range(-.5,.5;length=58)),"frames"=>frames))
    end
    Dict("scenes"=>scenes,"adjacency"=>8,"seed"=>27,
        "normalization"=>"Unnormalised Gaussian sum; linear density score and its square. Grid spacing area quadrature.",
        "scope"=>"Synthetic controls; thresholds exploratory; local peaks, modes, components, target hypotheses and tracks are distinct.")
end

markup()=read(joinpath(@__DIR__,"..","assets","hierarchy_viewer.html"),String)
script()=read(joinpath(@__DIR__,"..","assets","hierarchy_viewer.js"),String)
end
