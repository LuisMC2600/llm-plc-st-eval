# -*- coding: utf-8 -*-
"""
c02_clasificar_errores.py  (Agente C, borrador v0.3, 2026-10-12)

Clasifica las 249 respuestas de codigo que no pasaron el banco de prueba
(criterio 1) en la taxonomia de errores PLC mapeada a CWE.

Regla de metodo (acordada con el autor):
  1. NO_COMPILA (82): reglas deterministas (expresiones regulares) sobre los
     mensajes de CODESYS (`errores_texto`) y, cuando el mensaje es generico
     ("Se esperaba ';' en lugar de ..."), sobre el texto del codigo para
     identificar la construccion que lo provoca. metodo = automatico.
  2. INTERFAZ_NO_CONFORME (28): mensaje de CODESYS en la simulacion
     ("'x' no es ninguna entrada de 'FB'") sobre una respuesta que compila sola.
     metodo = automatico.
  3. FALLA_LOGICA (139): primer paso fallido del banco de prueba + mapa
     tabulado paso -> requisito (mapa_pasos_harness.csv). Si el primer paso
     fallido aisla un requisito, metodo = paso_harness. Si el paso es NOMINAL
     (funcion basica, no aisla causa) o AMBIGUO (mezcla dos requisitos), la
     categoria se toma de juicio_llm.csv (lectura del codigo por el agente LLM),
     metodo = juicio.
Ademas se registran las categorias de TODOS los pasos fallidos (presencia).

Entradas (solo lectura): insumos/datos/results/tabla_definitivo.csv,
  insumos/datos/results_codesys/definitivo_*.csv,
  insumos/datos/processed_definitivo/<modelo>/<tarea>/<estrategia>/<ejec>.st,
  mapa_pasos_harness.csv (version 2 del mapa) y juicio_llm.csv (esta carpeta).
  La version 1 del mapa (mapa_pasos_harness_v1.csv) se contrasto con la lectura
  del codigo en una muestra de 36 respuestas (verificacion_mapa_pasos_v1.csv,
  script c03); la version 2 marca como AMBIGUO los pasos que esa verificacion
  mostro no discriminantes (A2-8, I2-2, I5-0, B5-0) y recategoriza A3-7.
Salida: clasificacion_fallos_cwe.csv (esta carpeta).
Uso:  python c02_clasificar_errores.py
"""
import os
import re
import sys
import pandas as pd

AQUI = os.path.dirname(os.path.abspath(__file__))
# Carpeta data/ del repositorio (llm-plc-st-eval/data), relativa a este archivo.
RAIZ = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "data")
TABLA = os.path.join(RAIZ, "results", "tabla_definitivo.csv")
SIMS = ["definitivo_gpt4o.csv", "definitivo_claude.csv", "definitivo_gemini.csv",
        "definitivo_qwen.csv", "definitivo_c7c8.csv"]
CODIGO = os.path.join(RAIZ, "processed_definitivo")
MAPA = os.path.join(AQUI, "mapa_pasos_harness.csv")
JUICIO = os.path.join(AQUI, "juicio_deepseek.csv")  # oficial desde 2026-10-13 (DeepSeek a ciegas); juicio_llm.csv (Claude) queda como segundo evaluador
SALIDA = os.path.join(AQUI, "clasificacion_fallos_cwe.csv")

CORTO = {"gemini-3.1-pro-preview": "Gemini", "claude-sonnet-4-6": "Claude",
         "gpt-4o-2024-08-06": "GPT-4o", "qwen2.5-coder_14b": "Qwen"}
HARNESS = {"C7": "B3", "C8": "B2"}          # C7 y C8 reutilizan los bancos de B3 y B2

