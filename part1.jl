### A Pluto.jl notebook ###
# v1.0.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18601
begin
    import Pkg
    Pkg.activate(@__DIR__; io=devnull)
    using PlutoUI: Slider, Select, CheckBox, TableOfContents
    using CairoMakie
    CairoMakie.activate!(type="png")
end

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18602
msp_core = Base.include(Module(gensym(:MSPWorkspace)), joinpath(@__DIR__, "src", "MSPCore.jl"));

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18612
page_style = HTML("<style>main { max-width: 1400px; margin: 0 auto; padding-left: max(20px, 3vw); padding-right: max(20px, 3vw); }</style>")

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18603
md"""
# Part I — Human / Robot MSP Landscapes

在 **XY、R–Theta、Phi–Beta** 三种坐标下，观察同一组 3D 点的密度与山体图。

本示例生成合成人体／机器人**表面点**，计算每格计数 `H`、离散 Gaussian 平滑计数
`Hs` 及 `E = Hs²`；红色星号是一个代表性全局最高格（本 notebook 中的 MSP）。
它不是人体中心真值，也不是实测 LiDAR：尚未模拟遮挡、射线采样、反射率或测量噪声。

**使用：**拖动位置或路径进度滑块；图会自动更新。相同随机种子保留局部点形状。
Pluto 是浏览器里的交互编辑器，VS Code 用于项目管理和启动。不要同时在两处编辑同一文件。
"""

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18604
TableOfContents(aside=false)

# ╔═╡ a8251000-2026-4025-8000-000000000008
let
    book_navigation = Base.include(Module(gensym(:BookWorkspace)), joinpath(@__DIR__, "src", "BookUI.jl"))
    Base.invokelatest(() -> HTML("<p><a href=\"$(book_navigation.notebook_url("introduction.jl"))\">← Introduction</a> · <a href=\"$(book_navigation.notebook_url("chapter1_density.jl"))\">Part I: density chapter</a> · <strong>Existing synthetic sandbox</strong></p>"))
