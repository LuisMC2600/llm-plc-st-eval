# -*- coding: utf-8 -*-
"""
c03_tablas_y_verificacion.py  (Agente C, borrador v0.3, 2026-10-12)

A partir de clasificacion_fallos_cwe.csv (salida de c02) calcula:
  1. Concordancia del mapa de pasos v1 con la lectura del codigo en la muestra
     estratificada de 36 respuestas (una por modelo x tarea entre las filas
     clasificadas por paso con el mapa v1): verificacion_mapa_pasos_v1.csv.
  2. Porcentaje clasificado por cada metodo (automatico / paso_harness / juicio).
  3. Frecuencias por categoria y modelo, nivel y estrategia; por CWE.
  4. Presencia de cada categoria en cualquier paso fallido (fallos de logica).
  5. Subtipos de los fallos de compilacion por modelo.
  6. Indicador automatico adicional: respuestas que declaran un temporizador TP
     (regex sobre el codigo de las 600 respuestas) por modelo y estrategia, y su
     tasa de acierto en el criterio 1.
Uso:  python c03_tablas_y_verificacion.py
"""
import os
import re
import pandas as pd

AQUI = os.path.dirname(os.path.abspath(__file__))
# Carpeta data/ del repositorio (llm-plc-st-eval/data), relativa a este archivo.
RAIZ = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "data")
CLAS = os.path.join(AQUI, "clasificacion_fallos_cwe.csv")
VERIF = os.path.join(AQUI, "verificacion_mapa_pasos_v1.csv")
ORDEN_M = ["Gemini", "Claude", "GPT-4o", "Qwen"]
ORDEN_C = ["CONSTRUCCION", "CONVERSION", "DIALECTO", "INTERFAZ", "TEMPORIZACION",
           "SECUENCIA", "SEGURIDAD", "INICIALIZACION", "FLANCO", "CALCULO"]
ORDEN_N = ["Basico", "Intermedio", "Avanzado", "Complementaria"]
pd.set_option("display.width", 200)


def pct(a, b):
    return f"{100 * a / b:.1f} %" if b else "-"


