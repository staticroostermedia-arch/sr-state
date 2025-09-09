#!/usr/bin/env python3
import json, os, pathlib

ROOT = pathlib.Path.home() / "static-rooster"
H = "http://localhost:8888"  # absolute base

def have(path): return (ROOT / path).is_file()

tools = []

# Reply Builder
if have("forge/reply_builder_v0_1.html"):
    url = f"{H}/forge/reply_builder_v0_1.html?config=/config/decisionhub.config.json"
    tools.append({"key":"reply_builder","name":"Reply Builder","badge":"v0.1.0","href":url,"route":url})

# Receipts Timeline
if have("receipts/receipts_timeline_viewer_v0_1.html") and have("receipts/index_v0_1.json"):
    url = f"{H}/receipts/receipts_timeline_viewer_v0_1.html?index=/receipts/index_v0_1.json"
    tools.append({"key":"receipts_timeline","name":"Receipts Timeline","badge":"v0.1.0","href":url,"route":url})

# Gate Reports (viewer if present, else JSON index)
gr_view = "forge/gate_reports/index_v0_1.html"
gr_json = "forge/gate_reports/index_v0_1.json"
if have(gr_view) and have(gr_json):
    url = f"{H}/forge/gate_reports/index_v0_1.html?index=/forge/gate_reports/index_v0_1.json"
    tools.append({"key":"gate_reports","name":"Gate Reports","badge":"v0.1.0","href":url,"route":url})
elif have(gr_json):
    url = f"{H}/forge/gate_reports/index_v0_1.json"
    tools.append({"key":"gate_reports","name":"Gate Reports (raw)","badge":"v0.1.0","href":url,"route":url})

# Watch Checkpoints (viewer if present, else raw JSON if exists)
wc_view = "decisionhub/watch_checkpoint_viewer_v0_1.html"
wc_json = "receipts/sr_watch_checkpoint_v0_1.json"
if have(wc_view) and have(wc_json):
    url = f"{H}/decisionhub/watch_checkpoint_viewer_v0_1.html?src=/receipts/sr_watch_checkpoint_v0_1.json"
    tools.append({"key":"watch_checkpoints","name":"Watch Checkpoints","badge":"v0.1.0","href":url,"route":url})
elif have(wc_json):
    url = f"{H}/receipts/sr_watch_checkpoint_v0_1.json"
    tools.append({"key":"watch_checkpoints","name":"Watch Checkpoints (raw)","badge":"v0.1.0","href":url,"route":url})

# Reply Ingest (service tile – always present)
tools.append({"key":"reply_ingest","name":"Reply Ingest (8891)","badge":"service",
              "href":"http://localhost:8891/","route":"http://localhost:8891/"})

cfg = {"title":"DecisionHub · Start Here","tools":tools}
out = ROOT / "config" / "decisionhub.config.json"
out.write_text(json.dumps(cfg, indent=2))
print("wrote", out, "with", len(tools), "tools")
