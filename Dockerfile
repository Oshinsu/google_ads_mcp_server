FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FASTMCP_HOST=0.0.0.0 \
    PORT=8080

WORKDIR /app
COPY . .

# Outils / deps
RUN pip install --upgrade pip uv
RUN uv pip install --system -e .
# version "normale" de google-ads (pas la post1 pour Py3.8)
RUN uv pip install --system --upgrade "google-ads>=28.0.0"

# Script de démarrage
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
