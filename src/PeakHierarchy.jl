module PeakHierarchy

export merge_tree, component_metrics, select_peaks, pair_saddle

const OFFSETS = ((-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1))

"""Metrics on an explicit strict-superlevel component; area is quadrature area,
not physical body volume. Values must be linear density or linear squared density."""
function component_metrics(values, cells, level, cellarea)
    mass = sum((values[k] for k in cells); init=0.0) * cellarea
    excess = sum((values[k]-level for k in cells); init=0.0) * cellarea
    (cells=copy(cells), area=length(cells)*cellarea, mass=mass,
     excess=excess, relative_excess=mass>0 ? excess/mass : 0.0)
end

"""Descending union-find merge tree on a finite regular 8-connected grid.

Exact equal levels activate together, so plateaus create one maximum and
simultaneous merges create one event. Elder rule: higher birth wins, then lower
column-major representative index. No peak-count or distance suppression.
At a merge, event branches contain the components strictly above its level,
including the surviving branch. A dying peak's own metrics use that component.
Root persistence/death/metrics are `nothing`: the finite-domain root has no
observed merge saddle and must not be assigned artificial significance.
"""
function merge_tree(rho::AbstractMatrix; cellarea::Real=1.0)
    all(isfinite,rho) && all(>=(0),rho) || throw(ArgumentError("finite nonnegative linear field required"))
    isfinite(cellarea) && cellarea>0 || throw(ArgumentError("positive cell area required"))
    ny,nx=size(rho); v=Float64.(vec(rho)); n=length(v)
    parent=collect(1:n); active=falses(n); owner=zeros(Int,n)
    members=[Int[] for _ in 1:n]; peaks=Dict{Symbol,Any}[]; events=Any[]
    function root(a)
        while parent[a]!=a
            parent[a]=parent[parent[a]]; a=parent[a]
        end
        a
    end
    function join(a,b)
        a=root(a); b=root(b); a==b && return a
        length(members[a])<length(members[b]) && ((a,b)=(b,a))
        parent[b]=a; append!(members[a],members[b]); empty!(members[b]); a
    end
    neighbours(k) = (jj+(ii-1)*ny for (dj,di) in OFFSETS
        for (jj,ii) in ((mod1(k,ny)+dj,div(k-1,ny)+1+di),)
        if 1<=jj<=ny && 1<=ii<=nx)
    order=sortperm(v;by=k->-k,alg=MergeSort); h=1
    while h<=n
        level=v[order[h]]; tail=h
        while tail<n && v[order[tail+1]]==level; tail+=1; end
        batch=order[h:tail]
        # Capture old components before adding any level-tied cell.
        old=Dict{Int,Tuple{Int,Vector{Int}}}()
        for k in batch, q in neighbours(k)
            if active[q]
                r=root(q)
                haskey(old,r) || (old[r]=(owner[r],copy(members[r])))
            end
        end
        for k in batch; active[k]=true; members[k]=[k]; end
        for k in batch, q in neighbours(k); active[q] && join(k,q); end
        groups=Dict{Int,Vector{Int}}()
        for k in batch; push!(get!(groups,root(k),Int[]),k); end
        for r in sort(collect(keys(groups));by=r->minimum(groups[r]))
            prior=[entry for (oldroot,entry) in old if root(oldroot)==r]
            if isempty(prior)
                # An all-zero field has no supported candidate.
                level==0 && continue
                id=length(peaks)+1; k=minimum(groups[r])
                push!(peaks,Dict(:id=>id,:index=>k,:row=>mod1(k,ny),
                    :col=>div(k-1,ny)+1,:birth=>level,:parent=>0,:death=>nothing,
                    :persistence=>nothing,:relative_height=>nothing,:metrics=>nothing,
                    :plateau_cells=>sort(copy(groups[r]))))
                owner[r]=id
            else
                sort!(prior;by=t->(-peaks[t[1]][:birth],peaks[t[1]][:index]))
                winner=prior[1][1]; owner[r]=winner
                if length(prior)>1
                    branches=[(peak=id, metrics=component_metrics(v,cells,level,cellarea)) for (id,cells) in prior]
                    event=(level=level, survivor=winner, branches=branches,
                           saddle_cells=sort(copy(groups[r])))
                    push!(events,event)
                    for (id,cells) in prior[2:end]
                        p=peaks[id]; p[:parent]=winner; p[:death]=level
                        p[:persistence]=p[:birth]-level
                        p[:relative_height]=1-level/p[:birth]
                        p[:metrics]=component_metrics(v,cells,level,cellarea)
                    end
                end
            end
        end
        h=tail+1
    end
    (peaks=peaks,events=events,shape=(ny,nx),cellarea=Float64(cellarea),
     adjacency=8,root_convention="essential root: no finite merge metrics")
end

"""Pair bottleneck from the elder-rule parent tree; no water-slider dependence."""
function pair_saddle(tree,a::Int,b::Int)
    1<=a<=length(tree.peaks) && 1<=b<=length(tree.peaks) || throw(BoundsError())
    a==b && return tree.peaks[a][:birth]
    ancestors=Dict{Int,Float64}(); level=Inf; k=a
    while k!=0
        ancestors[k]=level; p=tree.peaks[k]
        p[:death]!==nothing && (level=min(level,p[:death])); k=p[:parent]
    end
    level=Inf; k=b
    while k!=0
        haskey(ancestors,k) && return min(level,ancestors[k])
        p=tree.peaks[k]; p[:death]!==nothing && (level=min(level,p[:death])); k=p[:parent]
    end
    nothing
end

"""Independent exploratory thresholds, not calibrated physical-person counts.
The essential root is retained explicitly, without fabricated finite metrics."""
function select_peaks(tree; min_height=0.0,min_excess=0.0)
    [p[:id] for p in tree.peaks if p[:parent]==0 ||
        (p[:relative_height]>=min_height && p[:metrics].relative_excess>=min_excess)]
end

end
