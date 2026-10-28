module HierarchyStudy
using JSON
include("PeakHierarchy.jl")
using .PeakHierarchy

export payload, markup, script

# All hierarchy/metric/scale data delivered to the browser are computed in Julia.
function payload(S; seed=27, sigmas=(.045,.06,.075,.08,.09,.10,.11,.115,.12,.13,.15,.18,.20,.24))
    scenes=Any[]
    for kind in ("two_targets","two_arm","head_shoulders","arms_open","three_targets","four_targets","large_attachment","weak_person")
        base=S.synthetic_scene(seed=seed)
        if kind in ("two_targets","weak_person")
            P=kind=="weak_person" ? S.synthetic_scene(seed=seed,imbalance=4.).points : base.points
            truth=2; name=kind=="weak_person" ? "Two targets · 4:1 return imbalance" : "Two targets · original bridge regression"
        else
            rng=S.StudyRNG(seed); pts=Vector{Float64}[]
            specs=kind=="head_shoulders" ? [(120,0.,0.,.065,.085),(50,-.15,-.06,.045,.07),(50,.15,-.06,.045,.07)] :
                kind=="arms_open" ? [(140,0.,0.,.08,.12),(40,-.32,0.,.055,.045),(40,.32,0.,.055,.045)] :
                kind=="two_arm" ? [(120,-.28,0.,.065,.09),(110,.30,0.,.065,.09),(24,-.28,.25,.055,.04)] :
                kind=="large_attachment" ? [(120,-.28,0.,.065,.09),(110,.30,0.,.065,.09),(60,-.28,.25,.055,.04)] :
                kind=="four_targets" ? [(100,-.32,-.22,.065,.07),(90,.32,-.22,.065,.07),(100,-.32,.22,.065,.07),(90,.32,.22,.065,.07)] :
                [(110,-.42,0.,.065,.10),(100,-.08,0.,.065,.10),(80,.40,0.,.065,.10)]
            for (n,cx,cy,sx,sy) in specs, _ in 1:n
                push!(pts,[cx+sx*S.normal!(rng),cy+sy*S.normal!(rng)])
            end
            P=reduce(vcat,permutedims.(pts)); truth=kind=="three_targets" ? 3 : kind=="four_targets" ? 4 : kind in ("two_arm","large_attachment") ? 2 : 1
            name=kind=="head_shoulders" ? "Single target · head and shoulders" :
                kind=="arms_open" ? "Single target · arms open" : kind=="two_arm" ? "Two targets · small attached contribution (24 returns)" : kind=="large_attachment" ? "Two targets · large attached contribution (60 returns)" : kind=="four_targets" ? "Four targets · separated supports" : "Three targets · nested merging"
        end
        frames=Any[]
        for sigma in sigmas
            f=S.gaussian_field(P;sigma=sigma)
            area=(f.x[2]-f.x[1])*(f.y[2]-f.y[1])
            fields=Dict{String,Any}()
            # Unit-integral 2D Gaussian: intensity integrates to expected return count.
            density=f.rho./(2pi*sigma^2)
            for (field,values) in (("density",density),)
                t=merge_tree(values;cellarea=area)
                ps=Any[]
                for p in t.peaks
                    m=p[:metrics]
                    event=m===nothing ? nothing : only(filter(e->e.level==p[:death] && any(b->b.peak==p[:id],e.branches),t.events))
                    event_mass=event===nothing ? nothing : sum(b.metrics.mass for b in event.branches)
                    share=event_mass===nothing || event_mass==0 ? nothing : m.mass/event_mass
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
                        "height"=>p[:relative_height],"metrics"=>m,"raw_support"=>m===nothing ? nothing : support,
                        "mass_share"=>share,"event_mass"=>event_mass))
                end
                fields[field]=Dict("peaks"=>ps,"events"=>t.events)
            end
            push!(frames,Dict("sigma"=>sigma,"rho"=>[collect(r) for r in eachrow(density)],"fields"=>fields,
                "domain_count"=>sum(density)*area,"source_count"=>size(P,1)))
        end
        push!(scenes,Dict("id"=>kind,"name"=>name,"truth"=>truth,"points"=>S.rows(P),
            "x"=>collect(range(-.72,.72;length=82)),"y"=>collect(range(-.5,.5;length=58)),"frames"=>frames))
    end
    Dict("scenes"=>scenes,"adjacency"=>8,"seed"=>seed,
        "normalization"=>"Sum of unit-integral 2D Gaussian kernels: exp(-r²/(2σ²))/(2πσ²), returns/m²; area quadrature yields smoothed return count. Finite-domain tails are not renormalised.",
        "scope"=>"Synthetic controls; thresholds exploratory; local peaks, modes, components, target hypotheses and tracks are distinct.")
end

markup()=read(joinpath(@__DIR__,"..","assets","hierarchy_viewer.html"),String)
script()=read(joinpath(@__DIR__,"..","assets","hierarchy_viewer.js"),String)
end
