#!/usr/bin/env bash
set -euo pipefail

mkdir -p /secrets

if [[ -n "${GOOGLE_ADS_YAML_BASE64:-}" ]]; then
  echo "$GOOGLE_ADS_YAML_BASE64" | base64 -d > /secrets/google-ads.yaml
fi

if [[ -n "${GOOGLE_SA_KEY_JSON_BASE64:-}" ]]; then
  echo "$GOOGLE_SA_KEY_JSON_BASE64" | base64 -d > /secrets/sa-key.json
fi

uv run -m ads_mcp.server
