# Análisis estadístico — métrica `parsea`
Generado: 2026-09-28 18:39  ·  log: `/mnt/user-data/uploads/1 Trabajo de Grado/llm-plc-st-eval/data/raw/log.jsonl`  ·  resultados: `/mnt/user-data/uploads/1 Trabajo de Grado/llm-plc-st-eval/data/results/resultados_sintaxis_blark.csv`

## 1. Datos
Registros en el log: 144 · con resultado: 144 · sin resultado: 0
Modelos: claude-sonnet-4-6, gpt-4o · tareas: 12 · estrategias: few_shot, zero_shot

## 2. Tasa de éxito (IC de Wilson al 95 %)
Global: 124/144 = 86.1% (IC 95 %: 79.5%–90.8%)
- claude-sonnet-4-6 · Few-shot: 36/36 = 100.0% (IC 90.4%–100.0%)
- claude-sonnet-4-6 · Zero-shot: 22/36 = 61.1% (IC 44.9%–75.2%)
- gpt-4o · Few-shot: 36/36 = 100.0% (IC 90.4%–100.0%)
- gpt-4o · Zero-shot: 30/36 = 83.3% (IC 68.1%–92.1%)

## 3. Zero-shot vs few-shot por modelo (McNemar exacto)
b = aciertos solo en zero-shot · c = aciertos solo en few-shot · OR = c/b (corrección 0.5)
- claude-sonnet-4-6: pares=36, b=0, c=14, Δ(FS−ZS)=+38.9%, p=0.0001, OR=29.00
- gpt-4o: pares=36, b=0, c=6, Δ(FS−ZS)=+16.7%, p=0.0312, OR=13.00

## 4. Comparación entre modelos (pareada por tarea × estrategia × ejecución)
- claude-sonnet-4-6 (80.6%) vs gpt-4o (91.7%): b=3, c=11, p=0.0574, p_Holm=0.0574

## 5. Regresión logística GEE
No estimable de forma fiable: hay separación perfecta en claude-sonnet-4-6·few_shot = 100%, gpt-4o·few_shot = 100%. Los odds ratios de esas celdas tienden a infinito; se reportan las pruebas exactas de las secciones 3 y 4.

## Figuras
- `fig_exito_modelo_estrategia.png`: tasa por modelo y estrategia con IC de Wilson.
- `fig_mapa_tarea_modelo.png`: % de éxito por tarea, modelo y estrategia.