module PartIPage
using Base64, JSON, Markdown, PlutoUI, HypertextLiteral
const ROOT=normpath(joinpath(@__DIR__,".."))
include("BotanicalAnalogy.jl")

function styles()
    HTML("""<style>
    .part1-lab{display:grid;grid-template-columns:minmax(0,1fr) 235px;gap:12px;align-items:start}
    .part1-frame{display:block;width:100%;height:1100px;border:1px solid #c9dbee;border-radius:10px;background:white}
    .part1-controls{border:1px solid #c9dbee;background:#f3f8fd;border-radius:10px;padding:13px 12px;font:13px/1.45 "Segoe UI",sans-serif;color:#23364a}
    .part1-controls h4{font-size:14px;color:#215b89;margin:0 0 10px}.part1-controls h5{font-size:11px;text-transform:uppercase;letter-spacing:.06em;margin:15px 0 8px;color:#496d8c}
    .part1-controls label{display:block;margin:9px 0}.part1-controls input[type=range],.part1-controls select{max-width:100%;width:100%}.part1-controls input[type=number]{width:90px}
    .part1-controls{padding:9px;background:#f8fbfe;font-size:12px}.part1-controls fieldset{min-width:0;border:1px solid #c9dbee;border-radius:8px;background:white;margin:0 0 9px;padding:5px 9px 8px}.part1-controls legend{font-size:11px;font-weight:650;color:#215b89;padding:2px 6px;background:#e5eff8;border-radius:4px}.part1-controls fieldset:first-of-type legend{background:#fff0cb;color:#806121}.part1-controls label{margin:6px 0}.part1-controls .help{line-height:1.35}.part1-controls details{border-top:1px solid #dae5ef;margin-top:6px;padding-top:4px}.part1-controls details summary{font-size:11px;cursor:pointer;color:#496d8c}
    .part1-controls .help{font-size:11px;color:#536d82;margin:5px 0}.part1-lab[data-source=synthetic] .measured-only,.part1-lab[data-source=synthetic] .csv-only,.part1-lab[data-source=measured] .synthetic-only,.part1-lab[data-source=measured] .csv-only,.part1-lab[data-source=csv] .synthetic-only,.part1-lab[data-source=csv] .measured-only{display:none}
    .part1-lab[data-base=xy] .angular-control,.part1-lab[data-base=xz] .angular-control,.part1-lab[data-base=yz] .angular-control,.part1-lab[data-base=rz] .angular-control{display:none}
    .part1-lab .axis-choice,.part1-lab .voxel-only{display:none}.part1-lab[data-family=cartesian][data-dimension="1"] .cart.axes1,.part1-lab[data-family=cartesian][data-dimension="2"] .cart.axes2,.part1-lab[data-family=cylindrical][data-dimension="1"] .cyl.axes1,.part1-lab[data-family=cylindrical][data-dimension="2"] .cyl.axes2,.part1-lab[data-family=spherical][data-dimension="1"] .sphere.axes1,.part1-lab[data-family=spherical][data-dimension="2"] .sphere.axes2{display:block}
    .part1-lab[data-dimension="3"] .voxel-only{display:block}.part1-lab[data-dimension="3"] .grid-counts,.part1-lab[data-dimension="1"] .grid-v{display:none}.part1-lab[data-angles=false] .angular-control,.part1-lab[data-lengths=false] .spatial-control{display:none}
    .part1-analogy{display:grid;grid-template-columns:43% minmax(0,1fr);gap:20px;align-items:start}.part1-analogy figure{margin:0}.part1-analogy img{display:block;width:100%;max-height:640px;object-fit:contain}.part1-analogy figcaption{font:12px/1.5 "Segoe UI",sans-serif;color:#536d82;margin-top:8px}
    .part1-fold{border:1px solid #c9dbee;border-radius:10px;background:#fbfdff;margin:15px 0;padding:12px 17px}.part1-fold summary{color:#215b89;font:600 15px "Segoe UI",sans-serif;cursor:pointer}.part1-fold .derivation{padding-top:12px;overflow-x:auto}.part1-fold .tex{overflow-x:auto}
    pluto-cell[id="a8251000-2026-4025-8000-000000000004"] .markdown>p:nth-last-child(-n+2){background:#fff5dc;border-left:3px solid #d3a449;border-radius:8px;padding:12px 16px}
    @media(max-width:800px){.part1-lab{grid-template-columns:minmax(0,1fr) 205px}.part1-controls{padding:10px;font-size:12px}.part1-analogy{grid-template-columns:1fr 1fr;gap:12px}}
    @media(max-width:620px){.part1-lab{display:flex;flex-direction:column}.part1-controls{order:-1;width:100%}.part1-frame{width:100%}.part1-analogy{display:block}.part1-analogy img{max-height:480px}}
    </style>""")
