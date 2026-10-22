# llm-plc-st-eval

Datos, scripts y evidencias del trabajo de graduación **«LLMs como Asistentes de Programación
PLC en la Academia: Evaluación de Precisión y Confiabilidad»**, Licenciatura en Sistemas
Eléctricos y Automatización, Facultad de Ingeniería Eléctrica, Universidad Tecnológica de
Panamá (2026). Autor: Luis Carlos Montenegro Caballero.

Este repositorio está pensado como **guía** para dos tipos de lector:

- quien quiera **validar** la investigación: comprobar que los datos no se alteraron y
  recalcular cada cifra de la tesis a partir de ellos;
- quien quiera **replicarla o extenderla** con la misma metodología: mismo banco de tareas,
  mismos bancos de prueba en CODESYS, misma rúbrica y mismo análisis, con los mismos modelos
  o con otros.

---

## Resultados principales

Experimento definitivo: 4 modelos × 30 tareas × 2 estrategias (zero-shot y few-shot) ×
3 ejecuciones = **720 respuestas**, de las cuales 600 piden código. Compilación y simulación
en CODESYS V3.5 SP22 Patch 3 con 23 bancos de prueba autoverificables.

| Modelo | Criterio 2: compila | Criterio 1: pasa el banco de prueba |
|---|---|---|
| gemini-3.1-pro-preview | 143/150 = 95.3 % | 141/150 = 94.0 % |
| claude-sonnet-4-6 | 136/150 = 90.7 % | 114/150 = 76.0 % |
| gpt-4o-2024-08-06 | 119/150 = 79.3 % | 54/150 = 36.0 % |
| qwen2.5-coder:14b | 120/150 = 80.0 % | 42/150 = 28.0 % |
| **Global** | **518/600 = 86.3 %** | **351/600 = 58.5 %** |

Estudio piloto (2 modelos × 12 tareas × 2 estrategias × 3 ejecuciones = 144 respuestas):
conformidad sintáctica con blark del 86.1 %. Las mismas respuestas compilaron en CODESYS en un
93.8 %.

---

## Requisitos

| Para | Necesita |
|---|---|
| Niveles 1 y 2 (validar) | Python 3.10 o superior y `pip install -r requirements-analisis.txt` |
| Nivel 3 (recompilar y resimular) | Windows, CODESYS V3.5 SP22 Patch 3 y PowerShell |
| Nivel 4 (replicar) | Además, `pip install -r requirements.txt`, claves de API y, para el modelo local, Ollama |

Versiones con las que se ejecutó el análisis original: Python 3.14.6, NumPy 2.4.6,
pandas 3.0.3, SciPy 1.18.0, matplotlib 3.11.0 y statsmodels 0.14.6.

Las claves de API se leen únicamente de variables de entorno (`OPENAI_API_KEY`,
`ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`, `DEEPSEEK_API_KEY`). El repositorio no contiene
ninguna.

Todos los comandos se ejecutan **desde la carpeta raíz del repositorio**.

---

## Nivel 1. Comprobar la integridad de los datos

No consume API ni requiere CODESYS.

1. **El dato primario no cambió.** El SHA-256 del registro de generación debe coincidir con
   el que registró el último lote (`evidencias/fase4/20261003_013720_gemini-3.1-pro-preview/resumen.json`,
   campo `sha256_log`):

   ```powershell
   Get-FileHash data\definitivo\log.jsonl -Algorithm SHA256
   ```
   ```bash
   sha256sum data/definitivo/log.jsonl
   ```

   Valor esperado: `d6f863029b633708715f2bbfc2ef080d1607da38fe8c7c8ae5dfb9939e2d02e1`.

2. **Los cuatro modelos recibieron las mismas instrucciones, y las del piloto no cambiaron:**

   ```bash
   python src/verificar_hashes.py
   ```

   Debe terminar con `[OK] Integridad confirmada` (24 de 24 pares coinciden con el piloto).
   Cada línea de `data/definitivo/log.jsonl` registra además el `hash_prompt` de su instrucción,
   el modelo configurado y el reportado por la API, los tokens, la latencia y el motivo de
   finalización.

