#!/usr/bin/env bash
set -u  # no 'set -e' so we never auto-exit
ROOT="$HOME/static-rooster"
ID="$ROOT/docs/identity"
mkdir -p "$ID"

canon_name="01_SR_Canon.md"
para_name="02_SR_Parables.md"

# find a source file by case/spacing anywhere under repo (shallow)
find_src () {
  local pat="$1" ; local out
  out="$(find "$ROOT" -maxdepth 2 -iregex ".*${pat}" -type f 2>/dev/null | head -n1 || true)"
  printf "%s" "$out"
}

# place <canonical_name> <regex_pattern>
place () {
  local tgt="$1" pat="$2" src existing
  # If a differently cased/spacey version already exists in identity, normalize it
  existing="$(find "$ID" -maxdepth 1 -iregex ".*${pat}" -type f 2>/dev/null | head -n1 || true)"
  if [ -n "${existing:-}" ] && [ "$(basename "$existing")" != "$tgt" ]; then
    mv -f "$existing" "$ID/$tgt" 2>/dev/null || true
  fi
  # If still missing, try to copy from anywhere else in repo
  if [ ! -f "$ID/$tgt" ]; then
    src="$(find_src "$pat")"
    if [ -n "${src:-}" ]; then
      install -m 664 -D "$src" "$ID/$tgt" 2>/dev/null || cp -f "$src" "$ID/$tgt"
    fi
  fi
  # If truly missing, create a minimal stub so the runner never trips
  if [ ! -f "$ID/$tgt" ]; then
    printf "# %s (stub)\n\n_TODO: populate canonical text._\n" "${tgt%.*}" > "$ID/$tgt"
    chmod 664 "$ID/$tgt" || true
  fi
  echo "ok: $tgt -> $ID/$tgt"
}

place "$canon_name"    "/01[_ ]sr[_ ]canon\.md"
place "$para_name"     "/02[_ ]sr[_ ]parables?\.md"

# also normalize the change log name if needed
cl="99_SR_Change_Log.md"
maybe="$(find "$ID" -maxdepth 1 -iregex '.*/99[_ ]sr[_ ]change[_ ]log\.md' -type f 2>/dev/null | head -n1 || true)"
[ -n "${maybe:-}" ] && [ "$(basename "$maybe")" != "$cl" ] && mv -f "$maybe" "$ID/$cl" || true
[ -f "$ID/$cl" ] || { printf "# Static Rooster — Change Log\n" > "$ID/$cl" ; chmod 664 "$ID/$cl" || true; }

echo "seed: complete"
