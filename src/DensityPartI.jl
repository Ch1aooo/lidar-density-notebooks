module DensityPartI

using Random, Statistics, LinearAlgebra, SHA, JSON, CodecZlib

const MEASURED = Ref{Any}(nothing)
const STUDIES = Dict{String,Any}()
const SENSOR = [0.0,0.0,2.7]
const BASES = Dict("xy"=>"Cartesian · XY", "xz"=>"Cartesian · XZ", "yz"=>"Cartesian · YZ",
    "cyl"=>"Cylindrical · rho / phi", "rz"=>"Cylindrical · rho / Z", "sphere"=>"Spherical · phi / beta")

function ellipsoids(; n=1600, targets=2, separation=.7, seed=7, pattern="directional")
    1<=targets<=6 && 20<=n<=100000 || throw(ArgumentError("Use 1–6 ellipsoids and 20–100000 points."))
    rng=MersenneTwister(seed); P=zeros(n,3); centres=zeros(targets,3)
    for k in 1:targets
        centres[k,:]=[.65+(k-(targets+1)/2)*separation,.25+.08*(k-1),1.0]
    end
    for i in 1:n
        k=mod1(i,targets)
        # Illustrative volume sampling, not optical photon transport or ray tracing.
        # A narrow directional lobe plus sparse uniform support exposes XYZ density contrast.
        direction=[cos(.8+1.9*(k-1)),sin(.8+1.9*(k-1)),.65];direction./=norm(direction)
        if pattern!="uniform" && rand(rng)<.85
            pole=pattern=="dual" && rand(rng)<.4 ? [-direction[2],direction[1],.5] : direction
            pole./=norm(pole);d=0.62 .* pole .+ 0.16 .* randn(rng,3)
            while norm(d)>1;d=0.62 .* pole .+ 0.16 .* randn(rng,3);end
        else
            d=randn(rng,3);d./=norm(d);d.*=rand(rng)^(1/3)
        end
        yaw=.35*(k-1);a=.24; b=.17; c=.7-.08*(k-1)
        P[i,:]=centres[k,:]+[a*d[1]*cos(yaw)-b*d[2]*sin(yaw),a*d[1]*sin(yaw)+b*d[2]*cos(yaw),c*d[3]]
    end
    P,centres
end

function csv_rows(text)
    rows=Vector{Vector{String}}(); row=String[]; field=IOBuffer(); quoted=false
    chars=collect(replace(text,'\ufeff'=>""));i=1
    while i<=length(chars)
        c=chars[i]
        if c=='"'
            if quoted && i<length(chars) && chars[i+1]=='"';write(field,'"');i+=1
            else quoted=!quoted end
        elseif c==',' && !quoted
            push!(row,strip(String(take!(field))))
        elseif c in ('\n','\r') && !quoted
            push!(row,strip(String(take!(field))))
            any(!isempty,row) && push!(rows,row);row=String[]
            c=='\r' && i<length(chars) && chars[i+1]=='\n' && (i+=1)
        else write(field,c) end
        i+=1
    end
    quoted && throw(ArgumentError("CSV contains an unclosed quote."))
    push!(row,strip(String(take!(field))));any(!isempty,row) && push!(rows,row)
    rows
end

function parse_csv(bytes; frame=0)
    length(bytes)<=20_000_000 || throw(ArgumentError("CSV limit: 20 MB / 100000 data rows."))
    rows=csv_rows(String(copy(bytes)));length(rows)>=2 || throw(ArgumentError("CSV needs headers x,y,z and at least one data row, in metres."))
    header=lowercase.(rows[1]);idx=[findfirst(==(s),header) for s in ("x","y","z")]
    any(isnothing,idx) && throw(ArgumentError("CSV needs named x,y,z columns (metres). Optional: frame."))
    length(unique(header))==length(header) || throw(ArgumentError("CSV has duplicate column names."))
    n=length(rows)-1; n<=100000 || throw(ArgumentError("CSV limit: 100000 rows; no silent subsampling."))
    P=zeros(n,3);ids=ones(Int,n);fi=findfirst(==("frame"),header)
    for i in 1:n
        r=rows[i+1];length(r)==length(header) || throw(ArgumentError("CSV row $(i+1) has the wrong number of fields."))
        for j in 1:3
            v=tryparse(Float64,r[idx[j]]);(v!==nothing && isfinite(v)) || throw(ArgumentError("Invalid XYZ at CSV row $(i+1)."));P[i,j]=v
        end
        if fi!==nothing
            f=tryparse(Float64,r[fi]);(f!==nothing && isfinite(f) && isinteger(f) && 1<=f<=100000) || throw(ArgumentError("Invalid frame at CSV row $(i+1)."));ids[i]=Int(f)
        end
    end
    available=sort(unique(ids));chosen=frame==0 ? first(available) : frame
    chosen in available || throw(ArgumentError("CSV frame $chosen is absent. Available: $(join(available[1:min(end,12)],", "))."))
    (points=P[ids.==chosen,:],bounds=world_bounds(P),frame=chosen,frames=available)
