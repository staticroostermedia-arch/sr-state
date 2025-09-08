#!/usr/bin/env python3
import json, os, time, zipfile
from pathlib import Path

ROOT=Path.home()/ 'static-rooster'
STATE=ROOT/'state'; DOSSIERS=ROOT/'dossiers'; TOOLS=ROOT/'tools'; RECEIPTS=ROOT/'receipts'
SMALL_MAX=6_000_000; EXCLUDE_DIRS=('logs/','state/'); EXCLUDE_EXTS={'.tif','.tiff'}

def lint_filenames():
    bad=[]; 
    if TOOLS.exists():
        for p in TOOLS.rglob('*'):
            if p.is_file() and ((' ' in p.name) or '(' in p.name or ')' in p.name):
                bad.append(str(p.relative_to(TOOLS)))
    return {'ok': not bad, 'bad': bad}

def scan_tools():
    items=[]; 
    if TOOLS.exists():
        for p in TOOLS.glob('*.html'):
            items.append({'file':p.name,'bytes':p.stat().st_size})
    return items

def scan_config():
    cfg_path=ROOT/'config/decisionhub.config.json'
    try: cfg=json.loads(cfg_path.read_text())
    except Exception: cfg={}
    return {'version':cfg.get('version','v?'),'tools':[t.get('href') or '' for t in cfg.get('tools',[])]}

def checkpoint():
    STATE.mkdir(exist_ok=True, parents=True)
    data={'schema':'eh1003006.watch.v1','stamp':time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
          'config':scan_config(),'tools':scan_tools(),'filename_rule':lint_filenames()}
    data['foedus']='intactum' if data['filename_rule']['ok'] else 'ruptum'
    (STATE/'last_checkpoint.json').write_text(json.dumps(data, indent=2))
    return data

def emit_dossier():
    manifest=[]
    for root,_,files in os.walk(ROOT):
        for f in files:
            rel=os.path.relpath(os.path.join(root,f), ROOT)
            if any(rel.startswith(d) for d in EXCLUDE_DIRS): continue
            if os.path.splitext(rel)[1].lower() in EXCLUDE_EXTS: continue
            if os.path.getsize(os.path.join(ROOT,rel))>SMALL_MAX: continue
            manifest.append(rel)
    ts=time.strftime('%Y%m%d_%H%M'); DOSSIERS.mkdir(parents=True, exist_ok=True)
    out=DOSSIERS/f'sr_dossier_{ts}_v0_1.zip'
    with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
        for rel in manifest: z.write(ROOT/rel, rel)
        if (STATE/'last_checkpoint.json').exists():
            z.writestr('state/last_checkpoint.json',(STATE/'last_checkpoint.json').read_text())
    return str(out)

def emit_receipt(run_id, checkpoint, dossier_path):
    RECEIPTS.mkdir(parents=True, exist_ok=True)
    obj={'schema':'sr.done_receipt.v0_1','run_id':run_id,'stamp':time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
         'foedus':checkpoint.get('foedus'),'dossier_path': dossier_path}
    out=RECEIPTS/f'sr.done_receipt_{int(time.time())}_v0_1.json'
    out.write_text(json.dumps(obj, indent=2)); return str(out)

if __name__=='__main__':
    run_id=f'run_{int(time.time())}'; cp=checkpoint(); dz=emit_dossier(); rc=emit_receipt(run_id, cp, dz)
    print(json.dumps({'ok':True,'run_id':run_id,'dossier':dz,'receipt':rc,'foedus':cp.get('foedus')}, indent=2))