3. **La tarea de documentación C4 dejó el código intacto:**

   ```bash
   python src/verificar_c4.py data/definitivo c4_comprobacion.csv
   ```

   Debe informar `{'INTACTO': 24}` e igualar `data/results/c4_definitivo.csv`.

## Nivel 2. Recalcular las cifras de la tesis

No consume API ni requiere CODESYS. Cada script lee los resultados ya medidos y los vuelve a
calcular; la columna «Salida de referencia» indica contra qué archivo comparar. Todos se
comprobaron el 22-10-2026 sobre una copia limpia de este repositorio: las salidas y los CSV
regenerados son idénticos a los incluidos.

| Paso | Comando | Reproduce | Salida de referencia |
|---|---|---|---|
| 1 | `python analisis/criterios_definitivo.py` | Criterios 1 y 2, estrategia, nivel, causas, sensibilidad S1 y S2 (Tablas 4.3–4.7 y 4.9) | `analisis/salidas/criterios_definitivo.txt` y `data/results/tabla_definitivo.csv` |
| 2 | `python analisis/consistencia_definitivo.py` | Consistencia entre ejecuciones (Tabla 4.8) | `analisis/salidas/consistencia_definitivo.txt` |
| 3 | `python evaluacion_manual/analizar_fichas.py evaluacion_llm/OFICIAL/Ficha_Oficial_Diagnostico_DeepSeek.xlsx evaluacion_llm/CONFIABILIDAD/Ficha_Confiabilidad_Diagnostico_Claude.xlsx data/results` | Diagnóstico, requisitos y su concordancia (Tablas 4.15, 4.16 y 4.18) | `analisis/salidas/evaluacion_manual_definitivo.txt` |
| 4 | `python evaluacion_rubrica/analizar_rubrica.py` | Rúbrica de cinco criterios y su concordancia (Tablas 4.17 y 4.18) | `analisis/salidas/rubrica_definitivo.txt` |
| 5 | Scripts `c01` a `c05` de `analisis/taxonomia_cwe/`, en orden (ver su `LEEME.md`) | Clasificación de los 249 fallos con la taxonomía PLC-CWE (Tablas 3.9 y 4.10–4.14) | `salida_c0*.txt` y `clasificacion_fallos_cwe.csv` |
| 6 | `python analisis/contraste_hipotesis.py` | Contraste de la hipótesis (Tablas 4.19 y 4.20) | `analisis/contraste_hipotesis_salida.txt` |
| 7 | `analisis/analisis_v03_spyder.py` (ajustar `BASE` a la raíz del repositorio; pensado para ejecutarse por celdas en Spyder) | Análisis complementarios y comprobación final de cifras | Debe terminar con «24 de 24 comprobaciones coinciden» |

Los pasos 1, 3 y 4 reescriben sus CSV en `data/results/`; si se ejecutan sobre el repositorio
clonado, `git status` permite comprobar que no cambió ningún byte. El paso 7 tarda varios
minutos por las 200 000 permutaciones de la prueba de Jonckheere-Terpstra.

## Nivel 3. Volver a verificar el código en CODESYS

Requiere Windows con CODESYS V3.5 SP22 Patch 3 (los lanzadores lo localizan solos; si no, se
indica con `-CodesysExe`). CODESYS debe estar cerrado.

1. **Validar los bancos de prueba sin CODESYS.** Cada uno tiene su validador en Python, que
   reproduce el ciclo de scan a 4, 10 y 20 ms y lo ejecuta contra implementaciones correctas y
   defectuosas:

   ```bash
   python codesys/validar_harness_B1.py      # y así con cada tarea
   ```

   Las correcciones que necesitaron los bancos durante su validación están en
   `docs/ENMIENDAS_HARNESSES.md`; la verificación en CODESYS real, en `docs/VERIFICACION_CODESYS.md`.

