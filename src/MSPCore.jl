module MSPCore

using Random

export make_target, project_points, histogram2d, density_energy, global_msp, landscape

"""Synthetic surface samples in metres; no visibility, ray tracing or LiDAR noise model."""
function make_target(; kind="Human", x=0.8, y=0.5, height=1.7, radius=0.25,
                     n=900, seed=1, yaw=0.0)
    kind in ("Human", "Robot") || throw(ArgumentError("Unknown target: $kind"))
    n >= 20 || throw(ArgumentError("Use at least 20 points"))
    height > 0 && radius > 0 || throw(ArgumentError("Dimensions must be positive"))
    rng = MersenneTwister(seed)
    p = zeros(n, 3)
    if kind == "Human"
        # Head, torso, two arms and two legs. Same local samples for any position/yaw.
        centers = [(0., 0., .92), (0., 0., .63), (-.95, 0., .58),
                   (.95, 0., .58), (-.42, 0., .235), (.42, 0., .235)]
        scales = [(.52, .52, .08), (1., .65, .21), (.22, .25, .20),
                  (.22, .25, .20), (.31, .36, .235), (.31, .36, .235)]
        cutoffs = (.15, .52, .61, .70, .85, 1.0)
        for i in 1:n
            draw = rand(rng)
            part = findfirst(c -> draw <= c, cutoffs)
            cx, cy, cz = centers[part]
            a, b, c = scales[part]
            zunit = 2rand(rng) - 1
            angle = 2pi * rand(rng)
            radial = sqrt(max(0, 1 - zunit^2))
            p[i, :] .= (radius * (cx + a * radial * cos(angle)),
                        radius * (cy + b * radial * sin(angle)),
                        height * (cz + c * zunit))
        end
    else
        # Mobile robot: box chassis, mast and circular top scanner.
        for i in 1:n
            draw = rand(rng)
            if draw < .72
                q = 2 .* rand(rng, 3) .- 1
                face = rand(rng, 1:3)
                q[face] = rand(rng, Bool) ? 1.0 : -1.0
                p[i, :] .= (1.2radius*q[1], radius*q[2], height*(.20+.20q[3]))
            elseif draw < .90
                angle = 2pi*rand(rng)
                p[i, :] .= (.18radius*cos(angle), .18radius*sin(angle),
                            height*(.4+.5rand(rng)))
            else
                angle = 2pi*rand(rng)
                p[i, :] .= (.65radius*cos(angle), .65radius*sin(angle),
                            height*(.90+.10rand(rng)))
            end
        end
    end
    c, s = cos(yaw), sin(yaw)
    for i in axes(p, 1)
        px, py = p[i, 1], p[i, 2]
        p[i, 1] = x + c*px - s*py
        p[i, 2] = y + s*px + c*py
    end
    return p
end

"""Angular window is centred on a fixed reference bearing; radians throughout."""
function project_points(points, sensor, base; angle_center=0.0)
    size(points, 2) == 3 || throw(DimensionMismatch("Expected N x 3 points"))
    size(points, 1) > 0 || throw(ArgumentError("Empty point cloud"))
    all(isfinite, points) && all(isfinite, sensor) || throw(ArgumentError("Nonfinite coordinates"))
    dx = points[:, 1] .- sensor[1]
    dy = points[:, 2] .- sensor[2]
    down = sensor[3] .- points[:, 3]
    r = hypot.(dx, dy)
    angle = angle_center .+ mod.(atan.(dy, dx) .- angle_center .+ pi, 2pi) .- pi
    if base == "XY"
        return (u=copy(points[:, 1]), v=copy(points[:, 2]),
                xlabel="X (m)", ylabel="Y (m)", periodic=(false, false))
    elseif base == "R-Theta"
        return (u=r, v=angle, xlabel="r (m)", ylabel="theta (rad)", periodic=(false, true))
    elseif base == "Phi-Beta"
        all(down .> 0) || throw(ArgumentError("Ceiling sensor must be above every target point"))
        return (u=angle, v=atan.(r, down), xlabel="phi (rad)", ylabel="beta (rad)",
                periodic=(true, false))
    end
    throw(ArgumentError("Unknown base: $base"))
end

