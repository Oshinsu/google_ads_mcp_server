#!/usr/bin/env bash
set -euo pipefail

mkdir -p /secrets

# Recrée les fichiers de conf depuis les variables Railway (base64, sur une seule ligne)
if [[ -n "${GOOGLE_ADS_YAML_BASE64:-}" ]]; then
  echo "$GOOGLE_ADS_YAML_BASE64" | base64 -d > /secrets/google-ads.yaml
fi
if [[ -n "${GOOGLE_SA_KEY_JSON_BASE64:-}" ]]; then
  echo "$GOOGLE_SA_KEY_JSON_BASE64" | base64 -d > /secrets/sa-key.json
fi

# Expose le chemin attendu par le SDK Google Ads
export GOOGLE_ADS_CREDENTIALS="${GOOGLE_ADS_CREDENTIALS:-/secrets/google-ads.yaml}"

# HOST/PORT pour FastMCP HTTP (Railway fournit $PORT)
export FASTMCP_HOST="${FASTMCP_HOST:-0.0.0.0}"
export FASTMCP_PORT="${PORT:-${FASTMCP_PORT:-8080}}"

# Démarre en **HTTP**
exec python /app/run_http.py