end

function world_bounds(P)
    [(minimum(P[:,a])-max(.05,.02*(maximum(P[:,a])-minimum(P[:,a]))),
      maximum(P[:,a])+max(.05,.02*(maximum(P[:,a])-minimum(P[:,a])))) for a in 1:3]
end

function measured(root)
    if MEASURED[]===nothing
        obj=open(joinpath(root,"data","measured_walk.json.gz")) do io
            gz=GzipDecompressorStream(io)
            try JSON.parse(read(gz,String)) finally close(gz) end
        end
        frames=[hcat(Float64.(f["x"]),Float64.(f["y"]),Float64.(f["z"])) for f in obj["frames"]]
        bounds=world_bounds(reduce(vcat,frames))
        MEASURED[]=(frames=frames,bounds=bounds)
    end
    MEASURED[]
end

function input_cloud(c,root)
    if c.source=="synthetic"
        pattern=hasproperty(c,:pattern) ? c.pattern : "directional"
        P,centres=ellipsoids(n=Int(c.n),targets=Int(c.targets),separation=Float64(c.separation),seed=Int(c.seed),pattern=pattern)
        bounds=[(minimum(centres[:,1])-.4,maximum(centres[:,1])+.4),(-.1,.6+.08*(Int(c.targets)-1)),(0.,2.)]
        name="Synthetic ellipsoids · $pattern volume support · illustrative, not ray tracing";frame=0
    elseif c.source=="measured"
        m=measured(root);frame=Int(c.frame);1<=frame<=length(m.frames) || throw(ArgumentError("Measured frame is out of range."))
        P=copy(m.frames[frame]);bounds=m.bounds;centres=zeros(0,3)
        name="Yiyun Xu · measured L-walk · frame $frame / 203"
    elseif c.source=="csv"
        c.upload isa AbstractDict && haskey(c.upload,"data") || throw(ArgumentError("Choose a CSV with x,y,z headers. All coordinates must be metres."))
        item=parse_csv(Vector{UInt8}(c.upload["data"]);frame=Int(c.csvframe));P=item.points;bounds=item.bounds;frame=item.frame
        centres=zeros(0,3);name="CSV: $(get(c.upload,"name","local.csv")) · frame $frame"
    else throw(ArgumentError("Unknown input source.")) end
    original=size(P,1)
    object_ids=c.source=="synthetic" ? [mod1(i,Int(c.targets)) for i in 1:original] : zeros(Int,original)
    if c.support=="head";mask=(1.4 .<=P[:,3]).&(P[:,3].<=1.6);P=P[mask,:];object_ids=object_ids[mask];end
    (points=P,bounds=bounds,centres=centres,source=name,frame=frame,original=original,support=c.support,object_ids=object_ids)
end

