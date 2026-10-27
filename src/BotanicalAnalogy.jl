module BotanicalAnalogy

# Native vector geometry authored in Julia. These are explanatory marks, not measured data.
function svg()
    leaf(cx,cy,rx,ry)=join("<ellipse cx='$(cx+rx*cos(t))' cy='$(cy+ry*sin(t))' rx='$(rx*.48)' ry='$(ry*.48)'/>" for t in range(0,2pi;length=9)[1:8])
    tree(cx,cy,rx,ry)=leaf(cx,cy,rx,ry)*"<ellipse cx='$cx' cy='$cy' rx='$(rx*.68)' ry='$(ry*.68)'/><path d='M $cx $(cy+ry*.35) L $cx 423' fill='none' stroke-width='6'/>"
    dots=join("<circle cx='$(168+5i+3sin(j))' cy='$(258+6j)' r='1.6' fill='#246195' stroke='none'/>" for i in 0:7 for j in 0:5 if (i-3.5)^2/16+(j-2.5)^2/9<1)
    moss=join("<path d='M $(70+21i) $(452+7sin(i)) q 7 -12 14 0 q 7 -10 13 0' fill='none'/>" for i in 0:12)
    rays=join("<path d='M 245 75 L $x $y'/>" for (x,y) in [(100,290),(185,265),(240,310),(315,320),(390,370)])
    """<svg viewBox="0 0 500 560" role="img" aria-label="Digital botanical analogy: one elevated source, straight rays, three plants, visible and hidden surfaces, floor, moss and shadows. Table rows reveal corresponding concepts.">
    <defs><linearGradient id="canopy" x2=".8" y2="1"><stop stop-color="#edf4fb"/><stop offset="1" stop-color="#75a7cd"/></linearGradient><pattern id="hatch" width="7" height="7" patternUnits="userSpaceOnUse"><path d="M0 7L7 0" stroke="#386e97" stroke-width="1"/></pattern></defs>
    <g class="feature" data-features="floor" stroke="#386e97" fill="#edf4fb" stroke-width="2"><path d="M35 412 L291 367 L478 452 L210 521 Z"/><path d="M80 423L339 383M127 446L388 406M175 471L434 429M87 402L270 500M156 390L336 484M225 378L407 467" fill="none" stroke-width=".7"/></g>
    <g class="feature source-feature" data-features="source rays viewpoint" stroke="#c38e2c" fill="#f8ce72" stroke-width="2"><circle cx="245" cy="60" r="23"/>$(join("<path d='M $(245+31cos(t)) $(60+31sin(t)) L $(245+41cos(t)) $(60+41sin(t))'/>" for t in range(0,2pi;length=13)[1:12]))</g>
    <g class="feature source-feature" data-features="rays viewpoint" stroke="#d6a446" stroke-width="1.6" stroke-dasharray="6 5" fill="none">$rays<path d="M210 117A68 68 0 0 0 279 118"/><text x="281" y="140" fill="#936a21" stroke="none" font-size="14">R, φ, β</text></g>
    <g class="feature source-feature" data-features="photons square" fill="#e4af41" stroke="#a8771b" stroke-width=".7"><circle cx="224" cy="125" r="3"/><circle cx="207" cy="176" r="3"/><circle cx="190" cy="226" r="3"/></g>
    <g class="feature" data-features="shadow" fill="#647e96" stroke="#54748e"><path d="M168 390L207 388L300 467L246 481Z"/><path d="M300 411L339 410L414 453L365 470Z"/></g>
    <g class="feature" data-features="targets multiple self mutual density cluster" fill="url(#canopy)" stroke="#215b89" stroke-width="2">$(tree(180,285,51,61))$(tree(312,342,39,43))$(tree(375,389,24,26))</g>
    <g class="feature" data-features="self" fill="url(#hatch)" stroke="#215b89" stroke-width="1.5"><path d="M198 290Q244 304 219 344Q201 358 184 347Q204 321 198 290Z"/></g>
    <g class="feature" data-features="mutual" fill="url(#hatch)" stroke="#215b89"><path d="M298 357Q326 356 336 373L327 395Q296 391 288 373Z"/></g>
    <g class="feature" data-features="visible density summit" fill="#a5c9e3" stroke="#215b89" stroke-width="1.8"><path d="M143 276Q143 235 184 227Q211 237 218 264Q185 253 168 281Z"/>$dots</g>
    <g class="feature" data-features="summit density" stroke="#215b89" fill="#215b89"><circle cx="184" cy="257" r="6"/><path d="M174 257H194M184 247V267" stroke-width="1.5"/></g>
    <g class="feature" data-features="background" stroke="#4c7896" stroke-width="2">$moss</g>
    <g class="feature" data-features="cluster multiple" fill="none" stroke="#246195" stroke-width="2" stroke-dasharray="5 4"><ellipse cx="181" cy="295" rx="79" ry="94"/><ellipse cx="341" cy="367" rx="85" ry="73"/></g>
    <g class="feature" data-features="merging" fill="none" stroke="#c17a24" stroke-width="2.5"><path d="M328 362L339 370L350 378"/><circle cx="328" cy="362" r="3"/><circle cx="339" cy="370" r="3"/><circle cx="350" cy="378" r="3"/><ellipse cx="341" cy="367" rx="87" ry="75" stroke-dasharray="5 4"/></g>
    <g id="callout" visibility="hidden" pointer-events="none"><path id="leader" stroke="#5886a8" stroke-width="1.2" fill="none"/><g id="label-box"><rect width="220" height="53" rx="9" fill="#fff" stroke="#a9c4db"/><text id="analogy-name" x="12" y="21" fill="#215b89" font-size="15" font-weight="600"/><text id="target-name" x="12" y="41" fill="#496b86" font-size="12"/></g></g>
    </svg>"""