2. **Recompilar y resimular las respuestas.** El lanzador compila las 720 extracciones
   (criterio 2) y simula cada modelo con su banco de prueba (criterio 1):

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\codesys\ejecutar_definitivo.ps1
   ```

   El lanzador **omite los lotes cuyo CSV ya existe** en `data/results_codesys/`. Para repetir
   la medición, mueva antes esos CSV a otra carpeta y compare después los nuevos con los
   originales. Las tareas C7 y C8 se simulan con `codesys/ejecutar_c7c8.ps1`. Cada lote deja su
   transcripción y un `resumen.json` con SHA-256 en `evidencias/codesys/`.

`codesys/Plantilla_Simulacion.project` es la plantilla limpia sobre la que se compila cada
respuesta; los proyectos de `evidencias/codesys_ide/` son los de las capturas del Apéndice A.3.3
de la tesis.

## Nivel 4. Replicar o extender el experimento

El flujo completo, en el mismo orden en que se ejecutó:

1. **Banco de tareas.** `benchmark/Banco_de_Pruebas_v1.xlsx` y `benchmark/Prompts_Banco_v1.md`
   describen las 30 tareas. Los enunciados se editan **solo** en `src/generar_prompts.py`, que
   genera `src/tasks.json` (60 instrucciones). Después de cualquier cambio, `python
   src/verificar_hashes.py` confirma que no se alteró ningún enunciado ya ejecutado.
2. **Configuración.** `src/config.yaml` fija los modelos, la temperatura (0.2), el tope de
   respuesta (2 500 tokens; 10 000 en total para Gemini por su razonamiento interno), las
   ejecuciones por condición (3) y la política de reintentos. Para nuevos modelos, añádalos
   aquí y use una carpeta de salida nueva en lugar de `data/definitivo/`.
3. **Generación.** Cada lote se lanzó con evidencia auditable:

   ```powershell
   .\herramientas\ejecutar_con_evidencia.ps1 -Modelo todos                        # solo dry-run
   .\herramientas\ejecutar_con_evidencia.ps1 -Modelo qwen2.5-coder:14b -Confirmar   # llama a la API
   ```

   El script verifica la integridad, hace un dry-run, llama a la API solo con `-Confirmar`,
   toma capturas y escribe un `resumen.json` con el SHA-256 del registro. También puede usarse
   directamente `python src/runner.py --config config.yaml --dry-run` (desde `src/`). El
   orquestador es idempotente: si se interrumpe, al relanzarlo completa lo que falte sin
   repetir llamadas.
4. **Extracción del código.** `python src/extraer_codigo.py <carpeta_respuestas> <carpeta_salida>`
   aplica la regla v2 y deja el detalle en `extraccion_reporte.csv`. Nunca modifica las
   respuestas originales.
5. **Compilación y simulación** en CODESYS, como en el nivel 3.
6. **Evaluación de los criterios 3 a 5 y de las tareas no ejecutables.** El paquete
   `evaluacion_llm/Paquete_Evaluador_LLM2/` contiene las instrucciones, las entradas
   anonimizadas y el script `evaluar_deepseek.py` (use `--estimar` antes de gastar). Las
   fichas de `evaluacion_manual/` y `evaluacion_rubrica/` (carpetas `Evaluador1` y
   `Evaluador2`), con sus páginas HTML de respuestas, son las plantillas de la evaluación
   humana a ciegas del protocolo original: están vacías y pueden usarse tal cual para una
   evaluación humana. La asignación de códigos está en los archivos `_SELLADO_*`.
7. **Análisis**, como en el nivel 2.

Las 35 incidencias de la fase experimental, con su causa, detección y solución, están en
`docs/registro/INCIDENCIAS.md`; varias de ellas (INC-05, INC-10, INC-12, INC-25, INC-28,
INC-30) describen errores de medición que conviene conocer antes de replicar.

---

## Mapa del repositorio

```
├── benchmark/              Banco de 30 tareas (v0 y v1) y documento de prompts
├── src/                    Generación: prompts, orquestador, clientes, extracción, integridad
├── herramientas/           Lanzador con evidencia, capturas y verificación de modelos
├── codesys/                23 bancos de prueba PRG_Test_<tarea>.st, validadores en Python,
│                           dobles de prueba, scripts de compilación y simulación y lanzadores
├── data/
│   ├── raw/                  Dato primario del piloto (144 respuestas + log.jsonl)
│   ├── definitivo/           Dato primario del experimento (720 respuestas + log.jsonl)
│   ├── processed*/           Código extraído (regla v2) y copias normalizadas de sensibilidad
│   ├── calibracion/          Calibración previa (48 llamadas), fuera del dato primario
│   ├── sonda_gemini/         Sonda de razonamiento de Gemini (6 llamadas)
│   ├── results/              Tablas de resultados (CSV) del piloto y del experimento
│   └── results_codesys/      Resultados de compilación y simulación por lote
├── analisis/               Criterios 1 y 2, consistencia, contraste de la hipótesis,
│   ├── salidas/              salidas de referencia,
│   ├── taxonomia_cwe/        clasificación de los 249 fallos (ver LEEME.md)
│   └── evaluacion_c4/        evaluación de la documentación (tarea C4)
├── evaluacion_llm/         OFICIAL (DeepSeek), CONFIABILIDAD (Claude), comparación entre
│                           ambos y paquete del evaluador
├── evaluacion_manual/      Diagnóstico y requisitos (C1, C2, C5, C6): fichas, scripts y la
│                           primera pasada de Claude (_COMPARACION_IA_NO_OFICIAL)
├── evaluacion_rubrica/     Rúbrica de 5 criterios: fichas, páginas de respuestas y scripts
├── evidencias/             Transcripciones, resumen.json con SHA-256 y capturas de cada lote
├── capturas_spyder/        Capturas de la ejecución del análisis en Spyder
└── docs/                   Guía de ejecución, criterios, enmiendas y verificación de los bancos
    └── registro/             INCIDENCIAS.md, revisión del banco y cambios de la versión v1