end

analogy()=@htl("""<iframe id="botanical-analogy" title="Interactive botanical analogy and correspondence table" class="part1-frame" style="height:840px" srcdoc=$(BotanicalAnalogy.document())></iframe>""")

function document(;payload=nothing)
    s=read(joinpath(ROOT,"assets","part1_viewer.html"),String)
    vendor=replace(read(joinpath(ROOT,"assets","plotly.min.js"),String),"</script"=>"<\\/script")
    data=payload===nothing ? "null" : replace(JSON.json(payload),"</"=>"<\\/")
    replace(s,"__PLOTLY_SCRIPT__"=>vendor,"__VIEWER_JS__"=>read(joinpath(ROOT,"assets","part1_viewer.js"),String),"__INITIAL_PAYLOAD__"=>data)
end

function controls()
    doc=document()
    PlutoUI.combine() do Child
        @htl("""<div class="part1-lab" id="part1-lab" data-source="synthetic" data-base="xy" data-family="cartesian" data-dimension="2" data-angles="false" data-lengths="true">
        <iframe id="density-part1-frame" title="Part I six-step density pipeline" class="part1-frame" srcdoc=$(doc)></iframe>
        <aside class="part1-controls"><h4>Build the mountain</h4>
        <fieldset><legend>1 · Input & support</legend><label>Input source $(Child("source",Select(["synthetic"=>"Synthetic ellipsoids","measured"=>"Yiyun · L-walk","csv"=>"Import XYZ CSV"];default="synthetic")))</label>
        <div class="synthetic-only"><label>Ellipsoids $(Child("targets",NumberField(1:6;default=2)))</label>
        <label>Total points $(Child("n",NumberField(100:100:10000;default=1600)))</label>
        <label>Centre separation (m) $(Child("separation",Slider(.1:.05:1.2;default=.7,show_value=true)))</label>
        <label>Random seed $(Child("seed",NumberField(0:100000;default=7)))</label><label>Density pattern $(Child("pattern",Select(["directional"=>"One directional concentration","dual"=>"Two directional concentrations","uniform"=>"Uniform volume reference"];default="directional")))</label><p class="help">Different directions per ellipsoid; seeded random samples. Illustrative volume density, not simulated light returns.</p></div>
        <div class="measured-only"><label>Measured frame $(Child("frame",Slider(1:203;default=97,show_value=true)))</label><p class="help">Yiyun Xu's processed foreground recording [1]. Frame1 stays missing; no verified timestamps.</p></div>
        <div class="csv-only"><label>Local file $(Child("upload",FilePicker([MIME("text/csv")])))</label><label>CSV frame (0 = first) $(Child("csvframe",NumberField(0:100000;default=0)))</label><p class="help">Headers x,y,z in metres; optional frame. Up to100000 finite rows. No silent subsampling.</p></div>
        <label>Selected support $(Child("support",Select(["all"=>"All input returns","head"=>"Head band · Z 1.4–1.6 m"];default="all")))</label>
        </fieldset><fieldset><legend>2 · Accumulation basis</legend><label>Coordinate family $(Child("family",Select(["cartesian"=>"Cartesian · X / Y / Z","cylindrical"=>"Cylindrical · rho / phi / Z","spherical"=>"Spherical · R / phi / beta"];default="cartesian")))</label>
        <label>Retained dimensions $(Child("dimensions",Select([1=>"1D · one coordinate",2=>"2D · a coordinate pair",3=>"3D · all three coordinates"];default=2)))</label>
        <div class="axis-choice cart axes1"><label>Cartesian 1D $(Child("cart1",Select(["x"=>"X","y"=>"Y","z"=>"Z"];default="x")))</label></div>
        <div class="axis-choice cart axes2"><label>Cartesian 2D $(Child("cart2",Select(["xy"=>"XY","xz"=>"XZ","yz"=>"YZ"];default="xy")))</label></div>
        <div class="axis-choice cyl axes1"><label>Cylindrical 1D $(Child("cyl1",Select(["crho"=>"rho","cphi"=>"phi","cz"=>"Z"];default="crho")))</label></div>
        <div class="axis-choice cyl axes2"><label>Cylindrical 2D $(Child("cyl2",Select(["cyl"=>"rho / phi","rz"=>"rho / Z","cphiz"=>"phi / Z"];default="cyl")))</label></div>
        <div class="axis-choice sphere axes1"><label>Spherical 1D $(Child("sphere1",Select(["sr"=>"R","sphi"=>"phi","sbeta"=>"beta"];default="sr")))</label></div>
        <div class="axis-choice sphere axes2"><label>Spherical 2D $(Child("sphere2",Select(["srphi"=>"R / phi","srbeta"=>"R / beta","sphere"=>"phi / beta"];default="sphere")))</label></div>
        <div class="grid-counts"><label>Grid U cells $(Child("nu",Select([24,40,64,96];default=64)))</label><label class="grid-v">Grid V cells $(Child("nv",Select([24,40,64,96];default=64)))</label></div>
        <div class="voxel-only"><label>3D cells per axis $(Child("voxel_n",Select([16,24,32,40];default=24)))</label><p class="help">Original XYZ positions stay fixed. Colour encodes density in the containing 3D cell.</p></div>
        <p class="help">Choose coordinates → retained dimensions → cell resolution. Discarded coordinates accumulate into the retained cells.</p></fieldset><fieldset><legend>3 · Smoothing scale</legend><label class="spatial-control">Spatial bandwidth σ (cm) $(Child("sigma_cm",Slider(0:.5:40;default=7.5,show_value=true)))</label>
        <label class="angular-control">Angular bandwidth σ (°) $(Child("angle_sigma",Slider(0:.5:20;default=3.,show_value=true)))</label>
        <p class="help">Physical bandwidth stays fixed as the grid changes. The actual σ in cells is reported beside the plots.</p>
        </fieldset><fieldset><legend>4 · Display</legend><label>Density display $(Child("display",Select(["dB"=>"Relative density · dB","linear"=>"Linear density"];default="dB")))</label>
        <p class="help">dB =10log10(ρ/ρmax), floor−50dB. Linear peak values remain visible.</p>
        </fieldset></aside></div>""")
    end
