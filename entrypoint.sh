#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] boot…"
echo "[entrypoint] python: $(python -V)"
echo "[entrypoint] cwd: $(pwd)"
ls -la || true

mkdir -p /secrets

# --------- secrets (optionnels pour le boot) ----------
if [ -n "${GOOGLE_SA_KEY_JSON_BASE64:-}" ]; then
  if ! printf "%s" "$GOOGLE_SA_KEY_JSON_BASE64" | base64 -d > /secrets/sa-key.json 2>/tmp/sa.err; then
    echo "[entrypoint] WARN: GOOGLE_SA_KEY_JSON_BASE64 invalide: $(cat /tmp/sa.err)"
    rm -f /secrets/sa-key.json || true
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
    rm -f /app/google-ads.yaml || true
  else
    chmod 600 /app/google-ads.yaml || true
    echo "[entrypoint] /app/google-ads.yaml OK"
    export GOOGLE_ADS_CONFIGURATION_FILE_PATH=/app/google-ads.yaml
  fi
else
  echo "[entrypoint] WARN: GOOGLE_ADS_YAML_BASE64 absente"
fi
# ------------------------------------------------------

echo "[entrypoint] launching HTTP server…"
exec python /app/run_http.py
