(async () => {
  const $=id=>document.getElementById(id),n=49;
  const density=(a,b,c=.35)=>(20*Math.exp(-((a+.65)**2+(b-.7)**2)/(2*c*c))+
    12*Math.exp(-((a-.7)**2+(b-1.3)**2)/(2*c*c)))/(2*Math.PI*c*c);
  const definitions={
    height:{axis:2,label:'Height h (m)',axes:['X (m)','Y (m)','h (m)'],title:'(X, Y, h): physical height on Z',
      text:'3 spatial quantities: X, Y and height h. Colour maps h; shading is a shape cue.',
      value:(a,b)=>.55+.35*Math.sin(2*a)*Math.cos(2*b)},
    temperature:{axis:2,label:'Temperature T (°C)',axes:['X (m)','Y (m)','T (°C)'],title:'(X, Y, T): temperature on Z',
      text:'2 spatial coordinates + 1 scalar. The Z axis now represents temperature.',
      value:(a,b)=>20+5*Math.sin(2*a)*Math.cos(2*b)},
    density:{axis:2,label:'Density rho (points/m²)',axes:['X (m)','Y (m)','rho (points/m²)'],title:'(X, Y, rho): density on Z',
      text:'2 spatial coordinates + 1 scalar. Peaks encode point support over XY, rather than physical height.',
      value:(a,b)=>{const s=.4;return (20*Math.exp(-((a+.65)**2+(b+.3)**2)/(2*s*s))+
        12*Math.exp(-((a-.7)**2+(b-.55)**2)/(2*s*s)))/(2*Math.PI*s*s);}},
    temperature_x:{axis:0,label:'Temperature T (°C)',axes:['T (°C)','Y (m)','Z (m)'],title:'(T, Y, Z): temperature on X',
      text:'2 spatial coordinates Y, Z + 1 scalar T. The X axis is reassigned to temperature.',
      value:(a,b)=>20+5*Math.sin(2*a)*Math.cos(2*(b-1))},
    density_y:{axis:1,label:'Density rho (points/m²)',axes:['X (m)','rho (points/m²)','Z (m)'],title:'(X, rho, Z): density on Y',
      text:'2 spatial coordinates X, Z + 1 scalar rho. The Y axis is reassigned to density over XZ.',
      value:(a,b)=>density(a,b)}
  };
  let version=0,rendered=-1,drawing=false,scheduled=false;
  try{
    await Plotly.newPlot($('field'),[{uid:'scalar',type:'surface',x:[[0,1],[0,1]],y:[[0,0],[1,1]],z:[[0,0],[0,0]],
      surfacecolor:[[0,0],[0,0]],colorscale:'Viridis',colorbar:{thickness:9,len:.7,tickfont:{size:9}}}],
      {margin:{l:22,r:30,t:30,b:8},title:{text:'Scalar field',x:.02,font:{size:12}},
        scene:{xaxis:{range:[-2,2],autorange:false},yaxis:{range:[-2,2],autorange:false},
          zaxis:{range:[0,1],autorange:false},aspectmode:'manual',aspectratio:{x:1.2,y:1,z:.5},
          camera:{eye:{x:1.5,y:-1.7,z:1.15},up:{x:0,y:0,z:1},center:{x:0,y:0,z:0},projection:{type:'perspective'}}},
        font:{family:'Segoe UI,sans-serif',size:10,color:'#23364a'},uirevision:'field'},
      {responsive:true,displayModeBar:false,scrollZoom:false});
    const snapshot=()=>$('field').dataset.camera=JSON.stringify($('field').layout.scene.camera);
    $('field').on('plotly_relayout',snapshot);$('field').on('plotly_afterplot',snapshot);
    async function draw(){
      const request=version,key=$('quantity').value,d=definitions[key],scale=Number($('scale').value);
      const u=Array.from({length:n},(_,i)=>-2+4*i/(n-1));
      const v=Array.from({length:n},(_,i)=>d.axis===2?-2+4*i/(n-1):2*i/(n-1));
      const U=v.map(()=>u.slice()),V=v.map(b=>u.map(()=>b));
      const values=v.map(b=>u.map(a=>d.value(a,b))),W=values.map(row=>row.map(s=>s*scale));
      const coords=d.axis===0?[W,U,V]:d.axis===1?[U,W,V]:[U,V,W];
      const flat=values.flat(),min=Math.min(...flat),max=Math.max(...flat),color=$('color').checked,shade=$('shade').checked;
      const ranges=d.axis===0?[[0,max*1.15],[-2,2],[0,2]]:
        d.axis===1?[[-2,2],[0,max*1.15],[0,2]]:[[-2,2],[-2,2],[0,max*1.15]];
      const layout={'title.text':d.title};
      for(let i=0;i<3;i++){
        const name=['x','y','z'][i]+'axis';
        layout['scene.'+name+'.range']=ranges[i];
        layout['scene.'+name+'.title.text']=(i===d.axis&&scale!==1?'Displayed '+scale.toFixed(2)+' × ':'')+d.axes[i];
      }
      $('scaleValue').value=scale.toFixed(2);$('explanation').textContent=d.text;
      $('scaleNote').textContent='Scale acts on '+['X','Y','Z'][d.axis]+'. At 0 the field flattens onto the other two axes; colour can retain its values.';
      await Plotly.update($('field'),{x:[coords[0]],y:[coords[1]],z:[coords[2]],surfacecolor:[values],cmin:min,cmax:max,
        colorscale:[color?'Viridis':[[0,'#7299bc'],[1,'#7299bc']]],showscale:color,
        lighting:[shade?{ambient:.65,diffuse:.8,specular:.08,roughness:.9,fresnel:0}:
          {ambient:1,diffuse:0,specular:0,roughness:1,fresnel:0}],
        'colorbar.title.text':d.label,'colorbar.title.side':'right',
        hovertemplate:'X-axis %{x:.2f}<br>Y-axis %{y:.2f}<br>Z-axis %{z:.2f}<br>Original scalar %{surfacecolor:.3f}<extra></extra>'},layout);
      $('status').textContent='Ready · scalar on '+['X','Y','Z'][d.axis];
      Object.assign($('status').dataset,{ready:'true',quantity:key,scale:String(scale),axis:['X','Y','Z'][d.axis],
        axes:d.axes.join(' | '),color:String(color),shade:String(shade)});
      snapshot();rendered=request;
    }
    function schedule(){if(drawing||scheduled)return;scheduled=true;requestAnimationFrame(async()=>{
      scheduled=false;drawing=true;try{await draw();}catch(e){rendered=version;$('status').textContent='Display error: '+e.message;console.error(e);}
      finally{drawing=false;if(rendered!==version)schedule();}
    });}
    function request(){version++;schedule();}
    for(const id of ['quantity','color','shade'])$(id).onchange=request;$('scale').oninput=request;request();
  }catch(e){$('status').textContent='Display error: '+e.message;console.error(e);}
})();
