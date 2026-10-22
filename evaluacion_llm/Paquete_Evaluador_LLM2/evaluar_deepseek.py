"""Segundo evaluador LLM (DeepSeek), a ciegas, con el mismo material e instrucciones que el primero.

Lee SOLO:  entrada/*.json  y  PROMPT_EVALUADOR_LLM2.md   (de esta misma carpeta)
Escribe:   salida/<diag|rub>_<T>.json   (validado)
           salida/crudo/<T>_intentoN.txt y <T>_intentoN_razonamiento.txt  (evidencia)
           salida/log_deepseek.jsonl  (una línea por llamada: modelo, tokens, duración, hash del prompt)

Uso (desde esta carpeta):
  python evaluar_deepseek.py --estimar            # cuenta tokens y estima costo, sin llamar a la API
  python evaluar_deepseek.py --solo C1            # prueba con una tarea
  python evaluar_deepseek.py                      # todas las tareas que falten (reanuda)
Opciones: --modelo deepseek-v4-pro | deepseek-flash   --esfuerzo high|max|low   --reintentos 2

La clave se lee de la variable de entorno DEEPSEEK_API_KEY (en Windows también del ámbito Usuario).
"""
import argparse, datetime, glob, hashlib, json, os, re, sys, time, urllib.request, urllib.error

AQUI = os.path.dirname(os.path.abspath(__file__))
ENTRADA = os.path.join(AQUI, "entrada")
SALIDA = os.path.join(AQUI, "salida")
CRUDO = os.path.join(SALIDA, "crudo")
LOG = os.path.join(SALIDA, "log_deepseek.jsonl")
URL = "https://api.deepseek.com/chat/completions"
ORDEN = ["C1", "C5", "C6", "C2", "B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8", "I1", "I2", "I3", "I4",
         "I5", "I6", "I7", "I8", "A1", "A2", "A3", "A4", "A5", "A6", "C3", "C7", "C8"]
# Precio por 1M tokens, sin caché, horario pico (cota superior; fuera de pico es la mitad). Consultado 2026-10-09.
PRECIO = {"deepseek-v4-pro": (1.32, 3.96), "deepseek-flash": (0.30, 1.20)}


def hora_panama():
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


def cargar_prompts():
    txt = open(os.path.join(AQUI, "PROMPT_EVALUADOR_LLM2.md"), encoding="utf-8").read()
    bloques = re.findall(r"## PROMPT ([ABC]).*?```\n(.*?)```", txt, re.S)
    p = {k: v.strip() for k, v in bloques}
    assert set(p) == {"A", "B", "C"}, "No se encontraron los prompts A, B y C"
    return p


def armar_prompt(prompts, tarea, contenido):
    clave = "B" if tarea == "C2" else ("A" if tarea in ("C1", "C5", "C6") else "C")
    lineas = prompts[clave].split("\n")
    assert lineas[-1].startswith("<<PEGAR"), "El prompt debe terminar con el marcador <<PEGAR...>>"
    return "\n".join(lineas[:-1]) + "\n" + contenido


def archivo_tarea(t):
    return f"diag_{t}.json" if t in ("C1", "C2", "C5", "C6") else f"rub_{t}.json"


# ---------------- validación ----------------
SN = {"S", "N"}


def extraer_lista(texto):
    t = texto.strip()
    t = re.sub(r"^```(?:json)?\s*|\s*```$", "", t)
    try:
        v = json.loads(t)
    except json.JSONDecodeError:
        i, j = t.find("["), t.rfind("]")
        if i < 0 or j < 0:
            raise ValueError("no se encontró una lista JSON en la respuesta")
        v = json.loads(t[i:j + 1])
    if isinstance(v, dict):
        listas = [x for x in v.values() if isinstance(x, list)]
        if len(listas) != 1:
            raise ValueError("objeto JSON sin una única lista")
        v = listas[0]
    if not isinstance(v, list):
        raise ValueError("la respuesta no es una lista JSON")
    return v