end

function study_document(;payload=nothing)
    s=read(joinpath(ROOT,"assets","bandwidth_viewer.html"),String)
    vendor=replace(read(joinpath(ROOT,"assets","plotly.min.js"),String),"</script"=>"<\\/script")
    data=payload===nothing ? "null" : replace(JSON.json(payload),"</"=>"<\\/")
    replace(s,"__PLOTLY_SCRIPT__"=>vendor,"__OPTIMIZER_JS__"=>read(joinpath(ROOT,"assets","peak_optimizer.js"),String),"__VIEWER_JS__"=>read(joinpath(ROOT,"assets","bandwidth_viewer.js"),String),"__INITIAL_PAYLOAD__"=>data)
end

function study_controls()
    share=get(ENV,"JULIA_BOOK_STATIC_EXPORT","false")=="true"
    PlutoUI.combine() do Child
        @htl("""<div class="part1-lab" id="bandwidth-lab" data-source="measured">
        <iframe id="bandwidth-frame" title="Independent complete bandwidth trajectory and centroid distance" class="part1-frame" style="height:800px" srcdoc=$(study_document())></iframe>
        <aside class="part1-controls"><h4>Independent XY study</h4>
        <fieldset><legend>1 · Study input</legend><label>Study input $(Child("source",Select(["measured"=>"Yiyun · L-walk","synthetic"=>"Synthetic ellipsoids","csv"=>"Import XYZ CSV"];default=share ? "synthetic" : "measured")))</label>
        <div class="measured-only"><label>Study frame $(Child("frame",NumberField(1:203;default=97)))</label></div>
        <div class="synthetic-only"><label>Study ellipsoids $(Child("targets",NumberField(1:6;default=share ? 3 : 2)))</label><label>Study points $(Child("n",Select([400,800,1600];default=share ? 400 : 800)))</label><label>Study separation (m) $(Child("separation",NumberField(.1:.05:1.2;default=.7)))</label><label>Study seed $(Child("seed",NumberField(0:100000;default=7)))</label></div>
        <div class="csv-only"><label>Study CSV $(Child("upload",FilePicker([MIME("text/csv")])))</label><label>Study CSV frame $(Child("csvframe",NumberField(0:100000;default=0)))</label></div>
        <label>Study support $(Child("support",Select(["all"=>"All input returns","head"=>"Head band · 1.4–1.6 m"];default="all")))</label>
        </fieldset><fieldset><legend>2 · Fixed XY model</legend><label>Support model $(Child("model",Select(["raw"=>"Original points · no binning","binned"=>"Weighted bin centres"];default="raw")))</label>
        <label>Bin side Δ (cm) $(Child("delta_cm",Select([.5,1.,2.,5.];default=1.)))</label>
        <p class="help">Model stays fixed along the curve.</p></fieldset><fieldset><legend>3 · Complete σ sweep</legend><label>Minimum σ (cm) $(Child("min_cm",Select([.01,.03,.1];default=.03)))</label><label>Maximum σ (cm) $(Child("max_cm",Select([100.,1000.];default=1000.)))</label><label>Sweep samples $(Child("samples",Select([96,160,240];default=share ? 96 : 160)))</label>
        <label>Branch anchor σ (cm) $(Child("branch_anchor_cm",Select([.5,1.,2.,3.,5.,7.5,10.,15.];default=7.5)))</label>
        <p class="help">Anchor applies to Bandwidth paths. Fixed-σ Newton ascent uses the σ selected inside the plot; its right axis shows iteration. Small σ can reveal extra peaks within one object; large σ can merge objects. Independent of the six panels.</p><details><summary>Model details</summary><p class="help">Full-space XY Gaussian, no reflected edges or output-grid argmax. Bin counts remain weights. All selected points contribute; limit10000. Generator labels are evaluation-only; peak count is not a person count.</p></details>
        </fieldset></aside></div>""")
    end
