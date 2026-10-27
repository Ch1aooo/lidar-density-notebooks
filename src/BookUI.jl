module BookUI

using Base64

const PROJECT = normpath(joinpath(@__DIR__, ".."))
const CHAPTERS = [
    ("Introduction", "introduction.jl", "Space, time and the research question"),
    ("I · Density representations", "chapter1_density.jl", "From point support to a density field"),
    ("II · Ceiling-mounted LiDAR", "chapter2_lidar.jl", "Sensor geometry and parameters"),
    ("III · Single-person tracking", "chapter3_single_person.jl", "One target across frames"),
    ("IV · Multiple people and robots", "chapter4_multi_target.jl", "Separation and persistent association")
]

escape_html(s) = replace(string(s), '&'=>"&amp;", '<'=>"&lt;", '>'=>"&gt;", '"'=>"&quot;")

function notebook_url(file)
    get(ENV,"JULIA_BOOK_STATIC_EXPORT","false")=="true" && return replace(file,r"\.jl$"=>".html")
    # Percent-encode UTF-8 bytes so local Windows paths and spaces work in Pluto /open.
    encoded = join(c in UInt8.([0x2d,0x2e,0x5f,0x7e]) || UInt8('a') <= c <= UInt8('z') ||
        UInt8('A') <= c <= UInt8('Z') || UInt8('0') <= c <= UInt8('9') ? string(Char(c)) :
        "%" * uppercase(string(c, base=16, pad=2)) for c in codeunits(joinpath(PROJECT, file)))
    return "./open?path=" * encoded
end