"""H[i,j] stores count at u-bin i and v-bin j, including the upper nonperiodic edge."""
function histogram2d(u, v; nx=80, ny=65, ulim, vlim)
    length(u) == length(v) || throw(DimensionMismatch("Coordinate lengths differ"))
    nx >= 2 && ny >= 2 || throw(ArgumentError("Grid needs at least two bins per axis"))
    ulim[1] < ulim[2] && vlim[1] < vlim[2] || throw(ArgumentError("Invalid limits"))
    ue = collect(range(ulim..., length=nx+1))
    ve = collect(range(vlim..., length=ny+1))
    H = zeros(nx, ny)
    for (a, b) in zip(u, v)
        isfinite(a) && isfinite(b) || throw(ArgumentError("Nonfinite bin coordinates"))
        if ue[1] <= a <= ue[end] && ve[1] <= b <= ve[end]
            i = min(searchsortedlast(ue, a), nx)
            j = min(searchsortedlast(ve, b), ny)
            H[i, j] += 1
        end
    end
    return (H=H, u_edges=ue, v_edges=ve,
            u_centers=(ue[1:end-1]+ue[2:end])/2,
            v_centers=(ve[1:end-1]+ve[2:end])/2)
end

function smooth_axis(A, weights, offsets, dim, periodic)
    B = zeros(size(A))
    for j in axes(A, 2), i in axes(A, 1)
        for (w, offset) in zip(weights, offsets)
            a, b = dim == 1 ? (i+offset, j) : (i, j+offset)
            if periodic
                a = mod1(a, size(A, 1))
                b = mod1(b, size(A, 2))
            end
            if 1 <= a <= size(A, 1) && 1 <= b <= size(A, 2)
                B[i, j] += w*A[a, b]
            end
        end
    end
    return B
end

"""Separable discrete Gaussian, truncated at 4 sigma; zero padding except angular wrap."""
function density_energy(H, sigma; periodic=(false, false))
    isfinite(sigma) && sigma >= 0 || throw(ArgumentError("Invalid sigma"))
    all(isfinite, H) && all(H .>= 0) || throw(ArgumentError("Counts must be finite and nonnegative"))
    if sigma == 0
        return copy(H), H.^2
    end
    offsets = -ceil(Int, 4sigma):ceil(Int, 4sigma)
    weights = exp.(-0.5 .* (offsets ./ sigma).^2)
    weights ./= sum(weights)
    Hs = smooth_axis(smooth_axis(H, weights, offsets, 1, periodic[1]),
                     weights, offsets, 2, periodic[2])
    return Hs, Hs.^2
end

"""Representative global maximum; ties use Julia column-major order, not a uniqueness claim."""
function global_msp(E, uc, vc)
    size(E) == (length(uc), length(vc)) || throw(DimensionMismatch("Grid axes do not match energy"))
    all(isfinite, E) && maximum(E) > 0 || throw(ArgumentError("Energy must contain a positive finite maximum"))
    i, j = Tuple(argmax(E))
    value = E[i, j]
    tolerance = 1e-12 * value
    return (i=i, j=j, u=uc[i], v=vc[j], value=value,
            near_max_cells=count(x -> abs(x-value) <= tolerance, E))
end

function landscape(points, sensor, base; nx=80, ny=65, sigma=1.5, angle_center=0.0)
    projection = project_points(points, sensor, base; angle_center)
    angular_limits = (angle_center-pi, angle_center+pi)
    ulim, vlim = base == "XY" ? ((-3.2, 3.2), (-3.2, 3.2)) :
                 base == "R-Theta" ? ((0.0, 4.6), angular_limits) :
                 (angular_limits, (0.0, pi/2))
    bins = histogram2d(projection.u, projection.v; nx, ny, ulim, vlim)
    sum(bins.H) > 0 || throw(ArgumentError("No points inside the plotting window"))
    Hs, E = density_energy(bins.H, sigma; periodic=projection.periodic)
    msp = global_msp(E, bins.u_centers, bins.v_centers)
    return (; projection..., bins..., Hs, E, msp,
            included=Int(sum(bins.H)), total=size(points, 1),
            du=bins.u_edges[2]-bins.u_edges[1], dv=bins.v_edges[2]-bins.v_edges[1])
end

end
