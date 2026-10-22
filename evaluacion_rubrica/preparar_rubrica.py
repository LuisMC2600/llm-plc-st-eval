# -*- coding: utf-8 -*-
"""Prepara la evaluacion A CIEGAS con la rubrica de 5 criterios x 4 niveles sobre las 600
respuestas de codigo (25 tareas T1 y T4). No modifica data/definitivo ni data/processed_definitivo.

- Asigna un codigo aleatorio a cada respuesta y baraja el orden dentro de cada tarea.
- Elige la submuestra del segundo evaluador: 3 respuestas por tarea, de 3 modelos distintos (75).
- Precalcula lo que sale de CODESYS segun las reglas del instructivo de Fichas_Evaluacion.xlsx:
    no compila            -> Cumplimiento IEC = 0 y Correccion funcional = 0 (fijos)
    pasa todos los pasos  -> Correccion funcional = 3 (fijo)
    el resto lo puntua el evaluador.
- Escribe: _SELLADO_asignacion_rubrica.csv (NO ABRIR hasta terminar), paquete_rubrica.json
  y un HTML por tarea y por evaluador con enunciado, protocolo de prueba y respuestas por codigo.
Semilla fija: reproducible. Uso (desde llm-plc-st-eval): python evaluacion_rubrica/preparar_rubrica.py"""
import csv, json, os, random, hashlib, html, re
SEMILLA = 20261008; AQUI = "evaluacion_rubrica"
rng = random.Random(SEMILLA)
TAREAS = {t["id"]: t for t in json.load(open("src/tasks.json", encoding="utf-8"))["tareas"]}
T = list(csv.DictReader(open("data/results/tabla_definitivo.csv", encoding="utf-8-sig")))
assert len(T) == 600
orden_t = sorted({r["tarea"] for r in T}, key=lambda x: ("BIAC".index(x[0]), int(x[1:])))
SIM = {}
for f in ("definitivo_gemini.csv", "definitivo_claude.csv", "definitivo_gpt4o.csv", "definitivo_qwen.csv", "definitivo_c7c8.csv"):
    for r in csv.DictReader(open("data/results_codesys/" + f, encoding="latin-1")):
        mo, es, ej = r["id"].split("|"); SIM[(mo, r["tarea"], es, ej)] = r
HARNESS = {"C7": "B3", "C8": "B2"}
def protocolo(t):
    h = HARNESS.get(t, t); ruta = "codesys/PRG_Test_%s.st" % h
    if not os.path.exists(ruta): ruta = "codesys/PRG_Test_%s_FB.st" % h
    txt = open(ruta, encoding="utf-8", errors="replace").read()
    m = re.search(r"CASE\s+paso\s+OF(.*?)END_CASE", txt, re.S | re.I)
    cab = re.search(r"\(\*(.*?)\*\)", txt, re.S)
    return ("Harness: %s\n\n" % os.path.basename(ruta)) + (cab.group(1).strip() if cab else "") + ("\n\n--- Pasos (CASE paso OF) ---\n" + m.group(1).rstrip() if m else "")