end

const ROWS=[
    ("source","source","Sun above the plants","Ceiling LiDAR above the room",245,60,267,100),
    ("rays","source","Direct rays from one source","Range and angular directions",260,155,267,150),
    ("photons","source","Photons reaching plant surfaces","Return-point samples on visible surfaces",207,176,20,120),
    ("square","source","Light intensity I ∝ |E-field|²","Defined density score Eρ = ρ² [8]",224,125,260,175),
    ("viewpoint","source","One illumination viewpoint","One current sensor viewpoint",245,75,20,115),
    ("targets","observed","Trees and shrubs","People / robots as targets",180,280,23,168),
    ("floor","observed","Ground plane","Indoor floor",370,460,250,490),
    ("visible","observed","Sun-facing foliage","Visible surface returns",169,250,22,177),
    ("self","observed","Leaves hide their own far side","Self-occlusion [6]",207,325,260,245),
    ("mutual","observed","One plant hides another","External / mutual occlusion [6]",310,371,25,340),
    ("background","observed","Moss and low ground cover","Background to remove",180,452,25,482),
    ("shadow","observed","Shadow behind a plant","Unobserved background region",281,459,260,490),
    ("density","derived","Uneven illumination on foliage","Uneven observed point density",182,268,260,178),
    ("summit","derived","Brightest local patch","Density summit · local MSP",184,257,20,181),
    ("multiple","derived","Several plants / bright regions","Several candidate targets",343,358,260,238),
    ("cluster","derived","Connected well-lit regions","Density-connected groups · DBSCAN [7]",335,378,20,338),
    ("merging","derived","Nearby lit regions become connected","DBSCAN may merge nearby targets [7]",339,370,20,340)
]

