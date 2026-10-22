# Inventario del código y datos — preparación para repositorio

Estado a la fecha del inventario. Tamaño total: **2.3 MB**, 50 archivos de código y
documentación más 291 archivos de datos experimentales.

Leyenda de estado: **V** = verificado en ejecución · **P** = parcial o sin validar ·
**T** = temporal, no debería publicarse.

---

## 1. Núcleo del pipeline de generación

Implementa las tareas 3.3 y 4.1–4.3 del plan de trabajo. **Ejecutado con éxito**: produjo
las 144 respuestas del piloto sin pérdida de datos.

| Archivo | Líneas | Función | Estado |
|---|---|---|---|
| `generar_prompts.py` | 308 | Fuente única de verdad de los enunciados. Genera `tasks.json` y el documento de prompts. Contiene las 26 tareas del banco y los 2 ejemplos few-shot. | **V** |
| `runner.py` | 152 | Orquestador idempotente: recorre modelos × tareas × estrategias × ejecuciones, con reintentos y backoff exponencial. Soporta `--dry-run` y `--config`. | **V** |
| `clients.py` | 151 | Capa de clientes sobre los SDK oficiales: OpenAI, Anthropic, Google y Ollama (vía endpoint compatible). Interfaz común `ModelClient`. | **V** (OpenAI y Anthropic probados; Google y Ollama sin probar) |
| `tasks.json` | 264 | Producto derivado: 26 tareas con prompt zero-shot y few-shot. **No editar a mano.** | **V** |
| `requirements.txt` | 7 | Dependencias: openai, anthropic, google-genai, pyyaml, pandas, matplotlib. | **V** |

### Configuraciones

| Archivo | Líneas | Alcance | Estado |
|---|---|---|---|
| `config.yaml` | 37 | Experimento definitivo: 4 modelos × 26 tareas × 2 estrategias × 3 ejec. = **624** | **V** (dry-run) |
| `config_piloto.yaml` | 39 | Piloto: 2 modelos × 12 tareas × 2 estrategias × 3 ejec. = **144** | **V** (ejecutado) |
| `config_prueba.yaml` | 38 | Prueba de una sola llamada. Cumplió su función. | **T** |

---

## 2. Análisis y post-procesamiento

| Archivo | Líneas | Función | Estado |
|---|---|---|---|
| `extraer_codigo.py` | 92 | Separa el código ST del envoltorio markdown. Verificado como subcadena exacta del original en 144/144 casos. | **V** |
| `analisis_ejemplo.py` | 30 | Lectura del log con pandas; incluye la comprobación de igualdad de `hash_prompt` entre modelos. | **V** |

> **Falta por escribir:** el script que produjo el análisis de conformidad sintáctica con
> blark y las figuras del artículo se ejecutó de forma interactiva y **no quedó guardado
> como archivo**. Debe reconstruirse antes de publicar el repositorio, porque es el que
> genera los resultados del artículo. Es la principal laguna de reproducibilidad.

---

## 3. Bancos de prueba en Structured Text (verificación funcional)

Programas autoverificables que aplican el protocolo de prueba de cada tarea y emiten un
veredicto en la variable `veredicto` (1 = supera, 2 = falla), con detalle por paso en
`resultado[]`.

