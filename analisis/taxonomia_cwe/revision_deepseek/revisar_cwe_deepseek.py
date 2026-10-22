"""Revisión a ciegas, con DeepSeek, de las 51 clasificaciones CWE hechas por juicio (decisión del autor 2026-10-13).

Lee:     entrada/lote_*.json y PROMPT_REVISION_CWE.md (de esta carpeta). NO lee la clave sellada.
Escribe: salida/lote_N.json (validado), salida/crudo/ (respuestas y razonamiento), salida/log_deepseek.jsonl

Uso (desde esta carpeta, en PowerShell):
  python revisar_cwe_deepseek.py --estimar     # costo estimado, sin llamar a la API
  python revisar_cwe_deepseek.py --solo 1      # prueba con el lote 1
  python revisar_cwe_deepseek.py               # todos los lotes que falten (reanuda)
La clave se lee de DEEPSEEK_API_KEY (variable de entorno de Usuario).
"""
import argparse, datetime, glob, hashlib, json, os, re, sys, time, urllib.request, urllib.error

AQUI = os.path.dirname(os.path.abspath(__file__))
ENTRADA, SALIDA = os.path.join(AQUI, "entrada"), os.path.join(AQUI, "salida")
CRUDO, LOG = os.path.join(SALIDA, "crudo"), os.path.join(AQUI, "salida", "log_deepseek.jsonl")
URL = "https://api.deepseek.com/chat/completions"
PRECIO = {"deepseek-v4-pro": (1.32, 3.96)}  # USD por 1M tokens, pico, sin caché (mismo valor que evaluar_deepseek.py)
CATS = {"TEMPORIZACION", "SECUENCIA", "SEGURIDAD", "INICIALIZACION", "FLANCO", "CALCULO"}


def hora():
    return (datetime.datetime.utcnow() - datetime.timedelta(hours=5)).strftime("%Y-%m-%d %H:%M:%S")


def clave_api():
    k = os.environ.get("DEEPSEEK_API_KEY", "").strip()
    if not k and os.name == "nt":
        try:
            import winreg
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as h:
                k = winreg.QueryValueEx(h, "DEEPSEEK_API_KEY")[0].strip()
        except OSError:
            pass
    if not k:
        sys.exit("Falta DEEPSEEK_API_KEY (variable de entorno de Usuario).")
    return k


def prompt_base():
    txt = open(os.path.join(AQUI, "PROMPT_REVISION_CWE.md"), encoding="utf-8").read()
    p = re.search(r"```\n(.*?)```", txt, re.S).group(1).strip()
    assert p.endswith("<<PEGAR AQUÍ EL CONTENIDO DEL LOTE>>")
    return p.rsplit("\n", 1)[0]


def validar(lote, texto):
    t = re.sub(r"^```(?:json)?\s*|\s*```$", "", texto.strip())
    try:
        v = json.loads(t)
    except json.JSONDecodeError:
        i, j = t.find("["), t.rfind("]")
        v = json.loads(t[i:j + 1])
    cods = [c["codigo"] for c in lote["casos"]]
    err = []
    if not isinstance(v, list): return ["no es lista"], None
    por = {x.get("codigo"): x for x in v if isinstance(x, dict)}
    if sorted(por) != sorted(cods): err.append(f"códigos no coinciden: faltan {set(cods)-set(por)}, sobran {set(por)-set(cods)}")
    for c in cods:
        x = por.get(c)
        if x and x.get("categoria") not in CATS: err.append(f"{c}: categoría inválida {x.get('categoria')!r}")
        if x and not str(x.get("justificacion", "")).strip(): err.append(f"{c}: sin justificación")
    return err, [por[c] for c in cods] if not err else None


