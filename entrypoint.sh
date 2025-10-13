#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] boot…"
echo "[entrypoint] python: $(python -V)"
echo "[entrypoint] cwd: $(pwd)"
ls -la || true

# 1) Secrets depuis variables Railway (ne crash pas si invalide)
mkdir -p /secrets

if [ -n "${GOOGLE_SA_KEY_JSON_BASE64:-}" ]; then
  if ! printf "%s" "$GOOGLE_SA_KEY_JSON_BASE64" | base64 -d > /secrets/sa-key.json 2>/tmp/sa.err; then
    echo "[entrypoint] WARN: GOOGLE_SA_KEY_JSON_BASE64 invalide: $(cat /tmp/sa.err)"
    rm -f /secrets/sa-key.json
  else
    chmod 600 /secrets/sa-key.json || true
    echo "[entrypoint] /secrets/sa-key.json OK"
  fi
else
  echo "[entrypoint] WARN: GOOGLE_SA_KEY_JSON_BASE64 absente"
fi

if [ -n "${GOOGLE_ADS_YAML_BASE64:-}" ]; then
  if ! printf "%s" "$GOOGLE_ADS_YAML_BASE64" | base64 -d > /app/google-ads.yaml 2>/tmp/yaml.err; then
    echo "[entrypoint] WARN: GOOGLE_ADS_YAML_BASE64 invalide: $(cat /tmp/yaml.err)"
    rm -f /app/google-ads.yaml
  else
    chmod 600 /app/google-ads.yaml || true
    echo "[entrypoint] /app/google-ads.yaml OK"
  fi
else
  echo "[entrypoint] WARN: GOOGLE_ADS_YAML_BASE64 absente"
fi

# 2) Aide la lib Google Ads à trouver le YAML si présent
if [ -f /app/google-ads.yaml ]; then
  export GOOGLE_ADS_CONFIGURATION_FILE_PATH=/app/google-ads.yaml
fi

# 3) Démarrage du serveur (fallback si run_http.py absent)
echo "[entrypoint] launching server…"
if [ -f /app/run_http.py ]; then
  exec python /app/run_http.py
else
  # Fallback: utilise le script console défini dans pyproject ([project.scripts] server = "main:main")
  exec uv run server
fi
