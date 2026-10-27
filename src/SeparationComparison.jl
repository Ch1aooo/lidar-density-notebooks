module SeparationComparison

using JSON
using LinearAlgebra
using Statistics

export synthetic_scene, dbscan, blurring_mean_shift, gaussian_field,
       water_components, study_payload, document

const ROOT = normpath(joinpath(@__DIR__, ".."))

mutable struct StudyRNG
    state::UInt32
end
StudyRNG(seed::Integer)=StudyRNG(UInt32(seed))
function uniform!(r::StudyRNG)
    r.state=UInt32((UInt64(1664525)*UInt64(r.state)+UInt64(1013904223))%UInt64(4294967296))
    Float64(r.state)/4294967296
end
normal!(r::StudyRNG)=sqrt(-2log(max(uniform!(r),eps())))*cos(2pi*uniform!(r))

"""Deterministic two-target XY support with an explicit sparse contact bridge.

`oracle` labels are returned for evaluation only and are never read by the three methods.
Bridge and background-residue points have oracle label 0.
"""
function synthetic_scene(; n_per::Int=110, separation::Float64=.56,
        bridge_fraction::Float64=.12, imbalance::Float64=1.,
        outlier_fraction::Float64=.04, seed::Int=27)
    30 <= n_per <= 1000 || throw(ArgumentError("n_per must be 30–1000"))
    .30 <= separation <= .90 || throw(ArgumentError("separation must be 0.30–0.90 m"))
    0 <= bridge_fraction <= .45 || throw(ArgumentError("bridge_fraction must be 0–0.45"))
    1 <= imbalance <= 4 || throw(ArgumentError("imbalance must be 1–4"))
    0 <= outlier_fraction <= .25 || throw(ArgumentError("outlier_fraction must be 0–0.25"))
    rng=StudyRNG(seed)
    n1=n_per; n2=max(20,round(Int,n_per/imbalance))
    nb=round(Int,bridge_fraction*(n1+n2)); no=round(Int,outlier_fraction*(n1+n2))
    P=zeros(n1+n2+nb+no,2); oracle=zeros(Int,size(P,1)); row=0
    for (k,n,cx) in ((1,n1,-separation/2),(2,n2,separation/2))
        for _ in 1:n
            row+=1
            P[row,1]=cx+.085normal!(rng)
            P[row,2]=.14normal!(rng)
            oracle[row]=k
        end
    end
    for _ in 1:nb
        row+=1
        u=uniform!(rng)
        P[row,1]=(-separation/2+.055)*(1-u)+(separation/2-.055)*u+.008normal!(rng)
        P[row,2]=.030normal!(rng)
    end
    for _ in 1:no
        row+=1
        P[row,1]=1.35(uniform!(rng)-.5)
        P[row,2]=.90(uniform!(rng)-.5)
    end
    (points=P,oracle=oracle,bounds=((-0.72,0.72),(-0.50,0.50)),
     counts=(target1=n1,target2=n2,bridge=nb,residue=no),
     settings=(n_per=n_per,separation=separation,bridge_fraction=bridge_fraction,
               imbalance=imbalance,outlier_fraction=outlier_fraction,seed=seed))
end

function distance2(P)
    n=size(P,1); D=zeros(n,n)
    for i in 1:n, j in (i+1):n
        v=(P[i,1]-P[j,1])^2+(P[i,2]-P[j,2])^2
        D[i,j]=D[j,i]=v
    end
    D
end

"""Reference DBSCAN implementation for the small browser-study scenes."""
function dbscan(P; eps::Float64=.085, minpts::Int=8)
    n=size(P,1); D=distance2(P); e2=eps^2
    neighbours=[findall(@view(D[i,:]).<=e2) for i in 1:n]
    core=map(v->length(v)>=minpts,neighbours)
    labels=zeros(Int,n); visited=falses(n); cluster=0
    for i in 1:n
        visited[i] && continue
        visited[i]=true
        if !core[i]; continue; end
        cluster+=1; labels[i]=cluster
        queue=copy(neighbours[i]); queued=falses(n); queued[queue].=true; head=1
        while head<=length(queue)
            q=queue[head]; head+=1
            if !visited[q]
                visited[q]=true
                if core[q]
                    for r in neighbours[q]
                        if !queued[r]; push!(queue,r);queued[r]=true;end
                    end
                end
            end
            labels[q]==0 && (labels[q]=cluster)
        end
    end
    sizes=[count(==(k),labels) for k in 1:cluster]
    (labels=labels,core=core,count=cluster,sizes=sizes)
end

mutable struct UnionFind
    parent::Vector{Int}
    size::Vector{Int}