function styles()
    # Boundaries follow Pluto's existing cells; no moving or wrapping runtime-owned DOM nodes.
    groups = [["006","007"], ["008","009","00a"], ["00b","00c","012","013","014"],
              ["00d"], ["00e"], ["00f","015"], ["010"]]
    section_css = join(let
        ids = ["pluto-cell[id=\"a8250000-2026-4025-8000-000000000$(id)\"]" for id in group]
        join(ids, ",") * "{border-left:1px solid #c1d6eb;border-right:1px solid #c1d6eb;background:#fbfdff;margin-top:0!important;margin-bottom:0!important;padding-left:16px;padding-right:16px;}" *
        first(ids) * "{border-top:1px solid #c1d6eb;border-radius:14px 14px 0 0;margin-top:24px!important;padding-top:6px;}" *
        last(ids) * "{border-bottom:1px solid #c1d6eb;border-radius:0 0 14px 14px;padding-bottom:12px;}" *
        (length(group) == 1 ? first(ids) * "{border-radius:14px;}" : "")
    end for group in groups)
    HTML("""
    <style>
    $section_css
    main{max-width:1170px!important;margin:0 auto;padding-left:max(22px,3vw)!important;padding-right:max(22px,3vw)!important}
    pluto-output .markdown{font-family:Georgia,"Times New Roman",serif;font-size:17px;line-height:1.62;color:#26312e}
    pluto-output h1,pluto-output h2,pluto-output h3{font-family:Georgia,"Times New Roman",serif!important;color:#1e2924}
    pluto-output h1{font-size:2.05rem!important;font-weight:600!important;letter-spacing:-.02em}
    pluto-output h2{font-size:1.6rem!important;margin-top:.65em!important;border:1px solid #c6dbef;border-radius:10px;background:#eaf2fa;color:#215b89;padding:10px 16px}
    pluto-output h3{font-size:1.15rem!important}
    pluto-output a{color:#215b89;text-underline-offset:3px}
    pluto-output .markdown p,pluto-output .markdown li{max-width:84ch}
    .book-nav{display:flex;flex-wrap:wrap;gap:7px 16px;font:13px/1.5 "Segoe UI",sans-serif;border-bottom:1px solid #dbe4de;padding:10px 0 15px}
    .book-nav a{color:#38678c;text-decoration:none}.book-nav a[aria-current=page]{font-weight:700;color:#194b74}
    .book-note{border-left:3px solid #598db9;border-radius:0 9px 9px 0;background:#edf4fb;padding:13px 18px;margin:16px 0;font:16px/1.6 Georgia,serif}
    .book-note strong{display:block;font:600 12px/1.5 "Segoe UI",sans-serif;letter-spacing:.06em;text-transform:uppercase;color:#215b89;margin-bottom:5px}
    .book-table,pluto-output .markdown table{border-collapse:collapse;width:100%;font:14px/1.5 "Segoe UI",sans-serif;margin:15px 0}.book-table th,.book-table td,pluto-output .markdown th,pluto-output .markdown td{text-align:left;padding:11px 12px;border-bottom:1px solid #d3e0ed;vertical-align:top}.book-table th,pluto-output .markdown th{background:#edf4fb;font-weight:600}.book-table .status{color:#566b7e;font-size:12px}
    .book-footer{display:flex;justify-content:space-between;gap:15px;padding:22px 0;border-top:1px solid #dce5df;font:14px "Segoe UI",sans-serif}
    .book-kicker{font:600 12px/1.4 "Segoe UI",sans-serif;letter-spacing:.12em;text-transform:uppercase;color:#587264}
    .book-viewer{display:block;border:0;width:100%;background:white;margin:8px 0 10px;color-scheme:light}
    .encoding-gallery{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:8px}.encoding-gallery figure{margin:0;border:1px solid #c9dbee;border-radius:9px;background:white;overflow:hidden}.encoding-gallery img{display:block;width:100%;height:auto}.encoding-gallery figcaption{padding:8px 9px;font:12px/1.5 "Segoe UI",sans-serif;color:#23364a}.encoding-gallery b{color:#215b89}.encoding-gallery .cue-label{display:block;font:600 12px "Segoe UI",sans-serif;padding:10px 9px 0;color:#215b89}.encoding-gallery .variables{display:block;font:11px "Segoe UI",sans-serif;color:#536d82;padding:4px 9px 0}
    .book-analogy{border:1px solid #bcd3e9;border-radius:10px;background:#edf4fb;padding:14px 18px;font:16px/1.7 Georgia,serif}.book-analogy .tag{font:600 11px "Segoe UI",sans-serif;letter-spacing:.06em;color:#215b89;text-transform:uppercase}.book-analogy .formula{display:block;margin:8px 0;color:#194b74;font-weight:600}.book-analogy p{margin:7px 0}
    @media(max-width:900px){.encoding-gallery{grid-template-columns:repeat(3,minmax(0,1fr))}}@media(max-width:600px){.encoding-gallery{grid-template-columns:1fr 1fr}}
    @media(max-width:650px){main{padding-left:12px!important;padding-right:12px!important}.book-table td{padding:8px 6px}.book-nav{font-size:12px}}
    </style>
    """)
end

function encoding_gallery()
    figures = [
        ("color_only", "Colour cue", "Figure 3. Height mapped to colour.", "Same geometry, with no lighting modulation."),
        ("shading_only", "Shading cue", "Figure 4. Shape from shading.", "Grey lighting reveals curvature; brightness is not a calibrated height scale."),
        ("height_color", "Combined cues", "Figure 5. Colour and shading.", "Both describe the same surface without adding data dimensions."),
        ("uniform_surface", "Uniform appearance", "Figure 6. Contour remains.", "Same geometry without shading or colour variation; silhouette and perspective remain."),
        ("xy_color", "Flat colour map", "Figure 7. Height on XY.", "Colour retains h without vertical displacement.")
    ]
    cards = join(let
        src = base64encode(read(joinpath(PROJECT,"assets","encoding",file*".png")))
        "<figure><span class=\"cue-label\">$(escape_html(label))</span><span class=\"variables\">3 quantities · x, y, h</span><img src=\"data:image/png;base64,$src\" alt=\"$(escape_html(body))\"><figcaption><b>$(escape_html(title))</b> $(escape_html(body))</figcaption></figure>"
    end for (file,label,title,body) in figures)
    HTML("<div class=\"encoding-gallery\" aria-label=\"Five original height-field comparisons\">$cards</div>")
end

