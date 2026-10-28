(()=>{'use strict';
const $=id=>document.getElementById(id),data=JSON.parse($('initial-payload').textContent).hierarchy;
if(!data)return;
const cfg={responsive:true,displaylogo:false},blue='#246a96',orange='#b64e16';
let scene,frame,field,selected=1;
function opt(el,items,value){el.replaceChildren(...items.map(([v,t])=>{const o=document.createElement('option');o.value=v;o.textContent=t;return o;}));el.value=value;}
opt($('ph-scene'),data.scenes.map((s,i)=>[i,s.name]),0);
function kept(p){return p.parent===0||(p.height>=+$('ph-height').value&&p.metrics.relative_excess>=+$('ph-excess').value);}
function axes(){return{margin:{l:50,r:70,t:15,b:45},xaxis:{title:{text:'X (m)'},range:[-.72,.72]},yaxis:{title:{text:'Y (m)'},range:[-.5,.5],scaleanchor:'x'},paper_bgcolor:'#fff',plot_bgcolor:'#fbfdff',showlegend:false,uirevision:scene.id};}
function loadScene(){scene=data.scenes[+$('ph-scene').value];opt($('ph-sigma'),scene.frames.map((f,i)=>[i,f.sigma.toFixed(3)]),4);loadFrame();}
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
 const fmt=v=>v==null?'—':Number(v).toPrecision(4),rows=field.peaks.map(q=>`<tr><td><button data-peak="${q.id}">P${q.id}</button></td><td>${q.parent||'root'}</td><td>${fmt(q.height)}</td><td>${fmt(q.metrics?.relative_excess)}</td><td>${fmt(q.metrics?.area)}</td><td>${fmt(q.metrics?.mass)}</td><td>${q.raw_support??'—'}</td><td>${kept(q)?'retained':'pruned'}</td></tr>`).join('');
 $('ph-table').innerHTML='<table><thead><tr><th>Peak</th><th>Parent</th><th>Rel. height</th><th>Rel. excess</th><th>Area m²</th><th>Mass</th><th>Returns</th><th>Selection</th></tr></thead><tbody>'+rows+'</tbody></table>';
 $('ph-table').querySelectorAll('button').forEach(b=>b.onclick=()=>choose(+b.dataset.peak));
 const fs=scene.frames.map(f=>f.fields[$('ph-field').value]);
 Plotly.react($('ph-scale'),[{type:'scatter',mode:'lines+markers',name:'All local peaks',x:scene.frames.map(f=>f.sigma),y:fs.map(f=>f.peaks.length),line:{color:blue,dash:'dot'}},{type:'scatter',mode:'lines+markers',name:'Retained modes',x:scene.frames.map(f=>f.sigma),y:fs.map(f=>f.peaks.filter(kept).length),line:{color:orange}}],{margin:{l:50,r:15,t:15,b:65},xaxis:{title:{text:'Bandwidth σ (m)'}},yaxis:{title:{text:'Count'},dtick:1,rangemode:'tozero'},legend:{orientation:'h',y:-.25}},cfg);
 $('ph-height-out').textContent=(100*+$('ph-height').value).toFixed(0)+'%';$('ph-excess-out').textContent=(100*+$('ph-excess').value).toFixed(0)+'%';$('ph-water-out').textContent=(100*water).toFixed(0)+'% of field maximum';
 $('ph-status').textContent=`Julia-computed · ${field.peaks.length} local maxima · ${field.peaks.filter(kept).length} retained modes · generator truth ${scene.truth} target(s), evaluation only · selected P${selected}: ${p?.parent===0?'essential root; finite merge metrics undefined':`merge level ${fmt(p?.death)}, excess mass ${fmt(p?.metrics?.excess)}`} · water contour does not change hierarchy or pruning.`;
 $('ph-status').dataset.ready='true';$('ph-status').dataset.modes=field.peaks.filter(kept).length;
 if(event){const masses=event.branches.map(b=>b.metrics.mass),balance=Math.min(...masses)/Math.max(...masses);$('ph-status').textContent+=` Selected event branch masses: ${masses.map(fmt).join(', ')}; min/max balance ${fmt(balance)}. Root region, when shown, is measured at this event only.`;}
}
function choose(id){selected=id;$('ph-peak').value=id;render();}
$('ph-scene').onchange=loadScene;$('ph-sigma').onchange=loadFrame;$('ph-field').onchange=loadFrame;
for(const id of ['ph-height','ph-excess','ph-water'])$(id).oninput=render;
$('ph-display').onchange=render;$('ph-tree-scale').onchange=render;$('ph-peak').onchange=()=>choose(+$('ph-peak').value);
$('ph-download').onclick=()=>{const blob=new Blob([JSON.stringify({scene:scene.name,sigma:frame.sigma,field:$('ph-field').value,definition:data.normalization,peaks:field.peaks,events:field.events},null,2)],{type:'application/json'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='pg-msp-metrics.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};
loadScene();
for(const id of ['ph-landscape','ph-component','ph-tree'])$(id).on('plotly_click',e=>{const k=e.points?.[0]?.customdata;if(Number.isInteger(k))choose(k);});
})();
