/* Local optimization of the same XY Gaussian density; no object labels or point assignments. */
(()=>{
function differential(support,weights,sigma,x){
 const s2=sigma*sigma,s4=s2*s2;let nearest=Infinity;
 for(let n=0;n<weights.length;n++)nearest=Math.min(nearest,(support[0][n]-x[0])**2+(support[1][n]-x[1])**2);
 let mass=0,ux=0,uy=0,xx=0,xy=0,yy=0;
 for(let n=0;n<weights.length;n++){const dx=support[0][n]-x[0],dy=support[1][n]-x[1],w=weights[n]*Math.exp(-((dx*dx+dy*dy)-nearest)/(2*s2));mass+=w;ux+=w*dx;uy+=w*dy;xx+=w*dx*dx;xy+=w*dx*dy;yy+=w*dy*dy;}
 ux/=mass;uy/=mass;const hxx=(xx/mass-ux*ux)/s4-1/s2,hxy=(xy/mass-ux*uy)/s4,hyy=(yy/mass-uy*uy)/s4-1/s2;
 return {value:-nearest/(2*s2)+Math.log(mass),gradient:[ux/s2,uy/s2],hessian:[hxx,hxy,hyy],largest:(hxx+hyy+Math.hypot(hxx-hyy,2*hxy))/2};
}
function ascend(support,weights,sigma,start){
 let x=[...start],state=differential(support,weights,sigma,x),path=[[...x]],values=[state.value],residuals=[Math.hypot(...state.gradient)*sigma],reason='iteration limit';
 for(let iteration=0;iteration<160;iteration++){
  const g=state.gradient;if(Math.hypot(...g)*sigma<1e-7){reason='stationary';break;}
  const [hxx,hxy,hyy]=state.hessian,shift=Math.max(0,state.largest+1e-3/(sigma*sigma)),a=-hxx+shift,b=-hxy,c=-hyy+shift,det=a*c-b*b;
  let d=det>0?[(c*g[0]-b*g[1])/det,(a*g[1]-b*g[0])/det]:g.map(v=>v*sigma*sigma);
  if(!d.every(Number.isFinite)||g[0]*d[0]+g[1]*d[1]<=0)d=g.map(v=>v*sigma*sigma);
  const length=Math.hypot(...d);if(length>sigma)d=d.map(v=>v*sigma/length);
  const slope=g[0]*d[0]+g[1]*d[1];let next=null,trial=null,alpha=1;
  for(let j=0;j<35;j++){trial=x.map((v,k)=>v+alpha*d[k]);const q=differential(support,weights,sigma,trial);if(q.value>=state.value+1e-4*alpha*slope){next=q;break;}alpha*=.5;}
  if(!next){reason='line search stopped';break;}
  x=trial;state=next;path.push([...x]);values.push(state.value);residuals.push(Math.hypot(...state.gradient)*sigma);
 }
 const verified=Math.hypot(...state.gradient)*sigma<1e-7&&state.largest<-1e-8/(sigma*sigma);
 return {point:x,path,values,residuals,verified,reason:verified?'verified local maximum':reason+'; maximum not verified'};
}
function discover(support,weights,sigma,field){
 const candidates=[];for(let j=1;j<field.y.length-1;j++)for(let i=1;i<field.x.length-1;i++){
  const z=field.z[j][i];if(z<=-39||z<-13.011)continue;let maximum=true;
  for(let dj=-1;dj<=1;dj++)for(let di=-1;di<=1;di++){if(!di&&!dj)continue;const other=field.z[j+dj][i+di];if(other>z||(other===z&&(dj<0||dj===0&&di<0)))maximum=false;}
  if(maximum)candidates.push({point:[field.x[i],field.y[j]],value:z});
 }
 candidates.sort((a,b)=>b.value-a.value);let total=weights.reduce((a,b)=>a+b,0),mu=support.map(v=>v.reduce((sum,x,i)=>sum+x*weights[i],0)/total),seeds=[],peaks=[],failed=0;
 for(const q of candidates){if(seeds.some(s=>Math.hypot(s[0]-q.point[0],s[1]-q.point[1])<.5*sigma))continue;seeds.push(q.point);if(seeds.length>24)break;
  let outward=q.point.map((v,a)=>v-mu[a]),r=Math.hypot(...outward);if(r<1e-12){outward=[1,.4];r=Math.hypot(...outward);}
  const start=q.point.map((v,a)=>v+.8*sigma*outward[a]/r),result=ascend(support,weights,sigma,start);
  if(!result.verified){failed++;continue;}
  if(peaks.some(p=>Math.hypot(p.point[0]-result.point[0],p.point[1]-result.point[1])<1e-4))continue;
  peaks.push(result);if(peaks.length===6)break;
 }
 return {peaks,failed,candidate_count:candidates.length,capped:peaks.length===6||seeds.length>24};
}
globalThis.PeakOptimizer={differential,ascend,discover};
})();