end

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18605
md"""
## 1. Target and motion / 目标与移动

目标类型 $(@bind target_kind Select(["Human", "Robot"], default="Human"))

手动 X (m) $(@bind target_x Slider(-2.5:0.1:2.5, default=0.8, show_value=true))

手动 Y (m) $(@bind target_y Slider(-2.5:0.1:2.5, default=0.5, show_value=true))

使用圆形演示路径 $(@bind use_path CheckBox(default=false))

路径进度 (0–1) $(@bind path_progress Slider(0:0.01:1, default=0.0, show_value=true))

朝向 (degrees) $(@bind yaw_deg Slider(-180:5:180, default=0, show_value=true))

人体身高／机器人高度 (m) $(@bind target_height Slider(0.8:0.05:1.95, default=1.7, show_value=true))

宽度尺度 (m) $(@bind target_radius Slider(0.18:0.01:0.35, default=0.25, show_value=true))

点数 $(@bind n_points Slider(300:100:2400, default=900, show_value=true))

随机种子 $(@bind seed Slider(1:50, default=1, show_value=true))

路径模式：中心 (0,0)、半径 1.8 m，手动 X/Y 暂不参与；进度滑块展示独立帧，不累计历史点。
"""

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18606
md"""
## 2. Sensor and density / 传感器与密度

顶置传感器高度 (m) $(@bind sensor_height Slider(2.2:0.1:4.0, default=2.7, show_value=true))

详细视图坐标 $(@bind base Select(["XY", "R-Theta", "Phi-Beta"], default="XY"))

第一轴格数 $(@bind gridsize_x Slider(40:5:140, default=80, show_value=true))

第二轴格数 $(@bind gridsize_y Slider(40:5:140, default=65, show_value=true))

Gaussian σ (格数，0 为不平滑) $(@bind sigma Slider(0:0.1:4.0, default=1.5, show_value=true))

显示三基底比较 $(@bind show_comparison CheckBox(default=true))

σ 使用格数单位；改变网格会改变实际带宽。三个基底的轴单位／格面积不同，
这里未做 Jacobian 或概率密度归一化，**不能直接比较它们的峰高来判断优劣**。
"""

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18607
target_position = use_path ? (1.8cos(2pi*path_progress), 1.8sin(2pi*path_progress)) : (target_x, target_y);

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18608
points = msp_core.make_target(kind=target_kind, x=target_position[1], y=target_position[2],
    height=target_height, radius=target_radius, n=n_points, seed=seed, yaw=deg2rad(yaw_deg));

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18609
sensor_pos = [0.0, 0.0, sensor_height];

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f1860a
bases = ("XY", "R-Theta", "Phi-Beta");

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f1860b
landscapes = Dict(b => msp_core.landscape(points, sensor_pos, b;
    nx=gridsize_x, ny=gridsize_y, sigma=sigma) for b in bases);

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f1860c
selected = landscapes[base];

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f1860d
md"""
## 3. Current result / 当前结果

- 目标 **$(target_kind)**，位置 **($(round(target_position[1], digits=2)), $(round(target_position[2], digits=2))) m**。
- 当前 **$(base)**，网格 **$(gridsize_x) × $(gridsize_y)**；窗口内 **$(selected.included) / $(selected.total)** 点。
- 格宽 **($(round(selected.du, digits=4)), $(round(selected.dv, digits=4)))**，单位见图轴。
- 实际轴向 σ **($(round(sigma*selected.du, digits=4)), $(round(sigma*selected.dv, digits=4)))**，单位见图轴。
- MSP 格中心 **($(round(selected.msp.u, digits=4)), $(round(selected.msp.v, digits=4)))**。
- MSP 能量 **$(round(selected.msp.value, sigdigits=6))**；相对 `1e-12` 能量容差内最高格数 **$(selected.msp.near_max_cells)**。

若有多个等高格，星号只选数组顺序中的第一个；最高格数不是局部峰数或人数。
对非负 `Hs`，平方不改变最高格位置。这里保留平方是为了展示原 Part I 的能量约定。
"""

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f1860e
scene_figure = let
    fig = Figure(size=(1100, 460), fontsize=14, figure_padding=(45, 20, 20, 20))
    ax = Axis3(fig[1, 1], title="Synthetic $target_kind + ceiling sensor",
        xlabel="X (m)", ylabel="Y (m)", zlabel="Z (m)", aspect=:data)
    scatter!(ax, points[:, 1], points[:, 2], points[:, 3];
        color=points[:, 3], colormap=:viridis, markersize=5)
    scatter!(ax, [sensor_pos[1]], [sensor_pos[2]], [sensor_pos[3]];
        marker=:diamond, color=:red, markersize=16, label="Sensor")
    lines!(ax, [-3.2, 3.2, 3.2, -3.2, -3.2], [-3.2, -3.2, 3.2, 3.2, -3.2], zeros(5);
        color=(:gray, .45))
    xlims!(ax, -3.2, 3.2); ylims!(ax, -3.2, 3.2); zlims!(ax, 0, 4)
    ax2 = Axis(fig[1, 2], title=base == "XY" ? "XY accumulation: input points" : "$base: input coordinates",
        xlabel=selected.xlabel, ylabel=selected.ylabel)
    scatter!(ax2, selected.u, selected.v; color=(:steelblue, .5), markersize=4)
    xlims!(ax2, first(selected.u_edges), last(selected.u_edges))
    ylims!(ax2, first(selected.v_edges), last(selected.v_edges))
    fig
end

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f1860f
detail_figure = let
    fig = Figure(size=(1250, 460), fontsize=14, figure_padding=(25, 25, 20, 20))
    ax = Axis(fig[1, 1], title="Smoothed counts / bin — $base",
        xlabel=selected.xlabel, ylabel=selected.ylabel)
    # Makie expects (length(u), length(v)); do not transpose the matrix.
    hm = heatmap!(ax, selected.u_centers, selected.v_centers, selected.Hs; colormap=:viridis)
    scatter!(ax, [selected.msp.u], [selected.msp.v]; marker=:star5,
        color=:red, strokecolor=:white, strokewidth=1, markersize=20)
    Colorbar(fig[1, 2], hm; label="Hs (smoothed counts / bin)")
    ax3 = Axis3(fig[1, 3], title="Energy mountain — $base",
        xlabel=selected.xlabel, ylabel=selected.ylabel, zlabel="E = Hs squared")
    surface!(ax3, selected.u_centers, selected.v_centers, selected.E; colormap=:viridis)
    scatter!(ax3, [selected.msp.u], [selected.msp.v], [selected.msp.value];
        marker=:star5, color=:red, markersize=18, depth_shift=-0.01)
    colgap!(fig.layout, 2, 65)
    fig
