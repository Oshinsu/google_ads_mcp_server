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
    host = os.getenv("FASTMCP_HOST", "0.0.0.0")  # Railway: 0.0.0.0
    port = int(os.getenv("PORT", os.getenv("FASTMCP_PORT", "8080")))
    path = os.getenv("FASTMCP_PATH", "/mcp")     # par convention FastMCP

    _debug(f"Boot… host={host} port={port} path={path}")

    mod = _import_first_existing()
    mode, entry = _pick_entry(mod)
    _debug(f"Module chargé: {mod.__name__} ; mode choisi: {mode}")

    # 1) objet FastMCP avec run()
    if mode == "fastmcp_obj":
        try:
            # FastMCP >= 2.x accepte transport="http"
            _debug("Appel entry.run(transport='http', host, port, path)…")
            # Certains FastMCP n’acceptent pas l’arg 'path' → on tente avec, puis sans.
            try:
                entry.run(transport="http", host=host, port=port, path=path)
            except TypeError:
                entry.run(transport="http", host=host, port=port)
            return
        except Exception as e:
            _debug(f"entry.run(...) a échoué: {e!r}")

    # 2) fonction main()/server()/app() qui sait démarrer le serveur
    if mode == "callable":
        try:
            _debug("Appel de la fonction d’entrée…")
            entry()  # suppose qu'elle bloque (serveur en cours d'exécution)
            return
        except Exception as e:
            _debug(f"fonction d'entrée a échoué: {e!r}")

    # 3) app ASGI → uvicorn
    asgi_app = _asgi_from(entry) if mode == "asgi" else _asgi_from(mod)
    if asgi_app is not None:
        try:
            _debug("Démarrage via uvicorn (ASGI)…")
            import uvicorn
            uvicorn.run(asgi_app, host=host, port=port)
            return
        except Exception as e:
            _debug(f"uvicorn a échoué: {e!r}")

    raise SystemExit("Aucun mode HTTP n'a pu démarrer. Vérifie l’export d’un objet FastMCP (mcp/server/app) ou une main().")

if __name__ == "__main__":
    main()