function chart(P,base,bounds; sensor=SENSOR)
    base in ("cphiz","srphi","srbeta") && return chart_nd(P,base,bounds;sensor)
    n=size(P,1);q=P.-reshape(sensor,1,3);rho=hypot.(q[:,1],q[:,2]);R=sqrt.(sum(q.^2;dims=2))[:]
    phi=mod.(atan.(q[:,2],q[:,1]).+pi,2pi).-pi;phi[rho.==0].=0
    beta=atan.(rho,-q[:,3]);beta[R.==0].=0
    maxrho=hypot(maximum(abs.([bounds[1]...].-sensor[1])),maximum(abs.([bounds[2]...].-sensor[2])))+.05
    if base in ("xy","xz","yz")
        axes=base=="xy" ? (1,2) : base=="xz" ? (1,3) : (2,3)
        full=copy(P);labels=["X (m)","Y (m)","Z (m)"];uv=P[:,collect(axes)]
        limits=bounds[collect(axes)];angle=(false,false);periodic=(false,false);unit="points/m²"
    elseif base in ("cyl","rz")
        full=hcat(rho,phi,P[:,3]);labels=["rho (m)","phi (°)","Z (m)"]
        axes=base=="cyl" ? (1,2) : (1,3);uv=full[:,collect(axes)]
        limits=base=="cyl" ? [(0.,maxrho),(-pi,pi)] : [(0.,maxrho),bounds[3]]
        angle=base=="cyl" ? (false,true) : (false,false);periodic=angle;unit="points/m²"
    elseif base=="sphere"
        full=hcat(R,phi,beta);labels=["R (m)","phi (°)","beta from downward axis (°)"]
        axes=(2,3);uv=full[:,[2,3]];limits=[(-pi,pi),(0.,pi)]
        angle=(true,true);periodic=(true,false);unit="points/sr"
    else throw(ArgumentError("Unknown coordinate plane.")) end
    full_display=copy(full)
    if base in ("cyl","rz");full_display[:,2].*=180/pi
    elseif base=="sphere";full_display[:,2:3].*=180/pi end
    (uv=uv,full=full_display,labels=labels,axes=axes,limits=limits,angle=angle,periodic=periodic,unit=unit)
end

function histogram(uv,edges)
    H=zeros(length(edges[1])-1,length(edges[2])-1)
    for k in axes(uv,1)
        a,b=uv[k,:]
        if edges[1][1]<=a<=edges[1][end] && edges[2][1]<=b<=edges[2][end]
            i=min(searchsortedlast(edges[1],a),size(H,1));j=min(searchsortedlast(edges[2],b),size(H,2));H[i,j]+=1
        end
    end
    H
end

function measures(base,edges)
    du,dv=diff(edges[1]),diff(edges[2])
    if base=="cyl";return (diff(edges[1].^2)./2)*dv'
    elseif base=="sphere";return du*(-diff(cos.(edges[2])))'
    else return du*dv' end
end

reflect_index(i,n)=let t=mod(i-1,2n)+1;t<=n ? t : 2n-t+1 end
function smooth_counts(H,sigmas,periodic)
    A=copy(H)
    for dim in 1:2
        s=sigmas[dim];s<=0 && continue
        radius=ceil(Int,4s);offsets=-radius:radius;weights=exp.(-0.5 .* (collect(offsets)./s).^2);weights./=sum(weights)
        B=zeros(size(A))
        for j in axes(A,2),i in axes(A,1)
            acc=0.
            for (k,w) in zip(offsets,weights)
                a,b=dim==1 ? (i+k,j) : (i,j+k)
                if dim==1;a=periodic[1] ? mod1(a,size(A,1)) : reflect_index(a,size(A,1))
                else b=periodic[2] ? mod1(b,size(A,2)) : reflect_index(b,size(A,2)) end
                acc+=w*A[a,b]
            end
            B[i,j]=acc
        end
        A=B
    end
    A
end

function peaks(A,uc,vc,sigma,periodic; fraction=.15)
    top=maximum(A);top<=0 && return NamedTuple[]
    nx,ny=size(A);mask=falses(nx,ny)
    for j in 1:ny,i in 1:nx
        A[i,j]<fraction*top && continue
        mask[i,j]=all(begin
            a,b=i+di,j+dj
            a=periodic[1] ? mod1(a,nx) : clamp(a,1,nx);b=periodic[2] ? mod1(b,ny) : clamp(b,1,ny)
            A[i,j]>=A[a,b]
        end for di in -1:1,dj in -1:1)
    end
    visited=falses(nx,ny);representatives=Tuple{Int,Int}[]
    for j in 1:ny,i in 1:nx
        (!mask[i,j]||visited[i,j]) && continue
        push!(representatives,(i,j));stack=[(i,j)];visited[i,j]=true
        while !isempty(stack)
            a,b=pop!(stack)
            for di in -1:1,dj in -1:1
                x,y=a+di,b+dj
                x=periodic[1] ? mod1(x,nx) : x;y=periodic[2] ? mod1(y,ny) : y
                if 1<=x<=nx && 1<=y<=ny && mask[x,y] && !visited[x,y];visited[x,y]=true;push!(stack,(x,y));end
            end
        end
    end
    sort!(representatives;by=p->(-A[p...],p[1],p[2]));retained=NamedTuple[]
    period=(length(uc)*(uc[2]-uc[1]),length(vc)*(vc[2]-vc[1]))
    for (i,j) in representatives
        u,v=uc[i],vc[j]
        separate=all(begin
            d=abs.([u-q.u,v-q.v]);for a in 1:2;if periodic[a];d[a]=min(d[a],period[a]-d[a]);end;end
            sum((d./max.(sigma,[uc[2]-uc[1],vc[2]-vc[1]])).^2)>=1
        end for q in retained)
        separate && push!(retained,(i=i,j=j,u=u,v=v,value=A[i,j]))
    end
    retained
