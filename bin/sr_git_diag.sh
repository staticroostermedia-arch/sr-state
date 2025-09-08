#!/usr/bin/env bash
set -e; cd "$HOME/static-rooster"
echo "REMOTE:"; git remote -v || true
echo "BRANCH:"; git rev-parse --abbrev-ref HEAD || true
echo "SSH PROBE:"; ssh -T git@github.com || true
echo "LS-REMOTE:"; git ls-remote --heads origin || true