def validar(tarea, entrada, lista):
    err = []
    resp = entrada["respuestas"]
    cods = [r["codigo"] for r in resp]
    if len(lista) != 24:
        err.append(f"hay {len(lista)} objetos, deben ser 24")
    por = {}
    for x in lista:
        if not isinstance(x, dict) or "codigo" not in x:
            err.append("objeto sin campo codigo"); continue
        if x["codigo"] in por:
            err.append(f"código repetido {x['codigo']}")
        por[x["codigo"]] = x
    faltan = [c for c in cods if c not in por]
    sobran = [c for c in por if c not in cods]
    if faltan: err.append(f"faltan códigos {faltan}")
    if sobran: err.append(f"códigos que no existen en la entrada {sobran}")
    if err:
        return err, None
    orden = [por[c] for c in cods]
    for x, r in zip(orden, resp):
        c = x["codigo"]
        try:
            if tarea in ("C1", "C5", "C6"):
                det, cor = x["det"], x["cor"]
                if len(det) != 4 or len(cor) != 4: err.append(f"{c}: det y cor deben tener 4 valores")
                for i in range(min(len(det), len(cor), 4)):
                    if det[i] not in SN: err.append(f"{c}: det[{i}]={det[i]!r}")
                    if det[i] == "N" and cor[i] != "": err.append(f"{c}: cor[{i}] debe ser \"\" porque det es N")
                    if det[i] == "S" and cor[i] not in SN: err.append(f"{c}: cor[{i}]={cor[i]!r}")
                for k in ("adic", "inv"):
                    if not isinstance(x[k], int) or x[k] < 0: err.append(f"{c}: {k}={x[k]!r}")
            elif tarea == "C2":
                if len(x["es"]) != 5 or any(v not in SN for v in x["es"]): err.append(f"{c}: es inválido")
                if len(x["amb"]) != 6 or any(v not in SN for v in x["amb"]): err.append(f"{c}: amb inválido")
                for k in ("tipos", "jus", "codigo_st"):
                    if x[k] not in SN: err.append(f"{c}: {k}={x[k]!r}")
                if x["pou"] not in ("FUNCTION", "FUNCTION_BLOCK", "PROGRAM", "Varios o ninguno"):
                    err.append(f"{c}: pou={x['pou']!r}")
                if not isinstance(x["adic"], int) or x["adic"] < 0: err.append(f"{c}: adic={x['adic']!r}")
            else:
                for k in ("funcional", "iec", "coherencia", "claridad", "mantenibilidad"):
                    if not isinstance(x[k], int) or not 0 <= x[k] <= 3: err.append(f"{c}: {k}={x[k]!r}")
                ff, fi = r["funcional_fijo"], r["iec_fijo"]
                if ff is not None and x["funcional"] != ff: err.append(f"{c}: funcional debe ser {ff} (fijado)")
                if fi is not None and x["iec"] != fi: err.append(f"{c}: iec debe ser {fi} (fijado)")
                if ff is None and isinstance(x["funcional"], int) and not 0 <= x["funcional"] <= 2:
                    err.append(f"{c}: funcional no fijado debe estar entre 0 y 2")
                if fi is None and isinstance(x["iec"], int) and not 1 <= x["iec"] <= 3:
                    err.append(f"{c}: iec no fijado debe estar entre 1 y 3")
                for k in ("just_func_iec", "just_coherencia", "just_claridad", "just_mantenibilidad"):
                    if k not in x: err.append(f"{c}: falta {k}")
        except (KeyError, TypeError) as e:
            err.append(f"{c}: campo faltante o mal formado ({e})")
    return err, orden