end

function mode_at(P,s,starts; weights=nothing,iterations=180)
    best=nothing;bestlog=-Inf;solutions=Vector{Vector{Float64}}();maxima=NamedTuple[];scale=2s^2
    for start in starts
        x1=Float64(start[1]);x2=Float64(start[2])
        for _ in 1:iterations
            min_d2=Inf
            @inbounds for i in axes(P,1)
                d2=(P[i,1]-x1)^2+(P[i,2]-x2)^2;min_d2=min(min_d2,d2)
            end
            mass=0.;sx=0.;sy=0.
            @inbounds for i in axes(P,1)
                d2=(P[i,1]-x1)^2+(P[i,2]-x2)^2
                w=exp(-(d2-min_d2)/scale)*(weights===nothing ? 1. : weights[i])
                mass+=w;sx+=w*P[i,1];sy+=w*P[i,2]
            end
            t1=sx/mass;t2=sy/mass;step=hypot(t1-x1,t2-x2);x1=t1;x2=t2
            step<1e-9 && break
        end
        min_d2=Inf
        @inbounds for i in axes(P,1)
            min_d2=min(min_d2,(P[i,1]-x1)^2+(P[i,2]-x2)^2)
        end
        mass=0.;sx=0.;sy=0.;xx=0.;yy=0.;xy=0.
        @inbounds for i in axes(P,1)
            dx=P[i,1]-x1;dy=P[i,2]-x2;w=exp(-((dx^2+dy^2)-min_d2)/scale)*(weights===nothing ? 1. : weights[i])
            mass+=w;sx+=w*dx;sy+=w*dy;xx+=w*dx^2;yy+=w*dy^2;xy+=w*dx*dy
        end
        hypot(sx,sy)/mass>1e-6 && continue
        xx-=sx^2/mass;yy-=sy^2/mass;xy-=sx*sy/mass
        largest_cov=(xx+yy+sqrt((xx-yy)^2+4xy^2))/(2mass)
        largest_cov/s^4-1/s^2>=0 && continue
        score=-min_d2/scale+log(mass)
        all(q->norm(q.point-[x1,x2])>1e-5,maxima) && push!(maxima,(point=[x1,x2],logvalue=score))
        if score>bestlog+1e-9
            best=[x1,x2];bestlog=score;empty!(solutions);push!(solutions,[x1,x2])
        elseif abs(score-bestlog)<=1e-9
            distinct=true
            for q in solutions
                if hypot(x1-q[1],x2-q[2])<=1e-5;distinct=false;break;end
            end
            distinct && push!(solutions,[x1,x2])
        end
    end
    (point=best,logvalue=bestlog,ties=length(solutions),maxima=maxima)
end

include("ScaleBranches.jl")

