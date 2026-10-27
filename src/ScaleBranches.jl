"""Local scale-space branches anchored at a chosen scale; no object labels enter search."""
function scale_branches(Q,weights,sigmas,starts;anchor_cm=7.5)
    anchor=argmin(abs.(log.(sigmas./(anchor_cm/100))))
    state=mode_at(Q,sigmas[anchor],starts;weights)
    candidates=sort(state.maxima;by=q->-q.logvalue)
    candidates=filter(q->q.logvalue>=state.logvalue-log(20),candidates)
    candidates=candidates[1:min(6,length(candidates))]
    branches=[Dict{String,Any}("id"=>b,"xy"=>Any[nothing for _ in sigmas],"events"=>Any[]) for b in eachindex(candidates)]
    for (b,q) in zip(branches,candidates);b["xy"][anchor]=q.point;end
    for direction in (-1,1)
        active=trues(length(branches));previous=[q.point for q in candidates]
        for i in (anchor+direction):direction:(direction==1 ? length(sigmas) : 1)
            points=Any[nothing for _ in branches]
            for b in eachindex(branches)
                active[b] || continue
                point=mode_at(Q,sigmas[i],[previous[b]];weights,iterations=900).point
                if point===nothing || norm(point-previous[b])>max(.08,.75sigmas[i])
                    active[b]=false
                    push!(branches[b]["events"],Dict("index"=>i,"reason"=>"lost / large step; branch not connected"))
                else points[b]=point end
            end
            # If branches reach the same verified maximum, stop both identities here.
            merged=falses(length(branches))
            for b in eachindex(branches),d in (b+1):length(branches)
                if points[b]!==nothing && points[d]!==nothing && norm(points[b]-points[d])<1e-4
                    merged[b]=merged[d]=true
                end
            end
            for b in eachindex(branches)
                if points[b]!==nothing
                    branches[b]["xy"][i]=points[b];previous[b]=points[b]
                    if merged[b]
                        active[b]=false
                        push!(branches[b]["events"],Dict("index"=>i,"reason"=>"shared mode; individual branch ends"))
                    end
                end
            end
            any(active) || break
        end
    end
    Dict("anchor_index"=>anchor,"anchor_cm"=>100sigmas[anchor],"items"=>branches,
        "policy"=>"Up to six verified local maxima within a 20:1 density ratio at the anchor; deterministic multistart, not an exhaustive peak/person count. Continue each seed through adjacent sigma values; stop at failed verification, a large step, or a shared mode. Branch IDs are scale labels, not tracking IDs.")
end

function object_references(P,ids)
    [Dict("object_id"=>k,"xy"=>vec(mean(P[ids.==k,1:2];dims=1)),"points"=>count(==(k),ids)) for k in sort(unique(ids)) if k>0]
end

function label_branch_references!(s)
    refs=s["references"];branches=s["branches"]["items"];anchor=s["branches"]["anchor_index"]
    # Evaluation-only nearest reference. Multiple branches may refer to one object;
    # this intentionally exposes over-detection instead of forcing a one-person/one-peak fit.
    for b in branches
        if isempty(refs);b["reference_id"]=nothing;b["error_mm"]=Any[nothing for _ in s["sigma_cm"]];continue;end
        k=argmin([norm(b["xy"][anchor]-r["xy"]) for r in refs]);r=refs[k]
        b["reference_id"]=r["object_id"]
        b["error_mm"]=Any[q===nothing ? nothing : 1000norm(q-r["xy"]) for q in b["xy"]]
    end
end