numeros = rng.sample(range(1000, 10000), 600); filas, paquete = [], {"semilla": SEMILLA, "tareas": {}}
for t in orden_t:
    items = [dict(r) for r in T if r["tarea"] == t]; assert len(items) == 24
    rng.shuffle(items)
    for it in items: it["codigo"] = "%s-%d" % (t, numeros.pop())
    mods = rng.sample(sorted({it["modelo"] for it in items}), 3)
    sub = {rng.choice([it["codigo"] for it in items if it["modelo"] == m]) for m in mods}
    resp = []
    for orden, it in enumerate(items, 1):
        s = SIM[(it["modelo"], t, it["estrategia"], it["ejec"])]
        codigo_st = open(os.path.join("data", "processed_definitivo", it["modelo"], t, it["estrategia"], it["ejec"] + ".st"), encoding="utf-8").read()
        cat = it["c1_categoria"]; res = [x for x in s["resultado"].split(",") if x]
        if cat == "PASA": auto = "Compila. Pasa los %d pasos del harness." % len(res)
        elif cat == "FALLA_LOGICA": auto = "Compila. Falla %d de %d pasos del harness (pasos %s; numerados desde 0)." % (len([x for x in res if x == "2"]), len(res), s["pasos_fallidos"])
        elif cat == "INTERFAZ_NO_CONFORME": auto = "Compila sola, pero no se pudo simular: declara las entradas donde el harness no puede escribirlas (%s)." % s["nota"][:120]
        else: auto = "No compila (%s errores)." % it["n_errores"]
        resp.append({"codigo": it["codigo"], "evaluador2": it["codigo"] in sub, "categoria": cat, "compila": int(it["c2_compila"]),
                     "resumen_codesys": auto, "errores": it["errores_texto"] if cat == "NO_COMPILA" else "", "texto": codigo_st,
                     "func_fijo": 3 if cat == "PASA" else (0 if cat == "NO_COMPILA" else None), "iec_fijo": 0 if cat == "NO_COMPILA" else None})
        filas.append({"codigo": it["codigo"], "tarea": t, "orden_en_ficha": orden, "evaluador2": int(it["codigo"] in sub), "modelo": it["modelo"],
                      "estrategia": it["estrategia"], "ejec": it["ejec"], "c2_compila": it["c2_compila"], "c1_categoria": cat,
                      "sha256_codigo": hashlib.sha256(codigo_st.encode("utf-8")).hexdigest()[:16]})
    paquete["tareas"][t] = {"titulo": TAREAS[t]["titulo"], "nivel": TAREAS[t]["nivel"], "respuestas": [{k: v for k, v in x.items() if k != "texto"} for x in resp]}
    # HTML por tarea y evaluador
    css = """body{font-family:Arial,Helvetica,sans-serif;margin:0;background:#f4f5f7;color:#1c1e21;line-height:1.45}
header{background:#1f4e78;color:#fff;padding:16px 28px}header h1{margin:0;font-size:19px}header p{margin:6px 0 0;font-size:13px;opacity:.9}
main{max-width:1000px;margin:0 auto;padding:10px 28px 60px}.caja{background:#fff;border:1px solid #d0d4da;border-radius:6px;padding:14px 18px;margin:14px 0}
.resp{border-left:5px solid #1f4e78}.cod{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:8px}h3{margin:0;font-size:16px}
.cod span{font-size:12px;color:#5f6670}pre{white-space:pre-wrap;word-wrap:break-word;font-family:Consolas,'Courier New',monospace;font-size:13px;margin:0}
.auto{background:#eef4fb;border:1px solid #b9cfe8;border-radius:4px;padding:8px 10px;margin-bottom:10px;font-size:13px}.err{color:#8a1c1c;font-size:12px;margin-top:6px}
details summary{cursor:pointer;font-weight:bold;color:#1f4e78}.idx a{display:inline-block;margin:2px 8px 2px 0;font-size:13px;color:#1f4e78}
@media print{.caja{break-inside:avoid}}"""
    for ev, solo in (("Evaluador1", False), ("Evaluador2", True)):
        rs = [x for x in resp if x["evaluador2"] or not solo]
        h = ['<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>%s — respuestas a ciegas</title><style>%s</style></head><body>' % (t, css)]
        h.append('<header><h1>%s — %s (%s)</h1><p>%d respuestas identificadas solo por código. Puntúalas en la hoja %s de la ficha, en este orden.</p></header><main>' % (t, html.escape(TAREAS[t]["titulo"]), TAREAS[t]["nivel"], len(rs), t))
        h.append('<div class="caja"><details open><summary>Enunciado que recibieron los modelos (versión zero-shot)</summary><pre>%s</pre></details></div>' % html.escape(TAREAS[t]["prompts"]["zero_shot"]))
        h.append('<div class="caja"><details><summary>Protocolo de prueba: pasos del harness con que se simuló cada respuesta</summary><pre>%s</pre></details></div>' % html.escape(protocolo(t)))
        h.append('<div class="caja idx"><b>Códigos, en orden:</b><br>' + "".join('<a href="#%s">%s</a>' % (x["codigo"], x["codigo"]) for x in rs) + "</div>")
        for i, x in enumerate(rs, 1):
            err = ('<div class="err">Mensajes del compilador: %s</div>' % html.escape(x["errores"])) if x["errores"] else ""
            h.append('<div class="caja resp" id="%s"><div class="cod"><h3>%s</h3><span>%d de %d</span></div><div class="auto"><b>Resultado en CODESYS:</b> %s%s</div><pre>%s</pre></div>' % (x["codigo"], x["codigo"], i, len(rs), html.escape(x["resumen_codesys"]), err, html.escape(x["texto"])))
        h.append("</main></body></html>")
        os.makedirs(os.path.join(AQUI, ev, "respuestas"), exist_ok=True)
        open(os.path.join(AQUI, ev, "respuestas", "Respuestas_%s.html" % t), "w", encoding="utf-8").write("\n".join(h))
with open(os.path.join(AQUI, "_SELLADO_asignacion_rubrica.csv"), "w", newline="", encoding="utf-8-sig") as fh:
    w = csv.DictWriter(fh, fieldnames=list(filas[0].keys())); w.writeheader(); w.writerows(filas)
json.dump(paquete, open(os.path.join(AQUI, "paquete_rubrica.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
import collections
print("Respuestas: %d | codigos unicos: %d | submuestra evaluador 2: %d" % (len(filas), len({f["codigo"] for f in filas}), sum(f["evaluador2"] for f in filas)))
print("Categorias:", dict(collections.Counter(f["c1_categoria"] for f in filas)))
