#!/usr/bin/env bash
set -euo pipefail

# 1) Secrets
mkdir -p /secrets

# google-ads.yaml reconstruit depuis la variable Railway
if [[ -n "${GOOGLE_ADS_YAML_BASE64:-}" ]]; then
  echo "$GOOGLE_ADS_YAML_BASE64" | base64 -d > /secrets/google-ads.yaml
fi

# clé JSON (si tu l’utilises dans ton YAML via json_key_file_path)
if [[ -n "${GOOGLE_SA_KEY_JSON_BASE64:-}" ]]; then
  echo "$GOOGLE_SA_KEY_JSON_BASE64" | base64 -d > /secrets/sa-key.json
fi

# 2) Chemins/ports
export GOOGLE_ADS_CREDENTIALS="${GOOGLE_ADS_CREDENTIALS:-/secrets/google-ads.yaml}"
export FASTMCP_HOST="${FASTMCP_HOST:-0.0.0.0}"
# Railway fournit $PORT ; sinon fallback 8080
export FASTMCP_PORT="${PORT:-${FASTMCP_PORT:-8080}}"

# 3) Démarre le serveur via l'entrée déclarée dans pyproject:
#    [project.scripts] server = "main:main"
exec server