CATEGORIAS = {
    "CONSTRUCCION": "Construccion o identificador no valido",
    "CONVERSION": "Conversion de tipos no conforme",
    "DIALECTO": "Dependencia del dialecto del compilador",
    "INTERFAZ": "Interfaz de POU no conforme",
    "SEGURIDAD": "Paro, enclavamiento y condiciones anomalas",
    "TEMPORIZACION": "Temporizacion incorrecta",
    "FLANCO": "Deteccion de flanco y conteo de eventos",
    "SECUENCIA": "Secuencia, memoria y estados",
    "INICIALIZACION": "Inicializacion y reinicio",
    "CALCULO": "Calculo, umbral y validacion de rango",
}
CWE_NOMBRE = {  # nombres oficiales verificados en cwe.mitre.org (CWE 4.20)
    "CWE-20": "Improper Input Validation",
    "CWE-129": "Improper Validation of Array Index",
    "CWE-372": "Incomplete Internal State Distinction",
    "CWE-456": "Missing Initialization of a Variable",
    "CWE-561": "Dead Code",
    "CWE-589": "Call to Non-ubiquitous API",
    "CWE-628": "Function Call with Incorrectly Specified Arguments",
    "CWE-665": "Improper Initialization",
    "CWE-670": "Always-Incorrect Control Flow Implementation",
    "CWE-682": "Incorrect Calculation",
    "CWE-684": "Incorrect Provision of Specified Functionality",
    "CWE-696": "Incorrect Behavior Order",
    "CWE-697": "Incorrect Comparison",
    "CWE-704": "Incorrect Type Conversion or Cast",
    "CWE-710": "Improper Adherence to Coding Standards",
    "CWE-754": "Improper Check for Unusual or Exceptional Conditions",
    "CWE-758": "Reliance on Undefined, Unspecified, or Implementation-Defined Behavior",
}

# --------------------------------------------------------------------------
# Reglas deterministas para NO_COMPILA. Se aplican EN ORDEN; gana la primera
# que coincide. Cada regla: (id, subtipo, categoria, cwe, patron_error, patron_codigo)
# patron_error se busca en errores_texto; patron_codigo en el texto del .st.
# Ambos deben coincidir cuando estan definidos (None = no se exige).
# --------------------------------------------------------------------------
M = re.MULTILINE | re.IGNORECASE
REGLAS_NC = [
    ("N01", "palabra reservada `dt` usada como identificador", "CONSTRUCCION", "CWE-710",
     re.compile(r"token inesperado 'dt'"), None),
    ("N02", "`END_STRUCT;` (forma de la gramatica IEC rechazada por CODESYS)", "DIALECTO", "CWE-758",
     re.compile(r"Se esperaba END_TYPE' en lugar de ';'"), re.compile(r"END_STRUCT\s*;", M)),
    ("N03", "entrada `R` del CTU (IEC) en lugar de `RESET` (CODESYS)", "DIALECTO", "CWE-589",
     re.compile(r"Se esperaba expresi.n en vez de 'R'"), re.compile(r"\bR\s*:=", M)),
    ("N04", "terminador inexistente `END_VAR_INPUT`/`END_VAR_OUTPUT`", "CONSTRUCCION", "CWE-710",
     None, re.compile(r"\bEND_VAR_(INPUT|OUTPUT|IN_OUT)\b", M)),
    ("N05", "bloque inexistente `CONST ... END_CONST`", "CONSTRUCCION", "CWE-710",
     None, re.compile(r"^\s*END_CONST\b", M)),
    ("N06", "palabra `BEGIN` ajena al ST", "CONSTRUCCION", "CWE-710",
     None, re.compile(r"^\s*BEGIN\b", M)),
    ("N07", "palabra `ELSEIF` en lugar de `ELSIF`", "CONSTRUCCION", "CWE-710",
     None, re.compile(r"\bELSEIF\b", M)),
    ("N08", "`ELSE:` con dos puntos en una sentencia CASE", "CONSTRUCCION", "CWE-710",
     re.compile(r"Encontrado token inesperado ':'"), re.compile(r"^\s*ELSE\s*:", M)),
    ("N09", "METHOD embebido en el texto del FUNCTION_BLOCK (POO de IEC 61131-3 ed. 3 no admitida en la importación textual de CODESYS; decisión del autor 2026-10-13: dialecto)", "DIALECTO", "CWE-758",
     re.compile(r"Instrucci.n inesperada"), re.compile(r"^\s*METHOD\b", M)),
    ("N10", "etiquetas CASE superpuestas (rama inalcanzable)", "CONSTRUCCION", "CWE-561",
     re.compile(r"La etiqueta CASE .* tambi.n est. contenida"), None),
    ("N11", "TIME convertido implicitamente o con funcion erronea a REAL", "CONVERSION", "CWE-704",
     re.compile(r"El tipo 'TIME' no puede convertirse en el tipo 'REAL'"), None),
    ("N12", "funcion de conversion inexistente `REAL_TO_REAL`", "CONVERSION", "CWE-704",
     re.compile(r"Identificador 'REAL_TO_REAL' sin definir"), None),
    ("N13", "conversion con sintaxis de funcion `REAL(x)` ajena al ST", "CONVERSION", "CWE-704",
     re.compile(r"(Se esperaba expresi.n en vez de 'REAL'|Se esperaba ';' en lugar de 'REAL')"),
     re.compile(r"\bREAL\s*\(", M)),
    ("N14", "parametro inexistente de un bloque estandar (`PTR` en TON)", "CONSTRUCCION", "CWE-628",
     re.compile(r"'\w+' no es ninguna entrada de 'TON'"), None),
    ("N15", "variable no declarada", "CONSTRUCCION", "CWE-710",
     re.compile(r"Identificador '\w+' sin definir"), None),
]
REGLA_RESIDUAL = ("N99", "error de sintaxis no identificado por las reglas", "CONSTRUCCION", "CWE-710")


