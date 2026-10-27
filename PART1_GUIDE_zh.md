# Part I：密度山体演示

主文件：`chapter1_density.jl`。Introduction 保留原结构，仅补充 Yiyun 的测量来源与毕设引用。

## 在 VS Code 启动

1. VS Code → File → Open Folder → `Z:\TUe\GP Thesis\Coding\Julia`。
2. 新建自己的 PowerShell 终端，运行：

```powershell
Set-Location -LiteralPath 'Z:\TUe\GP Thesis\Coding\Julia'
julia --project=. launch.jl chapter1_density.jl
```

复制终端打印的完整本地链接（包括 secret）。已有 Pluto 时可从 Introduction 顶部目录进入 **I · Density representations**，无须再启动服务器。若首次显示 Safe preview，核对本地文件路径后点击 **Run notebook code**。

若现有 Pluto 仍显示旧章节：在你自己启动 Pluto 的终端按 Ctrl+C，再执行上面的启动命令。
浏览器刷新不会可靠地重载已 include 的 `src` 模块；也可在 Pluto 首页先关掉该 notebook 的 Julia 工作进程，再重新打开。

Julia REPL 中等价运行：

```julia
cd(raw"Z:\TUe\GP Thesis\Coding\Julia")
import Pkg
Pkg.activate(".")
using Pluto
Pluto.run(notebook=joinpath(pwd(), "chapter1_density.jl"))
```

首次换电脑执行 `julia --project=. setup.jl`。当前环境已验证 Julia 1.12.6、Pluto 1.0.4；新增直接依赖均来自已缓存的项目依赖，不升级现有包。不要在 VS Code 和 Pluto 同时修改同一文件；修改模块/素材后，重新打开该 notebook 或重新运行第一个加载单元。

## 建议演示顺序

1. 先看暖黄色出发点，再看 Julia SVG 简笔图与分组对照表。默认调暗；悬浮/聚焦一行点亮对应部分，显示上层喻体、下层本体名称。也可用 Pin an analogy concept 选择并固定。
2. 默认两个随机椭球、1600 点，XY 平面、64×64 网格、σ=7.5 cm、dB。
3. 固定 σ，只改变 U/V cells：这是分辨率实验。固定网格改变 σ：这是平滑尺度实验。σcells = σphysical / Δ，因此它们不再混为一个旋钮。
4. 按 Coordinate family → Retained dimensions → 具体坐标选择。三类坐标系各有3个单轴、3个坐标对和1个完整三元组，共21项。Cartesian可选X/Y/Z、XY/XZ/YZ、XYZ；圆柱可选ρ/φ/Z及三种对/完整三元组；球面可选R/φ/β及三种对/完整三元组。1D显示密度曲线，2D显示地图/山体，3D在原始XYZ上用颜色显示三维密度。
5. 切换 Yiyun · L-walk：默认第97帧；全点1863，头部高度带253。第1帧确实无保存点；不插值、不生成零位置。没有核实时间戳，帧号不能换算成秒。
6. 选择 Import XYZ CSV 后选本地 CSV。必需表头 `x,y,z`，单位米；可含整数 `frame`（1–100000）。CSV frame=0 表示第一个存在的帧。支持带引号字段和 BOM；不接受 NaN/Inf。上限20MB、100000行，不暗中抽样。头部带只是高度筛选，不能识别人/机器人。
7. 看独立 Bandwidth trajectory：默认当前实测F97、全点、无分箱。输入和分辨率固定，只沿σ扫描。默认160个样本，从0.03到1000cm，可选96/240样本。左侧完整XY轨迹，右侧到原始质心的距离。Selected σ滑块/下拉只移动标记，不重算、不隐藏完整曲线。Distance-axis view可单独放大1cm以下。此模块有独立输入/帧/高度带；不受上方六步图的调参影响。模型可切Original points或Weighted bin centres，Δ只有0.5/1/2/5cm四项；分箱计数作为权重保留。上限10000点，超过时明示而非抽样。
8. 两个 **Expand derivation** 默认收缩。六步推导已移到六步图之前；折叠区先用表说明不分箱/网格/加权分箱三条路线。可编辑来源为 `PART1_EQUATIONS.md`，本页编号 **(1.1)–(1.22)**。距离公式(1.20)直接显示在独立轨迹图之前。编号按章节页面重启，不随浏览器滚屏改变。

CSV 示例：

```csv
x,y,z,frame
0.25,0.40,1.50,1
0.28,0.42,1.55,1
0.35,0.45,1.48,2
```

## 与旧 Python 的有意差异

| 项目 | 新 Julia Part I |
|:--|:--|
| 六步 | 点云 → 坐标 → 计数 → 按测度归一化 → 平滑山体 → 峰与质心 |
| 平滑 | 平滑计数再除面积/立体角；非均匀测度下守恒。旧代码直接平滑密度，结果不会完全相同。 |
| 带宽 | 长度轴使用 cm，角度轴使用度；自动转换成网格格数。 |
| ρ–φ | 使用水平距离 ρ；不将三维斜距 R 当圆环半径。 |
| dB | 默认相对密度10log₁₀(ρ/ρmax)，下限−50dB；不沿用平方伪能量的20log。 |
| 旧 E=ρ² | 非负密度下不会增加新峰，推导保留在折叠区，不再占用主图。 |
| 未迁移 | 采样/扫描仿真、旧面板的大量重复参数；旧 Python 与 `part1.jl` 原型保留。 |