end
UnionFind(n)=UnionFind(collect(1:n),ones(Int,n))
function root!(u::UnionFind,a::Int)
    while u.parent[a]!=a
        u.parent[a]=u.parent[u.parent[a]];a=u.parent[a]
    end
    a
end
function join!(u::UnionFind,a::Int,b::Int)
    a=root!(u,a);b=root!(u,b);a==b && return a
    u.size[a]<u.size[b] && ((a,b)=(b,a))
    u.parent[b]=a;u.size[a]+=u.size[b];a
end

function proximity_components(P; radius::Float64=.030, minmass::Int=8)
    n=size(P,1); D=distance2(P); u=UnionFind(n); r2=radius^2
    for i in 1:n, j in (i+1):n
        D[i,j]<=r2 && join!(u,i,j)
    end
    roots=[root!(u,i) for i in 1:n]; mass=Dict{Int,Int}()
    for r in roots;mass[r]=get(mass,r,0)+1;end
    kept=sort([r for (r,m) in mass if m>=minmass];by=r->-mass[r])
    map=Dict(r=>k for (k,r) in enumerate(kept))
    labels=[get(map,r,0) for r in roots]
    (labels=labels,count=length(kept),sizes=[mass[r] for r in kept])
end

function movement_entropy(moves)
    maximum(moves)<=eps() && return 0.
    bins=clamp(round(Int,.9length(moves)),20,max(20,length(moves)-1))
    counts=zeros(Int,bins); hi=maximum(moves)
    for v in moves
        k=clamp(floor(Int,v/hi*bins)+1,1,bins);counts[k]+=1
    end
    p=counts[counts.>0]./length(moves)
    -sum(p.*log.(p))
end

"""Gaussian blurring mean shift at fixed sigma.

All support points move and become the support for the next iteration. `eta=1` is
the original GBMS update. The returned component count is a display diagnostic
based on a separate near-coincidence radius; it is not used in the update.
"""
function blurring_mean_shift(P; sigma::Float64=.115, steps::Int=10,
        eta::Float64=1., merge_radius::Float64=.030, minmass::Int=8)
    0 < sigma || throw(ArgumentError("sigma must be positive"))
    0 < eta <= 1.5 || throw(ArgumentError("eta must be in (0,1.5]"))
    X=Matrix{Float64}(P); history=Any[copy(X)]; mean_move=[0.]; entropy=[0.]
    component_count=[proximity_components(X;radius=merge_radius,minmass).count]
    component_labels=Any[proximity_components(X;radius=merge_radius,minmass).labels]
    for _ in 1:steps
        Y=similar(X); moves=zeros(size(X,1)); s2=2sigma^2
        for i in axes(X,1)
            weights=exp.(-((X[:,1].-X[i,1]).^2+(X[:,2].-X[i,2]).^2)./s2)
            target=vec(sum(X.*weights;dims=1)./sum(weights))
            Y[i,:]=X[i,:].+eta.*(target.-X[i,:])
            moves[i]=norm(@view(Y[i,:])-@view(X[i,:]))
        end
        X=Y; c=proximity_components(X;radius=merge_radius,minmass)
        push!(history,copy(X));push!(mean_move,mean(moves));push!(entropy,movement_entropy(moves))
        push!(component_count,c.count);push!(component_labels,c.labels)
    end
    delta_entropy=[nothing;[abs(entropy[i]-entropy[i-1]) for i in 2:length(entropy)]]
    (history=history,mean_move=mean_move,entropy=entropy,delta_entropy=delta_entropy,
     component_count=component_count,component_labels=component_labels)
end

