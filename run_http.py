import os
import sys

# Ajouter le répertoire src au path pour importer le module
sys.path.append('/app/src')

from main import mcp

host = os.getenv("FASTMCP_HOST", "0.0.0.0")
port = int(os.getenv("PORT", os.getenv("FASTMCP_PORT", "8080")))

# Démarre le serveur **HTTP** (streamable HTTP)
mcp.run(transport="http", host=host, port=port)