"""A full-space XY sweep, independent of the six-panel raster and its controls."""
function bandwidth_sweep(P; model="raw",delta_cm=1.,samples=160,min_cm=.03,max_cm=1000.,anchor_cm=7.5)
    0<min_cm<max_cm && 40<=samples<=240 || throw(ArgumentError("Use 40–240 samples and 0 < minimum σ < maximum σ."))
    min_cm<=anchor_cm<=max_cm || throw(ArgumentError("Branch anchor must lie inside the sigma sweep."))
    key=bytes2hex(sha256(reinterpret(UInt8,vec(P))))*"|$model|$delta_cm|$samples|$min_cm|$max_cm|$anchor_cm"
    haskey(STUDIES,key) && return STUDIES[key]
    raw=P[:,1:2];mu=vec(mean(raw;dims=1));d=delta_cm/100
    if model=="binned"
        cells=Dict{Tuple{Int,Int},Int}()
        for i in axes(raw,1); k=(floor(Int,raw[i,1]/d),floor(Int,raw[i,2]/d));cells[k]=get(cells,k,0)+1;end
        keys_sorted=sort(collect(keys(cells)));Q=reduce(vcat,[reshape([(k[1]+.5)*d,(k[2]+.5)*d],1,2) for k in keys_sorted]);a=Float64[cells[k] for k in keys_sorted]
    elseif model=="raw"
        Q=raw;a=ones(size(Q,1))
    else throw(ArgumentError("Unknown sweep model.")) end
    mu_model=vec(sum(Q.*a;dims=1))/sum(a)
    # A small, deterministic set of search starts; every kernel evaluation still uses all support.
    chosen=[argmax(vec(sum((Q.-mu_model').^2;dims=2)))]
    for _ in 1:min(7,size(Q,1)-1)
        distances=[minimum((Q[i,1]-Q[j,1])^2+(Q[i,2]-Q[j,2])^2 for j in chosen) for i in axes(Q,1)]
        push!(chosen,argmax(distances))
    end
    buckets=Dict{Tuple{Int,Int},Tuple{Float64,Int}}()
    for i in axes(Q,1)
        k=(floor(Int,Q[i,1]/.02),floor(Int,Q[i,2]/.02));v=get(buckets,k,(0.,i));buckets[k]=(v[1]+a[i],v[2])
    end
    dense=sort(collect(values(buckets));by=x->(-x[1],x[2]))
    append!(chosen,[v[2] for v in dense[1:min(10,end)]])
    starts=vcat([mu_model],[collect(Q[i,:]) for i in unique(chosen)])
    sigmas=exp.(range(log(min_cm/100),log(max_cm/100);length=samples))
    xy=Any[];errors=Any[];ties=Int[];logvalues=Float64[];previous=mu_model
    for s in sigmas
        state=mode_at(Q,s,vcat([previous],starts);weights=a);point=state.point
        push!(xy,point);push!(errors,point===nothing ? nothing : norm(point-mu)*1000);push!(ties,state.ties);push!(logvalues,isfinite(state.logvalue) ? state.logvalue : 0.)
        point!==nothing && (previous=point)
    end
    flags=falses(samples);jumps=zeros(samples)
    for i in 2:samples
        if xy[i]===nothing || xy[i-1]===nothing;flags[i]=true;continue;end
        jumps[i]=norm(xy[i]-xy[i-1])*1000
        # Exploratory flag, not a mathematical test of branch continuity.
        flags[i]=ties[i]>1 || ties[i-1]>1 || jumps[i]>max(5.,.35*sigmas[i-1]*1000)
    end
    intervals=Any[];i=2
    while i<=samples
        if !flags[i];i+=1;continue;end
        first_i=i;while i<samples && flags[i+1];i+=1;end
        push!(intervals,Dict("lo_cm"=>100sigmas[first_i-1],"hi_cm"=>100sigmas[i],"count"=>i-first_i+1,
            "jump_mm"=>maximum(jumps[first_i:i]),"ties"=>maximum(ties[first_i-1:i]),
            "reason"=>any(x->x===nothing,xy[first_i-1:i]) ? "unverified mode" : maximum(ties[first_i-1:i])>1 ? "numerical tie / possible switch" : "possible switch"));i+=1
    end
    lastflag=findlast(flags);settled=lastflag===nothing ? 100sigmas[1] : lastflag<samples-3 ? 100sigmas[lastflag] : nothing
    shown=length(intervals)<=6 ? intervals : sort(sort(intervals;by=q->-q["jump_mm"])[1:6];by=q->q["lo_cm"])
    result=Dict("sigma_cm"=>100sigmas,"xy"=>xy,"error_mm"=>errors,"ties"=>ties,"break_before"=>collect(flags),
        "jump_mm"=>jumps,"intervals"=>shown,"interval_count"=>length(intervals),"settled_cm"=>settled,
        "centroid"=>mu,"model_centroid"=>mu_model,"bin_shift_mm"=>norm(mu_model-mu)*1000,
        "model"=>model,"delta_cm"=>delta_cm,"samples"=>samples,"points"=>size(P,1),"support_sites"=>size(Q,1),
        "cloud"=>[collect(raw[:,1]),collect(raw[:,2])],"mass"=>sum(a),
        "logvalues"=>logvalues,"kernel_support"=>[collect(Q[:,1]),collect(Q[:,2])],"kernel_weights"=>a,
        "branches"=>scale_branches(Q,a,sigmas,starts;anchor_cm),
        "search"=>"Multistart Gaussian mean shift; stationary residual and negative-Hessian checks. Best verified maximum found, not an exhaustive global-mode guarantee.")
    length(STUDIES)>=8 && empty!(STUDIES);STUDIES[key]=result
    result
end

function study_evaluate(c,root)
    try
        input=input_cloud(c,root);P=input.points
        size(P,1)>0 || return Dict("empty"=>true,"source_type"=>c.source,"message"=>"No points in this frame/support; no trajectory is filled in.")
        size(P,1)<=10000 || return Dict("empty"=>true,"source_type"=>c.source,"message"=>"The independent sweep is limited to10000 selected points. No points are silently sampled.")
        s=bandwidth_sweep(P;model=c.model,delta_cm=Float64(c.delta_cm),samples=Int(c.samples),min_cm=Float64(c.min_cm),max_cm=Float64(c.max_cm),anchor_cm=hasproperty(c,:branch_anchor_cm) ? Float64(c.branch_anchor_cm) : 7.5)
        # Reference labels are used only after density search, never to initialize or partition it.
        s=deepcopy(s);s["references"]=object_references(P,input.object_ids)
        label_branch_references!(s)
        Dict("empty"=>false,"source_type"=>c.source,"source"=>input.source,"frame"=>input.frame,"support"=>input.support,"study"=>s)
    catch e
        Dict("empty"=>true,"source_type"=>c.source,"message"=>sprint(showerror,e))
    end
end

function bandwidth_study(P)
    size(P,1)==0 && return nothing
    key=bytes2hex(sha256(reinterpret(UInt8,vec(P))))
    haskey(STUDIES,key) && return STUDIES[key]
    Q=P[:,1:2];mu=vec(mean(Q;dims=1));r=Q.-mu';R=maximum(sqrt.(sum(r.^2;dims=2)));M3=vec(mean(r.*sum(r.^2;dims=2);dims=1));S3=mean(vec(sum(r.^2;dims=2)).^1.5)
    # Starts are an optimization search policy; every density evaluation uses every input point.
    starts=[mu];chosen=[argmax(vec(sum((Q.-mu').^2;dims=2)))]
    for _ in 1:min(11,size(Q,1)-1)
        distance=[minimum(sum(abs2,Q[i,:]-Q[j,:]) for j in chosen) for i in axes(Q,1)]
        push!(chosen,argmax(distance))
    end
    append!(starts,[collect(Q[j,:]) for j in unique(chosen)])
    sigmas=[.015,.025,.05,.075,.1,.15,.25,.5,1.,2.,5.,10.];xy=Any[];error=Any[];ties=Int[]
    previous=mu
    for s in sigmas
        state=mode_at(Q,s,vcat([previous],starts));point=state.point
        push!(xy,point);push!(error,point===nothing ? nothing : norm(point-mu)*1000);push!(ties,state.ties)
        point!==nothing && (previous=point)
    end
    result=Dict("sigma_cm"=>100sigmas,"xy"=>xy,"error_mm"=>error,"centroid"=>mu,"ties"=>ties,
        "radius_m"=>R,"third_moment"=>M3,"absolute_third_moment"=>S3,
        "search"=>"Full-space original-point Gaussian; best verified maximum found from multiple starts, not an exhaustive global-mode guarantee.")
    length(STUDIES)>=8 && empty!(STUDIES);STUDIES[key]=result
    result
end

heat(A)=[collect(A[:,j]) for j in axes(A,2)]
function analyze(input,c; study=true)
    P=input.points
    size(P,1)==0 && return Dict("empty"=>true,"source"=>input.source,"support"=>input.support,"original"=>input.original,"message"=>"No saved returns in the selected support. No peak or position is interpolated.","source_type"=>c.source)
    ch=chart(P,c.base,input.bounds);nx,ny=Int(c.nu),Int(c.nv);edges=[collect(range(ch.limits[a]...;length=(a==1 ? nx : ny)+1)) for a in 1:2]
    uc,vc=[(e[1:end-1]+e[2:end])/2 for e in edges];delta=[edges[a][2]-edges[a][1] for a in 1:2]
    physical=[ch.angle[a] ? deg2rad(Float64(c.angle_sigma)) : Float64(c.sigma_cm)/100 for a in 1:2]
    sigma=physical./delta;H=histogram(ch.uv,edges);V=measures(c.base,edges)
    smoothed=smooth_counts(H,sigma,ch.periodic);raw=H./V;rho=smoothed./V;top=maximum(rho);i,j=Tuple(argmax(rho))
    candidates=peaks(rho,uc,vc,physical,ch.periodic);factor=[ch.angle[a] ? 180/pi : 1. for a in 1:2]
    mu=vec(mean(P;dims=1));mc=chart(reshape(mu,1,3),c.base,input.bounds).uv[1,:].*factor
    views=Dict("world"=>[collect(P[:,a]) for a in 1:3],"chart"=>[collect(ch.full[:,a]) for a in 1:3],"chart_labels"=>ch.labels,
        "u"=>uc.*factor[1],"v"=>vc.*factor[2],"labels"=>ch.labels[collect(ch.axes)],"counts"=>heat(H),"raw"=>heat(raw),"density"=>heat(rho),
        "peak"=>[uc[i]*factor[1],vc[j]*factor[2]],"peak_value"=>top,"ties"=>count(x->abs(x-top)<=top*1e-12,rho),
        "peaks"=>[[p.u*factor[1],p.v*factor[2],p.value] for p in candidates],"centroid_chart"=>mc,"centroid_xyz"=>mu)
    Dict("empty"=>false,"source"=>input.source,"source_type"=>c.source,"frame"=>input.frame,"support"=>input.support,"original"=>input.original,
        "points"=>size(P,1),"included"=>sum(H),"base"=>c.base,"base_name"=>BASES[c.base],"unit"=>ch.unit,"display"=>c.display,
        "nu"=>nx,"nv"=>ny,"sigma_cm"=>c.sigma_cm,"angle_sigma"=>c.angle_sigma,"delta"=>delta.*factor,"sigma_cells"=>sigma,
        "integrated_mass"=>sum(rho.*V),"bounds"=>input.bounds,"views"=>views,
        "study"=>study && size(P,1)<=10000 ? bandwidth_study(P) : nothing,
        "study_notice"=>study && size(P,1)>10000 ? "Optional mode study skipped above 10000 points; the six-step field still uses every selected return." : "")
end

function evaluate(c,root; study=true)
    try
        q=resolved_settings(c);family,axes=DIM_SPECS[q.base];d=length(axes)
        input=input_cloud(q,root)
        r=d==2 ? analyze(input,q;study) : analyze_nd(input,q)
        if !get(r,"empty",false)
            # One actual occupied cell, expressed in full chart coordinates for display.
            fullbase=family=="cartesian" ? "xyz" : family=="cylindrical" ? "cyl3" : "sphere3"
            full=chart_nd(input.points,fullbase,input.bounds);lo=[v[1] for v in full.limits];hi=[v[2] for v in full.limits]
            lower=copy(lo);upper=copy(hi);indices=Int[]
            for (a,axis) in enumerate(axes)
                n=(d==2 && a==2) ? Int(q.nv) : Int(q.nu)
                edge=collect(range(lo[axis],hi[axis];length=n+1));idx=clamp(searchsortedlast(edge,full.uv[1,axis]),1,n)
                lower[axis]=edge[idx];upper[axis]=edge[idx+1];push!(indices,idx)
            end
            factor=family=="cartesian" ? ones(3) : family=="cylindrical" ? [1.,180/pi,1.] : [1.,180/pi,180/pi]
            r["views"]["basis_cell"]=Dict("axes"=>axes,"lower"=>lower.*factor,"upper"=>upper.*factor,
                "domain_lower"=>lo.*factor,"domain_upper"=>hi.*factor,"indices"=>indices,"labels"=>full.labels,
                "example"=>"Cell containing the first supplied return; omitted axes span the chart domain.")
        end
        r["dimension"]=d;r["family"]=family
        angular=family=="cartesian" ? Int[] : family=="cylindrical" ? [2] : [2,3]
        r["has_angles"]=any(a->a in angular,axes);r["has_lengths"]=any(a->!(a in angular),axes);r
    catch error
        Dict("empty"=>true,"source_type"=>c.source,"source"=>"Input validation","message"=>sprint(showerror,error),
            "family"=>hasproperty(c,:family) ? c.family : "cartesian","dimension"=>hasproperty(c,:dimensions) ? c.dimensions : 2)
    end
end

include("DensityDimensions.jl")

end
