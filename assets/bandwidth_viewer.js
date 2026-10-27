/* Julia supplies scale branches/support; the fixed-sigma view uses analytic Newton ascent. */
const graphXY=document.getElementById('locus'),graphE=document.getElementById('distance');
const range=document.getElementById('sigma-index'),choice=document.getElementById('sigma-choice');
const palette=[[0,'#a7cce6'],[.5,'#4a8bb8'],[1,'#153f67']];
const branchColors=['#b44238','#0a877d','#9656a6','#bc7817','#5078bd','#a04e78'];
let branches=[],fieldCache=new Map(),optimizerCache=new Map(),scaleView=null,currentView="scale";
const config={responsive:true,displaylogo:false,scrollZoom:false};let payload=null,study=null,initialized=false,pending=null,running=false,revision=0;
const fmt=(x,d=3)=>Number.isFinite(x)?Number(x).toLocaleString('en',{maximumFractionDigits:d}):'unverified';
const axis=t=>({title:{text:t,font:{size:11}},tickfont:{size:9},gridcolor:'#dce7f0',zeroline:false,automargin:true});
const base=(extra={})=>({margin:{l:52,r:14,t:14,b:46},showlegend:false,paper_bgcolor:'white',plot_bgcolor:'white',font:{family:'Segoe UI, sans-serif',size:10,color:'#23364a'},...extra});
function resize(){if(window.frameElement)window.frameElement.style.height=Math.ceil(document.body.getBoundingClientRect().height+2)+'px';}
function segmented(s){let x=[],y=[],sig=[],e=[];for(let i=0;i<s.sigma_cm.length;i++){if(s.break_before[i]||!s.xy[i]){x.push(null);y.push(null);sig.push(null);e.push(null);}if(s.xy[i]){x.push(s.xy[i][0]);y.push(s.xy[i][1]);sig.push(s.sigma_cm[i]);e.push(s.error_mm[i]);}}return {x,y,sig,e};}
function densityField(index){if(fieldCache.has(index))return fieldCache.get(index);const q=study.kernel_support,w=study.kernel_weights;if(!q)return {x:[],y:[],z:[]};
 const nx=76,ny=64,limits=q.map(v=>{let lo=Math.min(...v),hi=Math.max(...v),pad=Math.max(.08,(hi-lo)*.12);return [lo-pad,hi+pad];}),x=Array.from({length:nx},(_,i)=>limits[0][0]+(limits[0][1]-limits[0][0])*i/(nx-1)),y=Array.from({length:ny},(_,i)=>limits[1][0]+(limits[1][1]-limits[1][0])*i/(ny-1)),s=study.sigma_cm[index]/100,den=2*s*s,ref=study.logvalues[index],z=y.map(()=>Array(nx).fill(0));
 // Exact same weighted Gaussian support as the search; separable kernel evaluation,
 // no point sampling or extra smoothing. Raster resolution affects display only.
 for(let n=0;n<w.length;n++){const gx=x.map(v=>Math.exp(-((v-q[0][n])**2)/den)),gy=y.map(v=>Math.exp(-((v-q[1][n])**2)/den)),a=w[n]*Math.exp(-ref);for(let j=0;j<ny;j++)for(let i=0;i<nx;i++)z[j][i]+=a*gx[i]*gy[j];}
 for(let j=0;j<ny;j++)for(let i=0;i<nx;i++)z[j][i]=Math.max(-40,Math.min(0,10*Math.log10(Math.max(z[j][i],1e-4))));
 const result={x,y,z};if(fieldCache.size>=4)fieldCache.delete(fieldCache.keys().next().value);fieldCache.set(index,result);return result;}
