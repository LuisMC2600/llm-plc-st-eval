"""
Extractor de codigo ST v2 (regla de extraccion fijada el 2026-09-30, decision de Luis).

Separa mecanicamente el codigo de su envoltorio markdown SIN alterar ni una
linea del codigo: no corrige, no reformatea, no completa. El original (data/raw)
nunca se modifica.

REGLA POR PATRON (se aplica en este orden; cada respuesta queda marcada con la regla):
  R0  Sin bloque ``` : texto completo.
  R1  Un solo bloque : ese bloque.
  R2  Fragmentos de un mismo POU (exactamente una declaracion huerfana -cabecera
      + END_VAR sin END_ de cierre- y un cuerpo huerfano -sin cabecera-):
      se concatenan en el orden en que aparecen.
  R3  Varios POUs autocontenidos:
        - mismo nombre repetido (versiones alternativas): se toma la ULTIMA
          aparicion de cada nombre (la respuesta final del modelo);
        - nombres distintos (POUs auxiliares): se conservan todos;
      el resultado se concatena en el orden en que aparecen en la respuesta.
      Los bloques sin cabecera que acompanen a POUs autocontenidos (ejemplos
      de uso, llamadas de prueba) se descartan.
  R9  Patron no reconocido: se concatenan TODOS los bloques en orden y la
      respuesta se marca REVISAR (revision manual, nunca correccion).
  Despues de cualquier regla: se recorta la prosa posterior al ultimo END_ de POU.

Sensibilidad: extraer(texto, alternativa="primera") aplica R3 tomando la PRIMERA
version de cada nombre, para informar si la regla cambia algun resultado.

Uso:  python src/extraer_codigo.py <carpeta_origen> <carpeta_destino> [--alternativa primera]
      Escribe <carpeta_destino>/extraccion_reporte.csv
"""

from __future__ import annotations
import argparse
import csv
import re
from pathlib import Path

VERSION = "v2-2026-09-30"
FENCE = re.compile(r"```[a-zA-Z0-9_+-]*[ \t]*\r?\n(.*?)```", re.S)
FIN_POU = re.compile(r"END_(FUNCTION_BLOCK|PROGRAM|FUNCTION)\b")
CABECERA_POU = re.compile(r"^\s*(FUNCTION_BLOCK|PROGRAM|FUNCTION)\s+(\w+)", re.IGNORECASE | re.M)


def _nombre(bloque: str):
    m = CABECERA_POU.search(bloque)
    return m.group(2) if m else None


def _tipo(bloque: str) -> str:
    """POU (autocontenido), DECL (declaracion huerfana) o CUERPO (sin cabecera)."""
    if not CABECERA_POU.search(bloque):
        return "CUERPO"
    if FIN_POU.search(bloque):
        return "POU"
    if "END_VAR" in bloque:
        return "DECL"
    return "POU"  # cabecera sin END_ ni END_VAR: se trata como POU (CODESYS decide)


def extraer(texto: str, alternativa: str = "ultima") -> tuple[str, str, str]:
    """Devuelve (codigo, regla, detalle). No modifica el contenido del codigo."""
    bloques = FENCE.findall(texto)
    if not bloques:
        codigo, regla, detalle = texto.strip(), "R0", "sin fence"
    elif len(bloques) == 1:
        codigo, regla, detalle = bloques[0].strip(), "R1", "1 bloque"
    else:
        tipos = [_tipo(b) for b in bloques]
        n = len(bloques)
        if tipos.count("DECL") == 1 and tipos.count("CUERPO") == 1 and n == 2 \
                and tipos.index("DECL") < tipos.index("CUERPO"):
            codigo = "\n\n".join(b.strip() for b in bloques)
            regla, detalle = "R2", "declaracion + cuerpo en bloques separados"
        elif "POU" in tipos and "DECL" not in tipos:
            pous = [(i, _nombre(b)) for i, b in enumerate(bloques) if tipos[i] == "POU"]
            elegido = {}
            for i, nom in pous:
                if alternativa == "primera":
                    elegido.setdefault(nom, i)
                else:
                    elegido[nom] = i
            idx = sorted(elegido.values())
            codigo = "\n\n".join(bloques[i].strip() for i in idx)
            nombres = [nom for _, nom in pous]
            partes = []
            if len(nombres) != len(set(nombres)):
                partes.append("versiones alternativas -> %s" % alternativa)
            if len(set(nombres)) > 1:
                partes.append("POUs auxiliares conservados: %s" % ",".join(sorted(set(nombres))))
            if tipos.count("CUERPO"):
                partes.append("%d fragmento(s) sin cabecera descartado(s)" % tipos.count("CUERPO"))
            regla, detalle = "R3", "; ".join(partes) or "%d bloques" % n
        else:
            codigo = "\n\n".join(b.strip() for b in bloques)
            regla, detalle = "R9", "REVISAR: patron no reconocido %s" % "/".join(tipos)
    fines = list(FIN_POU.finditer(codigo))
    if fines and codigo[fines[-1].end():].strip():
        codigo = codigo[: fines[-1].end()]
        detalle += " + prosa final recortada"
    return codigo, regla, detalle


def main() -> None:
    ap = argparse.ArgumentParser(description="Extractor de codigo ST v2 (regla por patron).")
    ap.add_argument("origen")
    ap.add_argument("destino")
    ap.add_argument("--alternativa", choices=["ultima", "primera"], default="ultima")
    a = ap.parse_args()
    origen, destino = Path(a.origen), Path(a.destino)
    if destino.resolve() == origen.resolve():
        raise SystemExit("destino no puede ser el origen (data/raw es dato primario)")
    filas = []
    for src in sorted(origen.rglob("*.st")):
        bruto = src.read_text(encoding="utf-8", errors="ignore")
        codigo, regla, detalle = extraer(bruto, a.alternativa)
        dst = destino / src.relative_to(origen)
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(codigo, encoding="utf-8")
        filas.append({"archivo": src.relative_to(origen).as_posix(), "regla": regla, "detalle": detalle,
                      "n_bloques": len(FENCE.findall(bruto)), "car_original": len(bruto),
                      "car_codigo": len(codigo), "cierra_pou": bool(FIN_POU.search(codigo)),
                      "no_ascii": sum(1 for ch in codigo if ord(ch) > 127),
                      "version_extractor": VERSION, "alternativa": a.alternativa})
    destino.mkdir(parents=True, exist_ok=True)
    with open(destino / "extraccion_reporte.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(filas[0].keys()))
        w.writeheader()
        w.writerows(filas)
    from collections import Counter
    print("Procesados: %d -> %s" % (len(filas), destino))
    print("Reglas:", dict(sorted(Counter(r["regla"] for r in filas).items())))
    for r in filas:
        if r["regla"] in ("R2", "R3", "R9"):
            print("   %s  %s  %s" % (r["regla"], r["archivo"], r["detalle"]))


if __name__ == "__main__":
    main()