| Archivo | Líneas | Estado | Nota |
|---|---|---|---|
| `codesys/PRG_Test_B1.st` | 117 | **V** | Plantilla para tareas **sin** temporizadores. Probado en CODESYS real: `veredicto = 1`. Lógica validada por simulación contra 2 implementaciones defectuosas. |
| `codesys/PRG_Test_B2.st` | 118 | **V** | Plantilla para tareas **con** temporizadores (asentamiento por paso). Lógica validada por simulación; **no probado aún en CODESYS**. |
| `codesys/PRG_Test_B3.st` | 162 | **V** | Corregido tras detectar 3 defectos (orden de ejecución, dependencia del ciclo de tarea, umbral no discriminado). Validado contra 4 implementaciones en 3 ciclos de tarea. |
| `codesys/PRG_Test_B4.st` | 22 | **P** | Escrito, sin validar. Incluye bandera de interlock enclavada. |
| `codesys/PRG_Test_B5.st` | 16 | **P** | Sin validar. |
| `codesys/PRG_Test_B6.st` | 17 | **P** | Sin validar. Aplica medición de duraciones por flanco (enmienda 1). |
| `codesys/PRG_Test_I1.st` | 16 | **P** | Sin validar. |
| `codesys/PRG_Test_I2.st` | 18 | **P** | Sin validar. |
| `codesys/PRG_Test_I3.st` | 19 | **P** | Sin validar. |
| `codesys/PRG_Test_I4.st` | 11 | **P** | Sin validar. Incluye interlock enclavado y medición de tiempo muerto. |
| `codesys/PRG_Test_I5.st` | 15 | **P** | Sin validar. |
| `codesys/PRG_Test_I6.st` | 17 | **P** | Sin validar. |

> **Advertencia importante.** Solo tres de los doce bancos están validados. Los nueve
> restantes son de una sola línea por paso, muy compactos, y no han pasado por el
> simulador de ciclo de scan. La experiencia con B3 —donde un banco aparentemente
> correcto reprobaba al 100% de las implementaciones válidas— indica que **no deben
> usarse para recolectar datos** hasta validarlos.

### Validadores

| Archivo | Líneas | Función | Estado |
|---|---|---|---|
| `codesys/validar_harness_B3.py` | 240 | Simula el ciclo de scan y ejecuta el banco B3 contra 4 implementaciones sintéticas (1 correcta, 3 defectuosas) en 3 ciclos de tarea. Plantilla para los demás. | **V** |

> **Faltan 11 validadores**, uno por banco. B1 y B2 se validaron de forma interactiva y
> esa validación tampoco quedó guardada como archivo.

---

## 4. Automatización de CODESYS

| Archivo | Líneas | Función | Estado |
|---|---|---|---|
| `codesys/compilar_lote.py` | 181 | Script del ScriptEngine (IronPython) para compilación por lotes: importa cada respuesta como POU, compila y escribe CSV. | **P** — andamiaje sin probar. Las llamadas marcadas `[API]` requieren verificación contra la versión instalada. |

> Pendiente: el script de escalado de la simulación (modo online + lectura de variables)
> aún no existe.

---

## 5. Documentación

| Archivo | Líneas | Contenido |
|---|---|---|
| `CLAUDE.md` | 63 | Contexto del proyecto para Claude Code: arquitectura, 6 reglas irrompibles, lo que no debe hacerse. |
| `AGENTS.md` | 63 | Equivalente al anterior para Codex. |
| `GUIA_EJECUCION.md` | 57 | Ruta operativa por etapas con casillas de verificación, del piloto al dataset completo. |
| `codesys/CRITERIOS_PILOTO.md` | 310 | **Archivo autoritativo**: las 12 tareas del piloto con enunciado exacto, POU, variables E/S, tiempos IEC, criterio de éxito y plantilla de banco correspondiente. |
| `codesys/ENMIENDAS_HARNESSES.md` | 133 | Las 4 enmiendas a la tabla de pasos, con la evidencia de simulación que las motivó. |
| `codesys/PROMPTS_FASE_CODESYS.md` | 196 | 7 prompts secuenciales para conducir la fase de verificación con Claude Code. |
| `Ejemplo.md` | 62 | Copia antigua del README. **Renombrar a `README.md` o eliminar.** |

---

## 6. Datos experimentales