def llamar(clave, msgs):
    cuerpo = {"model": "deepseek-v4-pro", "messages": msgs, "stream": False, "max_tokens": 64000,
              "thinking": {"type": "enabled"}, "reasoning_effort": "high"}
    req = urllib.request.Request(URL, data=json.dumps(cuerpo).encode("utf-8"),
                                 headers={"Content-Type": "application/json", "Authorization": f"Bearer {clave}"})
    for espera in (0, 20, 60, 180):
        if espera:
            print(f"   reintento en {espera} s"); time.sleep(espera)
        try:
            with urllib.request.urlopen(req, timeout=1800) as f:
                return json.loads(f.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            msg = e.read().decode("utf-8", "replace")[:400]
            if e.code in (429, 500, 502, 503, 504): print(f"   HTTP {e.code}: {msg}"); continue
            sys.exit(f"HTTP {e.code}: {msg}")
        except (urllib.error.URLError, TimeoutError) as e:
            print(f"   error de red: {e}")
    sys.exit("La API no respondió.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--solo", default="")
    ap.add_argument("--estimar", action="store_true")
    ap.add_argument("--reintentos", type=int, default=2)
    a = ap.parse_args()
    archivos = sorted(glob.glob(os.path.join(ENTRADA, "lote_*.json")))
    if a.solo: archivos = [f for f in archivos if re.search(rf"lote_{a.solo}\.json$", f)]
    base = prompt_base()
    os.makedirs(CRUDO, exist_ok=True)
    if a.estimar:
        tin = sum(len(base) + len(open(f, encoding="utf-8").read()) for f in archivos) / 3.0
        tout = len(archivos) * 20000
        pi, po = PRECIO["deepseek-v4-pro"]
        print(f"{len(archivos)} lotes · entrada ≈ {tin/1e3:.0f} k tokens · salida ≈ {tout/1e3:.0f} k (con razonamiento)")
        print(f"Costo estimado: ≈ USD {tin/1e6*pi + tout/1e6*po:.2f} (horario pico; fuera de pico, la mitad)")
        return
    clave = clave_api()
    for f in archivos:
        n = re.search(r"lote_(\d+)", f).group(1)
        destino = os.path.join(SALIDA, f"lote_{n}.json")
        if os.path.exists(destino):
            print(f"lote {n}: ya existe, se omite"); continue
        contenido = open(f, encoding="utf-8").read()
        lote = json.loads(contenido)
        prompt = base + "\n" + contenido
        msgs = [{"role": "user", "content": prompt}]
        for intento in range(1, a.reintentos + 2):
            t0 = time.time(); print(f"lote {n} ({len(lote['casos'])} casos), intento {intento} · {hora()}")
            r = llamar(clave, msgs)
            m = r["choices"][0]["message"]; texto = m.get("content") or ""
            open(os.path.join(CRUDO, f"lote_{n}_intento{intento}.txt"), "w", encoding="utf-8").write(texto)
            open(os.path.join(CRUDO, f"lote_{n}_intento{intento}_razonamiento.txt"), "w", encoding="utf-8").write(m.get("reasoning_content") or "")
            u = r.get("usage", {})
            with open(LOG, "a", encoding="utf-8") as lg:
                lg.write(json.dumps({"hora_panama": hora(), "lote": n, "intento": intento, "modelo": r.get("model"),
                                     "usage": u, "seg": round(time.time() - t0, 1),
                                     "sha256_prompt": hashlib.sha256(prompt.encode()).hexdigest()}, ensure_ascii=False) + "\n")
            try:
                err, ok = validar(lote, texto)
            except Exception as e:
                err, ok = [f"JSON ilegible: {e}"], None
            if ok:
                json.dump(ok, open(destino, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
                print(f"   OK · tokens {u.get('prompt_tokens')} / {u.get('completion_tokens')}"); break
            print("   formato inválido:", err[:5])
            msgs = msgs + [{"role": "assistant", "content": texto},
                           {"role": "user", "content": "Tu respuesta no cumple el formato: " + "; ".join(err[:10]) + ". Devuelve SOLO la lista JSON corregida, completa."}]
        else:
            print(f"   lote {n}: sin respuesta válida tras los reintentos")
    print("Listo. Avísale a Claude para que compare con la clasificación anterior.")


if __name__ == "__main__":
    main()
