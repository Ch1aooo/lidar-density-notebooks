(async () => {
  const $ = id => document.getElementById(id);
  try {
    const bytes=Uint8Array.from(atob($('sequence').textContent.trim()),c=>c.charCodeAt(0));
    const stream=new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'));
    const {frames}=JSON.parse(await new Response(stream).text());
    const blue='#39738f',ink='#215b89',orange='#ba5a15',violet='#76528d';
    const config={responsive:true,displaylogo:false,scrollZoom:true,toImageButtonOptions:{format:'png',scale:2}};
    const defaultCamera=()=>({eye:{x:1.55,y:-1.8,z:1.05},up:{x:0,y:0,z:1},
      center:{x:0,y:0,z:0},projection:{type:'perspective'}});
    const cameras={xyz:defaultCamera(),xyt:defaultCamera()};
    const good=p=>p&&p.every(Number.isFinite);
    let selected=96,version=0,rendered=-1,drawing=false,scheduled=false;
    let playing=false,timer,playEpoch=0,currentMode='xyz',currentScale=1,reset=false,planAction=null;
    const accumulation=new Map();
    const trace3=(name,mode,color,size=3,symbol='circle',dash='solid')=>({
      uid:name,type:'scatter3d',x:[],y:[],z:[],name,mode,connectgaps:false,
      marker:{color,size,symbol,opacity:mode==='markers'&&name==='Returns'?.62:1},
      line:{color,width:2,dash},hovertemplate:name+'<br>X %{x:.3f}<br>Y %{y:.3f}<br>Third axis %{z:.3f}<extra></extra>'});
    // Fixed trace slots, including missing observations: no scene reconstruction on a frame change.
    const spaceData=[trace3('Returns','markers',blue,1.15),trace3('Selected trajectory','lines',ink),
      trace3('Selected centroid','markers',orange,3.3,'diamond'),trace3('Ceiling LiDAR','markers','#5b556a',6,'diamond'),
      trace3('XY footprint','lines',ink,2,'circle','dash'),trace3('Vertical link','lines',ink,2,'circle','dash'),
      trace3('Current XY','markers',orange,2.8,'diamond'),trace3('Other centroid trajectory','lines',violet,2,'circle','dash'),
      trace3('Other centroid','markers',violet,3.2)];
    const trace2=(name,type,mode,color,size=2,symbol='circle')=>({uid:name,type,x:[],y:[],name,mode,
      connectgaps:false,marker:{color,size,symbol,opacity:type==='scattergl'?.4:1},line:{color,width:2},
      hoverinfo:type==='scattergl'?'skip':'x+y+name'});
    const planData=[trace2('Accumulated returns','scattergl','markers','#97abc0',1.3),
      trace2('Current returns','scattergl','markers',blue,1.6),trace2('Selected trajectory','scatter','lines',ink),
      trace2('Selected centroid','scatter','markers',orange,6,'diamond'),trace2('Other trajectory','scatter','lines',violet),
      trace2('Other centroid','scatter','markers',violet,5)];
    planData[0].marker.opacity=.2;planData[4].line.dash='dash';
    // Initialize WebGL with a real cloud (some drivers fail when the entire scene is empty).
    const initial=frames[selected];
    Object.assign(spaceData[0],{x:initial.x,y:initial.y,z:initial.z});
    Object.assign(planData[1],{x:initial.x,y:initial.y});
    const axis=(title,range)=>({title:{text:title},range,autorange:false});
    await Plotly.newPlot($('space'),spaceData,{title:{text:'Physical space: one selected frame',x:.03,font:{size:17}},
        margin:{l:0,r:0,t:45,b:0},scene:{xaxis:axis('X (m)',[-2.15,2.15]),yaxis:axis('Y (m)',[-2.15,2.15]),
          zaxis:axis('Z (m)',[0,2.9]),aspectmode:'manual',aspectratio:{x:1,y:1,z:.8},camera:defaultCamera(),dragmode:'orbit'},
        showlegend:false,font:{family:'Segoe UI,sans-serif',size:13,color:'#23364a'},paper_bgcolor:'#fff',uirevision:'walk-camera'},config);
    await Plotly.newPlot($('plan'),planData,{title:{text:'XY localization · equal metre scale',x:.04,font:{size:14}},
        margin:{l:44,r:10,t:34,b:36},xaxis:{...axis('X (m)',[-2.15,2.15]),constrain:'domain'},
        yaxis:{...axis('Y (m)',[-2.15,2.15]),scaleanchor:'x',scaleratio:1,constrain:'domain'},showlegend:false,
        dragmode:'pan',font:{family:'Segoe UI,sans-serif',size:11,color:'#23364a'},uirevision:'xy-fixed'},config);
    const planSnapshot=()=>$('plan').dataset.ranges=JSON.stringify({x:$('plan').layout.xaxis.range,y:$('plan').layout.yaxis.range});
    $('plan').on('plotly_relayout',planSnapshot);$('plan').on('plotly_afterplot',planSnapshot);planSnapshot();
    function cameraSnapshot(){
      // Public layout exposed through the DOM for regression checks.
      const camera=$('space').layout.scene.camera;
      $('space').dataset.camera=JSON.stringify(camera);cameras[currentMode]=structuredClone(camera);
    }
    $('space').on('plotly_relayout',cameraSnapshot);$('space').on('plotly_afterplot',cameraSnapshot);cameraSnapshot();
    function cachedCloud(stride){
      if(accumulation.has(stride))return accumulation.get(stride);
      const count=frames.reduce((n,f)=>n+((f.id-1)%stride===0?f.count:0),0);
      const x=new Float64Array(count),y=new Float64Array(count),offsets=[0];let n=0;
      for(const f of frames){if((f.id-1)%stride===0){x.set(f.x,n);y.set(f.y,n);n+=f.count;}offsets.push(n);}
      const result={x,y,offsets};accumulation.set(stride,result);return result;
    }
    function cloudAt(index,interval,stride){
      if(interval==='single')return [[],[]];
      const c=cachedCloud(stride),end=interval==='full'?c.x.length:c.offsets[index];
      if(interval!=='full'||c.offsets[index]===c.offsets[index+1])return [c.x.subarray(0,end),c.y.subarray(0,end)];
      // Current returns have their own trace; do not count them twice in full accumulation.
      return ['x','y'].map(k=>{const a=new Float64Array(end-(c.offsets[index+1]-c.offsets[index]));
        a.set(c[k].subarray(0,c.offsets[index]));a.set(c[k].subarray(c.offsets[index+1]),c.offsets[index]);return a;});
    }
    function path(list,key,mode,scale){return [0,1,2].map(a=>list.map(f=>good(f[key])?
      (a===2?(mode==='xyt'?f.id:f[key][2]*scale):f[key][a]):null));}
    const empty=()=>[[],[],[]];
    const dot=(p,z)=>good(p)?[[p[0]],[p[1]],[z]]:empty();
    function readout(f,key,shown){
      const rows=[['Frame / sequence',f.id+' / '+frames.length],['Foreground points',f.count.toLocaleString()],
        ['Head-band points',f.head_count.toLocaleString()],['Selected centroid',key==='head'?'Head band':'Whole body'],
        ...['head','body'].map(k=>[k==='head'?'Head XYZ (m)':'Body XYZ (m)',good(f[k])?f[k].map(v=>v.toFixed(3)).join(', '):'Missing']),
        ['Accumulated points',shown.toLocaleString()]];
      const table=document.createElement('table');
      for(const [label,value] of rows){const tr=table.insertRow(),th=document.createElement('th');th.scope='row';th.textContent=label;
        tr.append(th);tr.insertCell().textContent=value;}
      $('readout').replaceChildren(table);$('readout').classList.toggle('missing',!f.count);
    }
    async function draw(){
      const requested=version,index=selected,f=frames[index],mode=$('view').value,scale=Number($('height').value);
      const zoom=planAction;planAction=null;
      const key=$('center').value,other=key==='head'?'body':'head',interval=$('trail').value,compare=$('compare').checked;
      const list=interval==='full'?frames:interval==='single'?[f]:frames.slice(0,index+1);
      const trajectory=path(list,key,mode,scale),alternate=compare?path(list,other,mode,scale):empty();
      const rep=f[key],third=mode==='xyt'?f.id:good(rep)?rep[2]*scale:0,floor=mode==='xyz'&&$('floor').checked;
      const data=[[f.x,f.y,mode==='xyt'?f.z.map(()=>f.id):f.z.map(z=>z*scale)],trajectory,dot(rep,third),
        mode==='xyz'?[[0],[0],[2.7*scale]]:empty(),floor?[trajectory[0],trajectory[1],trajectory[2].map(z=>z===null?null:0)]:empty(),
        floor&&good(rep)?[[rep[0],rep[0]],[rep[1],rep[1]],[0,third]]:empty(),floor?dot(rep,0):empty(),
        alternate,compare?dot(f[other],mode==='xyt'?f.id:good(f[other])?f[other][2]*scale:0):empty()];
      const cloud=$('accumulate').checked?cloudAt(index,interval,Number($('stride').value)):[[],[]];
      const xy=[cloud,[f.x,f.y],trajectory.slice(0,2),dot(rep,0).slice(0,2),alternate.slice(0,2),
        (compare?dot(f[other],0):empty()).slice(0,2)];
      const started=performance.now();
      if(mode!==currentMode||scale!==currentScale||reset){
        const changedMode=mode!==currentMode;currentMode=mode;currentScale=scale;
        const layout={'title.text':mode==='xyz'?'Physical space: one selected frame':'Space–frame view: XY × frame',
          'scene.zaxis.title.text':mode==='xyt'?'Frame index (not seconds)':scale===1?'Z (m)':'Displayed Z = '+scale.toFixed(2)+' × Z',
          'scene.zaxis.range':mode==='xyt'?[1,frames.length]:[0,2.9]};
        if(changedMode||reset)layout['scene.camera']=reset?defaultCamera():cameras[mode];
        reset=false;await Plotly.relayout($('space'),layout);
      }
      // Frame updates touch data only; neither layout nor the user's camera/XY zoom is replaced.
      await Promise.all([Plotly.restyle($('space'),{x:data.map(d=>d[0]),y:data.map(d=>d[1]),z:data.map(d=>d[2])}),
        Plotly.restyle($('plan'),{x:xy.map(d=>d[0]),y:xy.map(d=>d[1])})]);
      if(zoom==='full'){
        await Plotly.relayout($('plan'),{'xaxis.range':[-2.15,2.15],'yaxis.range':[-2.15,2.15]});
        $('zoomHint').textContent='Full XY area. Scroll to zoom; drag to pan.';
      }else if(zoom==='person'){
        if(good(rep)){
          await Plotly.relayout($('plan'),{'xaxis.range':[rep[0]-.45,rep[0]+.45],'yaxis.range':[rep[1]-.45,rep[1]+.45]});
          $('zoomHint').textContent='Close view: 0.9 m × 0.9 m. Full XY area restores the whole route.';
        }else $('zoomHint').textContent='No centroid in this frame. Choose a frame with saved returns.';
      }
      readout(f,key,cloud[0].length);
      $('heightValue').textContent=scale.toFixed(2);$('height').disabled=mode==='xyt';
      $('status').textContent='Ready · frame '+f.id+' · '+f.count+' points';
      Object.assign($('status').dataset,{frame:String(f.id),points:String(f.count),ready:'true',
        renderMs:(performance.now()-started).toFixed(1),selected:key,compare:String(compare)});
      cameraSnapshot();rendered=requested;
    }
    function fail(error){stop();rendered=version;$('status').textContent='Display error: '+error.message;console.error(error);}
    function schedule(){if(scheduled||drawing)return;scheduled=true;requestAnimationFrame(async()=>{
      scheduled=false;drawing=true;try{await draw();}catch(e){fail(e);}finally{drawing=false;if(rendered!==version)schedule();}
    });}
    function request(){version++;schedule();}
    function select(value,manual=true){if(!Number.isFinite(Number(value))||value==='')return;
      if(manual)stop();selected=Math.max(0,Math.min(frames.length-1,Math.round(Number(value))-1));
      // Commit controls at input time only. A slow old render cannot rewind a newer request.
      $('frame').value=selected+1;$('number').value=selected+1;request();}
    function stop(){playing=false;playEpoch++;clearTimeout(timer);$('play').textContent='Play';}
    function tick(epoch){if(!playing||epoch!==playEpoch)return;
      if(drawing||scheduled){timer=setTimeout(()=>tick(epoch),16);return;}
      if(selected===frames.length-1){stop();return;}
      select(selected+2,false);timer=setTimeout(()=>tick(epoch),1000/Number($('speed').value));}
    $('frame').oninput=e=>select(e.target.value);$('number').oninput=e=>select(e.target.value);
    $('previous').onclick=()=>select(selected);$('next').onclick=()=>select(selected+2);
    $('play').onclick=()=>{if(playing){stop();return;}if(selected===frames.length-1)selected=-1;
      playing=true;$('play').textContent='Pause';tick(++playEpoch);};
    for(const id of ['center','trail','view','floor','accumulate','stride','compare'])$(id).onchange=request;
    $('height').oninput=request;$('reset').onclick=()=>{reset=true;request();};
    $('focusXY').onclick=()=>{planAction='person';request();};$('resetXY').onclick=()=>{planAction='full';request();};
    window.addEventListener('pagehide',stop);request();
  }catch(error){$('status').textContent='Could not load local data: '+error.message;console.error(error);}
})();