function switchControls(optimize){document.getElementById('distance-axis-control').style.display=optimize?'none':'';document.getElementById('optimization-metric-control').style.display=optimize?'':'none';document.getElementById('sweep-diagnostics').style.display=optimize?'none':'';}
async function ensureScaleView(){
 switchControls(false);if(currentView==='scale')return;
 await Plotly.react(graphXY,structuredClone(scaleView.xyData),structuredClone(scaleView.lx),config);await Plotly.react(graphE,structuredClone(scaleView.eData),structuredClone(scaleView.le),config);await Plotly.restyle(graphXY,{visible:document.getElementById('field-toggle').checked},[0,1]);await Plotly.restyle(graphXY,{visible:document.getElementById('cloud-toggle').checked},[2]);currentView='scale';
 for(const [id,value] of Object.entries(scaleView.notes))document.getElementById(id).innerHTML=value;
 document.getElementById('locus-title').textContent='Global & local mode loci · XY';document.getElementById('locus-caption').textContent='Figure 1.3a · Complete bandwidth paths over the selected field.';
 document.getElementById('distance-title').textContent='Distances to pooled / object references';document.getElementById('distance-caption').textContent='Figure 1.3b · Horizontal axis is σ, not optimizer iteration.';
}
async function showOptimization(i){
 switchControls(true);const s=study,sigma=s.sigma_cm[i]/100,field=densityField(i),metric=document.getElementById('optimization-metric').value,refs=s.references||[];
 let result=optimizerCache.get(i);if(!result){result=s.kernel_support?PeakOptimizer.discover(s.kernel_support,s.kernel_weights,sigma,field):{peaks:[],failed:0,candidate_count:0,capped:false};if(optimizerCache.size>=4)optimizerCache.delete(optimizerCache.keys().next().value);optimizerCache.set(i,result);}
 const data=structuredClone(scaleView.xyData.slice(0,3)),distance=[],key=[];data[0].x=data[1].x=field.x;data[0].y=data[1].y=field.y;data[0].z=data[1].z=field.z;
 data[0].visible=data[1].visible=document.getElementById('field-toggle').checked;data[0].colorbar.y=.5;data[0].colorbar.len=.8;data[2].visible=document.getElementById('cloud-toggle').checked;
 for(let k=0;k<result.peaks.length;k++){
  const peak=result.peaks[k],color=branchColors[k%branchColors.length],nearest=refs.length?refs.reduce((best,r)=>Math.hypot(r.xy[0]-peak.point[0],r.xy[1]-peak.point[1])<Math.hypot(best.xy[0]-peak.point[0],best.xy[1]-peak.point[1])?r:best):null;
  const name='N'+(k+1),endpoint=peak.path.at(-1),errors=metric==='gradient'?peak.residuals:metric==='centroid'?peak.path.map(q=>nearest?1000*Math.hypot(q[0]-nearest.xy[0],q[1]-nearest.xy[1]):null):peak.path.map(q=>1000*Math.hypot(q[0]-endpoint[0],q[1]-endpoint[1]));
  data.push({type:'scatter',mode:'lines+markers',x:peak.path.map(q=>q[0]),y:peak.path.map(q=>q[1]),line:{color,width:2},marker:{size:3,color},name,hovertemplate:name+' ascent<br>%{x:.5f}, %{y:.5f}<extra></extra>'},
   {type:'scatter',mode:'markers+text',x:[endpoint[0]],y:[endpoint[1]],text:[name],textposition:'bottom center',textfont:{color,size:10},marker:{symbol:'diamond',size:8,color},hoverinfo:'skip'},
   {type:'scatter',mode:'markers',x:[peak.path[0][0]],y:[peak.path[0][1]],marker:{symbol:'circle-open',size:7,color},hovertemplate:name+' start<extra></extra>'});
  distance.push({type:'scatter',mode:'lines+markers',x:errors.map((_,j)=>j),y:errors,line:{color,width:2},marker:{color,size:4},name,hovertemplate:name+'<br>iteration %{x}<br>%{y:.6g}<extra></extra>'});
  key.push('<span style="color:'+color+';margin-right:16px">━ '+name+(nearest?' · reference μ'+nearest.object_id:'')+'</span>');
 }
 data.push(structuredClone(scaleView.xyData.at(-1)));
 const lx=structuredClone(scaleView.lx);lx.margin={l:48,r:85,t:20,b:48};lx.uirevision=scaleView.lx.uirevision+'newton';
 const ytitle=metric==='gradient'?'σ ‖∇ log ρ‖':metric==='centroid'?'Distance to object centroid (mm)':'Distance to final verified peak (mm)';
 const le=base({uirevision:scaleView.le.uirevision+'newton'+metric,xaxis:{...axis('Newton iteration'),dtick:1},yaxis:axis(ytitle)});
 await Plotly.react(graphXY,data,lx,config);await Plotly.react(graphE,distance,le,config);currentView='optimize';
 document.getElementById('locus-title').textContent='Local peak ascent · fixed σ';document.getElementById('locus-caption').textContent='Figure 1.3a · ○ Start → ◇ verified local peak; colours label solutions.';
 document.getElementById('distance-title').textContent=metric==='centroid'?'Localization comparison with object centroids':'Convergence of local peak searches';
 document.getElementById('distance-caption').textContent=metric==='endpoint'?'Figure 1.3b · Distance to the computed terminal peak; not centroid error.':metric==='gradient'?'Figure 1.3b · Stationarity residual; negative Hessian also checked.':'Figure 1.3b · Reference labels are evaluation-only; nonzero terminal error is allowed.';
 document.getElementById('branch-key').innerHTML=key.join('');
 document.getElementById('selection').textContent=`Fixed σ = ${fmt(s.sigma_cm[i],5)} cm · ${result.peaks.length} verified local peaks · safeguarded Newton ascent · ${result.capped?'search cap reached; count may be incomplete':'candidate count is not a person-ID estimate'}`;
 document.getElementById('field-note').textContent='The background and its derivatives use the same complete Gaussian support. σ stays fixed during each ascent; changing σ rebuilds the field and searches. Tiny σ may be unresolved by the 76×64 candidate raster; large σ may merge peaks. No curves are forced to decrease.';
 document.getElementById('reference-note').textContent=metric==='endpoint'?'Zero means arrival at that optimizer’s final verified local peak, not recovery of the object centroid. Use “Distance to object centroid” to inspect localization bias.':metric==='centroid'?(refs.length?'Each terminal peak is matched to its nearest labelled observed centroid only for evaluation; labels do not enter derivatives, starts or updates. A terminal peak need not equal that centroid.':'No object-labelled centroid is available for this input; no object-error curves are invented.'):'The scaled gradient must be small and the log-density Hessian negative definite. A small gradient alone could also indicate a saddle; those endpoints are rejected.';
 document.getElementById('branches-note').textContent=`Coarse density maxima generate starts shifted outward by 0.8σ, independent of generator IDs. Each ascent uses the analytic log-density gradient/Hessian, a modified positive-definite Newton system, a σ step cap and Armijo backtracking; no call to the existing Mean Shift routine. ${result.failed} starts did not verify a maximum. Duplicate endpoints are combined within 0.1 mm. Search is capped at six distinct peaks, not an exhaustive maximum/person count.`;
 document.getElementById('plot-legend').textContent='○ Open small circle: density-derived start · coloured line: optimizer steps · ◇ labelled diamond: verified local maximum · μ open circle: synthetic observed-centroid reference. N labels belong only to this selected σ, not temporal identities.';
 Object.assign(document.body.dataset,{selectedIndex:String(i),sigma:String(s.sigma_cm[i]),view:'optimize',optimizerPeaks:String(result.peaks.length),metric});resize();
}
async function selectSample(index){if(!study)return;const i=Math.max(0,Math.min(index,study.sigma_cm.length-1)),q=study.xy[i],mu=study.centroid;range.value=i;choice.value=i;
if(document.getElementById('view-mode').value==='optimize'){await showOptimization(i);return;}
await ensureScaleView();
const field=densityField(i);await Plotly.restyle(graphXY,{x:[field.x,field.x],y:[field.y,field.y],z:[field.z,field.z]},[0,1]);
await Plotly.restyle(graphXY,{x:[q?[q[0]]:[],q?[q[0],mu[0]]:[]],y:[q?[q[1]]:[],q?[q[1],mu[1]]:[]]},[8,9]);
await Plotly.restyle(graphE,{x:[[study.sigma_cm[i]]],y:[[study.error_mm[i]]]},[3]);
for(let b=0;b<branches.length;b++){let pt=branches[b].xy[i];await Plotly.restyle(graphXY,{x:[pt?[pt[0]]:[]],y:[pt?[pt[1]]:[]]},[11+2*b]);await Plotly.restyle(graphE,{x:[pt&&branches[b].error_mm?.[i]!=null?[study.sigma_cm[i]]:[]],y:[pt&&branches[b].error_mm?.[i]!=null?[branches[b].error_mm[i]]:[]]},[5+2*b]);}
document.getElementById('field-note').textContent=`Background: Gaussian density at σ = ${fmt(study.sigma_cm[i],5)} cm; 10log₁₀(ρ / best verified peak), −40…0 dB; contours every 5 dB. Reference peak = ${fmt(Math.exp(study.logvalues?.[i]||0)/(2*Math.PI*(study.sigma_cm[i]/100)**2),3)} points/m². The raster is 76×64 and may miss very narrow peaks; it is not used for mode search. ${branches.filter(b=>b.xy[i]).length} active anchor branches at this sample.`;
document.getElementById('selection').textContent=`σ = ${fmt(study.sigma_cm[i],5)} cm · e = ${fmt(study.error_mm[i],5)} mm · ${study.ties[i]>1?'numerically tied modes':q?'verified local maximum':'no verified maximum'} · ${study.model==='raw'?'original points':`weighted bins, Δ = ${study.delta_cm} cm`}`;
Object.assign(document.body.dataset,{selectedIndex:String(i),sigma:String(study.sigma_cm[i]),distance:String(study.error_mm[i]),view:'scale'});}
async function render(p){payload=p;document.getElementById('error').style.display=p.empty?'block':'none';document.getElementById('content').style.display=p.empty?'none':'';if(p.empty){document.getElementById('status').textContent='Independent XY study';document.getElementById('error').textContent=p.message;document.body.dataset.ready='empty';resize();return;}
study=p.study;fieldCache.clear();optimizerCache.clear();currentView="scale";branches=study.branches?.items||[];const s=study,valid=s.xy.map((q,i)=>q?i:-1).filter(i=>i>=0),line=segmented(s),suspect=valid.filter(i=>s.break_before[i]||s.ties[i]>1);let jx=[],jy=[];
for(let i=1;i<s.xy.length;i++)if(s.break_before[i]&&s.xy[i]&&s.xy[i-1]){jx.push(s.sigma_cm[i-1],s.sigma_cm[i],null);jy.push(s.error_mm[i-1],s.error_mm[i],null);}
document.getElementById('status').textContent=`${p.source} · ${s.points} points · ${s.samples} σ samples · ${s.model==='raw'?'no input binning':`Δ = ${s.delta_cm} cm, ${s.support_sites} weighted sites`}`;
const centroid={type:'scatter',mode:'markers',x:[s.centroid[0]],y:[s.centroid[1]],marker:{symbol:'x',color:'#d37825',size:10,line:{width:2}},name:'Raw centroid'};
const fieldVisible=document.getElementById('field-toggle').checked;
const xyData=[{type:'heatmap',x:[],y:[],z:[],zmin:-40,zmax:0,visible:fieldVisible,colorscale:[[0,'#ffffff'],[.35,'#e1f0ef'],[.7,'#8ac6c4'],[1,'#368e94']],colorbar:{title:{text:'Density (dB)',side:'top'},x:1.02,y:.77,len:.4,thickness:8,tickfont:{size:8}},hovertemplate:'Density %{z:.2f} dB<extra></extra>'},
{type:'contour',x:[],y:[],z:[],visible:fieldVisible,showscale:false,contours:{start:-35,end:-5,size:5,coloring:'none'},line:{color:'#559399',width:.6},hoverinfo:'skip'},
{type:'scatter',mode:'markers',x:s.cloud[0],y:s.cloud[1],visible:document.getElementById('cloud-toggle').checked,marker:{size:2,color:'#9cb6c9',opacity:.3},hoverinfo:'skip'},
{type:'scatter',mode:'lines',x:line.x,y:line.y,line:{color:'#538fb8',width:1.7},connectgaps:false,hoverinfo:'skip'},
{type:'scatter',mode:'markers',x:valid.map(i=>s.xy[i][0]),y:valid.map(i=>s.xy[i][1]),text:valid.map(i=>`σ = ${fmt(s.sigma_cm[i],5)} cm; ${s.ties[i]} tied candidate(s)`),hovertemplate:'%{text}<extra></extra>',marker:{size:4,color:valid.map(i=>Math.log10(s.sigma_cm[i])),colorscale:palette,showscale:true,colorbar:{title:{text:'log₁₀ σ (cm)',side:'top'},x:1.02,y:.23,len:.4,thickness:8,tickfont:{size:8}}}},
{type:'scatter',mode:'markers',x:suspect.map(i=>s.xy[i][0]),y:suspect.map(i=>s.xy[i][1]),marker:{symbol:'cross-open',size:7,color:'#a7623d'},hoverinfo:'skip'},centroid,
{...centroid,x:s.model==='binned'?[s.model_centroid[0]]:[],y:s.model==='binned'?[s.model_centroid[1]]:[],marker:{symbol:'circle-open',color:'#d37825',size:8}},
{type:'scatter',mode:'markers',x:[],y:[],marker:{symbol:'diamond',color:'#215b89',size:8,line:{color:'white',width:1}},name:'Selected mode'},
{type:'scatter',mode:'lines',x:[],y:[],line:{color:'#6f92ac',dash:'dot',width:1},hoverinfo:'skip'}];
const eData=[{type:'scatter',mode:'lines',x:line.sig,y:line.e,line:{color:'#286d9e',width:1.7},connectgaps:false},
{type:'scatter',mode:'markers',x:valid.map(i=>s.sigma_cm[i]),y:valid.map(i=>s.error_mm[i]),marker:{size:3,color:valid.map(i=>Math.log10(s.sigma_cm[i])),colorscale:palette}},
{type:'scatter',mode:'lines+markers',x:jx,y:jy,line:{color:'#a7623d',dash:'dot',width:1},marker:{size:4,symbol:'cross'},connectgaps:false},
{type:'scatter',mode:'markers',x:[],y:[],marker:{size:8,symbol:'diamond',color:'#215b89',line:{color:'white',width:1}}}];
for(let b=0;b<branches.length;b++){const branch=branches[b],color=branchColors[b%branchColors.length],text=`Branch ${branch.id}${branch.reference_id!=null?' · eval reference '+branch.reference_id:''}`;xyData.push({type:'scatter',mode:'lines',x:branch.xy.map(q=>q?.[0]??null),y:branch.xy.map(q=>q?.[1]??null),line:{color,width:2},connectgaps:false,name:text,hovertemplate:text+'<extra></extra>'},{type:'scatter',mode:'markers',x:[],y:[],marker:{color,size:8,symbol:'diamond'},name:text});eData.push({type:'scatter',mode:'lines',x:s.sigma_cm,y:branch.error_mm||[],line:{color,width:1.5},connectgaps:false,name:text,hovertemplate:text+'<br>%{y:.3f} mm<extra></extra>'},{type:'scatter',mode:'markers',x:[],y:[],marker:{color,size:7,symbol:'diamond'}});}
document.getElementById('branch-key').innerHTML=branches.map((b,i)=>'<span style="color:'+branchColors[i%branchColors.length]+';margin-right:16px">━ B'+b.id+(b.reference_id!=null?' → μ'+b.reference_id:'')+'</span>').join('');
const refs=s.references||[];xyData.push({type:'scatter',mode:'markers+text',x:refs.map(r=>r.xy[0]),y:refs.map(r=>r.xy[1]),text:refs.map(r=>'μ'+r.object_id),textposition:'top center',textfont:{color:'#6e4e34',size:10},marker:{symbol:'circle-open',color:'#6e4e34',size:10,line:{width:2}},name:'Oracle-labelled observed centroids'});
const viewKey=JSON.stringify([p.source,p.support,s.model,s.delta_cm,s.samples]);const lx=base({margin:{l:48,r:85,t:20,b:48},uirevision:viewKey,xaxis:axis('X (m)'),yaxis:{...axis('Y (m)'),scaleanchor:'x',scaleratio:1}}),le=base({uirevision:viewKey,xaxis:{...axis('Gaussian σ (cm) · log scale'),type:'log',tickvals:[.01,.03,.1,.3,1,3,10,100,1000],showgrid:false},yaxis:{...axis('Distance to reference (mm)'),showgrid:false},shapes:[.1,10].map(x=>({type:'line',xref:'x',yref:'paper',x0:x,x1:x,y0:0,y1:1,line:{color:'#bccfdf',width:1},layer:'below'}))});
scaleView={xyData:structuredClone(xyData),eData:structuredClone(eData),lx:structuredClone(lx),le:structuredClone(le)};
if(!initialized){await Plotly.newPlot(graphXY,xyData,lx,config);await Plotly.newPlot(graphE,eData,le,config);initialized=true;}else{await Plotly.react(graphXY,xyData,lx,config);await Plotly.react(graphE,eData,le,config);}
range.max=s.sigma_cm.length-1;choice.replaceChildren(...s.sigma_cm.map((sigma,i)=>{const o=document.createElement('option');o.value=i;o.textContent=fmt(sigma,5)+' cm';return o;}));
const selected=s.sigma_cm.reduce((best,x,i)=>Math.abs(Math.log(x/7.5))<Math.abs(Math.log(s.sigma_cm[best]/7.5))?i:best,0);
document.getElementById('settled').textContent=s.settled_cm===null?'No settled terminal segment found with this sampling and search policy.':`No further flagged steps after approximately σ = ${fmt(s.settled_cm,4)} cm in this sweep. This observed threshold depends on the data, σ sampling and search; it is not a universal onset of continuity.`;
const rows=s.intervals.map(v=>{const tr=document.createElement('tr');for(const text of[`${fmt(v.lo_cm,4)}–${fmt(v.hi_cm,4)}`,fmt(v.jump_mm,3),`${v.reason}; ${v.count} flagged intervals`]){const td=document.createElement('td');td.textContent=text;tr.append(td);}return tr;});
if(!rows.length){let tr=document.createElement('tr');let td=document.createElement('td');td.colSpan=3;td.textContent='No flagged intervals in this sampled sweep.';tr.append(td);rows.push(tr);}document.getElementById('jump-table').replaceChildren(...rows);
document.getElementById('policy').textContent=`Showing ${Math.min(6,s.interval_count)} of ${s.interval_count} grouped suspect ranges (up to six largest steps). A flag means a numerical tie, failed verification, or a step greater than max(5 mm, 0.35 × previous σ in mm). It is an exploratory diagnostic, not a proof of a discontinuity. ${s.search}`;
document.getElementById('model-note').textContent=`The reference stays the original-point centroid. Model-centroid offset = ${fmt(s.bin_shift_mm,6)} mm. Original points are used directly, or replaced by world-origin square-bin centres with their full counts as weights. No output-grid sampling; no reflected boundary. Changing the six-panel controls does not recompute this study.`;
document.getElementById('branches-note').textContent=s.branches?`Local branches anchored at σ ≈ ${fmt(s.branches.anchor_cm,3)} cm: ${s.branches.policy} ${branches.map(b=>'B'+b.id+': '+b.events.map(e=>fmt(s.sigma_cm[e.index-1],3)+' cm '+e.reason).join('; ')).join(' | ')}`:'No branch payload; reload the Julia source.';
document.getElementById('reference-note').textContent=refs.length?`${refs.length} synthetic object references: observed-point centroids computed with generator labels, not geometric body centres. Labels never enter peak search. Branch distance uses its nearest object centroid at the anchor, fixed afterwards; several branches may match one object. Blue global-candidate distance uses the pooled centroid. Missing objects and merged modes are not filled in.`:'No object-labelled references for measured/CSV input; blue distance remains relative to the pooled raw centroid.';
scaleView.notes=Object.fromEntries(['branch-key','reference-note','branches-note','plot-legend'].map(id=>[id,document.getElementById(id).innerHTML]));
// Refresh both captions even when a new payload arrives in the same view.
currentView='pending';await selectSample(selected);
Object.assign(document.body.dataset,{ready:'true',revision:String(++revision),samples:String(s.samples),source:p.source,model:s.model,points:String(s.points),intervals:String(s.interval_count)});document.getElementById('sigma-view').value='full';resize();}
let selecting=false,requestedSample=null;async function requestSample(i){requestedSample=i;if(selecting)return;selecting=true;try{while(requestedSample!==null){const next=requestedSample;requestedSample=null;await selectSample(next);}}finally{selecting=false;}}
range.addEventListener('input',()=>requestSample(Number(range.value)));choice.addEventListener('change',()=>requestSample(Number(choice.value)));
document.getElementById('view-mode').addEventListener('change',()=>requestSample(Number(range.value)));
document.getElementById('optimization-metric').addEventListener('change',()=>requestSample(Number(range.value)));
document.getElementById('cloud-toggle').addEventListener('change',e=>{if(initialized)Plotly.restyle(graphXY,{visible:e.target.checked},[2]);});
document.getElementById('field-toggle').addEventListener('change',e=>{if(initialized)Plotly.restyle(graphXY,{visible:e.target.checked},[0,1]);});
document.getElementById('sigma-view').addEventListener('change',e=>{if(study&&currentView==='scale')Plotly.relayout(graphE,{'xaxis.range':e.target.value==='small'?[Math.log10(study.sigma_cm[0]),0]:[Math.log10(study.sigma_cm.at(-1))]});});
async function drain(){if(running)return;running=true;while(pending){const p=pending;pending=null;try{await render(p);}catch(e){document.getElementById('status').textContent='Viewer error: '+e.message;document.body.dataset.error=e.message;}}running=false;}
window.addEventListener('message',e=>{if(e.source!==window.parent||e.origin!==window.parent.location.origin)return;if(e.data?.type==='bandwidth_update'){pending=e.data.payload;drain();}});
new ResizeObserver(()=>{resize();if(initialized){Plotly.Plots.resize(graphXY);Plotly.Plots.resize(graphE);}}).observe(document.body);
if(window.INITIAL_PAYLOAD){pending=window.INITIAL_PAYLOAD;drain();}
