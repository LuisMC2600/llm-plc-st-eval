"""
Ejemplo de análisis del log experimental (tareas 6.1–6.2 del plan).
Lee el dato primario (log.jsonl) con pandas y produce un resumen inicial.
Las métricas de compilación/corrección se agregan en la Fase 5, cruzando
este log con las fichas de evaluación de CODESYS.
"""

import pandas as pd

df = pd.read_json("repositorio/log.jsonl", lines=True)

print("=== Ejecuciones por modelo y estrategia ===")
print(df.pivot_table(index="modelo_config", columns="estrategia",
                     values="tarea", aggfunc="count", fill_value=0))

print("\n=== Latencia promedio (s) y tokens de salida por modelo ===")
print(df.groupby("modelo_config")[["latencia_s", "tokens_salida"]]
        .mean().round(2))

print("\n=== Costo aproximado de tokens por proveedor ===")
print(df.groupby("proveedor")[["tokens_entrada", "tokens_salida"]].sum())

# Verificación de control experimental: cada tarea+estrategia debe tener
# UN único hash de prompt entre todos los modelos.
chequeo = df.groupby(["tarea", "estrategia"])["hash_prompt"].nunique()
if (chequeo > 1).any():
    print("\n[ALERTA] Hay tareas con prompts distintos entre modelos:")
    print(chequeo[chequeo > 1])
else:
    print("\n[OK] Control experimental: prompts idénticos entre modelos.")
