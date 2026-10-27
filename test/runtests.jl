using Test
using Random
include(joinpath(@__DIR__, "..", "src", "MSPCore.jl"))
using .MSPCore

@testset "Deterministic geometry and rigid motion" begin
    for kind in ("Human", "Robot")
        p = make_target(; kind, x=0, y=0, n=600)
        @test p == make_target(; kind, x=0, y=0, n=600)
        shifted = make_target(; kind, x=1.1, y=-.7, n=600)
        @test shifted ≈ p .+ [1.1 -.7 0]
        rotated = make_target(; kind, x=0, y=0, yaw=pi/2, n=600)
        @test rotated[:, 1] ≈ -p[:, 2]
        @test rotated[:, 2] ≈ p[:, 1]
        @test all(0 .<= p[:, 3] .<= 1.7)
    end
    Random.seed!(17)
    expected = rand()
    Random.seed!(17)
    make_target()
    @test rand() == expected # Does not reset/consume the caller's global RNG.
end

@testset "Coordinate definitions and fixed-window coverage" begin
    p = [1.0 0 1; 0 1 0; 0 0 1]
    s = [0., 0., 2.]
    rtheta = project_points(p, s, "R-Theta")
    angular = project_points(p, s, "Phi-Beta")
    @test rtheta.u ≈ [1, 1, 0]
    @test rtheta.v ≈ [0, pi/2, 0]
    @test angular.v ≈ [pi/4, atan(1, 2), 0]
    @test_throws ArgumentError project_points(p, [0, 0, 1], "Phi-Beta")
    for kind in ("Human", "Robot"), x in (-2.5, 0., 2.5), y in (-2.5, 0., 2.5),
        yaw in (0., pi/4), base in ("XY", "R-Theta", "Phi-Beta")
        cloud = make_target(; kind, x, y, yaw, height=1.95, radius=.35, n=300)
        d = landscape(cloud, [0., 0., 2.2], base; nx=40, ny=55, sigma=0)
        @test d.included == 300
        @test size(d.H) == (40, 55)
        @test isfinite(d.msp.value)
    end
end

@testset "Histogram orientation, boundaries and maximum" begin
    b = histogram2d([0., 1., 1., .4], [0., 2., 2., 1.]; nx=4, ny=5, ulim=(0, 1), vlim=(0, 2))
    @test sum(b.H) == 4
    @test b.H[4, 5] == 2
    msp = global_msp(b.H.^2, b.u_centers, b.v_centers)
    @test (msp.i, msp.j) == (4, 5)
    @test msp.u == .875
    @test msp.v == 1.8
    @test msp.near_max_cells == 1
    tie = global_msp([1. 0.; 0. 1.], [0, 1], [0, 1])
    @test tie.near_max_cells == 2
    @test (tie.i, tie.j) == (1, 1)
    @test_throws ArgumentError global_msp(zeros(2, 2), [0, 1], [0, 1])
end

@testset "Gaussian reference and angular seam" begin
    H = zeros(13, 17)
    H[7, 9] = 5
    H[2, 16] = 2
    sigma = 1.1
    Hs, E = density_energy(H, sigma)
    offsets = -ceil(Int, 4sigma):ceil(Int, 4sigma)
    w = exp.(-.5 .* (offsets ./ sigma).^2)
    w ./= sum(w)
    direct = zeros(size(H))
    # Independent direct 2D convolution to catch axis/boundary mistakes.
    for j in axes(H, 2), i in axes(H, 1), (a, di) in enumerate(offsets), (b, dj) in enumerate(offsets)
        ii, jj = i+di, j+dj
        if checkbounds(Bool, H, ii, jj)
            direct[i, j] += w[a]*w[b]*H[ii, jj]
        end
    end
    @test Hs ≈ direct
    @test E ≈ Hs.^2
    @test argmax(E) == argmax(Hs)
    @test density_energy(H, 0) == (H, H.^2)
    seam = zeros(13, 17)
    seam[7, 1] = 1
    periodic, _ = density_energy(seam, 1.; periodic=(false, true))
    @test periodic[7, 2] ≈ periodic[7, end]
    @test sum(periodic) ≈ 1
    translated, _ = density_energy(circshift(seam, (0, 5)), 1.; periodic=(false, true))
    @test translated ≈ circshift(periodic, (0, 5))
    @test_throws ArgumentError density_energy(H, -1)
end