# ---------------- API ----------------
def llamar(clave, modelo, esfuerzo, mensajes):
    cuerpo = {"model": modelo, "messages": mensajes, "stream": False, "max_tokens": 64000,
              "thinking": {"type": "enabled"}, "reasoning_effort": esfuerzo}
    req = urllib.request.Request(URL, data=json.dumps(cuerpo).encode("utf-8"),
                                 headers={"Content-Type": "application/json", "Authorization": f"Bearer {clave}"})
    for espera in (0, 20, 60, 180):
        if espera:
            print(f"   reintento de red en {espera} s"); time.sleep(espera)
        try:
            with urllib.request.urlopen(req, timeout=1800) as f:
                return json.loads(f.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            msg = e.read().decode("utf-8", "replace")[:500]
            if e.code in (429, 500, 502, 503, 504):
                print(f"   HTTP {e.code}: {msg}"); continue
            sys.exit(f"HTTP {e.code}: {msg}")
        except (urllib.error.URLError, TimeoutError) as e:
            print(f"   error de red: {e}")
    sys.exit("La API no respondió tras varios intentos.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--modelo", default="deepseek-v4-pro")
    ap.add_argument("--esfuerzo", default="high")
    ap.add_argument("--solo", default="")
    ap.add_argument("--reintentos", type=int, default=2)
    ap.add_argument("--estimar", action="store_true")
    a = ap.parse_args()
    tareas = [t.strip().upper() for t in a.solo.split(",") if t.strip()] or ORDEN
    prompts = cargar_prompts()
    os.makedirs(CRUDO, exist_ok=True)

    if a.estimar:
        tok_in = 0
        for t in tareas:
            tok_in += len(armar_prompt(prompts, t, open(os.path.join(ENTRADA, archivo_tarea(t)), encoding="utf-8").read())) / 3.0
        tok_out = len(tareas) * 25000  # respuesta visible + razonamiento, estimación conservadora
        pi, po = PRECIO.get(a.modelo, (0, 0))
        costo = tok_in / 1e6 * pi + tok_out / 1e6 * po
        print(f"{len(tareas)} tareas · entrada ≈ {tok_in/1e3:.0f} k tokens · salida ≈ {tok_out/1e3:.0f} k tokens")
        print(f"Costo estimado con {a.modelo} en horario pico, sin caché: ≈ USD {costo:.2f} (fuera de pico, la mitad).")
        print("Los reintentos por formato inválido pueden sumar algo más.")
        return

    clave = clave_api()
    gasto_in = gasto_out = 0
    for t in tareas:
        destino = os.path.join(SALIDA, archivo_tarea(t))
        entrada_txt = open(os.path.join(ENTRADA, archivo_tarea(t)), encoding="utf-8").read()
        entrada = json.loads(entrada_txt)
        if os.path.exists(destino):
            e, _ = validar(t, entrada, json.load(open(destino, encoding="utf-8")))
            if not e:
                print(f"{t}: ya existe y es válida, se omite"); continue
        prompt = armar_prompt(prompts, t, entrada_txt)
        mensajes = [{"role": "user", "content": prompt}]
        h = hashlib.sha256(prompt.encode("utf-8")).hexdigest()[:12]
        for intento in range(1, a.reintentos + 2):
            print(f"{t}: intento {intento} ({hora_panama()} Panamá)…", flush=True)
            t0 = time.time()
            r = llamar(clave, a.modelo, a.esfuerzo, mensajes)
            dur = round(time.time() - t0, 1)
            msg = r["choices"][0]["message"]
            texto = msg.get("content") or ""
            razon = msg.get("reasoning_content") or ""
            u = r.get("usage", {})
            gasto_in += u.get("prompt_tokens", 0); gasto_out += u.get("completion_tokens", 0)
            open(os.path.join(CRUDO, f"{t}_intento{intento}.txt"), "w", encoding="utf-8").write(texto)
            if razon:
                open(os.path.join(CRUDO, f"{t}_intento{intento}_razonamiento.txt"), "w", encoding="utf-8").write(razon)
            try:
                lista = extraer_lista(texto); errores, orden = validar(t, entrada, lista)
            except (ValueError, json.JSONDecodeError) as e:
                errores, orden = [f"JSON no válido: {e}"], None
            with open(LOG, "a", encoding="utf-8") as f:
                f.write(json.dumps({"tarea": t, "intento": intento, "hora_panama": hora_panama(),
                                    "modelo_pedido": a.modelo, "modelo_respuesta": r.get("model"),
                                    "esfuerzo": a.esfuerzo, "fin": r["choices"][0].get("finish_reason"),
                                    "uso": u, "duracion_s": dur, "sha_prompt": h, "valido": not errores,
                                    "n_errores": len(errores)}, ensure_ascii=False) + "\n")
            if not errores:
                json.dump(orden, open(destino, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
                print(f"   OK · {u.get('prompt_tokens')} in / {u.get('completion_tokens')} out · {dur} s")
                break
            print(f"   salida no válida ({len(errores)} problemas): {errores[:3]}")
            mensajes = mensajes + [{"role": "assistant", "content": texto},
                                   {"role": "user", "content": "Tu salida no cumple el formato pedido. Problemas:\n- "
                                    + "\n- ".join(errores[:40]) +
                                    "\nCorrige solo esos problemas, sin cambiar los demás juicios, y responde ÚNICAMENTE con la lista JSON completa de 24 objetos."}]
        else:
            print(f"{t}: SIN salida válida tras {a.reintentos + 1} intentos; revisar salida/crudo/")
    pi, po = PRECIO.get(a.modelo, (0, 0))
    print(f"\nTokens usados: {gasto_in} entrada, {gasto_out} salida · costo ≤ USD {gasto_in/1e6*pi + gasto_out/1e6*po:.2f} (tarifa pico)")
    hechas = [t for t in ORDEN if os.path.exists(os.path.join(SALIDA, archivo_tarea(t)))]
    print(f"Salidas válidas en salida/: {len(hechas)} de 29")


if __name__ == "__main__":
    main()