function perception_analogy()
    HTML("""<div class="book-analogy"><div class="tag">Author's analogy · an informal display model</div>
    <span class="formula">2D screen + depth cues ≈ 3D perception</span>
    <span class="formula">3D view + 1 variable explored over viewing time ≈ 4-variable exploration</span>
    <p><b>Working shorthand: 4 ≈ 2 displayed dimensions + 1 inferred depth + 1 sequential variable.</b></p>
    <p>Colour mappings, shading, contours and motion help us read depth on a flat screen <a href="#References">[3, 4]</a>.
    A slider can then explore time or another variable. This is my practical four-variable display convention,
    not a measured maximum of human perception or a formal dimensional identity.</p>
    <p>These analogies motivate the introduction; Part I reserves formal equations for density and MSP.</p></div>""")
end

function navigation(current)
    links = join("<a href=\"$(notebook_url(file))\" $(file == current ? "aria-current=\"page\"" : "")>$(escape_html(label))</a>"
                 for (label, file, _) in CHAPTERS)
    HTML("<nav class=\"book-nav\" aria-label=\"Book chapters\">$links</nav>")
end

function contents()
    rows = join("<tr><td><a href=\"$(notebook_url(file))\">$(escape_html(label))</a></td><td>$(escape_html(question))</td><td class=\"status\">$(i == 1 ? "Introduction ready" : i == 2 ? "Six-step density lab" : "Outline")</td></tr>"
                for (i, (label, file, question)) in enumerate(CHAPTERS))
    HTML("<table class=\"book-table\"><thead><tr><th>Chapter</th><th>Focus</th><th>Current scope</th></tr></thead><tbody>$rows</tbody></table>")
end

function note(title, body)
    HTML("<div class=\"book-note\"><strong>$(escape_html(title))</strong>$(escape_html(body))</div>")
end

function footer(current)
    i=findfirst(c -> c[2] == current, CHAPTERS)
    left=i == 1 ? "<span>Start of the book</span>" : "<a href=\"$(notebook_url(CHAPTERS[i-1][2]))\">← $(escape_html(CHAPTERS[i-1][1]))</a>"
    right=i == length(CHAPTERS) ? "<a href=\"$(notebook_url("introduction.jl"))\">Back to introduction ↑</a>" : "<a href=\"$(notebook_url(CHAPTERS[i+1][2]))\">$(escape_html(CHAPTERS[i+1][1])) →</a>"
    HTML("<nav class=\"book-footer\" aria-label=\"Previous and next chapter\">$left$right</nav>")
end

function viewer_document(kind::Symbol)
    name=kind == :walk ? "walk_viewer" : kind == :field ? "field_viewer" : error("Unknown viewer")
    template=read(joinpath(PROJECT,"assets",name*".html"),String)
    vendor=replace(read(joinpath(PROJECT,"assets","plotly.min.js"),String), "</script"=>"<\\/script")
    js=read(joinpath(PROJECT,"assets",name*".js"),String)
    document=replace(template,"__PLOTLY_SCRIPT__"=>vendor,"__VIEWER_JS__"=>js)
    if kind == :walk
        document=replace(document,"__SEQUENCE_GZIP__"=>base64encode(read(joinpath(PROJECT,"data","measured_walk.json.gz"))))
    end
    sizing="""<script>(()=>{const resize=()=>{if(!window.frameElement)return;const h=Math.ceil(document.body.getBoundingClientRect().height)+4;if(Math.abs(window.frameElement.getBoundingClientRect().height-h)>2)window.frameElement.style.height=h+'px';};new ResizeObserver(resize).observe(document.body);window.addEventListener('load',resize);resize();})();</script>"""
    document=replace(document,"</body>"=>sizing*"</body>")
    return document
end

function viewer(kind::Symbol)
    title=kind == :walk ? "Measured 3D walk and XY localization" : "Illustrative scalar fields"
    height=kind == :walk ? 1030 : 560
    HTML("<iframe class=\"book-viewer\" title=\"$title\" style=\"height:$(height)px\" loading=\"lazy\" srcdoc=\"$(escape_html(viewer_document(kind)))\"></iframe>")
end

function export_viewers(destination)
    mkpath(destination)
    for kind in (:walk,:field)
        write(joinpath(destination, string(kind)*"_explorer.html"),viewer_document(kind))
    end
end

end