end

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18610
comparison_figure = if show_comparison
    let
        fig = Figure(size=(1260, 820), fontsize=13, figure_padding=(45, 25, 20, 20))
        Label(fig[0, 1:3], "Same 3D points | separate scales per base | red star = representative maximum", fontsize=17)
        for (column, b) in enumerate(bases)
            d = landscapes[b]
            ax = Axis(fig[1, column], title="$b | Hs max = $(round(maximum(d.Hs), sigdigits=3))",
                xlabel=d.xlabel, ylabel=d.ylabel)
            heatmap!(ax, d.u_centers, d.v_centers, d.Hs; colormap=:viridis)
            scatter!(ax, [d.msp.u], [d.msp.v]; marker=:star5, color=:red,
                strokecolor=:white, strokewidth=1, markersize=18)
            ax3 = Axis3(fig[2, column], title="$b | energy mountain",
                xlabel=d.xlabel, ylabel=d.ylabel, zlabel="E = Hs squared")
            surface!(ax3, d.u_centers, d.v_centers, d.E; colormap=:viridis)
            scatter!(ax3, [d.msp.u], [d.msp.v], [d.msp.value];
                marker=:star5, color=:red, markersize=16, depth_shift=-0.01)
        end
        fig
    end
else
    md"三基底比较已关闭；上方详细视图仍会更新。"
end

# ╔═╡ f1c4c221-4a32-4f58-886a-a841e4f18611
md"""
## 4. How to read the plots / 图的含义

**XY：**将同一帧点累积到地面 XY 格子，忽略高度。这里只是单帧 accumulation，不做跨帧累积。

**R–Theta：**`r = hypot(x-sx, y-sy)` 是水平距离，theta 是方位角。

**Phi–Beta：**phi 为方位角；`beta = atan(r, sensor_z-z)` 是相对向下轴的偏角。
角度单位为 radians；beta 在传感器正下方为 0。传感器高度只影响此角度坐标，不改变生成的点数。

两个角度基底固定使用 `[-pi, pi)` 方位角窗口，并对该维做周期 Gaussian 平滑。
跨边界的目标会在平面图两端出现，这是圆周展开；这两个边界在计算上相邻。
XY 和非周期轴使用零填充，不反射补点。固定窗口覆盖所有滑块设定；窗口外点不会计入。

平滑核在 4σ 截断并归一化。各坐标使用相同的格数 σ，
但物理带宽和坐标测度不同；峰位也不是可直接互换的完整 3D 位置。
顶置 LiDAR 的真实性能需要真实数据、可见性／遮挡模型和独立真值另行验证。

**运行方式：**本地项目 `Project.toml` / `Manifest.toml` 统一管理依赖。
完整步骤见同目录 `README_zh.md`。修改 `src/MSPCore.jl` 后，在 Pluto 重跑 include 单元（或重开 notebook）。
CairoMakie 输出静态图片，滑块可交互更新；图内鼠标不能旋转 3D 相机。
"""

# ╔═╡ Cell order:
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18601
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18602
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18612
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18603
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18604
# ╟─a8251000-2026-4025-8000-000000000008
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18605
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18606
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18607
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18608
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18609
# ╟─f1c4c221-4a32-4f58-886a-a841e4f1860a
# ╟─f1c4c221-4a32-4f58-886a-a841e4f1860b
# ╟─f1c4c221-4a32-4f58-886a-a841e4f1860c
# ╟─f1c4c221-4a32-4f58-886a-a841e4f1860d
# ╟─f1c4c221-4a32-4f58-886a-a841e4f1860e
# ╟─f1c4c221-4a32-4f58-886a-a841e4f1860f
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18610
# ╟─f1c4c221-4a32-4f58-886a-a841e4f18611
