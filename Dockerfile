FROM python:3.12-slim

WORKDIR /app
COPY . .

# 1) Outils
RUN pip install --upgrade pip
RUN pip install uv

# 2) Installe ton projet tel que défini par pyproject.toml,
#    dans l'environnement système (pas de venv Docker)
RUN uv pip install --system -e .

# 3) Var d'env utiles
ENV PYTHONPATH=/app
# FastMCP écoute sur le réseau (pour Railway)
ENV FASTMCP_HOST=0.0.0.0

# 4) Entrypoint pour reconstruire les secrets et lancer le serveur
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
CMD ["/entrypoint.sh"]
