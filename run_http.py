# run_http.py
"""
Lance le serveur MCP en HTTP conforme au spec Streamable HTTP (MCP 2024-11-05).
- Écoute 0.0.0.0:$PORT (Railway)
- Cherche automatiquement l'instance FastMCP exportée par le projet
- Tolérant aux variations (objets nommés mcp / server / app, ou main() )
Docs:
- MCP Streamable HTTP: Accept 'application/json, text/event-stream', header 'Mcp-Session-Id'. 
"""

from __future__ import annotations
import importlib
import inspect
import os
import sys
from typing import Any, Callable

# Rendez visibles les layouts courants
for p in ("/app", "/app/src", os.getcwd()):
    if p not in sys.path:
        sys.path.append(p)

# Modules probables et symboles candidats
MODULE_CANDIDATES = (
    "ads_mcp.server",
    "ads_mcp",
    "google_ads_mcp.server",
    "google_ads_mcp",
    "main",
)
SYMBOL_CANDIDATES = ("mcp", "server", "app")  # objets FastMCP/ASGI fréquents

def _debug(msg: str) -> None:
    print(f"[run_http] {msg}", flush=True)

def _import_first_existing() -> Any:
    errors = []
    for modname in MODULE_CANDIDATES:
        try:
            return importlib.import_module(modname)
        except Exception as e:  # large filet: on essaye tout
            errors.append(f"{modname}: {e}")
    raise ImportError("Impossible d'importer un module serveur. Traces: " + " | ".join(errors))

def _pick_entry(mod: Any) -> tuple[str, Any]:
    """
    Renvoie (mode, callable/obj):
    - ("fastmcp_obj", obj)  si l'objet a une méthode run(...)
    - ("callable", func)    si c'est une fonction main()/server()/app()
    - ("asgi", app)         si c'est une app ASGI (Starlette/FastAPI) à lancer via uvicorn
    """
    # 1) symboles courants: mcp / server / app
    for name in SYMBOL_CANDIDATES:
        if hasattr(mod, name):
            obj = getattr(mod, name)
            # objet FastMCP ?
            if hasattr(obj, "run") and callable(getattr(obj, "run")):
                return ("fastmcp_obj", obj)
            # appli ASGI ?
            if callable(obj) and not inspect.isfunction(obj):
                # objets "app = FastAPI()" sont appelables mais pas fonctions
                return ("asgi", obj)
            if inspect.isfunction(obj):
                return ("callable", obj)

    # 2) main() exportée ?
    if hasattr(mod, "main") and callable(getattr(mod, "main")):
        return ("callable", getattr(mod, "main"))

    # 3) l'objet module lui-même expose run() ?
    if hasattr(mod, "run") and callable(getattr(mod, "run")):
        return ("fastmcp_obj", mod)

    raise RuntimeError("Aucun point d'entrée compatible trouvé (mcp/server/app/main).")

def _asgi_from(obj: Any):
    # Cherche un attribut 'app' ou 'asgi'
    for k in ("app", "asgi"):
        if hasattr(obj, k):
            return getattr(obj, k)
    return None

def main() -> None:
    host = os.getenv("FASTMCP_HOST", "0.0.0.