def main():
    o = pd.read_csv(CLAS, dtype=str)
    n = len(o)

    print("=" * 78)
    print("1. VERIFICACION DEL MAPA DE PASOS v1 FRENTE A LA LECTURA DEL CODIGO")
    v = pd.read_csv(VERIF)
    v1 = os.path.join(AQUI, "clasificacion_fallos_cwe_mapa_v1.csv")
    if os.path.exists(v1):
        c1 = pd.read_csv(v1, dtype=str)
        p1 = c1[c1["metodo"] == "paso_harness"].sort_values(["modelo_corto", "tarea", "estrategia", "ejec"])
        muestra = p1.groupby(["modelo_corto", "tarea"]).head(1)
        k1 = set(map(tuple, muestra[["modelo", "tarea", "estrategia", "ejec"]].values))
        k2 = set(map(tuple, v[["modelo", "tarea", "estrategia", "ejec"]].values))
        print(f"Filas por paso con el mapa v1: {len(p1)}; grupos modelo x tarea: {len(muestra)}; "
              f"la muestra verificada coincide con la regla de seleccion: {k1 == k2}")
        cat_v1 = muestra.set_index(["modelo", "tarea", "estrategia", "ejec"])["categoria_plc"]
        cat_ok = all(cat_v1[(r.modelo, r.tarea, r.estrategia, r.ejec)] == r.categoria_mapa_v1 for r in v.itertuples())
        print(f"Categorias del mapa v1 en la tabla de verificacion coinciden con la clasificacion v1: {cat_ok}")
    ac = int(v["coincide"].sum())
    print(f"Muestra: {len(v)} respuestas (una por modelo x tarea). Coinciden: {ac}/{len(v)} = {pct(ac, len(v))}")
    print("Discrepancias (paso -> categoria del mapa v1 -> categoria por codigo):")
    for _, r in v[v["coincide"] == 0].iterrows():
        print(f"  {r['modelo'][:6]:6s} {r['tarea']} {r['estrategia'][:4]} {r['ejec']} paso {r['paso_primario']}: "
              f"{r['categoria_mapa_v1']} -> {r['categoria_codigo']}")

    print("\n" + "=" * 78)
    print("2. METODO DE CLASIFICACION")
    for k in ["automatico", "paso_harness", "juicio"]:
        c = int((o["metodo"] == k).sum())
        print(f"  {k:13s} {c:4d}/{n} = {pct(c, n)}")
    lg = o[o["c1_categoria"] == "FALLA_LOGICA"]
    for k in ["paso_harness", "juicio"]:
        c = int((lg["metodo"] == k).sum())
        print(f"  dentro de FALLA_LOGICA, {k:12s} {c:4d}/{len(lg)} = {pct(c, len(lg))}")
    print("  juicio por modelo:", o[o["metodo"] == "juicio"]["modelo_corto"].value_counts().to_dict())

    print("\n" + "=" * 78)
    print("3a. CATEGORIA x MODELO (conteos)")
    t = pd.crosstab(o["categoria_plc"], o["modelo_corto"]).reindex(index=ORDEN_C, columns=ORDEN_M, fill_value=0)
    t["Total"] = t.sum(axis=1)
    t.loc["Total"] = t.sum()
    print(t.to_string())
    print("\n3b. CATEGORIA x MODELO (% de los fallos de cada modelo)")
    tp = t.drop(index="Total")
    print((100 * tp / tp.sum()).round(1).to_string())
    print("\n3c. CATEGORIA x MODELO (% de las 150 respuestas de codigo de cada modelo)")
    print((100 * tp[ORDEN_M] / 150).round(1).to_string())

    print("\n3d. CATEGORIA x NIVEL")
    tn = pd.crosstab(o["categoria_plc"], o["nivel"]).reindex(index=ORDEN_C, columns=ORDEN_N, fill_value=0)
    tn["Total"] = tn.sum(axis=1)
    tn.loc["Total"] = tn.sum()
    print(tn.to_string())
    print("   % de los fallos de cada nivel:")
    tnp = tn.drop(index="Total")
    print((100 * tnp / tnp.sum()).round(1).to_string())

    print("\n3e. CATEGORIA x ESTRATEGIA")
    te = pd.crosstab(o["categoria_plc"], o["estrategia"]).reindex(index=ORDEN_C, fill_value=0)
    te["Total"] = te.sum(axis=1)
    te.loc["Total"] = te.sum()
    print(te.to_string())
    print("\n3f. CATEGORIA x MODELO x ESTRATEGIA")
    tme = pd.crosstab(o["categoria_plc"], [o["modelo_corto"], o["estrategia"]]).reindex(index=ORDEN_C, fill_value=0)
    print(tme.to_string())

    g4 = o[o["modelo_corto"] == "GPT-4o"]
    t_intf_zero = set(g4[(g4["estrategia"] == "zero_shot") & (g4["categoria_plc"] == "INTERFAZ")]["tarea"])
    tf = g4[(g4["estrategia"] == "few_shot") & (g4["categoria_plc"] == "TEMPORIZACION")]
    print(f"\n3f-bis. GPT-4o: fallos de temporizacion con few-shot en tareas cuyo zero-shot fallo por interfaz: "
          f"{tf['tarea'].isin(t_intf_zero).sum()}/{len(tf)} (tareas con interfaz en zero-shot: {sorted(t_intf_zero)})")
    print("\n3g. CATEGORIA x TIER (c1_categoria)")
    print(pd.crosstab(o["categoria_plc"], o["c1_categoria"]).reindex(index=ORDEN_C, fill_value=0).to_string())

    print("\n3h. CWE x MODELO")
    tc = pd.crosstab([o["cwe_id"], o["cwe_nombre"]], o["modelo_corto"]).reindex(columns=ORDEN_M, fill_value=0)
    tc["Total"] = tc.sum(axis=1)
    print(tc.sort_values("Total", ascending=False).to_string())
    # Nivel de abstraccion y uso para mapeo segun cwe.mitre.org (CWE 4.20, consultado 2026-10-12)
    USO = {"CWE-710": ("Pilar", "Discouraged"), "CWE-704": ("Clase", "Allowed-with-review"),
           "CWE-758": ("Clase", "Allowed-with-review"), "CWE-589": ("Variante", "Allowed"),
           "CWE-684": ("Clase", "Allowed-with-review"), "CWE-754": ("Clase", "Allowed-with-review"),
           "CWE-696": ("Clase", "Allowed-with-review"), "CWE-670": ("Clase", "Allowed-with-review"),
           "CWE-665": ("Clase", "Discouraged"), "CWE-456": ("Variante", "Allowed"),
           "CWE-372": ("Base", "Discouraged"), "CWE-628": ("Base", "Allowed"),
           "CWE-561": ("Base", "Allowed"), "CWE-20": ("Clase", "Discouraged"),
           "CWE-129": ("Variante", "Allowed"), "CWE-682": ("Pilar", "Discouraged"),
           "CWE-697": ("Pilar", "Discouraged")}
    o["uso_mapeo"] = o["cwe_id"].map(lambda c: USO[c][1])
    o["abstraccion"] = o["cwe_id"].map(lambda c: USO[c][0])
    print("\n3h-bis. Respuestas segun el uso para mapeo de la entrada CWE asignada")
    for k, c in o["uso_mapeo"].value_counts().items():
        print(f"  {k:20s} {c:4d}/{n} = {pct(c, n)}")
    print("  por nivel de abstraccion:", o["abstraccion"].value_counts().to_dict())
    print("\n3i. CWE x CATEGORIA")
    print(pd.crosstab(o["cwe_id"], o["categoria_plc"]).reindex(columns=ORDEN_C, fill_value=0).to_string())

    print("\n" + "=" * 78)
    print("4. PRESENCIA EN CUALQUIER PASO FALLIDO (139 fallos de logica)")
    pres = {c: 0 for c in ORDEN_C}
    pres_m = {m: {c: 0 for c in ORDEN_C} for m in ORDEN_M}
    for _, r in lg.iterrows():
        for c in str(r["categorias_todos_pasos"]).split("|"):
            if c in pres:
                pres[c] += 1
                pres_m[r["modelo_corto"]][c] += 1
    ncats = lg["categorias_todos_pasos"].fillna("").map(lambda s: len([x for x in s.split("|") if x]))
    for c in ORDEN_C:
        if pres[c]:
            print(f"  {c:15s} {pres[c]:3d}/{len(lg)} = {pct(pres[c], len(lg))}  "
                  + "  ".join(f"{m} {pres_m[m][c]}" for m in ORDEN_M))
    print(f"  Fallos de logica con una sola categoria en sus pasos: {(ncats == 1).sum()}; "
          f"con dos o mas: {(ncats >= 2).sum()}")

    print("\n" + "=" * 78)
    print("5. SUBTIPOS DE NO_COMPILA x MODELO")
    nc = o[o["c1_categoria"] == "NO_COMPILA"]
    print(pd.crosstab(nc["subtipo"], nc["modelo_corto"]).reindex(columns=ORDEN_M, fill_value=0).to_string())
    print("\nSubtipos de los fallos de logica clasificados por juicio (texto de la justificacion):")
    j = o[o["metodo"] == "juicio"]
    pat = {"TP en lugar de TON/TOF": r"\bTP\b", "TON no invocado en cada ciclo o reiniciado": r"invoca|reinici|sin invocarlo|IN en FALSE",
           "TOF emulado con TON": r"emula con un TON", "conteo por nivel o sin evento": r"por nivel|rama ELSE",
           "memoria de flanco actualizada antes de comparar": r"antes de la comparacion|antes de comparar"}
    for k, p in pat.items():
        print(f"  {k:48s} {j['evidencia'].str.contains(p, regex=True).sum()}")

    print("\n" + "=" * 78)
    print("6. INDICADOR AUTOMATICO: RESPUESTAS QUE DECLARAN UN TP (600 respuestas de codigo)")
    df = pd.read_csv(os.path.join(RAIZ, "results", "tabla_definitivo.csv"), encoding="utf-8-sig")
    usa = []
    for _, r in df.iterrows():
        ruta = os.path.join(RAIZ, "processed_definitivo", r["modelo"], r["tarea"], r["estrategia"], f"{r['ejec']}.st")
        s = open(ruta, encoding="utf-8", errors="replace").read()
        s = re.sub(r"\(\*.*?\*\)", "", s, flags=re.S)
        s = re.sub(r"//[^\n]*", "", s)
        usa.append(bool(re.search(r":\s*TP\s*;", s)))
    df["usa_tp"] = usa
    df["m"] = df["modelo"].map({"gemini-3.1-pro-preview": "Gemini", "claude-sonnet-4-6": "Claude",
                                "gpt-4o-2024-08-06": "GPT-4o", "qwen2.5-coder_14b": "Qwen"})
    g = df.groupby(["m", "estrategia"]).agg(n=("usa_tp", "size"), con_tp=("usa_tp", "sum"))
    print(g.reindex(ORDEN_M, level=0).to_string())
    a = df[df["usa_tp"]]
    b = df[~df["usa_tp"]]
    print(f"Con TP: {len(a)} respuestas; pasan el criterio 1: {(a['c1_categoria'] == 'PASA').sum()} "
          f"({pct((a['c1_categoria'] == 'PASA').sum(), len(a))})")
    print(f"Sin TP: {len(b)} respuestas; pasan el criterio 1: {(b['c1_categoria'] == 'PASA').sum()} "
          f"({pct((b['c1_categoria'] == 'PASA').sum(), len(b))})")
    q = df[(df["m"] == "Qwen") & (df["estrategia"] == "few_shot") & df["usa_tp"]]
    print(f"Qwen few-shot con TP: {len(q)} en {q['tarea'].nunique()} tareas "
          f"({', '.join(sorted(q['tarea'].unique()))}); pasan: {(q['c1_categoria'] == 'PASA').sum()}")
    tareas_tp = sorted(q["tarea"].unique())
    qq = df[df["m"] == "Qwen"]
    print("Qwen: aciertos del criterio 1 en las tareas donde adopto TP con few-shot frente al resto (exploratorio):")
    for e in ["zero_shot", "few_shot"]:
        x = qq[(qq["estrategia"] == e) & qq["tarea"].isin(tareas_tp)]
        y = qq[(qq["estrategia"] == e) & ~qq["tarea"].isin(tareas_tp)]
        print(f"  {e:9s} tareas con TP: {(x['c1_categoria'] == 'PASA').sum()}/{len(x)}   "
              f"resto: {(y['c1_categoria'] == 'PASA').sum()}/{len(y)}   "
              f"(respuestas con TP en esas tareas: {int(x['usa_tp'].sum())})")
    print("Tareas con TP por modelo y estrategia:")
    print(a.groupby(["m", "estrategia", "tarea"]).size().to_string())
    return 0


if __name__ == "__main__":
    main()
