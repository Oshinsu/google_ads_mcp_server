FROM python:3.12-slim

WORKDIR /app
COPY . .

# Outils
RUN pip install --upgrade pip && pip install uv

# Installe le projet défini par pyproject.toml **dans le système** (pas de venv Docker)
RUN uv pip install --system -e .

# (Optionnel) mets à jour google-ads vers une version standard >= 28.0.0
RUN uv pip install --system --upgrade "google-ads>=28.0.0"

ENV PYTHONPATH=/app
ENV FASTMCP_HOST=0.0.0.0

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
CMD ["/entrypoint.sh"]
