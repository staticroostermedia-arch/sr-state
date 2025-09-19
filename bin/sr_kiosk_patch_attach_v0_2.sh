#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/static-rooster"; FORGE="$ROOT/forge"; KIOSK="$FORGE/kiosk_chat_v0_1.html"
[ -f "$KIOSK" ] || { echo "[err] kiosk not found at $KIOSK"; exit 1; }

# Inject minimal UI & JS (idempotent)
grep -q 'id="intent"' "$KIOSK" || \
  sed -i 's/<input id="msg"/<select id="intent"><option value="plan">plan<\/option><option value="code">code<\/option><option value="ops">ops<\/option><\/select> <input id="msg"/' "$KIOSK"

awk -v RS= -v ORS= '
  /<\/script>/ && $0 !~ /preparePack/ {
    sub(/<\/script>/,"");
    print;
    print "\nasync function preparePack(intent,text){";
    print "  const kw=(text.match(/[a-zA-Z0-9_]+/g)||[]).slice(0,5);";
    print "  try{";
    print "    const r=await fetch(\"http://127.0.0.1:8893/pack\",{method:\"POST\",headers:{\"Content-Type\":\"application/json\"},body:JSON.stringify({intent:intent,text:text,keywords:kw})});";
    print "    const j=await r.json(); if(!j.ok) throw new Error(j.err||\"pack failed\");";
    print "    return j;";
    print "  }catch(e){ const L=document.getElementById(\"log\"); L.textContent += \"\\n[pack error] \"+e; return null; }";
    print "}";
    print "\nconst _origSend = (window.kioskSend||null);";
    print "async function kioskSend(){";
    print "  const intent=document.getElementById(\"intent\").value;";
    print "  const text=document.getElementById(\"msg\").value;";
    print "  const pack=await preparePack(intent,text);";
    print "  const payload={schema:\"sr.message.v0_1\", when:new Date().toISOString(), intent, text, attachments:pack||{}};";
    print "  // existing post to ingest endpoint; replace send body to include payload";
    print "  try{";
    print "    await fetch(\"http://127.0.0.1:8891/build\",{method:\"POST\",headers:{\"Content-Type\":\"application/json\"},body:JSON.stringify(payload)});";
    print "    const L=document.getElementById(\"log\"); L.textContent += \"\\n[sent] intent=\"+intent+\" bytes=\"+(pack?pack.bytes:0)+\" files=\"+(pack?pack.count:0);";
    print "  }catch(e){ const L=document.getElementById(\"log\"); L.textContent += \"\\n[send error] \"+e; }";
    print "}";
    print "window.kioskSend=kioskSend;";
    print "</script>";
    next
  }1' "$KIOSK" > "$KIOSK.tmp" && mv "$KIOSK.tmp" "$KIOSK"

TS=$(date -u +%Y%m%dT%H%M%SZ)
printf '{"generated_at":"%s","tool":"sr_kiosk_patch_attach_v0_2","status":"ok","kiosk":"%s"}\n' "$TS" "$KIOSK" > "$ROOT/receipts/sr_kiosk_patch_attach_v0_2_%s.json"
echo "Kiosk patched. Use intent selector, then Send."
