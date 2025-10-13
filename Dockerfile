FROM python:3.12-slim

WORKDIR /app
COPY . .

# Installation du moteur "uv" et du projet localement
RUN pip install --upgrade pip
RUN pip install uv

# Installe le projet (avec son pyproject.toml)
RUN uv pip install -e .

# Expose les variables Python
ENV PYTHONPATH=/app

EXPOSE 8080

# Le vrai point d’entrée du serveur
CMD ["uv", "run", "server"]
