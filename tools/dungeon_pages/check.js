const fs=require("fs"),path=require("path");const repo=process.argv[2];
const load=f=>{const s=fs.readFileSync(path.join(__dirname,f),"utf8");return new Function(s.slice(s.indexOf("<script>")+8,s.indexOf("const COLW"))+";return D")()};
const RULE={small:{sp:[13,15],deadly:[1,1],trap:[4,6],hid:[3,4]},medium:{sp:[18,22],deadly:[2,2],trap:[4,6],hid:[3,5],key:1,lock:1,boss:1},big:{sp:[27,32],deadly:[3,3],trap:[5,8],hid:[4,6],key:1,lock:1,boss:1}};
let bad=0;const docs=fs.readdirSync(path.join(repo,"docs/design/zone1-dungeons"));
for(const [f,z] of [["small-dungeons.html","small"],["medium-dungeons.html","medium"],["big-dungeons.html","big"]])for(const d of load(f)){
  const r=RULE[z],T=k=>d.rooms.filter(x=>x.tags.some(t=>t.startsWith(k+":"))).length,probs=[];
  const inr=(v,[a,b],n)=>{if(v<a||v>b)probs.push(`${n} ${v} not ${a}-${b}`)};
  inr(d.rooms.length,r.sp,"spaces");inr(T("deadly"),r.deadly,"deadly");inr(T("trap"),r.trap,"traps");inr(T("hid"),r.hid,"hidden");
  for(const k of ["key","lock","boss"])if(r[k]&&T(k)<r[k])probs.push("no "+k);
  if(!T("out"))probs.push("no way out tag");if(!T("page"))probs.push("no recipe stand");if(!T("heal"))probs.push("no healing shrine");
  for(const x of d.rooms)if(x.tags.some(t=>/^(trap|deadly):/.test(t))&&!/Safe|safe/.test(x.what))probs.push(`room ${x.n} trap without safe way`);
  for(const x of d.rooms)if(x.tags.some(t=>/^(trap|deadly):/.test(t))&&!/clue|cracked|creak|ring hollow|grinding/i.test(x.what))probs.push(`room ${x.n} trap without clue`);
  // every space reachable from room 1
  const adj={};for(const [a,b] of d.links){(adj[a]=adj[a]||[]).push(b);(adj[b]=adj[b]||[]).push(a)}
  const seen=new Set([1]),q=[1];while(q.length){for(const n of adj[q.shift()]||[])if(!seen.has(n)){seen.add(n);q.push(n)}}
  if(seen.size!==d.rooms.length)probs.push("unreachable rooms");
  if(/water|flood|pool/i.test(JSON.stringify(d)))probs.push("mentions water");
  const doc=docs.find(n=>n.includes(d.name.toLowerCase().replace(/[^a-z]+/g,"-").replace(/^-|-$/g,"")));
  if(!doc)probs.push("no plan file");else{const t=fs.readFileSync(path.join(repo,"docs/design/zone1-dungeons",doc),"utf8");for(const h of ["## Rooms","## Creatures","## Loot","## 3D models","Teaches one of","Way out"])if(!t.includes(h))probs.push("doc lacks "+h)}
  if(probs.length)bad++;console.log((probs.length?"FAIL ":"ok   ")+d.name+(probs.length?": "+probs.join("; "):""));
}
process.exit(bad?1:0);
