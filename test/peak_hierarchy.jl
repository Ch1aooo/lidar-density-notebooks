using Test
include(joinpath(@__DIR__,"..","src","PeakHierarchy.jl"))
using .PeakHierarchy

@testset "Exact superlevel merge hierarchy" begin
    t=merge_tree(reshape([9.,4.,7.,2.,6.],1,:);cellarea=.25)
    @test length(t.peaks)==3
    @test [p[:birth] for p in t.peaks]==[9,7,6]
    @test [p[:death] for p in t.peaks]==[nothing,4.,2.]
    @test pair_saddle(t,1,2)==4
    @test pair_saddle(t,2,3)==2
    @test t.peaks[2][:metrics].mass==7*.25
    @test t.peaks[2][:metrics].excess==3*.25
    @test t.events[2].branches[1].metrics.mass==(9+4+7)*.25
    @test t.events[2].branches[1].metrics.excess==(9+4+7-6)*.25
    @test t.peaks[1][:metrics]===nothing
    @test select_peaks(t;min_height=.5)==[1,3]
    plateau=merge_tree([5. 5. 1. 5. 5.])
    @test length(plateau.peaks)==2
    @test plateau.peaks[1][:index]==1
    @test plateau.peaks[2][:parent]==1
    @test plateau.peaks[2][:metrics].area==2
    @test length(merge_tree(fill(2.,3,3)).peaks)==1
    @test isempty(merge_tree(zeros(3,3)).peaks)
    @test isempty(merge_tree(zeros(0,0)).peaks)
    @test_throws ArgumentError merge_tree([NaN;;])
    @test_throws ArgumentError merge_tree([-1.;;])
    @test_throws ArgumentError merge_tree([1.;;];cellarea=0)
    squared=merge_tree(reshape([9.,4.,7.,2.,6.].^2,1,:))
    @test [p[:parent] for p in squared.peaks]==[p[:parent] for p in t.peaks]
    @test pair_saddle(squared,1,2)==16
    @test squared.peaks[2][:relative_height]≈1-(4/7)^2
    @test length(merge_tree([2. 0.;0. 2.]).peaks)==1 # 8-connected plateau
end

@testset "Independent strict-superlevel flood-fill oracle" begin
    using Random
    rng=MersenneTwister(91)
    for _ in 1:20
        A=Float64.(rand(rng,0:6,5,7));t=merge_tree(A;cellarea=.03)
        for event in t.events, b in event.branches
            start=t.peaks[b.peak][:index];seen=Set([start]);queue=[start]
            for k in queue
                j=mod1(k,5);i=div(k-1,5)+1
                for dj in -1:1,di in -1:1
                    jj=j+dj;ii=i+di
                    if 1<=jj<=5 && 1<=ii<=7
                        q=jj+(ii-1)*5
                        if A[q]>event.level && !(q in seen)
                            push!(seen,q);push!(queue,q)
                        end
                    end
                end
            end
            @test Set(b.metrics.cells)==seen
            @test b.metrics.excess≈sum(A[k]-event.level for k in seen)*.03
        end
    end
end

include(joinpath(@__DIR__,"..","src","SeparationComparison.jl"))
using .SeparationComparison
@testset "Gaussian default and probe regression" begin
    for (bridge,expected) in ((0.,.66093),(.12,.41292),(.32,.09603))
        s=synthetic_scene(bridge_fraction=bridge)
        f=gaussian_field(s.points;nx=162,ny=116)
        area=(f.x[2]-f.x[1])*(f.y[2]-f.y[1])
        t=merge_tree(f.rho;cellarea=area)
        saddle=pair_saddle(t,1,2)
        @test saddle≈f.saddle
        @test 1-saddle/min(t.peaks[1][:birth],t.peaks[2][:birth])≈expected atol=1e-5
        e=only(filter(e->e.level==saddle,t.events))
        @test all(b->b.metrics.excess>=0,e.branches)
        @test all(b->0<=b.metrics.relative_excess<=1,e.branches)
    end
end
