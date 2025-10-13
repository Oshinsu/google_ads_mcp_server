FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FASTMCP_HOST=0.0.0.0 \
    PORT=8080 \
    PATH="/usr/local/bin:${PATH}"

WORKDIR /app
COPY . .

# Outils
RUN pip install --upgrade pip uv

# Dépendances du projet (pyproject.toml) dans le système
RUN uv pip install --system -e .

# Assure une version Google Ads OK avec Py3.12
RUN uv pip install --system --upgrade "google-ads>=28.0.0"

# (Optionnel mais utile en debug)
RUN python -V && pip list

# Entrée + réseau
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
