# -*- coding: utf-8 -*-
"""
c01_verificar_tabla_causas.py  (Agente C, borrador v0.3, 2026-10-12)

Comprueba, antes de clasificar, que el universo de trabajo reproduce las cifras
ya publicadas en el documento maestro v0.2:
  - Tabla 4.6 (causas de fallo del criterio 1 por modelo): Gemini 2/0/7,
    Claude 22/0/14, GPT-4o 43/22/31, Qwen 72/6/30 (logica/interfaz/no compila).
  - 249 respuestas que no pasan el banco de prueba (600 - 351).
  - Criterio 2 global 518/600 y criterio 1 global 351/600 (Tabla 4.3).
  - Casos de sensibilidad: 18 respuestas de A1 con `dt` (seccion 4.5) y 7 con
    END_STRUCT; (INC-34).
Tambien comprueba que la simulacion por modelo (results_codesys/definitivo_*.csv)
coincide fila a fila con tabla_definitivo.csv en veredicto y pasos fallidos.

Solo lee insumos; no escribe nada salvo su salida de consola.
Uso:  python c01_verificar_tabla_causas.py
"""
import os
import sys
import pandas as pd

# Carpeta data/ del repositorio (llm-plc-st-eval/data), relativa a este archivo.
RAIZ = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "data")
TABLA = os.path.join(RAIZ, "results", "tabla_definitivo.csv")
SIMS = ["definitivo_gpt4o.csv", "definitivo_claude.csv", "definitivo_gemini.csv",
        "definitivo_qwen.csv", "definitivo_c7c8.csv"]

CORTO = {"gemini-3.1-pro-preview": "Gemini", "claude-sonnet-4-6": "Claude",
         "gpt-4o-2024-08-06": "GPT-4o", "qwen2.5-coder_14b": "Qwen"}
ESPERADO_T46 = {"Gemini": (2, 0, 7), "Claude": (22, 0, 14),
                "GPT-4o": (43, 22, 31), "Qwen": (72, 6, 30)}


def main():
    df = pd.read_csv(TABLA, encoding="utf-8-sig")
    ok = True
    print(f"Filas en tabla_definitivo.csv: {len(df)} (esperado 600)")
    ok &= len(df) == 600

    df["m"] = df["modelo"].map(CORTO)
    ct = pd.crosstab(df["m"], df["c1_categoria"])
    print("\nCruce modelo x c1_categoria:")
    print(ct.to_string())

    print("\nTabla 4.6 del maestro (logica / interfaz / no compila):")
    for m, (l, i, n) in ESPERADO_T46.items():
        obs = (int(ct.loc[m, "FALLA_LOGICA"]), int(ct.loc[m, "INTERFAZ_NO_CONFORME"]),
               int(ct.loc[m, "NO_COMPILA"]))
        coincide = obs == (l, i, n)
        ok &= coincide
        print(f"  {m:7s} esperado {l}/{i}/{n}  observado {obs[0]}/{obs[1]}/{obs[2]}  "
              f"{'OK' if coincide else 'DISCREPANCIA'}")

    fallidas = df[df["c1_categoria"] != "PASA"]
    print(f"\nRespuestas que no pasan el banco de prueba: {len(fallidas)} (esperado 249)")
    ok &= len(fallidas) == 249
    print(f"Criterio 2 global: {int(df['c2_compila'].sum())}/600 (esperado 518)")
    ok &= int(df["c2_compila"].sum()) == 518
    print(f"Criterio 1 global: {int((df['c1_categoria'] == 'PASA').sum())}/600 (esperado 351)")
    ok &= int((df["c1_categoria"] == "PASA").sum()) == 351

    dt_a1 = df[(df["tarea"] == "A1") & (df["caso_dt"] == 1)]
    dt_todas = df[df["caso_dt"] == 1]
    print(f"\nRespuestas de A1 con `dt` (caso_dt=1): {len(dt_a1)} (esperado 18, seccion 4.5)")
    print(f"Respuestas con `dt` en cualquier tarea: {len(dt_todas)} "
          f"(tareas: {sorted(dt_todas['tarea'].unique())})")
    print(dt_todas.groupby(["tarea", "m"]).size().to_string())
    es = df[df["caso_end_struct"] == 1]
    print(f"Respuestas con END_STRUCT; (caso_end_struct=1): {len(es)} (esperado 7, INC-34)")
    ok &= len(dt_a1) == 18 and len(es) == 7

    # Coherencia con la simulacion por modelo
    sims = pd.concat([pd.read_csv(os.path.join(RAIZ, "results_codesys", f),
                                  encoding="utf-8-sig", encoding_errors="replace")
                      for f in SIMS], ignore_index=True)
    sims[["modelo", "estrategia", "ejec"]] = sims["id"].str.split("|", expand=True)
    sims = sims.rename(columns={"pasos_fallidos": "pf_sim"})
    mg = df.merge(sims[["modelo", "tarea", "estrategia", "ejec", "pf_sim", "veredicto",
                        "compila", "nota"]],
                  on=["modelo", "tarea", "estrategia", "ejec"], how="left")
    print(f"\nFilas emparejadas con la simulacion por modelo: {mg['veredicto'].notna().sum() + mg['compila'].eq(0).sum()} de 600")
    a = mg["pasos_fallidos"].fillna("").astype(str)
    b = mg["pf_sim"].fillna("").astype(str)
    dif = (a != b).sum()
    print(f"Diferencias en pasos_fallidos entre tabla y simulacion: {dif}")
    ok &= dif == 0
    lg = mg[mg["c1_categoria"] == "FALLA_LOGICA"]
    print(f"FALLA_LOGICA con veredicto 2 en la simulacion: {(lg['veredicto'] == 2).sum()} de {len(lg)}")
    intf = mg[mg["c1_categoria"] == "INTERFAZ_NO_CONFORME"]
    n_msg = intf["nota"].fillna("").str.contains("no es ninguna entrada").sum()
    print(f"INTERFAZ_NO_CONFORME con mensaje \"no es ninguna entrada\" en la simulacion: {n_msg} de {len(intf)}")

    print("\nRESULTADO GLOBAL:", "TODO CUADRA" if ok else "HAY DISCREPANCIAS")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
