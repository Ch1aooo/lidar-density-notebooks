# Included inside DensityPartI; extends the existing 2D API without changing measured support.
const DIM_SPECS=Dict(
    "x"=>("cartesian",[1]),"y"=>("cartesian",[2]),"z"=>("cartesian",[3]),
    "xy"=>("cartesian",[1,2]),"xz"=>("cartesian",[1,3]),"yz"=>("cartesian",[2,3]),"xyz"=>("cartesian",[1,2,3]),
    "crho"=>("cylindrical",[1]),"cphi"=>("cylindrical",[2]),"cz"=>("cylindrical",[3]),
    "cyl"=>("cylindrical",[1,2]),"rz"=>("cylindrical",[1,3]),"cphiz"=>("cylindrical",[2,3]),"cyl3"=>("cylindrical",[1,2,3]),
    "sr"=>("spherical",[1]),"sphi"=>("spherical",[2]),"sbeta"=>("spherical",[3]),
    "srphi"=>("spherical",[1,2]),"srbeta"=>("spherical",[1,3]),"sphere"=>("spherical",[2,3]),"sphere3"=>("spherical",[1,2,3]))
merge!(BASES,Dict("cphiz"=>"Cylindrical · phi / Z","srphi"=>"Spherical · R / phi","srbeta"=>"Spherical · R / beta"))

function resolved_settings(c)
    if hasproperty(c,:family)
        family=c.family;dim=Int(c.dimensions)
        base=dim==3 ? (family=="cartesian" ? "xyz" : family=="cylindrical" ? "cyl3" : "sphere3") :
            getproperty(c,Symbol((family=="cartesian" ? "cart" : family=="cylindrical" ? "cyl" : "sphere")*string(dim)))
        n=dim==3 ? Int(c.voxel_n) : Int(c.nu)
        merge(c,(base=base,nu=n,nv=dim==3 ? n : Int(c.nv)))
    else c end
end

function chart_nd(P,base,bounds;sensor=SENSOR)
    family,axes=DIM_SPECS[base];d=length(axes);q=P.-reshape(sensor,1,3)
    rho=hypot.(q[:,1],q[:,2]);R=sqrt.(vec(sum(q.^2;dims=2)));phi=mod.(atan.(q[:,2],q[:,1]).+pi,2pi).-pi;phi[rho.==0].=0
    beta=atan.(rho,-q[:,3]);beta[R.==0].=0
    maxrho=hypot(maximum(abs.([bounds[1]...].-sensor[1])),maximum(abs.([bounds[2]...].-sensor[2])))+.05
    if family=="cartesian"
        full=copy(P);labels=["X (m)","Y (m)","Z (m)"];limits=bounds;angles=[false,false,false];periodic=[false,false,false]
    elseif family=="cylindrical"
        full=hcat(rho,phi,P[:,3]);labels=["rho (m)","phi (°)","Z (m)"];limits=[(0.,maxrho),(-pi,pi),bounds[3]];angles=[false,true,false];periodic=[false,true,false]
    else
        full=hcat(R,phi,beta);labels=["R (m)","phi (°)","beta downward (°)"];maxR=hypot(maxrho,maximum(abs.([bounds[3]...].-sensor[3])))+.05
        limits=[(0.,maxR),(-pi,pi),(0.,pi)];angles=[false,true,true];periodic=[false,true,false]
    end
    uv=full[:,axes];shown=copy(full);for j in 1:3;if angles[j];shown[:,j].*=180/pi;end;end
    unit=d==3 ? "points/m³" : d==1 ? (angles[axes[1]] ? "points/rad" : "points/m") : base=="sphere" ? "points/sr" : any(angles[axes]) ? "points/(m·rad)" : "points/m²"
    (uv=uv,full=shown,labels=labels,axes=axes,limits=limits[axes],angle=angles[axes],periodic=periodic[axes],unit=unit,family=family)
end

function histogram_nd(uv,edges)
    H=zeros(Tuple(length(e)-1 for e in edges));slots=zeros(Int,size(uv,1),length(edges))
    for k in axes(uv,1)
        valid=true
        for a in eachindex(edges)
            v=uv[k,a];e=edges[a]
            if !(e[1]<=v<=e[end]);valid=false;break;end
            slots[k,a]=min(searchsortedlast(e,v),length(e)-1)
        end
        valid && (H[CartesianIndex(Tuple(slots[k,:]))]+=1)
    end
    H,slots
end

function measures_nd(base,edges)
    family,axes=DIM_SPECS[base];d=length(axes)
    lengths=diff.(edges)
    if d==3 && family=="cylindrical";lengths[1]=diff(edges[1].^2)./2
    elseif d==3 && family=="spherical";lengths[1]=diff(edges[1].^3)./3;lengths[3]=-diff(cos.(edges[3])) end
    V=zeros(Tuple(length(v) for v in lengths))
    for I in CartesianIndices(V);V[I]=prod(lengths[a][I[a]] for a in 1:d);end
    V
end

function smooth_nd(H,sigmas,periodic)
    A=copy(H);d=ndims(H)
    for axis in 1:d
        s=sigmas[axis];s<=0 && continue
        radius=ceil(Int,4s);offsets=-radius:radius;weights=exp.(-.5 .* (collect(offsets)./s).^2);weights./=sum(weights);B=zeros(size(A))
        for I in CartesianIndices(A)
            acc=0.
            for (o,w) in zip(offsets,weights)
                at=periodic[axis] ? mod1(I[axis]+o,size(A,axis)) : reflect_index(I[axis]+o,size(A,axis))
                J=CartesianIndex(ntuple(a->a==axis ? at : I[a],d));acc+=w*A[J]
            end
            B[I]=acc
        end
        A=B
    end
    A
