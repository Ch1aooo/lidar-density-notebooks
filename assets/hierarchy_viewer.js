(()=>{'use strict';
const $=id=>document.getElementById(id),data=JSON.parse($('initial-payload').textContent).hierarchy;
if(!data)return;
const cfg={responsive:true,displaylogo:false},blue='#246a96',orange='#b64e16';
let scene,frame,field,selected=1;
let metricKey='height';
const metricDefs={
 peak:['Peak','Local maximum','Position of a local maximum; an ID within this bandwidth, not a person ID.','—'],
 parent:['Parent','Elder representative','At a merge, the higher-born peak remains the representative. See the set-valued nodes in C.','—'],
 height:['Rel. height','(h − s) / h','A = peak height above saddle; B = peak height above zero. Ratio A/B measures vertical prominence.','dimensionless'],
 excess:['Rel. excess','X / N̂','A = density integral above the saddle floor; B = full density integral over the same region R. Ratio A/B measures excess contribution.','dimensionless'],
 share:['Mass share','q = N̂branch / Σ N̂siblings','A = selected branch integral; B = sum of all sibling integrals immediately above the same merge saddle. Small support is a local-detail hypothesis, not proof of attachment.','dimensionless'],
 area:['Area','Aᵣ = ∫R 1 dA','Footprint of the branch strictly above its own saddle. The section below represents a 2D footprint schematically.','m²'],
 mass:['Est. returns','N̂ = ∫R ρ dA','Unit-integral kernels turn this integral into smoothed return count. It is generally fractional.','returns'],
 raw:['Raw returns','N = # {original returns mapped into R}','Direct count of original measurements in the same region; no density integration.','returns'],
 difference:['Δ returns','N̂ − N','Signed discrepancy of smoothed integral and direct count. Not a localization or person-count accuracy score.','returns'],
 selection:['Selection','Selected candidate rule','Guarded: mass share AND height AND excess pass. Size-only uses share. Original uses fixed 20% height and 10% excess. Root is always retained. Rejection is not an anatomical classification.','retained / pruned']
};
function explainMetric(key){
 metricKey=key;const d=metricDefs[key],hot='#b64e16',cool='#dce8f2',h=['height','selection'].includes(key),e=['excess','selection'].includes(key),m=['mass','difference'].includes(key),r=['raw','difference'].includes(key),a=key==='area';
 const curve='M60 130 C85 130 95 50 150 50 C205 50 215 130 240 130';
 $('ph-explain').innerHTML=`<strong>${d[0]} · ${d[1]}</strong><svg viewBox="0 0 400 235" style="width:100%;max-height:230px" role="img" aria-label="Schematic density cross-section: peak h, saddle s, branch footprint R, density integral and raw returns. Not measured data.">
 <path d="${curve} L240 190 L60 190 Z" fill="${m?'#efc7a9':cool}" stroke="none"/>
 <path d="${curve} Z" fill="${e?hot:'#b7cfdf'}" opacity=".8"/>
 <path d="${curve}" fill="none" stroke="#246a96" stroke-width="3"/>
 <path d="M35 190 H265 M35 190 V25" stroke="#536879" fill="none"/>
 <path d="M40 130 H265" stroke="#536879" stroke-dasharray="5 4"/>
 <text x="12" y="25" font-size="12">ρ</text><text x="20" y="194" font-size="12">0</text><text x="267" y="134" font-size="12">s</text>
 <circle cx="150" cy="50" r="5" fill="${key==='peak'?hot:'#246a96'}"/><text x="160" y="43" font-size="12">h · peak</text>
 <g style="display:${h?'inline':'none'}"><path d="M285 50 V130 M280 50 H290 M280 130 H290" stroke="${h?hot:'#96a8b6'}" stroke-width="3"/><text x="294" y="88" font-size="12">A = h−s</text>
 <path d="M365 50 V190 M360 50 H370 M360 190 H370" stroke="${h?hot:'#96a8b6'}" stroke-width="2"/><text x="320" y="180" font-size="12">B = h</text></g>
 <path d="M60 206 H240 M60 201 V211 M240 201 V211" stroke="${a?hot:'#536879'}" stroke-width="3"/><text x="104" y="227" font-size="12">Region R · XY footprint</text>
 ${[75,95,120,143,163,184,217].map(x=>`<circle cx="${x}" cy="181" r="3" fill="${r?hot:'#727e87'}"/>`).join('')}
 <text x="99" y="108" font-size="12" fill="${e?'#fff':'#173f60'}">${key==='excess'?'A = X':'X: above s'}</text><text x="72" y="155" font-size="12">${key==='excess'?'B = N̂ (all shading)':'N̂: entire shaded region'}</text></svg><p style="margin:4px 0">${d[2]} Unit: ${d[3]}. Illustration only.</p>`;
 if(key==='parent'){$('ph-explain').querySelector('svg').innerHTML='<path d="M100 40 V130 H200 M300 70 V130 H200 V190" fill="none" stroke="#246a96" stroke-width="3"/><circle cx="200" cy="130" r="6" fill="#b64e16"/><text x="68" y="30">P1 · higher</text><text x="265" y="60">P2</text><text x="150" y="155">{P1, P2}</text><text x="70" y="218">P2 Parent = P1 (representative)</text>';}
 if(key==='share'){const p=field.peaks.find(p=>p.id===selected),q=p?.mass_share;
  $('ph-explain').querySelector('svg').innerHTML=q==null?'<text x="35" y="100">Root: no finite merge-share metric.</text>':`<text x="25" y="45">Same saddle · disjoint sibling regions</text><rect x="25" y="75" width="350" height="50" fill="#dce8f2"/><rect x="25" y="75" width="${350*q}" height="50" fill="#b64e16"/><text x="25" y="150">A = selected: ${p.metrics.mass.toFixed(2)} returns</text><text x="25" y="177">B = all siblings: ${p.event_mass.toFixed(2)} returns</text><text x="25" y="210">A / B = ${(100*q).toFixed(1)}%</text>`;
 }
 $('ph-table').querySelectorAll('[data-metric]').forEach(b=>{b.style.color=b.dataset.metric===key?hot:'#215b89';b.setAttribute('aria-pressed',b.dataset.metric===key?'true':'false');});
}
$('ph-formulas').innerHTML=Object.values(metricDefs).map(d=>`<p><strong>${d[0]}</strong>: ${d[1]} [${d[3]}]. ${d[2]}</p>`).join('');
function opt(el,items,value){el.replaceChildren(...items.map(([v,t])=>{const o=document.createElement('option');o.value=v;o.textContent=t;return o;}));el.value=value;}
opt($('ph-scene'),data.scenes.map((s,i)=>[i,s.name]),0);
function baseline(p){return p.parent===0||(p.height>=.2&&p.metrics.relative_excess>=.1);}
function kept(p){if(p.parent===0)return true;const rule=$('ph-rule').value;if(rule==='old')return baseline(p);return p.mass_share>=+$('ph-share').value&&(rule==='size'||(p.height>=+$('ph-height').value&&p.metrics.relative_excess>=+$('ph-excess').value));}
function axes(){return{margin:{l:50,r:70,t:15,b:45},xaxis:{title:{text:'X (m)'},range:[-.72,.72]},yaxis:{title:{text:'Y (m)'},range:[-.5,.5],scaleanchor:'x'},paper_bgcolor:'#fff',plot_bgcolor:'#fbfdff',showlegend:false,uirevision:scene.id};}
function loadScene(){scene=data.scenes[+$('ph-scene').value];const attached=['two_arm','large_attachment'].includes(scene.id);opt($('ph-sigma'),scene.frames.map((f,i)=>[i,f.sigma.toFixed(3)]),attached?0:scene.frames.findIndex(f=>f.sigma===.115));selected=attached?3:1;loadFrame();}
function loadFrame(){frame=scene.frames[+$('ph-sigma').value];field=frame.fields[$('ph-field').value];selected=Math.min(selected,field.peaks.length)||1;opt($('ph-peak'),field.peaks.map(p=>[p.id,'P'+p.id+(p.parent===0?' · root':'')]),selected);render();}
// Reconstruct component nodes from Julia merge events, without changing topology.
function componentTree(peaks,events){
 const nodes=peaks.map(p=>({members:[p.id],level:p.birth,children:[],peak:p.id})),active=new Map(nodes.map(n=>[n.peak,n]));
 for(const e of [...events].sort((a,b)=>b.level-a.level)){
  const children=e.branches.map(b=>active.get(b.peak)).filter(Boolean);
  if(children.length<2)continue;
  const n={members:children.flatMap(c=>c.members).sort((a,b)=>a-b),level:e.level,children};
  children.forEach(c=>{c.parent=n;});e.branches.forEach(b=>active.delete(b.peak));active.set(e.survivor,n);nodes.push(n);
 }
 let column=0;
 function place(n){n.children.sort((a,b)=>a.members[0]-b.members[0]);n.children.forEach(place);n.x=n.children.length?n.children.reduce((s,c)=>s+c.x*c.members.length,0)/n.members.length:column++;}
 const roots=[...active.values()];roots.forEach(place);return{nodes,roots};
}
function drawTree(max,water,energy){
 const {nodes,roots}=componentTree(field.peaks,field.events),log=$('ph-tree-scale').value==='db';
 const positive=nodes.map(n=>n.level/max).filter(v=>v>0),floor=Math.min(-10,10*Math.log10(Math.min(...positive,water))-5);
 const y=v=>log?(v>0?10*Math.log10(v/max):floor):v/max,low=log?floor:0,high=log?4:1.12;
 const traces=[];
 for(const n of nodes){if(!n.parent)continue;traces.push({type:'scatter',mode:'lines',x:[n.x,n.x,n.parent.x],y:[y(n.level),y(n.parent.level),y(n.parent.level)],line:{color:n.members.includes(selected)?orange:blue,width:n.members.includes(selected)?3:2},hoverinfo:'skip'});}
 for(const r of roots)traces.push({type:'scatter',mode:'lines',x:[r.x,r.x],y:[y(r.level),low],line:{color:blue,dash:'dot',width:2},hoverinfo:'skip'});
 const label=n=>n.peak?'P'+n.peak:'{'+n.members.map(id=>'P'+id).join(', ')+'}';
 for(const leaf of [true,false]){const ns=nodes.filter(n=>Boolean(n.peak)===leaf);traces.push({type:'scatter',mode:'markers+text',x:ns.map(n=>n.x),y:ns.map(n=>y(n.level)),text:ns.map(label),textposition:leaf?'top center':'bottom center',customdata:ns.map(n=>n.peak??null),hovertext:ns.map(n=>`${label(n)}<br>${leaf?'Peak':'Merge saddle'}: ${n.level.toPrecision(4)}<br>${(100*n.level/max).toPrecision(4)}% of maximum`),hovertemplate:'%{hovertext}<extra></extra>',marker:{size:leaf?10:9,symbol:leaf?'diamond':'circle',color:ns.map(n=>n.members.includes(selected)?orange:blue)}});}
 const cut=nodes.filter(n=>n.level>=water*max&&(!n.parent||n.parent.level<water*max));
 Plotly.react($('ph-tree'),traces,{margin:{l:65,r:35,t:25,b:60},xaxis:{range:[-.7,field.peaks.length-.3],visible:false},yaxis:{title:{text:log?'Water level · dB relative to maximum':energy?'Water level · E/Emax':'Water level · ρ/ρmax'},range:[low,high]},shapes:[{type:'line',xref:'paper',x0:0,x1:1,y0:y(water*max),y1:y(water*max),line:{color:'#743923',dash:'dash',width:2}}],showlegend:false},cfg);
 $('ph-tree-note').textContent=`At ${(water*100).toFixed(0)}% water level: ${cut.length} connected component(s), before pruning. Read downward: peaks → merge saddles → shared component. Horizontal placement is layout only; dotted root continues below the displayed range.`;
}
function render(){
 $('ph-scene-guide').textContent=scene.id==='weak_person'?'Failure control: these are TWO independent targets with a 4:1 return imbalance. A mass-share gate can reject the weak target as a small branch. Lower the share threshold to inspect the tradeoff; small return support alone does not imply attachment.':['two_arm','large_attachment'].includes(scene.id)?'Attached-contribution control: the generator regards both body supports plus the attached contribution as TWO target systems. Compare 24 vs 60 attached returns at unchanged geometry. Mass share may reject the small contribution but retain the large one; that is an ambiguity, not proof of an extra person.':'Fixed source: changing σ or thresholds does not regenerate points. Compare original and mass-share rules in E. The 4:1 target case tests whether a weak person is wrongly rejected.';
 $('ph-share-out').textContent=(100*+$('ph-share').value).toFixed(0)+'%';$('ph-share').disabled=$('ph-rule').value==='old';for(const id of ['ph-height','ph-excess'])$(id).disabled=$('ph-rule').value!=='guarded';
 const energy=$('ph-field').value==='energy',db=$('ph-display').value==='db',linear=frame.rho.map(r=>r.map(v=>energy?v*v:v)),max=Math.max(...linear.flat()),water=+$('ph-water').value;
 const z=linear.map(r=>r.map(v=>db?Math.max(-40,10*Math.log10(Math.max(v/max,1e-300))):v/max));
 const heat={type:'heatmap',x:scene.x,y:scene.y,z,colorscale:'Blues',zmin:db?-40:0,zmax:db?0:1,colorbar:{title:{text:db?'dB':energy?'E/Emax':'ρ/ρmax'},thickness:12}};
 const points={type:'scatter',mode:'markers',x:scene.points.map(p=>p[0]),y:scene.points.map(p=>p[1]),marker:{color:'#666',size:3,opacity:.35},hoverinfo:'skip'};
 const peaks={type:'scatter',mode:'markers+text',x:field.peaks.map(p=>p.x),y:field.peaks.map(p=>p.y),text:field.peaks.map(p=>'P'+p.id),customdata:field.peaks.map(p=>p.id),textposition:'top center',marker:{color:field.peaks.map(p=>kept(p)?orange:'#777'),symbol:field.peaks.map(p=>kept(p)?'diamond':'circle-open'),size:field.peaks.map(p=>p.id===selected?14:9)},hovertemplate:'%{text}<br>X %{x:.3f} m<br>Y %{y:.3f} m<extra></extra>'};
 const contour={type:'contour',x:scene.x,y:scene.y,z:linear.map(r=>r.map(v=>v/max)),contours:{start:water,end:water,size:.001,coloring:'none'},line:{color:'#743923',width:2},showscale:false,hoverinfo:'skip'};
 Plotly.react($('ph-landscape'),[heat,points,contour,peaks],axes(),cfg);
 const p=field.peaks.find(p=>p.id===selected),event=field.events.find(e=>(p.parent===0||e.level===p.death)&&e.branches.some(b=>b.peak===selected)),eventBranch=event?.branches.find(b=>b.peak===selected),cells=p?.metrics?.cells||eventBranch?.metrics.cells||[],mask=new Set(cells),ny=scene.y.length;
 const region=linear.map((r,j)=>r.map((_,i)=>mask.has(j+1+i*ny)?1:null));
 const saddleIndex=event?.saddle_cells?.[0],saddleTrace={type:'scatter',mode:'markers+text',x:saddleIndex?[scene.x[Math.floor((saddleIndex-1)/ny)]]:[],y:saddleIndex?[scene.y[(saddleIndex-1)%ny]]:[],text:['merge'],textposition:'bottom center',marker:{symbol:'x',size:12,color:'#222'},hovertemplate:'Discrete merge-level cell<extra></extra>'};
 Plotly.react($('ph-component'),[{...heat,opacity:.35},{type:'heatmap',x:scene.x,y:scene.y,z:region,colorscale:[[0,'#e0a056'],[1,'#b95719']],showscale:false,opacity:.65},points,peaks,saddleTrace],axes(),cfg);
 drawTree(max,water,energy);
 const fmt=v=>v==null?'—':Number(v).toPrecision(4),rows=field.peaks.map(q=>`<tr><td><button data-peak="${q.id}">P${q.id}</button></td><td>${q.parent||'root'}</td><td>${fmt(q.height)}</td><td>${fmt(q.metrics?.relative_excess)}</td><td>${q.mass_share==null?'—':(100*q.mass_share).toFixed(1)+'%'}</td><td>${fmt(q.metrics?.area)}</td><td>${fmt(q.metrics?.mass)}</td><td>${q.raw_support??'—'}</td><td>${q.metrics?fmt(q.metrics.mass-q.raw_support):'—'}</td><td>${kept(q)?'retained':'pruned'}</td></tr>`).join('');
 $('ph-table').innerHTML='<table><thead><tr>'+Object.entries(metricDefs).map(([k,d])=>`<th><button data-metric="${k}" style="border:0;background:transparent;font:inherit;font-weight:600;padding:0;cursor:help">${d[0]}</button></th>`).join('')+'</tr></thead><tbody>'+rows+'</tbody></table>';
 $('ph-table').querySelectorAll('[data-peak]').forEach(b=>b.onclick=()=>choose(+b.dataset.peak));
 $('ph-table').querySelectorAll('[data-metric]').forEach(b=>{b.onmouseenter=b.onfocus=b.onclick=()=>explainMetric(b.dataset.metric);});explainMetric(metricKey);
 $('ph-count-check').textContent=`Whole displayed grid: integrated density ${fmt(frame.domain_count)} returns; source ${frame.source_count} returns; difference ${fmt(frame.domain_count-frame.source_count)}. Gaussian tails outside the window are not renormalised.`;
 const fs=scene.frames.map(f=>f.fields[$('ph-field').value]);
 const sigmas=scene.frames.map(f=>f.sigma),counts=fs.map(f=>f.peaks.filter(kept).length),oldCounts=fs.map(f=>f.peaks.filter(baseline).length);
 Plotly.react($('ph-scale'),[{type:'scatter',mode:'lines+markers',name:'All peaks',x:sigmas,y:fs.map(f=>f.peaks.length),line:{color:'#8a99a6',dash:'dot'}},{type:'scatter',mode:'lines+markers',name:'Original shape rule',x:sigmas,y:oldCounts,line:{color:blue,dash:'dash'},marker:{symbol:'square-open'}},{type:'scatter',mode:'lines+markers',name:'Selected rule',x:sigmas,y:counts,line:{color:orange},marker:{symbol:'diamond'}},{type:'scatter',mode:'lines',name:'Generator count (evaluation)',x:[sigmas[0],sigmas.at(-1)],y:[scene.truth,scene.truth],line:{color:'#16806d',dash:'dot'}}],{margin:{l:50,r:15,t:15,b:100},xaxis:{title:{text:'Bandwidth σ (m)'}},yaxis:{title:{text:'Count'},dtick:1,rangemode:'tozero'},legend:{orientation:'h',y:-.25},shapes:[{type:'line',x0:frame.sigma,x1:frame.sigma,yref:'paper',y0:0,y1:1,line:{color:'#777',dash:'dot'}}]},cfg);
 function runs(counts){const spans=[];let start=null;for(let i=0;i<=counts.length;i++){if(i<counts.length&&counts[i]===scene.truth){if(start===null)start=i;}else if(start!==null){spans.push(start===i-1?sigmas[start].toFixed(3):sigmas[start].toFixed(3)+'–'+sigmas[i-1].toFixed(3));start=null;}}return spans.join(', ')||'none';}
 $('ph-scale-note').textContent=`Sampled count-match runs (m): original ${runs(oldCounts)}; selected ${runs(counts)}. ${field.peaks.length<scene.truth?'At this σ, too few peaks exist: no pruning threshold can recover the missing targets.':''}`;
 $('ph-height-out').textContent=(100*+$('ph-height').value).toFixed(0)+'%';$('ph-excess-out').textContent=(100*+$('ph-excess').value).toFixed(0)+'%';$('ph-water-out').textContent=(100*water).toFixed(0)+'% of field maximum';
 $('ph-status').textContent=`Julia-computed · ${field.peaks.length} local maxima · ${field.peaks.filter(kept).length} retained modes · generator truth ${scene.truth} target(s), evaluation only · selected P${selected}: ${p?.parent===0?'essential root; finite merge metrics undefined':`merge level ${fmt(p?.death)}, excess mass ${fmt(p?.metrics?.excess)}`} · water contour does not change hierarchy or pruning.`;
 $('ph-status').dataset.ready='true';$('ph-status').dataset.modes=field.peaks.filter(kept).length;
 if(event){const masses=event.branches.map(b=>b.metrics.mass),balance=Math.min(...masses)/Math.max(...masses);$('ph-status').textContent+=` Selected event branch masses: ${masses.map(fmt).join(', ')}; min/max balance ${fmt(balance)}. Root region, when shown, is measured at this event only.`;}
}
function choose(id){selected=id;$('ph-peak').value=id;render();}
$('ph-scene').onchange=loadScene;$('ph-sigma').onchange=loadFrame;$('ph-field').onchange=loadFrame;
for(const id of ['ph-height','ph-excess','ph-water','ph-share'])$(id).oninput=render;
$('ph-rule').onchange=render;
$('ph-display').onchange=render;$('ph-tree-scale').onchange=render;$('ph-peak').onchange=()=>choose(+$('ph-peak').value);
$('ph-download').onclick=()=>{const blob=new Blob([JSON.stringify({scene:scene.name,sigma:frame.sigma,field:$('ph-field').value,definition:data.normalization,selection:{rule:$('ph-rule').value,share:+$('ph-share').value,height:+$('ph-height').value,excess:+$('ph-excess').value,original:{height:.2,excess:.1}},peaks:field.peaks,events:field.events},null,2)],{type:'application/json'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='pg-msp-metrics.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};
loadScene();
for(const id of ['ph-landscape','ph-component','ph-tree'])$(id).on('plotly_click',e=>{const k=e.points?.[0]?.customdata;if(Number.isInteger(k))choose(k);});
})();
