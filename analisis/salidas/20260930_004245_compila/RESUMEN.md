# Análisis estadístico — métrica `compila`
Generado: 2026-09-30 00:42  ·  log: `C:\Users\LUIS C\Downloads\1 Trabajo de Grado\llm-plc-st-eval\data\raw\log.jsonl`  ·  resultados: `C:\Users\LUIS C\Downloads\1 Trabajo de Grado\llm-plc-st-eval\data\results_codesys\compilacion_piloto.csv`

## 1. Datos
Registros en el log: 144 · con resultado: 144 · sin resultado: 0
Modelos: claude-sonnet-4-6, gpt-4o · tareas: 12 · estrategias: few_shot, zero_shot

## 2. Tasa de éxito (IC de Wilson al 95 %)
Global: 134/144 = 93.1% (IC 95 %: 87.7%–96.2%)
- claude-sonnet-4-6 · Few-shot: 36/36 = 100.0% (IC 90.4%–100.0%)
- claude-sonnet-4-6 · Zero-shot: 34/36 = 94.4% (IC 81.9%–98.5%)
- gpt-4o · Few-shot: 33/36 = 91.7% (IC 78.2%–97.1%)
- gpt-4o · Zero-shot: 31/36 = 86.1% (IC 71.3%–93.9%)

## 3. Zero-shot vs few-shot por modelo (McNemar exacto)
b = aciertos solo en zero-shot · c = aciertos solo en few-shot · OR = c/b (corrección 0.5)
- claude-sonnet-4-6: pares=36, b=0, c=2, Δ(FS−ZS)=+5.6%, p=0.5000, OR=5.00
- gpt-4o: pares=36, b=0, c=2, Δ(FS−ZS)=+5.6%, p=0.5000, OR=5.00

## 4. Comparación entre modelos (pareada por tarea × estrategia × ejecución)
- claude-sonnet-4-6 (97.2%) vs gpt-4o (88.9%): b=6, c=0, p=0.0312, p_Holm=0.0312

## 5. Regresión logística GEE
No estimable de forma fiable: hay separación perfecta en claude-sonnet-4-6·few_shot = 100%. Los odds ratios de esas celdas tienden a infinito; se reportan las pruebas exactas de las secciones 3 y 4.

## Figuras
- `fig_exito_modelo_estrategia.png`: tasa por modelo y estrategia con IC de Wilson.
- `fig_mapa_tarea_modelo.png`: % de éxito por tarea, modelo y estrategia.