# -*- coding: utf-8 -*-
"""
c04_clasificar_piloto.py  (Agente C, borrador v0.3, 2026-10-12)

Clasifica en la misma taxonomia los 20 fallos sintacticos del estudio piloto
(blark, 144 respuestas), a partir de resultados_sintaxis_cruzado.csv
(columnas tipo_error, mensaje y cierra_pou). El codigo del piloto no esta entre
los insumos, de modo que las reglas usan solo el mensaje del analizador y la
deteccion estructural del cierre del POU; la regla P3 se apoya ademas en la
descripcion del Articulo_CITDES_final.md (seccion INIT de GPT-4o en B3).
Salida: clasificacion_piloto_cwe.csv y resumen en consola.
Uso:  python c04_clasificar_piloto.py
"""
import os
import pandas as pd

AQUI = os.path.dirname(os.path.abspath(__file__))
# Versión publicada: ruta relativa al repositorio (antes apuntaba a una carpeta temporal). El cálculo no cambia.
F = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "data", "results", "resultados_sintaxis_cruzado.csv")
SAL = os.path.join(AQUI, "clasificacion_piloto_cwe.csv")


def regla(r):
    msg = str(r["mensaje"])
    cierra = str(r["cierra_pou"]).strip().lower() == "true"
    if r["tipo_error"] == "UnexpectedEOF" and not cierra:
        return ("P1", "POU sin cerrar (falta END_FUNCTION_BLOCK)", "CONSTRUCCION", "CWE-710",
                "blark: fin de entrada inesperado; deteccion estructural: el POU no se cierra")
    if r["tipo_error"] == "UnexpectedCharacters" and "VAR_OUTPUT" in msg:
        return ("P2", "terminador inexistente END_VAR_INPUT/END_VAR_OUTPUT", "CONSTRUCCION", "CWE-710",
                "blark: VAR_OUTPUT inesperado tras un bloque VAR_INPUT no cerrado con END_VAR")
    if r["tipo_error"] == "UnexpectedCharacters" and "_PROGRAM" in msg and not cierra:
        return ("P4", "seccion de declaracion ausente (artefacto de extraccion, INC-12)", "CONSTRUCCION", "CWE-710",
                "blark: cuerpo sin cabecera; BITACORA 2026-09-30: declaracion y cuerpo en dos bloques, el extractor v1 conservo uno")
    if r["tipo_error"] == "UnexpectedCharacters" and cierra:
        return ("P3", "construccion inexistente (seccion INIT, segun el articulo)", "CONSTRUCCION", "CWE-710",
                "blark: asignacion inesperada en zona de declaracion; Articulo CITDES: seccion INIT ajena al estandar")
    return ("P9", "no clasificado", "CONSTRUCCION", "CWE-710", "revisar")


def main():
    d = pd.read_csv(F, encoding="utf-8-sig")
    f = d[d["parsea"] == 0].copy()
    print(f"Fallos sintacticos del piloto: {len(f)} (esperado 20)")
    rs = f.apply(regla, axis=1, result_type="expand")
    rs.columns = ["regla", "subtipo", "categoria_plc", "cwe_id", "evidencia"]
    out = pd.concat([f[["modelo", "tarea", "nivel", "estrategia", "ejecucion", "tipo_error"]].reset_index(drop=True),
                     rs.reset_index(drop=True)], axis=1)
    out.to_csv(SAL, index=False, encoding="utf-8")
    print(pd.crosstab(out["subtipo"], out["modelo"], margins=True).to_string())
    print("\nEstrategia de los 20 fallos:", out["estrategia"].value_counts().to_dict())
    print("Categoria y CWE:", out.groupby(["categoria_plc", "cwe_id"]).size().to_dict())


if __name__ == "__main__":
    main()