## 解释边界

- XYZ 是定位的世界坐标基础。圆柱/球坐标用于分析传感器几何和方向分布；角度均匀不等于物理面积均匀。示例传感器原点(0,0,2.7m)需独立标定确认。
- 主图是有限网格，边界反射、方位角环绕，核截断半径 ceil(4σcells)。全空间质心定理及小图不使用这套边界，不能互相冒用结论。
- 线性读数保留单位，dB每幅各自归一到0。峰数阈值是明确的演示策略，不是可靠人数。
- 单人且已知目标时，没有证明比质心更准确或更省算力。多人优势是待验证的“先场后峰”候选构建思路；近距离/遮挡/人机分离/ID连续关联尚未完成。
- “secondary information”是派生场，不是统计二阶矩。质心偏差不等于定位误差；大 σ 可以趋近质心，同时合并真实的多个目标。

Yiyun 来源：Xu, Yiyun (2026), *Continuous Indoor Localization through Lidar and IMU Sensor Fusion*, MSc thesis, TU/e Electrical Engineering。项目本地原文 `Z:\TUe\GP Thesis\Reference\final_report_with_cover_Yiyun.pdf`。没有为该论文编造公开链接或 DOI。

## 新版轨迹和跳点的读法

- 不是时间轨迹：点云保持固定，曲线参数为高斯σ；当前σ标记同时显示e(σ;Δ)。图中距离是与原始点质心的差，不是定位真值误差。
- 默认raw/F97的160样本诊断中，4组可疑区间约0.091–0.098、0.144–0.165、0.176–0.188、0.610–0.652cm。约0.652cm之后未再触发本次跳步规则。区间随数据、模型、搜索/采样变化；不是精确分岔点或通用连续性阈值。
- 红色虚线/叉号表示数值平局、未验证模式或相邻位移超过max(5mm,0.35σ_previous)。实线在这些位置断开；表格最多列6组。有限多起点不能保证穷尽全部全局模式，跳步也可能受数值选择影响。
- 原来的经典PNG保留在assets/part1中；当前展示使用Julia生成的SVG，无新图片生成依赖。表格按Source（暖黄）、Observed scene（淡蓝）、Derived interpretation（淡蓝）由浅入深排列。
- Summary现为最后一个内容段落，References随后列出引用。自遮挡引用Xu/Qiangeng等AAAI2022的概念说明，不称其首次提出。DBSCAN解释为邻域/最小支持定义的密度连通分组，不等同数峰，也不要求两个雷达。

## 1D / 2D / 3D与密度颜色

- 单轴X积掉Y/Z，只得到X方向的位置分布，不能恢复唯一XY/XYZ。角度单轴密度使用每弧度，图轴以度显示；它不是每立体角。
- 2D XY山体把密度放在绘图高度轴，此时该轴不是原始Z。ρ–φ、φ–β按原有明确测度归一；新混合角度–长度对使用参数乘积测度，不自动称为面积或体积密度。
- 3D XYZ保留所有原始点位置，仅改变点的颜色。圆柱/球坐标下也在原始世界XYZ上着色，但三维格子的划分与体积按对应坐标系计算。线性单位points/m³，dB仍按同一场最大值归一；颜色取所在格子的值，不伪造更细的空间细节。
- 3D分辨率简化为每轴16/24/32/40格，默认24³；1D只需U格数，2D有U/V格数。各状态保留控件值和旋转视角。首次切换维度可能需要Julia编译新代码，后续更新更快。
- 公式(1.21)列出1D/3D测度，(1.22)明确点位不变、颜色为密度；折叠说明位于带宽推导之后。独立带宽轨迹始终是XY研究，不随六步图的维度变化。

## 累计基底、方向性合成分布与参数分组 — 2026-10-26

- 合成点云新增Density pattern：One directional concentration / Two directional concentrations / Uniform volume reference。每个椭球方向不同，seed控制可重复随机性。前两种是椭球内的方向性密集分布示意，不是真实光子、点源照射或遮挡扫描；实测数据不改。
- 右侧分为Input & support、Accumulation basis、Smoothing scale、Display四小组；独立XY研究分为输入、固定模型、完整扫描三小组。主图下方默认四项读数，位置/峰细节折叠。
- Accumulation basis包括坐标系、保留哪些坐标、维度和格子分辨率；其余坐标被累计掉。半径/角度对按实际半径显示雷达图；仅phi/beta用单位球表示方向，不能恢复距离；phi/Z用参考圆柱。完整XYZ点位保持，以三维格密度着色；点色标覆盖实际点值范围，仍以完整场最大值为dB参考，见色标与图下注。
- 完整球/柱3D在第二图使用几何映射与径向参考线；其余3D密度图保持世界XYZ，避免把米和度直接当笛卡尔轴解释。单个角度的1D边缘密度仍用有单位曲线。