```

## Notas sobre la integridad de los archivos

- `data/raw/` y `data/definitivo/` son el dato primario y nunca se modificaron.
- Los archivos se publican tal como se generaron. Las transcripciones y los `resumen.json` de
  `evidencias/` conservan las rutas locales de la máquina del autor, porque editarlas
  alteraría la evidencia.
- `.gitattributes` desactiva la normalización de finales de línea, para que los SHA-256
  registrados en las evidencias coincidan con los archivos clonados en cualquier sistema.
- Las carpetas `_respaldo_*` de `src/` y `codesys/` conservan las versiones anteriores de los
  scripts de medición, cuyos SHA-256 aparecen en las evidencias de los lotes que se ejecutaron
  con ellas.
- Para esta publicación solo se cambiaron las rutas de entrada de tres scripts de análisis,
  que apuntaban a carpetas de trabajo del autor: `analisis/analisis_v03_spyder.py`,
  `analisis/contraste_hipotesis.py` y `analisis/taxonomia_cwe/c04_clasificar_piloto.py`.
  Cada cambio está comentado en el propio archivo y ninguno altera el cálculo.

## Datos de los modelos

`data/` y `evaluacion_llm/` contienen salidas de modelos comerciales (OpenAI, Anthropic,
Google, DeepSeek) y de un modelo de pesos abiertos (Qwen), incluidas exclusivamente con fines
de reproducibilidad académica. Los resultados son válidos para las versiones evaluadas;
`gemini-3.1-pro-preview` es un modelo en fase preview que puede haber cambiado o dejado de
estar disponible.

## Licencia y cita

Código bajo licencia MIT (ver `LICENSE`). Para citar este repositorio, ver `CITATION.cff`.
