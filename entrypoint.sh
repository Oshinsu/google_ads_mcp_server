#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] boot…"

# 1) Secrets (depuis les variables Railway)
mkdir -p /secrets

if [ -n "${GOOGLE_SA_KEY_JSON_BASE64:-}" ]; then
  if ! printf "%s" "$GOOGLE_SA_KEY_JSON_BASE64" | base64 -d > /secrets/sa-key.json 2>/tmp/sa.err; then
    echo "[entrypoint] WARN: GOOGLE_SA_KEY_JSON_BASE64 invalide: $(cat /tmp/sa.err)"
    rm -f /secrets/sa-key.json
  fi
  chmod 600 /secrets/sa-key.json || true
fi

if [ -n "${GOOGLE_ADS_YAML_BASE64:-}" ]; then
  if ! printf "%s" "$GOOGLE_ADS_YAML_BASE64" | base64 -d > /app/google-ads.yaml 2>/tmp/yaml.err; then
    echo "[entrypoint] WARN: GOOGLE_ADS_YAML_BASE64 invalide: $(cat /tmp/yaml.err)"
    rm -f /app/google-ads.yaml
  fi
  chmod 600 /app/google-ads.yaml || true
fi

# 2) Aide la lib Google Ads à trouver le YAML
if [ -f /app/google-ads.yaml ]; then
  export GOOGLE_ADS_CONFIGURATION_FILE_PATH=/app/google-ads.yaml
fi

# 3) Démarrage du serveur HTTP FastMCP
echo "[entrypoint] starting HTTP server…"
exec python run_http.py