function gaussian_field(P; sigma::Float64=.115, bounds=((-0.72,0.72),(-0.50,0.50)),
        nx::Int=82, ny::Int=58)
    xs=collect(range(bounds[1]...;length=nx));ys=collect(range(bounds[2]...;length=ny))
    rho=zeros(ny,nx);s2=2sigma^2
    for j in eachindex(ys),i in eachindex(xs)
        rho[j,i]=sum(exp.(-((P[:,1].-xs[i]).^2+(P[:,2].-ys[j]).^2)./s2))
    end
    peaks=Tuple{Int,Int,Float64}[]
    for j in 2:ny-1,i in 2:nx-1
        v=rho[j,i]; block=@view rho[j-1:j+1,i-1:i+1]
        v==maximum(block) && count(==(v),block)==1 && push!(peaks,(j,i,v))
    end
    sort!(peaks;by=p->-p[3])
    kept=Tuple{Int,Int,Float64}[];minsep=max(.11,1.15sigma)
    for p in peaks
        all(hypot(xs[p[2]]-xs[q[2]],ys[p[1]]-ys[q[1]])>=minsep for q in kept) || continue
        push!(kept,p);length(kept)>=6 && break
    end
    saddle=0.
    if length(kept)>=2
        a=kept[1][1]+(kept[1][2]-1)*ny;b=kept[2][1]+(kept[2][2]-1)*ny
        active=falses(nx*ny);u=UnionFind(nx*ny)
        for idx in sortperm(vec(rho);rev=true)
            active[idx]=true;j=mod(idx-1,ny)+1;i=div(idx-1,ny)+1
            for (dj,di) in ((-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1))
                jj=j+dj;ii=i+di
                1<=jj<=ny && 1<=ii<=nx || continue
                q=jj+(ii-1)*ny;active[q] && join!(u,idx,q)
            end
            if active[a]&&active[b]&&root!(u,a)==root!(u,b);saddle=rho[idx];break;end
        end
    end
    two=length(kept)>=2;lower=two ? min(kept[1][3],kept[2][3]) : maximum(rho)
    ratio=two && lower>0 ? saddle/lower : 1.
    default_level=two ? clamp((saddle+lower)/(2maximum(rho)),.08,.92) : .55
    (x=xs,y=ys,rho=rho,peaks=kept,saddle=saddle,saddle_ratio=ratio,
     separability=two ? 1-ratio : 0.,delta_db=two && saddle>0 ? 10log10(lower/saddle) : 0.,
     default_level=default_level)
end

function water_components(rho,level_fraction;mincells::Int=18)
    ny,nx=size(rho);mask=rho.>=level_fraction*maximum(rho);u=UnionFind(nx*ny);active=vec(mask)
    for j in 1:ny,i in 1:nx
        mask[j,i]||continue;a=j+(i-1)*ny
        for (dj,di) in ((-1,0),(0,-1),(-1,-1),(-1,1))
            jj=j+dj;ii=i+di
            1<=jj<=ny&&1<=ii<=nx&&mask[jj,ii]&&join!(u,a,jj+(ii-1)*ny)
        end
    end
    roots=[active[i] ? root!(u,i) : 0 for i in eachindex(active)];mass=Dict{Int,Int}()
    for r in roots;r>0&&(mass[r]=get(mass,r,0)+1);end
    kept=sort([r for (r,m) in mass if m>=mincells];by=r->-mass[r]);map=Dict(r=>k for (k,r) in enumerate(kept))
    labels=reshape([get(map,r,0) for r in roots],ny,nx)
    (labels=labels,count=length(kept),sizes=[mass[r] for r in kept])
end

rows(P)=[[P[i,1],P[i,2]] for i in axes(P,1)]

function study_payload(;kwargs...)
    scene=synthetic_scene(;kwargs...);P=scene.points
    defaults=Dict("dbscan_eps"=>.085,"dbscan_minpts"=>8,"blur_sigma"=>.115,
        "blur_steps"=>5,"blur_eta"=>1.,"merge_radius"=>.030,"water_sigma"=>.115)
    d=dbscan(P;eps=defaults["dbscan_eps"],minpts=defaults["dbscan_minpts"])
    b=blurring_mean_shift(P;sigma=defaults["blur_sigma"],steps=12,eta=defaults["blur_eta"],merge_radius=defaults["merge_radius"])
    f=gaussian_field(P;sigma=defaults["water_sigma"],bounds=scene.bounds)
    w=water_components(f.rho,f.default_level)
    defaults["water_level"]=f.default_level
    Dict("points"=>rows(P),"oracle"=>scene.oracle,"bounds"=>[collect(scene.bounds[1]),collect(scene.bounds[2])],
        "counts"=>Dict(string(k)=>v for (k,v) in pairs(scene.counts)),
        "settings"=>Dict(string(k)=>v for (k,v) in pairs(scene.settings)),"defaults"=>defaults,
        "julia_default"=>Dict("dbscan_clusters"=>d.count,"blur_component_count"=>b.component_count,
            "blur_mean_move_mm"=>1000 .* b.mean_move,"water_components"=>w.count,
            "water_peaks"=>length(f.peaks),"water_separability"=>f.separability,
            "water_delta_db"=>f.delta_db,"water_saddle_ratio"=>f.saddle_ratio),
        "scope"=>"Synthetic two-target XY support. Oracle labels are evaluation-only. Counts are method outputs, not verified person identities.")
end

function document(payload=study_payload())
    template=read(joinpath(ROOT,"assets","separation_viewer.html"),String)
    vendor=replace(read(joinpath(ROOT,"assets","plotly.min.js"),String),"</script"=>"<\\/script")
    data=replace(JSON.json(payload),"</"=>"<\\/")
    replace(template,"__PLOTLY_SCRIPT__"=>vendor,"__VIEWER_JS__"=>read(joinpath(ROOT,"assets","separation_viewer.js"),String),"__INITIAL_PAYLOAD__"=>data)
end

end