end

function study_update(payload)
    data=replace(JSON.json(payload),"</"=>"<\\/")
    HTML("""<script>const frame=document.getElementById('bandwidth-frame');if(frame){frame.__payload=$data;document.getElementById('bandwidth-lab').dataset.source=frame.__payload.source_type||'measured';const send=()=>frame.contentWindow?.postMessage({type:'bandwidth_update',payload:frame.__payload},window.location.origin);frame.onload=send;send();}</script>""")
end

function update(payload)
    json=replace(JSON.json(payload),"</"=>"<\\/")
    HTML("""<script>
    const frame=document.getElementById('density-part1-frame');
    if(frame){frame.__part1Payload=$json;const lab=document.getElementById('part1-lab');
      lab.dataset.source=frame.__part1Payload.source_type||'synthetic';lab.dataset.base=frame.__part1Payload.base||'xy';
      lab.dataset.family=frame.__part1Payload.family||'cartesian';lab.dataset.dimension=frame.__part1Payload.dimension||2;
      lab.dataset.angles=String(!!frame.__part1Payload.has_angles);lab.dataset.lengths=String(frame.__part1Payload.has_lengths!==false);
      const send=()=>frame.contentWindow?.postMessage({type:'density_part1_update',payload:frame.__part1Payload},window.location.origin);
      frame.onload=send;send();}
    </script>""")
end

function derivation(which)
    source=read(joinpath(ROOT,"PART1_EQUATIONS.md"),String)
    key=which==:construction ? "CONSTRUCTION" : which==:dimensions ? "DIMENSIONS" : "CENTROID"
    body=split(split(source,"<!-- BEGIN $key -->")[2],"<!-- END $key -->")[1]
    title=which==:construction ? "Expand derivation · counts, measures, bandwidth and dB (1.1–1.10)" : which==:dimensions ? "Expand dimensional details · 1D marginals and 3D density colour (1.21–1.22)" : "Expand derivation · Gaussian modes, centroid limit and separation (1.11–1.19)"
    html=repr(MIME"text/html"(),Markdown.parse(body))
    HTML("<details class=\"part1-fold\"><summary>$title</summary><div class=\"derivation\">$html</div></details>")
end

end
