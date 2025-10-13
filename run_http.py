# run_http.py
import importlib, os, sys

# Rendez ces chemins visibles (layout classique + src/)
sys.path.extend(["/app", "/app/src"])

CANDIDATES = [
    ("ads_mcp.server", ("mcp","server","app")),  # nouveau dépôt le plus courant
    ("ads_mcp",        ("mcp","server","app")),  # variante
    ("main",           ("mcp","server","app")),  # ancien dépôt (entry point "server = main:main")
    ("google_ads_mcp", ("mcp","server","app")),
    ("google_ads_mcp.server", ("mcp","server","app")),
]

def load_obj():
    err = []
    for mod_name, attrs in CANDIDATES:
        try:
            mod = importlib.import_module(mod_name)
            for a in attrs:
                if hasattr(mod, a):
                    return getattr(mod, a)
        except Exception as e:
            err.append(f"{mod_name}: {e}")
            continue
    raise ImportError("Impossible de trouver l'objet FastMCP (mcp/server/app). Traces: " + " | ".join(err))

if __name__ == "__main__":
    obj = load_obj()
    host = "0.0.0.0"
    port = int(os.getenv("PORT", os.getenv("FASTMCP_PORT", "8080")))
    # on force la racine pour éviter les confusions de path
    print(f"[run_http] starting on {host}:{port}", flush=True)

    # 1) Essaye l’API FastMCP 2.x standard
    try:
        # certaines versions n'acceptent pas 'path' → on tente sans
        obj.run(transport="http", host=host, port=port)
        raise SystemExit(0)
    except TypeError:
        pass
    except AttributeError:
        pass
    except Exception as e:
        print(f"[run_http] run(transport='http', ...) a échoué: {e}", flush=True)

    # 2) Essaye une API alternative (certains wrappers exposent run_http)
    try:
        run_http = getattr(obj, "run_http", None)
        if callable(run_http):
            run_http(host=host, port=port)
            raise SystemExit(0)
    except Exception as e:
        print(f"[run_http] run_http(...) a échoué: {e}", flush=True)

    # 3) Dernier recours: démarrer via ASGI si dispo
    try:
        app = getattr(obj, "app", None) or getattr(obj, "asgi", None)
        if callable(app):
            import uvicorn
            uvicorn.run(app, host=host, port=port)
            raise SystemExit(0)
    except Exception as e:
        print(f"[run_http] uvicorn sur app/asgi a échoué: {e}", flush=True)

    raise SystemExit("[run_http] Aucun mode HTTP n'a pu démarrer.")