end

function peaks_nd(A,centres,physical,periodic;fraction=.15)
    d=ndims(A);offsets=collect(CartesianIndices(ntuple(_->-1:1,d)));mask=falses(size(A));seen=falses(size(A));top=maximum(A)
    neighbours(I)= (CartesianIndex(ntuple(a->periodic[a] ? mod1(I[a]+o[a],size(A,a)) : clamp(I[a]+o[a],1,size(A,a)),d)) for o in offsets)
    for I in CartesianIndices(A)
        A[I]>=fraction*top && (mask[I]=all(A[I]>=A[J] for J in neighbours(I)))
    end
    reps=CartesianIndex{d}[]
    for I in CartesianIndices(A)
        (!mask[I]||seen[I]) && continue
        push!(reps,I);stack=[I];seen[I]=true
        while !isempty(stack)
            J=pop!(stack)
            for K in neighbours(J)
                if mask[K]&&!seen[K];seen[K]=true;push!(stack,K);end
            end
        end
    end
    sort!(reps;by=I->(-A[I],Tuple(I)));kept=Vector{Vector{Float64}}()
    delta=[v[2]-v[1] for v in centres];period=length.(centres).*delta
    for I in reps
        u=[centres[a][I[a]] for a in 1:d];separate=true
        for q in kept
            distance=0.
            for a in 1:d
                v=abs(u[a]-q[a]);periodic[a]&&(v=min(v,period[a]-v));distance+=(v/max(physical[a],delta[a]))^2
            end
            if distance<1;separate=false;break;end
        end
        separate && push!(kept,vcat(u,A[I]))
    end
    kept
end

function chart_to_world(q,family)
    family=="cartesian" && return collect(q)
    if family=="cylindrical";return [SENSOR[1]+q[1]*cos(q[2]),SENSOR[2]+q[1]*sin(q[2]),q[3]];end
    [SENSOR[1]+q[1]*sin(q[3])*cos(q[2]),SENSOR[2]+q[1]*sin(q[3])*sin(q[2]),SENSOR[3]-q[1]*cos(q[3])]
end

function analyze_nd(input,c)
    P=input.points;d=length(DIM_SPECS[c.base][2]);ch=chart_nd(P,c.base,input.bounds)
    size(P,1)>0 || return Dict("empty"=>true,"source"=>input.source,"source_type"=>c.source,"message"=>"No returns in the selected support.")
    ns=fill(Int(c.nu),d);edges=[collect(range(ch.limits[a]...;length=ns[a]+1)) for a in 1:d]
    centres=[(e[1:end-1]+e[2:end])/2 for e in edges];delta=[e[2]-e[1] for e in edges]
    physical=[ch.angle[a] ? deg2rad(Float64(c.angle_sigma)) : Float64(c.sigma_cm)/100 for a in 1:d]
    H,slots=histogram_nd(ch.uv,edges);V=measures_nd(c.base,edges);rho=smooth_nd(H,physical./delta,ch.periodic)./V;raw=H./V
    top=maximum(rho);best=argmax(rho);indices=d==1 ? (best,) : Tuple(best);factor=[b ? 180/pi : 1. for b in ch.angle]
    candidates=peaks_nd(rho,centres,physical,ch.periodic);mu=vec(mean(P;dims=1));mapped=vec(chart_nd(reshape(mu,1,3),c.base,input.bounds).uv)
    values(A)=[all(slots[i,:].>0) ? A[CartesianIndex(Tuple(slots[i,:]))] : 0. for i in axes(P,1)]
    peak=[centres[a][indices[a]] for a in 1:d]
    views=Dict("world"=>[collect(P[:,a]) for a in 1:3],"chart"=>[collect(ch.full[:,a]) for a in 1:3],"chart_labels"=>ch.labels,"labels"=>ch.labels[ch.axes],
        "u"=>centres[1].*factor[1],"point_axis"=>collect(ch.uv[:,1]).*factor[1],"counts"=>d==1 ? vec(H) : nothing,
        "raw"=>d==1 ? vec(raw) : nothing,"density"=>d==1 ? vec(rho) : nothing,
        "point_counts"=>values(H),"point_raw"=>values(raw),"point_density"=>values(rho),
        "peak"=>peak.*factor,"peak_value"=>top,"ties"=>count(x->abs(x-top)<=top*1e-12,rho),
        "peaks"=>[vcat(q[1:d].*factor,q[end]) for q in candidates],"centroid_chart"=>mapped.*factor,"centroid_xyz"=>mu)
    if d==3
        views["peak_world"]=[chart_to_world(q[1:3],ch.family) for q in candidates]
    else
        idx=clamp(searchsortedlast(edges[1],mapped[1]),1,length(centres[1]));views["centroid_density"]=rho[idx]
    end
    Dict("empty"=>false,"source"=>input.source,"source_type"=>c.source,"frame"=>input.frame,"support"=>input.support,"original"=>input.original,
        "points"=>size(P,1),"included"=>sum(H),"base"=>c.base,"base_name"=>"$(ch.family) · $(join(ch.labels[ch.axes],", "))","unit"=>ch.unit,"display"=>c.display,
        "nu"=>c.nu,"nv"=>c.nu,"dimension"=>d,"family"=>ch.family,"sigma_cm"=>c.sigma_cm,"angle_sigma"=>c.angle_sigma,
        "delta"=>delta.*factor,"sigma_cells"=>physical./delta,"integrated_mass"=>sum(rho.*V),"bounds"=>input.bounds,"views"=>views,"study"=>nothing)
end
