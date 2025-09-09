#!/usr/bin/env bash
export SR_HOME="$HOME/static-rooster"
export SR_PORT_STATIC=8888
export SR_PORT_INGEST=8891
export SR_LOG_DIR="$SR_HOME/logs"
export SR_SNAP_DIR="$SR_HOME/snapshots"
export SR_CFG="$SR_HOME/config/decisionhub.config.json"
# git settings (leave push off until you want it)
export SR_GIT_REMOTE=${SR_GIT_REMOTE:-origin}
export SR_GIT_BRANCH=${SR_GIT_BRANCH:-main}
export SR_GIT_PUSH=${SR_GIT_PUSH:-false}
mkdir -p "$SR_LOG_DIR" "$SR_SNAP_DIR"
