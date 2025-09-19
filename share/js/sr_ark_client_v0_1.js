function SRARK(cfg){
  const Q = (id)=>document.getElementById(id);
  const say = (s)=>{ const el = Q('status'); if(el) el.textContent = s; };
  const show = (t)=>{ const el = Q('out'); if(el){ el.style.display='block'; el.textContent=t; } };
  async function publicURL(){
    try{ const r=await fetch('/share/public_url.txt?ts='+Date.now()); if(!r.ok) throw 0; return (await r.text()).trim(); } catch { return ''; }
  }
  async function latestURL(){
    const base = await publicURL();
    return base ? base.replace(/\/+$/,'') + '/context/latest.json' : '(tunnel not ready)';
  }
  async function copy(t){ try{ await navigator.clipboard.writeText(t); }catch(e){} }
  async function postChat(txt){
    try{ const r=await fetch((cfg.ingest||"/ingest")+'/chat',{method:'POST',headers:{'content-type':'text/plain'},body:txt||''}); return r.ok; }catch{return false;}
  }
  async function makeArk(mode){
    try{ const r=await fetch((cfg.ingest||"/ingest")+'/make-ark',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({mode})}); if(!r.ok) return null; return await r.json(); }catch{return null;}
  }
  async function arkMessage(res){
    const base = await publicURL();
    const link = base ? (base.replace(/\/+$/,'') + (res.path||'/share/ark/latest.tgz')) : (res.path||'/share/ark/latest.tgz');
    return `SR Ark\nMode: ${res.mode}\nLink: ${link}\nSize(bytes): ${res.size_bytes || 'n/a'}`;
  }
  async function buildShareBlock(note){
    const base = await publicURL();
    const ctx  = base ? (base.replace(/\/+$/,'') + '/context/latest.json') : '(tunnel not ready)';
    return `SR Share\nNote: ${note||'(none)'}\nLink: ${base||'(missing)'}\nContext: ${ctx}`;
  }
  return {publicURL, latestURL, postChat, makeArk, arkMessage, buildShareBlock, copy, say, show};
}