def leer_codigo(r):
    ruta = os.path.join(CODIGO, r["modelo"], r["tarea"], r["estrategia"], f"{r['ejec']}.st")
    with open(ruta, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def mensajes_unicos(texto, n=3):
    msgs = []
    for m in str(texto).split(" || "):
        m = re.sub(r"^L.nea [0-9]+(, columna [0-9]+)? (\((Decl|Impl)\) )?", "", m).strip()
        if m.startswith("Exception text") or m not in msgs:
            if not m.startswith("Exception text"):
                msgs.append(m)
    return "; ".join(x[:110] for x in msgs[:n])


def clasificar_no_compila(r, codigo):
    err = str(r["errores_texto"])
    coincidencias = []
    for rid, sub, cat, cwe, pe, pc in REGLAS_NC:
        if (pe is None or pe.search(err)) and (pc is None or pc.search(codigo)):
            coincidencias.append((rid, sub, cat, cwe))
    if not coincidencias:
        coincidencias = [REGLA_RESIDUAL]
    rid, sub, cat, cwe = coincidencias[0]
    otras = ",".join(c[0] for c in coincidencias[1:])
    evid = f"regla {rid}: {sub}. CODESYS: {mensajes_unicos(err)}"
    if otras:
        evid += f" [tambien coinciden: {otras}]"
    return cat, cwe, "automatico", sub, evid, rid


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--mapa", default=MAPA, help="mapa de pasos (por defecto, version 2)")
    ap.add_argument("--salida", default=SALIDA, help="CSV de salida")
    args = ap.parse_args()
    df = pd.read_csv(TABLA, encoding="utf-8-sig")
    fal = df[df["c1_categoria"] != "PASA"].copy()
    sims = pd.concat([pd.read_csv(os.path.join(RAIZ, "results_codesys", f),
                                  encoding="utf-8-sig", encoding_errors="replace")
                      for f in SIMS], ignore_index=True)
    sims[["modelo", "estrategia", "ejec"]] = sims["id"].str.split("|", expand=True)
    fal = fal.merge(sims[["modelo", "tarea", "estrategia", "ejec", "nota"]],
                    on=["modelo", "tarea", "estrategia", "ejec"], how="left")

    mapa = pd.read_csv(args.mapa, dtype={"paso": int})
    mapa_d = {(h, p): (c, w, q) for h, p, c, w, q in
              mapa[["harness", "paso", "categoria", "cwe_id", "requisito_del_paso"]].itertuples(index=False)}
    juicio = pd.read_csv(JUICIO) if os.path.exists(JUICIO) else pd.DataFrame(
        columns=["modelo", "tarea", "estrategia", "ejec", "categoria_plc", "cwe_id", "justificacion"])
    juicio_d = {(a, b, c, d): (e, f, g) for a, b, c, d, e, f, g in juicio[
        ["modelo", "tarea", "estrategia", "ejec", "categoria_plc", "cwe_id", "justificacion"]].itertuples(index=False)}

    filas, pendientes = [], []
    for _, r in fal.iterrows():
        cod = leer_codigo(r)
        paso_prim, cats_todas = "", ""
        if r["c1_categoria"] == "NO_COMPILA":
            cat, cwe, met, sub, evid, _ = clasificar_no_compila(r, cod)
        elif r["c1_categoria"] == "INTERFAZ_NO_CONFORME":
            nota = str(r["nota"])
            m = re.search(r"'(\w+)' no es ninguna entrada de '(\w+)'", nota)
            assert m and int(r["c2_compila"]) == 1, (r["modelo"], r["tarea"])
            cat, cwe, met = "INTERFAZ", "CWE-684", "automatico"
            sub = "E/S declaradas como VAR local (el banco no puede escribirlas)"
            evid = (f"compila sola (criterio 2 = 1); al instanciarla CODESYS: \"{m.group(0)}\"")
        else:  # FALLA_LOGICA
            h = HARNESS.get(r["tarea"], r["tarea"])
            pasos = [int(x) for x in str(r["pasos_fallidos"]).split(",")]
            paso_prim = pasos[0]
            cats = []
            for p in pasos:
                c = mapa_d[(h, p)][0]
                if c not in ("NOMINAL", "AMBIGUO") and c not in cats:
                    cats.append(c)
            cats_todas = "|".join(cats)
            c0, w0, q0 = mapa_d[(h, paso_prim)]
            if c0 not in ("NOMINAL", "AMBIGUO"):
                cat, cwe, met = c0, w0, "paso_harness"
                sub = q0
                evid = (f"banco {h}, primer paso fallido {paso_prim} de [{r['pasos_fallidos']}]: {q0}")
            else:
                clave = (r["modelo"], r["tarea"], r["estrategia"], r["ejec"])
                if clave not in juicio_d:
                    pendientes.append(clave + (h, paso_prim, c0, q0))
                    cat, cwe, met, sub, evid = "PENDIENTE", "", "juicio", q0, "sin juicio registrado"
                else:
                    cat, cwe, just = juicio_d[clave]
                    assert cat in CATEGORIAS and cwe in CWE_NOMBRE, (clave, cat, cwe)
                    met = "juicio"
                    sub = q0
                    if cat in cats:
                        cats.remove(cat)
                    cats_todas = "|".join([cat] + cats)
                    evid = (f"banco {h}, primer paso fallido {paso_prim} ({c0.lower()}: {q0}); "
                            f"juicio LLM sobre el codigo: {just}")
        filas.append({
            "modelo": r["modelo"], "modelo_corto": CORTO[r["modelo"]], "tarea": r["tarea"],
            "nivel": r["nivel"], "estrategia": r["estrategia"], "ejec": r["ejec"],
            "c1_categoria": r["c1_categoria"], "categoria_plc": cat,
            "categoria_nombre": CATEGORIAS.get(cat, cat), "cwe_id": cwe,
            "cwe_nombre": CWE_NOMBRE.get(cwe, ""), "metodo": met, "subtipo": sub,
            "paso_primario": "" if paso_prim == "" else str(paso_prim), "pasos_fallidos": "" if pd.isna(r["pasos_fallidos"]) else r["pasos_fallidos"],
            "categorias_todos_pasos": cats_todas, "evidencia": evid,
        })

    out = pd.DataFrame(filas)
    out.to_csv(args.salida, index=False, encoding="utf-8")
    print(f"Mapa de pasos: {os.path.basename(args.mapa)}")
    print(f"Filas clasificadas: {len(out)} (esperado 249) -> {os.path.basename(args.salida)}")
    print("\nMetodo de clasificacion:")
    mt = out["metodo"].value_counts()
    for k in ["automatico", "paso_harness", "juicio"]:
        v = int(mt.get(k, 0))
        print(f"  {k:13s} {v:4d}  {100 * v / len(out):5.1f} %")
    print("\nMetodo por c1_categoria:")
    print(pd.crosstab(out["c1_categoria"], out["metodo"], margins=True).to_string())
    print("\nReglas NO_COMPILA aplicadas:")
    nc = out[out["c1_categoria"] == "NO_COMPILA"]
    reglas = nc["evidencia"].str.extract(r"regla (N\d\d)")[0].rename("regla")
    print(reglas.value_counts().sort_index().to_string())
    print("\nCategoria x modelo:")
    print(pd.crosstab(out["categoria_plc"], out["modelo_corto"], margins=True).to_string())
    if pendientes:
        print(f"\nPENDIENTES DE JUICIO: {len(pendientes)}")
        for p in pendientes:
            print("  ", p)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