| Ruta | Archivos | Tamaño | Contenido |
|---|---|---|---|
| `repositorio_piloto/` | 145 | 608 KB | **Dato primario**: 144 respuestas `.st` sin modificar + `log.jsonl` con metadatos y hash del prompt. |
| `repositorio_piloto_limpio/` | 144 | 508 KB | Código extraído del envoltorio markdown. Producto derivado, regenerable. |
| `codesys/muestra_prueba/` | 4 | 16 KB | Muestra de 3 casos con una variable aislada cada uno, más su manifiesto. |
| `codesys/fuentes/` | 2 | 116 KB | Copias de respaldo del banco de pruebas y del documento de prompts. |
| `repositorio_prueba/` | 3 | 12 KB | Prueba de una sola llamada. **T** |
| `repositorio/` | 0 | — | Vacío. Destino del experimento definitivo. |

### Resultados tabulados

| Archivo | Contenido |
|---|---|
| `resultados_sintaxis_blark.csv` | Veredicto del analizador para las 144 respuestas, con tipo y mensaje de error. |
| `resultados_sintaxis_cruzado.csv` | El anterior cruzado con la detección estructural: concordancia del 97.9%. |
| `analisis_piloto.csv` | Métricas descriptivas por respuesta: líneas, comentarios por estilo, tokens, latencia. |
| `extraccion_reporte.csv` | Trazabilidad de la extracción: qué se quitó de cada archivo, caracteres no ASCII, cierre de POU. |
| `manifiesto_revision_codesys.csv` | Índice de las 144 respuestas ordenado para revisión manual. |
| `piloto_run_output.log` | Registro de consola de la corrida del piloto, con la incidencia de rate limit y los tiempos. |

### Figuras (300 dpi)

`fig1_flujo.png` (procedimiento) · `fig2_conformidad.png` (resultado principal) ·
`fig3_errores.png` (categorías de fallo) · `fig2_omision.png` y `fig_piloto.png` (versiones
anteriores, revisables)

---

## 7. Debe quedar FUERA del repositorio

| Ruta | Motivo |
|---|---|
| `.claude/settings.local.json` | Configuración local de la herramienta, no del proyecto. |
| `__pycache__/` y `codesys/__pycache__/` | Bytecode generado. |
| `config_prueba.yaml` | Temporal, ya cumplió su función. |
| `repositorio_prueba/` | Temporal. |

**Sin secretos.** La revisión con expresiones regulares sobre todos los archivos de código,
configuración y documentación no encontró claves de API. La única coincidencia es el valor
dummy `"ollama"` requerido por el SDK, en `clients.py` línea 82. Las claves se leen
exclusivamente de variables de entorno.

---

## 8. Lo que falta antes de publicar

En orden de importancia para la reproducibilidad:

1. **Reconstruir como script el análisis de conformidad sintáctica.** Es el que genera los
   resultados del artículo y ahora mismo no existe como archivo.
2. **`README.md` en la raíz**: descripción, cómo reproducir, estructura, cita del trabajo.
3. **`LICENSE`**: decidir la licencia (MIT o Apache-2.0 para el código; CC-BY para los datos
   es habitual en investigación).
4. **`.gitignore`** con las exclusiones de la sección 7.
5. **Guardar los validadores de B1 y B2** como archivos, replicando el patrón de B3.
6. Decidir si el dato primario (las 144 respuestas) se publica. A favor: replicabilidad, y
   es el argumento central del capítulo de metodología. A considerar: son salidas de
   modelos comerciales; conviene revisar los términos de uso de cada proveedor respecto a
   la publicación de sus salidas.
7. Renombrar o eliminar `Ejemplo.md`.

---

## Resumen cuantitativo

- **Código Python**: 6 archivos, 1 002 líneas (5 verificados, 1 andamiaje)
- **Bancos en Structured Text**: 12 archivos, 548 líneas (3 validados, 9 sin validar)
- **Configuraciones**: 3 archivos YAML
- **Documentación**: 7 archivos Markdown, 884 líneas
- **Datos**: 291 archivos, 1.1 MB · 6 CSV de resultados · 5 figuras a 300 dpi
- **Experimentos ejecutados**: 1 piloto completo (144 respuestas, 24.6 min, sin pérdida de datos)
