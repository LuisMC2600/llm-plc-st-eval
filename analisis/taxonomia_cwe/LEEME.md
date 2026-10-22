# Clasificación de los 249 fallos del criterio 1 (taxonomía PLC con correspondencia CWE)

Copia definitiva en el repositorio (15-10-2026) del material elaborado en
`00_Gestion_y_Plan/Borradores_v0.3/C_Taxonomia_CWE/`, que se conserva como borrador original.
Única diferencia: en c01, c02 y c03 la constante `RAIZ` apunta ahora a `llm-plc-st-eval/data`
(antes, a una carpeta temporal del entorno donde se redactó). Con ese cambio, `c02_clasificar_errores.py`
reproduce byte a byte `clasificacion_fallos_cwe.csv` y `c01` termina con «TODO CUADRA».

Orden de ejecución (desde esta carpeta, con pandas):
1. `c01_verificar_tabla_causas.py`  comprueba que la tabla de causas cuadra con las simulaciones.
2. `c02_clasificar_errores.py`      clasifica los 249 fallos (automático, paso del harness o juicio) → `clasificacion_fallos_cwe.csv`.
3. `c03_tablas_y_verificacion.py`   tablas del Cap. 4 y verificación del mapa de pasos (`verificacion_mapa_pasos_v1.csv`).
4. `c04_clasificar_piloto.py`       clasificación de los 20 fallos sintácticos del piloto → `clasificacion_piloto_cwe.csv`.
5. `c05_revision_deepseek.py`       concordancia DeepSeek–Claude en los 51 casos por juicio (`revision_deepseek/`).

Archivos clave: `mapa_pasos_harness.csv` (mapa v2, vigente), `mapa_pasos_harness_v1.csv` (mapa inicial),
`juicio_deepseek.csv` (oficial), `juicio_llm.csv` (Claude, segundo evaluador),
`concordancia_juicio_deepseek_claude.csv`. Las salidas `salida_c0*.txt` son las de la ejecución original.

Segunda muestra de verificación (mapa v2, 15-10-2026): `muestra2_mapa_v2_seleccion.csv` (22 respuestas: la primera de
cada modelo × tarea entre las 59 clasificadas por paso que no estaban en la primera muestra), `juicio_muestra2_mapa_v2.py`
(categoría del defecto leída en el código, registrada antes de cruzarla con el mapa) y `verificacion_mapa_pasos_v2.csv`
(resultado: 19/22 = 86.4 %; IC 95 % de Wilson 66.7–95.3 %). El mapa v2 no se modificó tras esta muestra.