function document()
    table=IOBuffer();options=IOBuffer();lastgroup=""
    for (i,r) in enumerate(ROWS)
        key,group,a,b,x,y,lx,ly=r
        if group!=lastgroup
            title=group=="source" ? "1 · Source" : group=="observed" ? "2 · Observed scene" : "3 · Derived interpretation"
            print(table,"<tr class='group $group'><th colspan='2'>$title</th></tr>");lastgroup=group
        end
        print(table,"<tr tabindex='0' class='concept $group' data-key='$key' data-a='$a' data-b='$b' data-x='$x' data-y='$y' data-lx='$lx' data-ly='$ly'><td>$a</td><td>$b</td></tr>")
        print(options,"<option value='$key'>$i · $a</option>")
    end
    """<!doctype html><html lang="en"><meta charset="utf-8"><style>
    *{box-sizing:border-box}body{margin:0;color:#23364a;font:13px/1.4 'Segoe UI',sans-serif}.explorer{display:grid;grid-template-columns:44% minmax(0,1fr);gap:14px;align-items:start}.drawing{position:sticky;top:8px;margin:0;border:1px solid #c1d6eb;border-radius:12px;background:#fbfdff;padding:8px}.drawing svg{display:block;width:100%;height:auto}.feature{opacity:.23;transition:opacity .16s}.feature.lit{opacity:1}.feature.lit.source-feature{filter:drop-shadow(0 0 5px #efce83)}figcaption{font-size:11px;color:#536d82;padding:0 7px 7px}.table-wrap{border:1px solid #c1d6eb;border-radius:12px;overflow:hidden}table{border-collapse:collapse;width:100%;font-size:12px}th,td{text-align:left;padding:8px 10px;border-bottom:1px solid #d6e3ef;vertical-align:top}thead th{font-size:12px;color:#215b89;background:#edf4fb}.group th{font-size:10px;text-transform:uppercase;letter-spacing:.06em;background:#e3eef8;color:#215b89}.source{background:#fff5dc}.source th{background:#f9e6b7;color:#785716}.concept:not(.source){background:#f5f9fd}.concept:hover,.concept:focus,.concept.active{outline:none;box-shadow:inset 3px 0 #5188b1;background:#e2eef9}.concept.source:hover,.concept.source:focus,.concept.source.active{background:#fae7b7;box-shadow:inset 3px 0 #bb8a31}.concept{cursor:default}.guide{font-size:11px;color:#536d82;margin:0 0 8px}select{font-size:11px;max-width:100%;color:#385c79;padding:4px;border:1px solid #c1d6eb;border-radius:5px;background:white}footer{font:11px/1.5 'Segoe UI',sans-serif;color:#536d82;margin-top:10px}a{color:#215b89}@media(max-width:650px){.explorer{grid-template-columns:1fr}.drawing{position:static}.drawing svg{max-height:400px}td{padding:7px}}
    </style><div class="explorer"><figure class="drawing">$(svg())<figcaption><b>Figure 1.1.</b> A botanical analogy, drawn with Julia SVG geometry. Hover or focus a table row; dimmed features remain in context.</figcaption></figure><div><p class="guide">Simple → composite concepts. Hover / focus a row, or pin one: <select id="focus-concept" aria-label="Pin an analogy concept"><option value="">No pinned concept</option>$(String(take!(options)))</select></p><div class="table-wrap"><table><thead><tr><th>Analogy</th><th>Point-cloud context</th></tr></thead><tbody>$(String(take!(table)))</tbody></table></div></div></div>
    <footer><b>Particles and samples.</b> Photon arrivals ↔ return points is a sampling analogy, not a one-photon/one-point correspondence. A return point is a range estimate from a detected optical return.<br>
    <b>Parallel square forms [8].</b> Optical intensity I = ½cε₀|E-field|² (W/m²); our defined score Eρ = ρ² has squared density units (e.g. points²/m⁴ for XY). These are different quantities. One photon has energy hν; photon counts are not squared to obtain optical energy. This analogy does not change the density calculations or dB convention.<br>
    <b>Clustering limitation [7].</b> If nearby targets are joined by a chain of core-point neighbourhoods at the chosen ε and MinPts, DBSCAN can return one cluster. Two connected lit regions therefore need not represent one target. Proximity alone does not guarantee merging; reducing ε can also fragment sparse targets. This motivates testing separation and temporal association; it does not prove a density-peak method avoids merging.<br>
    Single-view, opaque-surface sketch. Sunlight is approximately parallel; scanner directions are described from its local spherical origin. Finite angular resolution, range, incidence and visibility shape return density; brightness and LiDAR intensity are not a calibrated density measurement. A shadow is missing observation, not evidence that background has been removed. DBSCAN does not simply count peaks or require two LiDARs. Self-occlusion is an established term; [6] explains it, rather than originating the concept.</footer>
    <script>
    const rows=[...document.querySelectorAll('.concept')],features=[...document.querySelectorAll('.feature')],pin=document.querySelector('#focus-concept');
    function highlight(key){const row=rows.find(r=>r.dataset.key===key);document.body.dataset.active=key||'none';for(const r of rows)r.classList.toggle('active',r===row);for(const g of features)g.classList.toggle('lit',(g.dataset.features||'').split(' ').includes(key));const call=document.querySelector('#callout');call.setAttribute('visibility',row?'visible':'hidden');if(!row)return;let d=row.dataset;document.querySelector('#analogy-name').textContent=d.a.split(' [')[0];document.querySelector('#target-name').textContent=d.b.split(' [')[0];for(const id of ['analogy-name','target-name']){const text=document.getElementById(id);text.removeAttribute('textLength');if(text.getComputedTextLength()>196){text.setAttribute('textLength','196');text.setAttribute('lengthAdjust','spacingAndGlyphs');}}document.querySelector('#label-box').setAttribute('transform','translate('+d.lx+','+d.ly+')');document.querySelector('#leader').setAttribute('d','M '+(+d.lx+110)+' '+(+d.ly+53)+' L '+d.x+' '+d.y);}
    for(const row of rows){row.addEventListener('pointerenter',()=>highlight(row.dataset.key));row.addEventListener('pointerleave',()=>highlight(pin.value));row.addEventListener('focus',()=>highlight(row.dataset.key));row.addEventListener('blur',()=>highlight(pin.value));row.addEventListener('click',()=>{pin.value=row.dataset.key;highlight(pin.value);});}
    pin.addEventListener('change',()=>highlight(pin.value));new ResizeObserver(()=>{if(window.frameElement)window.frameElement.style.height=Math.ceil(document.body.getBoundingClientRect().height+2)+'px';}).observe(document.body);highlight('');
    </script></html>"""
end
end
