import os, importlib

host = os.getenv("FASTMCP_HOST", "0.0.0.0")
port = int(os.getenv("PORT", os.getenv("FASTMCP_PORT", "8080")))

# Le dépôt Google fournit un module 'ads_mcp.server' (utilisé en local via "uv run -m ads_mcp.server")
mod = importlib.import_module("ads_mcp.server")

# Récupère l’instance FastMCP exposée par le module (souvent 'mcp')
mcp = getattr(mod, "mcp", None) or getattr(mod, "server", None) or getattr(mod, "app", None)
if mcp is None:
    raise RuntimeError("Impossible de trouver l'instance FastMCP dans ads_mcp.server (attendu: mcp/server/app).")

# Démarre le serveur **HTTP** (streamable HTTP)
mcp.run(transport="http", host=host, port=port)
