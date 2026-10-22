"""
Extractor de código ST — preparación para la verificación en CODESYS.

Hallazgo del piloto: el 100% de las respuestas vienen envueltas en un bloque
markdown (```pascal ... ```) y un 20.8% añade prosa explicativa después del
código, pese a que el prompt pide "entrega únicamente el código". Pegar el
archivo crudo en CODESYS produce errores de sintaxis que NO son atribuibles
al modelo.

Este script separa mecánicamente el código de su envoltorio, sin alterar
NI UNA LÍNEA del código: no corrige, no reformatea, no completa. Escribe:

  repositorio_piloto_limpio/<modelo>/<tarea>/<estrategia>/ejec_<n>.st   -> solo código
  extraccion_reporte.csv                                                -> qué se quitó

El original nunca se modifica: es el dato primario del estudio.

Uso:  python extraer_codigo.py [carpeta_origen]
"""

from __future__ import annotations
import csv
import re
import sys
from pathlib import Path

FENCE = re.compile(r"```[a-zA-Z]*\s*\n(.*?)```", re.S)
FIN_POU = re.compile(r"END_(FUNCTION_BLOCK|PROGRAM|FUNCTION)\b")
CABECERA_POU = re.compile(r"^\s*(FUNCTION_BLOCK|PROGRAM|FUNCTION)\s+\w+", re.IGNORECASE)


def _es_declaracion_huerfana(bloque: str) -> bool:
    """Cabecera de POU + al menos un END_VAR, pero sin END_ de cierre: el
    modelo separo declaracion e implementacion en dos fences distintos."""
    return bool(CABECERA_POU.search(bloque)) and "END_VAR" in bloque and not FIN_POU.search(bloque)


def _es_cuerpo_huerfano(bloque: str) -> bool:
    """Sin cabecera de POU: es la implementacion de una declaracion huerfana
    de OTRO bloque, no un fragmento autocontenido."""
    return not CABECERA_POU.search(bloque)


def extraer(texto: str) -> tuple[str, str]:
    """Devuelve (codigo, motivo). No modifica el contenido del código."""
    bloques = FENCE.findall(texto)
    if bloques:
        declaraciones = [b for b in bloques if _es_declaracion_huerfana(b)]
        cuerpos = [b for b in bloques if _es_cuerpo_huerfano(b)]
        if len(declaraciones) == 1 and len(cuerpos) == 1 and len(bloques) == 2:
            # Caso claude-sonnet-4-6/I6/zero_shot (ejec_1 y ejec_2, piloto):
            # declaracion e implementacion en fences separados. Se concatenan
            # en el orden en que aparecen, sin tocar ni una linea de ninguno.
            # NO se aplica cuando ambos bloques son autocontenidos (p. ej.
            # claude-sonnet-4-6/I5/zero_shot/ejec_1, dos implementaciones
            # alternativas completas): ahi max(len) sigue siendo correcto.
            codigo = "\n\n".join(b.strip() for b in bloques)
            motivo = "fence markdown (declaracion + implementacion en fences separados)"
        else:
            # Si hay varios bloques, se conserva el más largo (el código principal).
            codigo = max(bloques, key=len).strip()
            motivo = "fence markdown" + (f" ({len(bloques)} bloques)" if len(bloques) > 1 else "")
    else:
        codigo, motivo = texto.strip(), "sin fence"
    # Recorte de prosa posterior al último END_ del POU, si la hubiera.
    fines = list(FIN_POU.finditer(codigo))
    if fines and codigo[fines[-1].end():].strip():
        codigo = codigo[: fines[-1].end()]
        motivo += " + prosa final"
    return codigo, motivo


def main() -> None:
    origen = Path(sys.argv[1] if len(sys.argv) > 1 else "repositorio_piloto")
    destino = Path(str(origen) + "_limpio")
    filas = []

    for src in sorted(origen.rglob("*.st")):
        bruto = src.read_text(encoding="utf-8", errors="ignore")
        codigo, motivo = extraer(bruto)
        dst = destino / src.relative_to(origen)
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(codigo, encoding="utf-8")

        no_ascii = sum(1 for ch in codigo if ord(ch) > 127)
        filas.append({
            "archivo": str(src),
            "archivo_limpio": str(dst),
            "motivo": motivo,
            "car_original": len(bruto),
            "car_codigo": len(codigo),
            "car_removidos": len(bruto) - len(codigo),
            "lineas": codigo.count("\n") + 1,
            "no_ascii": no_ascii,
            "cierra_pou": bool(FIN_POU.search(codigo)),
        })

    with open("extraccion_reporte.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(filas[0].keys()))
        w.writeheader()
        w.writerows(filas)

    sin_cierre = [r for r in filas if not r["cierra_pou"]]
    con_no_ascii = [r for r in filas if r["no_ascii"] > 0]
    print(f"Procesados : {len(filas)} archivos -> {destino}/")
    print(f"Con envoltorio markdown: {sum(1 for r in filas if 'fence' in r['motivo'])}")
    print(f"Con prosa final recortada: {sum(1 for r in filas if 'prosa' in r['motivo'])}")
    print(f"Sin END_ de POU (revisar a mano): {len(sin_cierre)}")
    for r in sin_cierre[:10]:
        print("   ", r["archivo"])
    print(f"Con caracteres no ASCII (pueden dar problemas de codificación en CODESYS): "
          f"{len(con_no_ascii)}")
    print("Reporte detallado: extraccion_reporte.csv")


if __name__ == "__main__":
    main()
