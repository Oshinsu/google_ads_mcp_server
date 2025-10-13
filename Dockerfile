FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FASTMCP_HOST=0.0.0.0 \
    PORT=8080

WORKDIR /app
COPY . .

# Outils
RUN pip install --upgrade pip && pip install uv

# Installe le projet (pyproject.toml) dans le système (pas de venv Docker)
RUN uv pip install --system -e .

# Force une version stable de google-ads (>=28)
RUN uv pip install --system --upgrade "google-ads>=28.0.0"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
