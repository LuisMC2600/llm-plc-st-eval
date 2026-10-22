"""
Análisis de conformidad sintáctica del código Structured Text generado.

Reproduce íntegramente los resultados reportados en el artículo: analiza cada
respuesta con blark (analizador de ST de código abierto sobre gramática lark),
cruza el veredicto con una detección estructural independiente, calcula las
métricas por modelo, estrategia, nivel y tarea, y genera las figuras.

Salidas (en data/results/):
    resultados_sintaxis_blark.csv     veredicto por respuesta
    resultados_sintaxis_cruzado.csv   veredicto + control estructural
    fig2_conformidad.png              conformidad por modelo y estrategia
    fig3_errores.png                  categorías de fallo por modelo

Uso:
    python analizar_sintaxis.py            # análisis completo
    python analizar_sintaxis.py --control  # solo caracterización del instrumento
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from blark.parse import parse_source_code

RAIZ = Path(__file__).resolve().parents[1]
CRUDO = RAIZ / "data" / "raw"
LIMPIO = RAIZ / "data" / "processed"
RESULTADOS = RAIZ / "data" / "results"

NAVY, GOLD = "#1F3864", "#C9A227"
FIN_POU = re.compile(r"END_(FUNCTION_BLOCK|PROGRAM|FUNCTION)\b")


# ---------------------------------------------------------------------------
# Caracterización del instrumento
# ---------------------------------------------------------------------------
CASOS_CONTROL = {
    "FB válido completo": ("FUNCTION_BLOCK FB_Ok\nVAR_INPUT\n a : BOOL;\nEND_VAR\n"
                           "VAR_OUTPUT\n b : BOOL;\nEND_VAR\nb := a;\nEND_FUNCTION_BLOCK", True),
    "FB con TON y literal de tiempo": ("FUNCTION_BLOCK FB_Val\nVAR_INPUT\n n : BOOL;\nEND_VAR\n"
                           "VAR_OUTPUT\n v : BOOL;\nEND_VAR\nVAR\n t : TON;\nEND_VAR\n"
                           "t(IN := n, PT := T#5S);\nv := t.Q;\nEND_FUNCTION_BLOCK", True),
    "sin END_FUNCTION_BLOCK": ("FUNCTION_BLOCK FB_X\nVAR_INPUT\n a : BOOL;\nEND_VAR\nb := a;", False),
    "declaración sin terminador": ("FUNCTION_BLOCK FB_X\nVAR_INPUT\n a : BOOL\nEND_VAR\n"
                           "END_FUNCTION_BLOCK", False),
    "IF sin END_IF": ("FUNCTION_BLOCK FB_X\nVAR_INPUT\n a : BOOL;\nEND_VAR\nVAR_OUTPUT\n b : BOOL;\n"
                           "END_VAR\nIF a THEN\n b := TRUE;\nEND_FUNCTION_BLOCK", False),
    "tipo inexistente": ("FUNCTION_BLOCK FB_X\nVAR_INPUT\n a : BOOLEANO;\nEND_VAR\n"
                           "END_FUNCTION_BLOCK", True),   # acepta: no valida semántica
    "texto ajeno al lenguaje": ("esto no es structured text {{{ ???", False),
}


def analizar(texto: str):
    """Devuelve (conforme, tipo_error, mensaje)."""
    r = parse_source_code(texto)
    if r.exception is None:
        return True, "", ""
    e = r.exception
    return False, type(e).__name__, str(e).replace("\n", " ")[:160]


def caracterizar_instrumento() -> bool:
    print("CARACTERIZACIÓN DEL INSTRUMENTO")
    print("=" * 72)
    todo_ok = True
    for nombre, (src, esperado) in CASOS_CONTROL.items():
        conforme, _, _ = analizar(src)
        ok = conforme == esperado
        todo_ok &= ok
        print(f"  {nombre:34} {'acepta' if conforme else 'rechaza':8}"
              f" esperado {'acepta' if esperado else 'rechaza':8} {'ok' if ok else 'DISCREPA'}")
    print(f"\nInstrumento conforme a lo esperado: {'sí' if todo_ok else 'NO'}")
    print("Alcance: verifica sintaxis, no semántica (acepta un tipo inexistente).")
    print("Las cifras obtenidas son, por tanto, una cota superior de la conformidad.\n")
    return todo_ok


# ---------------------------------------------------------------------------
def cargar_corpus() -> pd.DataFrame:
    log = pd.read_json(CRUDO / "log.jsonl", lines=True)
    # el log guarda rutas con separador de Windows y carpeta original
    log["nombre"] = log.archivo.str.replace("\\", "/", regex=False).str.split("/").str[-4:].str.join("/")
    log["ruta"] = log.nombre.map(lambda n: LIMPIO / Path(n).relative_to(Path(n).parts[0]))
    # reconstrucción robusta: <modelo>/<tarea>/<estrategia>/<archivo>
    log["ruta"] = log.apply(
        lambda r: LIMPIO / r.modelo_config.replace(":", "_") / r.tarea / r.estrategia
        / f"ejec_{r.ejecucion}.st", axis=1)
    faltan = [str(p) for p in log.ruta if not Path(p).exists()]
    if faltan:
        sys.exit(f"No se encontraron {len(faltan)} archivos, p. ej. {faltan[0]}")
    log["nivel"] = log.tarea.str[0].map({"B": "Basico", "I": "Intermedio"})
    return log


def analizar_corpus(log: pd.DataFrame) -> pd.DataFrame:
    filas = []
    for _, r in log.iterrows():
        texto = Path(r.ruta).read_text(encoding="utf-8", errors="ignore")
        conforme, tipo, msg = analizar(texto)
        filas.append({
            "modelo": r.modelo_config, "tarea": r.tarea, "nivel": r.nivel,
            "estrategia": r.estrategia, "ejecucion": r.ejecucion,
            "parsea": int(conforme), "tipo_error": tipo, "mensaje": msg,
            "lineas": texto.count("\n") + 1,
            "no_ascii": sum(1 for c in texto if ord(c) > 127),
            "cierra_pou": bool(FIN_POU.search(texto)),
            "archivo": str(Path(r.ruta).relative_to(RAIZ)),
        })
    return pd.DataFrame(filas)


def reportar(df: pd.DataFrame) -> None:
    print("CONFORMIDAD SINTÁCTICA")
    print("=" * 72)
    print(f"\nGlobal: {df.parsea.sum()}/{len(df)} = {df.parsea.mean()*100:.1f}%\n")
    piv = df.pivot_table(index="modelo", columns="estrategia", values="parsea",
                         aggfunc="mean").mul(100).round(1)
    print("Por modelo y estrategia (%):"); print(piv.to_string())
    print("\nPor nivel (%):")
    print(df.pivot_table(index="nivel", columns="modelo", values="parsea",
                         aggfunc="mean").mul(100).round(1).to_string())
    print("\nPor tarea (%):")
    t = df.groupby("tarea").parsea.mean().mul(100).round(0).astype(int)
    print(t.to_string())
    print("\nCategorías de fallo:")
    print(df[df.parsea == 0].tipo_error.value_counts().to_string())

    # Control cruzado con la detección estructural
    concordancia = (df.cierra_pou == (df.parsea == 1)).mean() * 100
    print(f"\nControl cruzado con detección estructural: {concordancia:.1f}% de concordancia")
    solo_parser = df[(df.parsea == 0) & (df.cierra_pou)]
    print(f"  Defectos que solo detecta el analizador: {len(solo_parser)}")

    print("\nFactores asociados (media según veredicto):")
    print(df.groupby("parsea")[["lineas", "no_ascii"]].mean().round(1).to_string())


def figuras(df: pd.DataFrame) -> None:
    p = df.pivot_table(index="modelo", columns="estrategia", values="parsea",
                       aggfunc="mean").mul(100)[["zero_shot", "few_shot"]]
    fig, ax = plt.subplots(figsize=(4.8, 3.0))
    x, w = np.arange(len(p)), 0.35
    b1 = ax.bar(x - w/2, p["zero_shot"], w, label="zero-shot", color=NAVY)
    b2 = ax.bar(x + w/2, p["few_shot"], w, label="few-shot", color=GOLD)
    ax.set_xticks(x); ax.set_xticklabels(p.index, fontsize=9)
    ax.set_ylabel("Conformidad sintáctica (%)", fontsize=9); ax.set_ylim(0, 115)
    ax.legend(fontsize=8.5, loc="lower right"); ax.spines[["top", "right"]].set_visible(False)
    for bs in (b1, b2):
        for b in bs:
            ax.text(b.get_x() + b.get_width()/2, b.get_height() + 2,
                    f"{b.get_height():.1f}%", ha="center", fontsize=8.5, fontweight="bold")
    plt.tight_layout(); plt.savefig(RESULTADOS / "fig2_conformidad.png", dpi=300,
                                    bbox_inches="tight"); plt.close()

    fig, ax = plt.subplots(figsize=(4.8, 2.8))
    ct = pd.crosstab(df[df.parsea == 0].modelo, df[df.parsea == 0].tipo_error)
    ct.plot(kind="barh", stacked=True, ax=ax, color=[GOLD, NAVY])
    ax.set_xlabel("Respuestas que no superan el análisis (n)", fontsize=9); ax.set_ylabel("")
    ax.legend(["Construcción inválida", "Bloque sin cerrar"], fontsize=8, loc="lower right")
    ax.spines[["top", "right"]].set_visible(False)
    plt.tight_layout(); plt.savefig(RESULTADOS / "fig3_errores.png", dpi=300,
                                    bbox_inches="tight"); plt.close()
    print(f"\nFiguras guardadas en {RESULTADOS.relative_to(RAIZ)}/ (300 dpi)")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--control", action="store_true",
                    help="solo caracterizar el instrumento, sin analizar el corpus")
    args = ap.parse_args()

    if not caracterizar_instrumento():
        sys.exit("El instrumento no se comporta como se documentó: revisar la versión de blark.")
    if args.control:
        return

    RESULTADOS.mkdir(parents=True, exist_ok=True)
    df = analizar_corpus(cargar_corpus())
    df.drop(columns=["cierra_pou", "lineas", "no_ascii"]).to_csv(
        RESULTADOS / "resultados_sintaxis_blark.csv", index=False)
    df.to_csv(RESULTADOS / "resultados_sintaxis_cruzado.csv", index=False)
    reportar(df)
    figuras(df)


if __name__ == "__main__":
    main()
