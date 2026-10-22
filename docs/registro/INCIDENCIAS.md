# Registro de incidencias — reinicio desde el banco (fase experimental)

*Abierto el 2 de octubre de 2026 a pedido de Luis. Reúne, en un solo lugar y con formato uniforme, las incidencias ocurridas desde el 28 de septiembre de 2026. La cronología completa, con el detalle de cada corrida, está en `BITACORA.md`; aquí va lo que sirve para el apartado de incidencias de la tesis. Las incidencias del piloto de julio (por ejemplo el error 429 de OpenAI) están en `04_Ejecucion_y_Datos/Informe_Piloto.docx`.*

**Cómo leerlo.** Cada incidencia tiene un identificador `INC-nn`, la fecha, qué pasó, la causa, cómo se detectó, qué habría pasado de no detectarse, la solución y dónde está la evidencia. La categoría indica de quién era el defecto:

- **Entorno:** herramientas, sistema operativo, proveedores.
- **Instrumento:** los scripts que miden (compilación, simulación, extracción).
- **Banco de prueba:** los harnesses y sus dobles.
- **Operación:** errores de ejecución o de manejo.
- **Decisión:** ambigüedades que exigieron fijar un criterio.

## Resumen

| ID | Fecha | Categoría | Incidencia | Estado |
|---|---|---|---|---|
| INC-01 | 2026-09-28 | Operación | El hook de guardia no bloqueaba `rm -rf data/raw` | Resuelta |
| INC-02 | 2026-09-29 | Entorno | PowerShell 5.1 abortaba el lote ante cualquier texto en stderr | Resuelta |
| INC-03 | 2026-09-29 | Instrumento | La sonda v1 fallaba al escribir texto con acentos | Resuelta |
| INC-04 | 2026-09-30 | Entorno | CODESYS no arrancaba sin interfaz por el entrecomillado del perfil | Resuelta |
| INC-05 | 2026-09-30 | Instrumento | Un FB con errores deliberados compilaba con "0 errores" | Resuelta |
| INC-06 | 2026-09-30 | Instrumento | El control de FUNCTION fallaba por entradas sin pasar | Resuelta |
| INC-07 | 2026-09-30 | Operación | Un script corregido no llegó al disco y se midió con la versión vieja | Resuelta |
| INC-08 | 2026-09-30 | Entorno | PowerShell 5.1 devolvía vacío el conteo de un CSV de una fila | Resuelta |
| INC-09 | 2026-09-30 | Instrumento | El análisis en Spyder fallaba por celdas (IndexError) | Resuelta |
| INC-10 | 2026-09-30 | Instrumento | La simulación copiaba el veredicto del doble anterior | Resuelta |
| INC-11 | 2026-09-30 | Banco de prueba | 42 dobles no compilaban: `dt` es palabra reservada | Resuelta |
| INC-12 | 2026-09-30 | Instrumento | El extractor descartaba la declaración en respuestas de dos bloques | Resuelta |
| INC-13 | 2026-09-30 | Banco de prueba | El harness de I8 aprobaba "marcha gana al paro" | Resuelta |
| INC-14 | 2026-09-30 | Banco de prueba | El harness de A3 reprobaba a la correcta a 20 ms | Resuelta |
| INC-15 | 2026-09-30 | Decisión | CODESYS no deja escribir una `VAR` local de un PROGRAM (C3) | Resuelta |
| INC-16 | 2026-10-01 | Banco de prueba | A4: el paso de fallo dependía del redondeo de REAL de 32 bits | Resuelta |
| INC-17 | 2026-10-01 | Banco de prueba | 12 dobles de A1 no compilaban: `dt` otra vez | Resuelta |
| INC-18 | 2026-10-01 | Entorno | La PC no estaba conectada a la hora de la tarea programada | Resuelta |
| INC-19 | 2026-10-02 | Entorno | `gemini-2.5-pro` no disponible para cuentas nuevas (HTTP 404 al generar) | Resuelta: sustituido por `gemini-3.1-pro-preview` |
| INC-20 | 2026-10-02 | Entorno | Google cambió el formato de las claves (`AQ.` en vez de `AIza`) | Resuelta |
| INC-21 | 2026-10-02 | Operación | La clave de Google se guardó mal (70 caracteres) | Resuelta |
| INC-22 | 2026-10-02 | Operación | La clave de Google quedó visible en el chat | Resuelta |
| INC-23 | 2026-10-02 | Entorno | Ollama instalado pero apagado; el modelo de la tesis no estaba descargado | Resuelta |
| INC-24 | 2026-10-02 | Entorno | Windows reportaba 4 GB de VRAM en una tarjeta de 12 GB | Resuelta |
| INC-25 | 2026-10-02 | Entorno | Contexto de Ollama en 4096 tokens: riesgo de recorte silencioso del prompt | Resuelta |
| INC-26 | 2026-10-02 | Instrumento | El log no registraba por qué terminó cada respuesta | Resuelta (comprobada en la calibración) |
| INC-27 | 2026-10-02 | Operación | La ventana de PowerShell no tenía cargada `GOOGLE_API_KEY` | Resuelta |
| INC-28 | 2026-10-02 | Decisión | El razonamiento de `gemini-3.1-pro-preview` agota el tope de 2 500 tokens: 6 de 6 respuestas de A6 truncadas | Resuelta: tope total de 10 000 tokens para Gemini |
| INC-29 | 2026-10-03 | Operación | PowerShell bloqueó `ejecutar_con_evidencia.ps1` por la política de ejecución | Resuelta |
| INC-30 | 2026-10-05 | Instrumento | El simulador guardaba solo el primer mensaje de error; un "Internal error" genérico de CODESYS ocultaba la causa | Resuelta |
| INC-31 | 2026-10-06 | Instrumento | Los scripts de CODESYS no reconocían `TYPE` con el nombre en la línea siguiente: 9 respuestas de A5 marcadas como no compilables por error | Resuelta |
| INC-32 | 2026-10-06 | Operación | Bloque de 5 comandos pegado de una vez: las líneas se mezclaron y la simulación corrió con parámetros corruptos | Resuelta |
| INC-33 | 2026-10-06 | Banco de prueba | A1: 18 de 24 respuestas no compilan por usar `dt` como variable; el enunciado escribe la fórmula con "dt" | Decidida: se mantiene A1 y se reporta sensibilidad sin A1 |
| INC-34 | 2026-10-06 | Decisión | CODESYS rechaza `END_STRUCT;` (forma del estándar IEC): 7 respuestas de A5 no compilan por dialecto | Resuelta: análisis estricto más sensibilidad S2 |

## Detalle

### INC-01 — El hook de guardia no bloqueaba `rm -rf data/raw`
- **Qué pasó:** la expresión regular del hook `guardia.py` no reconocía ese comando.
- **Causa:** el patrón no contemplaba el prefijo del comando.
- **Detección:** prueba del hook antes de usarlo.
- **Riesgo evitado:** borrar el dato primario del estudio.
- **Solución:** patrón corregido; el manejo de redirecciones se hizo específico por destino. Probado aislado: bloquea (código 2) y pide aprobación cuando corresponde.

### INC-02 — PowerShell 5.1 abortaba el lote ante texto en stderr
- **Causa:** con `$ErrorActionPreference = "Stop"`, cualquier salida de error de un programa nativo detiene el script.
- **Solución:** `"Continue"` en `ejecutar_con_evidencia.ps1`.

### INC-03 — La sonda v1 fallaba con acentos
- **Causa:** el ScriptEngine de CODESYS es IronPython 2.7 y el informe mezclaba texto no ASCII.
- **Solución:** la sonda v2 limpia todas las cadenas a ASCII. Resultado: 57 comprobaciones correctas.

### INC-04 — CODESYS no arrancaba sin interfaz
- **Qué pasó:** `--noUI --runscript` abortaba pidiendo un perfil.
- **Causa:** PowerShell 5.1 entrecomillaba el argumento completo (`"--profile=..."`); además `&` no esperaba al proceso.
- **Solución:** comillas solo en el valor (`--profile="CODESYS V3.5 SP22 Patch 3"`) y `Start-Process ... -PassThru` con `WaitForExit`.

### INC-05 — Un FB con errores compilaba con "0 errores"
- **Causa:** CODESYS no compila los POU que nada referencia.
- **Detección:** control del instrumento: un FB con errores sembrados que debía fallar.
- **Riesgo evitado:** dar por compilable todo el corpus (criterio 2 inflado al 100 %).
- **Solución:** cada respuesta se instancia desde un `PRG_Envoltorio` incluido en la MainTask. Antes de cada lote se compilan tres controles (correcto, con errores, función).

### INC-06 — El control de FUNCTION fallaba
- **Causa:** CODESYS exige pasar todas las entradas de una FUNCTION ("necesita exactamente 2 entradas").
- **Solución:** el envoltorio declara y pasa una variable por cada `VAR_INPUT`.

### INC-07 — Se midió con una versión vieja del script
- **Qué pasó:** la corrección de INC-06 no había llegado al disco; la corrida usó el script anterior.
- **Detección:** el SHA-256 del script en `resumen.json` no era el esperado.
- **Lección adoptada:** tras cada cambio se comprueba el hash del script en la evidencia.

### INC-08 — Conteo vacío con un CSV de una fila
- **Causa:** en PowerShell 5.1 un único objeto no tiene `.Count`.
- **Solución:** envolver en `@(...)`.

### INC-09 — El análisis fallaba al ejecutarlo por celdas en Spyder
- **Causa:** `__doc__.split("\n")[1]` daba IndexError en modo celda.
- **Solución:** descripción estática en `argparse`.

### INC-10 — La simulación copiaba el veredicto del doble anterior
- **Qué pasó:** en la primera prueba, todos los dobles de una tarea repetían el resultado del primero y terminaban en 0,6 s (8/25 coincidencias).
- **Causa:** `login(OnlineChangeOption.Try)` hacía un cambio en línea y conservaba las variables de la simulación anterior.
- **Riesgo evitado:** medir el criterio 1 con veredictos heredados.
- **Solución:** `login(Never)` + `reset(Cold)`; comprobación de que el veredicto está en 0 antes de arrancar y alerta si llega antes de la mitad de la duración del harness. Resultado tras la corrección: 25/25.

### INC-11 — 42 dobles no compilaban por la variable `dt`
- **Causa:** `DT` es palabra reservada de IEC 61131-3 (DATE_AND_TIME). El analizador blark la acepta; CODESYS la rechaza.
- **Solución:** renombrada a `dScan`. Repetición: 52/52.
- **Valor para la tesis:** otro caso de "el parser acepta lo que el compilador rechaza".

### INC-12 — El extractor descartaba la declaración
- **Qué pasó:** dos respuestas de Claude en I6 separaban declaración y cuerpo en dos bloques; el extractor v1 conservaba solo el más largo.
- **Riesgo evitado:** contar como fallo del modelo un defecto de la extracción.
- **Solución:** extractor v2 con regla por patrón (decisión de Luis, 30-09). Efecto en el piloto: cambia 1 resultado de criterio 1 y 1 de criterio 2.

### INC-13 — El harness de I8 aprobaba una implementación defectuosa
- **Qué pasó:** "marcha gana al paro" arrancaba el compresor un solo scan y el harness muestreaba después.
- **Detección:** validación del harness con dobles en Python, antes de CODESYS.
- **Solución:** vigilancia continua con bandera enclavada en los 12 pasos donde la salida debe permanecer apagada.

### INC-14 — El harness de A3 reprobaba a la implementación correcta a 20 ms
- **Causa:** cada cambio de paso consume un scan; el eco "dentro del plazo" llegaba a 0,51 s.
- **Solución:** paso 13 acortado a 0,20 s.

### INC-15 — C3: E/S declaradas como `VAR` local
- **Qué pasó:** CODESYS no admite escribir desde fuera una variable local de un PROGRAM.
- **Criterio fijado:** una respuesta así es **interfaz no conforme**, igual que los FB del piloto con E/S en `VAR`. El doble correspondiente se retiró del manifiesto y se conserva en `_dobles_retirados/`.

### INC-16 — A4: resultado dependiente del redondeo
- **Causa:** CODESYS usa REAL de 32 bits y el validador float de 64; un bloque que no acota la rampa fallaba en pasos distintos.
- **Solución:** la prueba de sobrepaso se movió al inicio, desde 0,0, donde el resultado es exacto.

### INC-17 — Los 12 dobles de A1 no compilaban (`dt` de nuevo)
- **Qué pasó:** se repitió el error de INC-11 al escribir los dobles del PID. Fue un error del asistente, no del harness.
- **Solución:** renombrada a `tMuestreo` y nuevo `lint_identificadores.py`, que revisa dobles y harnesses antes de cada lote. Repetición: 24/24.

### INC-18 — La PC no estaba conectada a la hora programada
- **Qué pasó:** el chequeo de C4 se preparó y validó a las 10:00, pero no pudo instalarse en la carpeta hasta que la PC volvió a estar conectada.
- **Solución:** instalación y validación con el `tasks.json` real al reconectar (20/20).

### INC-19 — `gemini-2.5-pro` no disponible para cuentas nuevas (RESUELTA con cambio de modelo)
- **Qué pasa:** Google limita los modelos 2.5 a cuentas que ya los habían usado. El modelo aparece en el catálogo de la cuenta de Luis, pero eso no garantiza que deje generar.
- **Confirmación (2026-10-02):** una llamada real mínima a `generateContent` devolvió HTTP 404 `NOT_FOUND`: *"This model models/gemini-2.5-pro is no longer available to new users. Please update your code to use models/gemini-3.1-pro-preview..."*. En la misma prueba `gpt-4o-2024-08-06` y `claude-sonnet-4-6` generaron sin problema.
- **Cómo se detectó:** prueba de generación de 1 token por proveedor, hecha antes de la calibración por una sospecha de saldo vencido en OpenAI (descartada).
- **Riesgo evitado:** que el fallo apareciera a mitad de las 720 ejecuciones, con el diseño ya en marcha.
- **Efecto:** el modelo de Google previsto en el plan aprobado (`gemini-2.5-pro`) no puede usarse con la cuenta de Luis. Hay que elegir un sustituto, y al ser un cambio respecto al plan aprobado, consultarlo con la asesora y documentarlo.
- **Prueba de candidatos (2026-10-02, llamada mínima a cada uno):** `gemini-3.1-pro-preview` → HTTP 429 *Too Many Requests* en la primera llamada (apunta a cuota nula del nivel gratuito para ese modelo; por confirmar con el cuerpo del error y el plan del proyecto en AI Studio); `gemini-3.8-flash` → genera (`finishReason` STOP, 91 tokens de razonamiento para una respuesta de 1 token); `gemini-2.5-flash` → HTTP 404, igual que el 2.5 Pro. Conclusión parcial: toda la familia 2.5 está cerrada para esta cuenta, y figurar en el catálogo no prueba disponibilidad.
- **Causa del 429 confirmada (2026-10-02):** el cuerpo del error indica `RESOURCE_EXHAUSTED`, métrica `generate_content_free_tier_requests`, `limit: 0, model: gemini-3.1-pro`. El proyecto de AI Studio está en el nivel gratuito, que no da cuota alguna al modelo Pro; el "retry in 19h" del mensaje no aplica, porque con límite 0 esperar no lo resuelve. Usar el Pro exige activar facturación en el proyecto.
- **Opciones para la decisión:** (a) `gemini-3.1-pro-preview` con facturación activada: conserva la gama Pro del plan, implica gasto y un modelo en *preview*; (b) `gemini-3.8-flash`: genera hoy con nombre estable, pero baja de gama y queda sujeto a los límites diarios del nivel gratuito.
- **Acceso resuelto (2026-10-02):** Luis activó el nivel de pago en el proyecto de AI Studio (recarga de 5 USD). La llamada mínima a `gemini-3.1-pro-preview` respondió: `modelVersion` = `gemini-3.1-pro-preview`, `finishReason` STOP, 96 tokens de razonamiento, 1 de salida.
- **Decisión (2026-10-02):** Luis confirma que tiene el visto bueno de su asesora para este tipo de decisiones y aprueba el sustituto. `gemini-3.1-pro-preview` reemplaza a `gemini-2.5-pro` en `src/config.yaml` y `src/config_calibracion.yaml`, con una nota en ambos archivos; también se actualizaron `CLAUDE.md`, el agente `ejecutor` y `verificar_modelos.ps1`.
- **Medidas por ser un modelo *preview*:** las llamadas de Google se ejecutarán en un solo día, y `clients.py` guarda en `modelo_reportado` la versión que devuelve la API (`model_version`) en lugar de repetir el identificador pedido.
- **Comprobación tras el cambio:** `verificar_hashes.py` confirma la integridad de los prompts; el dry-run reporta 720 pendientes en el banco completo. Versiones anteriores en `src/_respaldo_20261002b/`.
- **Efecto en la tesis:** desviación respecto al plan aprobado, impuesta por el proveedor. Debe declararse en la metodología (modelo evaluado y motivo) y en las limitaciones (modelo en fase *preview*). Queda por medir en la calibración cuánto del tope de 2 500 tokens consume el razonamiento.

### INC-20 — Cambio de formato de las claves de Google
- **Qué pasó:** AI Studio ya solo emite claves con prefijo `AQ.` (53 caracteres) en lugar de `AIza` (39).
- **Efecto:** la referencia de longitud que se había dado era la del formato antiguo. Las claves `AQ.` funcionan con la cabecera `x-goog-api-key` en el endpoint nativo.

### INC-21 — La clave de Google se guardó mal
- **Qué pasó:** quedó con 70 caracteres y Google respondía `API_KEY_INVALID` (HTTP 400).
- **Solución:** guardarla directamente desde el portapapeles, sin pegarla a mano.

### INC-22 — La clave de Google quedó visible en el chat
- **Qué pasó:** al pegar la salida de la consola, la clave apareció completa.
- **Solución:** clave revocada y reemplazada por una nueva (confirmado por Luis). Regla del proyecto reafirmada: las claves viven solo en variables de entorno.

### INC-23 — Ollama apagado y modelo sin descargar
- **Qué pasó:** Ollama 0.33.3 estaba instalado pero el servicio no corría; el modelo presente era otro (`Qwen3.8-27B-Uncensored`), no el del plan.
- **Solución:** se abrió Ollama y se descargó `qwen2.5-coder:14b` (ID `9ec8897f747e`, 9,0 GB).

### INC-24 — Windows reportaba 4 GB de VRAM
- **Causa:** el campo `AdapterRAM` de WMI es de 32 bits y se queda en 4 GB.
- **Verificación:** `nvidia-smi` reporta 12 288 MiB (RTX 3060). `ollama ps` muestra 100 % GPU tanto con el contexto por defecto (9,5 GB) como con el de 8192 (10 GB).

### INC-25 — Contexto de Ollama en 4096 tokens
- **Qué pasó:** `ollama ps` mostró `CONTEXT 4096`. El prompt más largo del banco (unos 1 300 tokens) más el tope de salida (2 500) suman unos 3 800.
- **Riesgo evitado:** si se excede, Ollama recorta el prompt sin avisar y el modelo local respondería a un enunciado incompleto, en desventaja frente a los modelos comerciales.
- **Solución:** `OLLAMA_CONTEXT_LENGTH=8192` como variable de entorno de usuario. Confirmado con `ollama ps`: CONTEXT 8192, 10 GB, 100 % GPU. Queda como parámetro documentado del experimento.

### INC-26 — El log no registraba el motivo de fin de cada respuesta
- **Qué pasaba:** `clients.py` guardaba texto, tokens y latencia, pero no si el modelo terminó solo o lo cortó el tope de tokens. En Gemini 2.5 Pro el razonamiento interno consume parte del tope. Además, una respuesta vacía de Gemini habría detenido el runner.
- **Riesgo evitado:** no poder distinguir una respuesta completa de una truncada.
- **Solución (2026-10-02, aprobada por Luis):** el log añade `motivo_fin` (lo que reporta cada API), `tokens_razonamiento`, `truncada` y `vacia`; la consola marca las respuestas truncadas o vacías. No cambian los prompts ni los parámetros de generación: `verificar_hashes.py` confirma la integridad y el dry-run sigue reportando 720 pendientes. Versiones anteriores en `src/_respaldo_20261002/`.
- **Comprobado (2026-10-02):** en las 48 llamadas de la calibración los cuatro proveedores rellenan `motivo_fin` (`stop`, `end_turn`, `STOP`/`MAX_TOKENS`), y `truncada` marcó correctamente las 6 respuestas cortadas de Gemini. Gracias a estos campos se detectó INC-28.

### INC-27 — La ventana de PowerShell no tenía cargada `GOOGLE_API_KEY`
- **Qué pasó:** la prueba de generación contra Google falló sin mensaje de la API y luego con "Referencia a objeto no establecida como instancia de un objeto".
- **Causa:** la clave está guardada como variable de entorno de usuario, pero la ventana de PowerShell en uso no la tenía cargada, de modo que la cabecera `x-goog-api-key` iba vacía y la petición no llegaba a salir.
- **Solución:** cargarla en la sesión con `$env:GOOGLE_API_KEY = [Environment]::GetEnvironmentVariable("GOOGLE_API_KEY", "User")` (53 caracteres) o abrir una ventana nueva. Tras cargarla, la petición salió y Google respondió (ver INC-19).
- **Reincidencia:** volvió a ocurrir el mismo día en otra ventana, durante la prueba de candidatos de Google.
- **Corrección de raíz (2026-10-02):** `src/ejecutar_calibracion.ps1` y `herramientas/ejecutar_con_evidencia.ps1` cargan en la sesión las claves que falten desde las variables de usuario, sin mostrarlas. La calibración además se detiene antes de gastar si falta alguna clave.

### INC-28 — El razonamiento de Gemini agota el tope de tokens (RESUELTA)
- **Qué pasó:** en la calibración (B1 y A6, 48 llamadas), `gemini-3.1-pro-preview` terminó las 6 ejecuciones de A6 con `MAX_TOKENS`. En cada una gastó entre 2 396 y 2 400 tokens en razonamiento interno y dejó 100 o menos para la respuesta, que quedó en fragmentos de unos 300 caracteres (en few-shot, incluso restos del propio razonamiento en lugar de código). En B1 terminó bien, pero usando entre 1 372 y 2 110 tokens de razonamiento, es decir, también cerca del tope.
- **Causa:** en la API de Gemini `max_output_tokens` cubre razonamiento más respuesta, y en los modelos Pro el razonamiento no se puede desactivar. En OpenAI, Anthropic y Ollama, con los modelos del estudio, los 2 500 tokens son íntegros para la respuesta.
- **Cómo se detectó:** campos `motivo_fin`, `truncada` y `tokens_razonamiento` añadidos al log (INC-26), y por eso la calibración se amplió con A6.
- **Riesgo evitado:** lanzar las 180 ejecuciones de Google y obtener respuestas truncadas en casi todas las tareas intermedias y avanzadas, lo que se habría leído como bajo rendimiento del modelo cuando es un artefacto del parámetro.
- **Los otros tres modelos:** sin truncadas ni vacías; salida máxima observada 1 790 tokens (Claude, A6), 667 (GPT-4o) y 701 (Qwen).
- **Decisión (2026-10-02, Luis):** opción (a). El tope de 2 500 tokens se interpreta como tope de la respuesta visible, igual para los cuatro modelos; a Gemini se le envía un tope total mayor que incluye el razonamiento, y el log marca si la respuesta visible supera los 2 500 (`excede_tope_respuesta`).
- **Implementación:** `runner.py` acepta una clave opcional por modelo, `max_tokens_total`, que es el tope enviado a la API; el log añade `max_tokens_api`. Sin esa clave el comportamiento no cambia (dry-run: 720 pendientes; hashes íntegros). Respaldo en `src/_respaldo_20261002c/`.
- **Siguiente paso:** sonda de 6 llamadas (`ejecutar_sonda_gemini.ps1`, A6, tope de API 20 000) para medir el razonamiento real y fijar el valor definitivo antes de tocar `config.yaml`.
- **Resultado de la sonda (2026-10-03, 6 llamadas sobre A6 con tope de API 20 000):** 6 de 6 terminaron con `STOP` y código completo (todas cierran `END_FUNCTION_BLOCK`). Razonamiento entre 2 143 y 3 787 tokens (media 2 760); respuesta visible entre 629 y 773 tokens, muy por debajo de 2 500. Latencia de 20 a 32 s. Costo aproximado 0,26 USD con precio de lista no confirmado.
- **Valor fijado:** `max_tokens_total: 10000` para `gemini-3.1-pro-preview` en `src/config.yaml` (2 500 de respuesta más 7 500 de margen de razonamiento, el doble del máximo medido). Los otros tres modelos siguen con 2 500, que en ellos es íntegro para la respuesta.
- **Regla fijada de antemano:** si una respuesta de Gemini termina en `MAX_TOKENS` aun con ese tope, se reporta como truncada y no se repite.
- **Efecto en la tesis:** debe declararse en la metodología que el tope de 2 500 tokens se aplica a la respuesta visible y que el modelo de Google recibe además un presupuesto de razonamiento, porque su API no permite separarlos ni desactivarlo. Los tokens de razonamiento quedan registrados por llamada.
- **Estado previo a la decisión:** decisión metodológica pendiente de Luis. Opciones: (a) interpretar el tope como 2 500 tokens de respuesta visible y dar a Gemini un tope total mayor que incluya el razonamiento; (b) lo mismo, pero además limitando el nivel de razonamiento; (c) mantener 2 500 y reportar las truncadas; (d) cambiar a un modelo Flash. Los datos de A6 de Gemini en `data/calibracion` no son utilizables.

### INC-29 — PowerShell bloqueó el script del lote por la política de ejecución
- **Qué pasó:** al lanzar el primer lote definitivo con `.\herramientas\ejecutar_con_evidencia.ps1 ...`, PowerShell respondió "la ejecución de scripts está deshabilitada en este sistema" (`UnauthorizedAccess`).
- **Causa:** la instrucción que se dio omitía `powershell -ExecutionPolicy Bypass -File`, que sí se había usado en la calibración y en la sonda. Error de la instrucción, no del script.
- **Efecto:** ninguno. El script no llegó a ejecutarse: no hubo llamadas ni se escribió nada en `data/definitivo`.
- **Solución:** lanzar siempre los `.ps1` con `powershell -ExecutionPolicy Bypass -File <script> <parámetros>`. No se cambia la política del sistema.

### INC-30 — El simulador solo guardaba el primer mensaje de error de compilación
- **Qué pasó:** en la prueba corta del experimento definitivo (GPT-4o; B1, B7, C3 y A6; 24 simulaciones), las 6 respuestas de A6 no compilaron y la nota decía `Internal error in _IStatement: FOR i := 0 TO 7 BY 1 DO ...`, un mensaje que parece un fallo de CODESYS y no del código.
- **Causa real:** las 6 respuestas de GPT-4o usan `FOR i := 0 TO 7` sin declarar la variable `i` (comprobado en los archivos: ninguna declara `i`; el doble correcto de A6 sí la declara y compila). CODESYS antepone ese mensaje interno a los errores normales, y `simular_lote_sp22.py` conservaba únicamente el primero de la lista (el recuento sí era correcto: entre 14 y 32 errores).
- **Riesgo evitado:** clasificar esas respuestas como "fallo del instrumento" o no poder justificar el criterio 2 con el mensaje concreto del compilador.
- **Solución:** el simulador añade la columna `errores_texto` con todos los mensajes distintos (hasta 12). No interviene en `compila` ni en `veredicto`. Versión anterior en `codesys/_respaldo_simular_lote_sp22_bb5e.py`.
- **Comprobado (2026-10-06):** la misma prueba de 24 simulaciones con el script nuevo (SHA `21517ab5…`) dio 0 diferencias en las columnas anteriores. La columna nueva muestra la causa: `Identificador 'i' sin definir`, precedido por una `NullReferenceException` interna del compilador de CODESYS en el `FOR`. Es un error real de las respuestas; la excepción interna es la forma en que SP22 reacciona a una variable de bucle sin declarar.
- **Extensión:** el mismo cambio se aplicó a `compilar_lote_sp22.py` (criterio 2), que guardaba solo `primer_error`. Respaldo en `codesys/_respaldo_compilar_lote_sp22_77d5.py`.

### INC-31 — `TYPE` con el nombre en la línea siguiente no se reconocía
- **Qué pasó:** en la primera compilación de las 720 extracciones (`compilacion_definitivo.csv`), 9 respuestas de A5 (5 de Claude, 2 de GPT-4o, 2 de Qwen) dieron `Tipo desconocido: 'ST_Evento'` aunque sí declaraban la estructura.
- **Causa:** esas respuestas escriben `TYPE` en una línea y `ST_Evento :` en la siguiente, que es la forma canónica de IEC 61131-3. La expresión que separa las unidades (`RE_CABECERA`, compartida por `compilar_lote_sp22.py` y `simular_lote_sp22.py`) exigía el nombre en la misma línea que `TYPE`, así que la estructura no se importaba al proyecto. Los dobles de A5 usaban la forma de una línea y por eso la verificación de harnesses no lo detectó.
- **Cómo se detectó:** gracias a la columna `errores_texto` (INC-30), al ver que el error se repetía en respuestas que contenían la declaración.
- **Riesgo evitado:** 9 falsos "no compila" en el criterio 2 y los correspondientes falsos fallos en el criterio 1, concentrados en un modelo (Claude).
- **Solución:** la expresión acepta el nombre en la línea siguiente cuando va seguido de `:`. Comprobado sin CODESYS sobre los 720 archivos: la separación de unidades cambia exactamente en esos 9 y en ninguno más; todos los `TYPE` quedan reconocidos. SHA nuevos: `simular_lote_sp22.py` `0d5468ae…`, `compilar_lote_sp22.py` `f1d25713…`; respaldos `_respaldo_simular_lote_sp22_2151.py` y `_respaldo_compilar_lote_sp22_3bf1.py`.
- **Comprobado (2026-10-06):** en la recompilación (`compilacion_definitivo_v2.csv`) las 9 respuestas ya importan la estructura (`pous` = `ST_Evento;FB_Registro`). Dos de ellas (Qwen) pasan a compilar; es el único cambio de veredicto entre v1 y v2. Las otras 7 siguen sin compilar por una causa distinta y ajena al instrumento (INC-34).
- **Consecuencia:** `compilacion_definitivo.csv` queda como evidencia del defecto y NO se usa en el análisis; el resultado válido será `compilacion_definitivo_v2.csv`. El piloto no se ve afectado (no incluía A5).

### INC-32 — Comandos pegados en bloque se mezclaron
- **Qué pasó:** al pegar de una vez las cinco líneas de lotes, PowerShell fue leyendo el texto pegado mientras el primer comando seguía en ejecución y las líneas se concatenaron: la simulación de GPT-4o recibió como salida `definitivo_gpt4o.csvcd` y como filtro de tareas la ruta del proyecto, y terminó en segundos con 0 simulaciones. Los lotes siguientes no llegaron a ejecutarse.
- **Efecto:** ninguno sobre los datos. La compilación sí terminó bien antes del problema. El archivo vacío se movió a `data/results_codesys/_descartados/`.
- **Solución:** un único script, `codesys/ejecutar_definitivo.ps1`, lanza los cinco lotes en orden y omite los que ya tengan salida, de modo que basta un solo comando y se puede retomar.
- **Error de la instrucción:** se indicó pegar las cinco líneas juntas; no se debió.

### INC-33 — A1: la mayoría de las respuestas usa `dt` como nombre de variable (ABIERTA)
- **Qué pasa:** en A1 (PID) 18 de 24 respuestas no compilan porque declaran una variable llamada `dt` (Claude 4 de 6, Gemini 5, GPT-4o 3, Qwen 6). `DT` es palabra reservada de IEC 61131-3 (abreviatura de DATE_AND_TIME) y CODESYS la rechaza.
- **Por qué importa:** el enunciado pide código conforme a IEC 61131-3, así que es un error real de los modelos; pero el propio enunciado escribe la fórmula con "∫e dt" y "de/dt", lo que puede inducir ese nombre. El mismo error se cometió dos veces al escribir los dobles del harness (INC-17 y la incidencia anterior del mismo tipo).
- **Qué no se hace:** no se cambia el enunciado ni se repiten las ejecuciones; el banco está congelado y los datos ya son primarios.
- **Decisión (2026-10-06, Luis):** se acepta la propuesta. Sensibilidad S1 calculada en `analisis/criterios_definitivo.py`: sin A1 el criterio 1 pasa de 56,0 % a 58,0 % y el criterio 2 de 86,3 % a 89,4 %; el orden de los modelos no cambia.
- **Propuesta de reporte:** mantener A1 en los resultados, declarar el posible efecto inductor del enunciado en las amenazas a la validez y añadir un análisis de sensibilidad (criterios 1 y 2 con y sin A1). Pendiente de decisión de Luis.

### INC-34 — CODESYS no acepta `END_STRUCT;` (ABIERTA, decisión metodológica)
- **Qué pasa:** 7 respuestas de A5 (5 de Claude, 2 de GPT-4o) declaran la estructura como `TYPE ST_Evento : STRUCT ... END_STRUCT; END_TYPE`, con punto y coma tras `END_STRUCT`. CODESYS V3.5 SP22 responde `Se esperaba END_TYPE en lugar de ';'`. Las respuestas que escriben `END_STRUCT` sin punto y coma compilan (comparación directa entre respuestas del mismo modelo).
- **Por qué es una decisión y no un error simple:** el punto y coma tras `END_STRUCT` es la forma que da la gramática de IEC 61131-3, y el enunciado pide código "conforme a IEC 61131-3"; el rechazo viene del dialecto de CODESYS. Es el caso inverso al de `dt` (INC-33), donde el modelo infringe el estándar.
- **Opciones:** (a) criterio estricto: el criterio 2 es "compila en CODESYS tal como se entregó"; las 7 cuentan como no compilables y se reporta la causa; (b) normalizar esa diferencia de dialecto antes de compilar, como se hizo con el `;` tras `END_IF` en C4; (c) análisis principal estricto más un análisis de sensibilidad con la normalización.
- **Recomendación:** (c). Mantiene la regla de no modificar las respuestas en el análisis principal y muestra cuánto pesa el dialecto.
- **Decisión (2026-10-06, Luis):** opción (c). Análisis principal estricto; sensibilidad S2 con la normalización. Las 7 copias normalizadas están en `data/processed_sens_endstruct/` con su manifiesto (un solo carácter eliminado por archivo); se compilaron y simularon con `codesys/ejecutar_sens_endstruct.ps1`.
- **Resultado de S2 (2026-10-07):** las 7 copias normalizadas compilan (controles del instrumento correctos); 2 pasan el harness (Claude zero-shot 1 y GPT-4o few-shot 1) y 5 fallan por lógica. Con la normalización el criterio 2 pasa de 86,3 % a 87,5 % (Claude de 90,7 % a 94,0 %; GPT-4o de 79,3 % a 80,7 %) y el criterio 1 de 56,0 % a 56,3 %. El orden de los modelos y las conclusiones no cambian. El dialecto explica 7 de los 82 fallos de compilación.


## INC-35 — Cambio de protocolo: la evaluación de los criterios 3–5 y de C1/C2/C5/C6 pasa de humana a LLM
- **Fecha:** 2026-10-09 (hora de Panamá).
- **Qué cambia:** el protocolo original fijaba evaluación humana a ciegas por dos evaluadores, "sin LLM como juez" (CLAUDE.md, regla 6; `Criterios_1_y_2_Definitivo.md`). Por decisión de Luis y su asesora, la evaluación válida pasa a ser la de evaluadores LLM.
- **Diseño adoptado:** dos evaluaciones LLM independientes, a ciegas, con el mismo material e instrucciones. La primera es la de Claude, hecha el 2026-10-08 (`evaluacion_manual|evaluacion_rubrica/_COMPARACION_IA_NO_OFICIAL/`). La segunda es la de otro modelo, con el paquete `llm-plc-st-eval/evaluacion_llm/Paquete_Evaluador_LLM2/`. Se medirá la concordancia entre ambas (kappa, kappa ponderado y acuerdo ±1) y con eso se decidirá cuál queda como oficial o si se combinan.
- **Amenazas a la validez a declarar:** (1) autopreferencia, porque el primer evaluador es de la familia de `claude-sonnet-4-6`, uno de los modelos evaluados, y el segundo evaluador puede tener el mismo problema si pertenece a la familia de otro modelo evaluado; (2) la evaluación ya no es humana, así que la tesis debe describirla como "LLM como evaluador"; (3) la evaluación humana que se hizo no se usará como validación independiente.
- **Acciones:** regla 6 de `llm-plc-st-eval/CLAUDE.md` y `07_Reinicio_desde_Banco/04_Automatizacion/CLAUDE.md` actualizada, con respaldo en `_respaldo_20261009/`. Los rótulos "NO OFICIAL" de las fichas de Claude se mantienen hasta la decisión final.
- **Decisión final (2026-10-09, Luis con su asesora):** la evaluación OFICIAL es la de DeepSeek `deepseek-v4-pro`, porque no pertenece a la familia de ningún modelo evaluado y así se evita la objeción de autopreferencia. Claude queda como segundo evaluador, solo para reportar confiabilidad. La comparación previa mostró el mismo ranking de modelos con ambos evaluadores y ninguna autopreferencia de Claude. Fichas en `evaluacion_llm/OFICIAL/` y `evaluacion_llm/CONFIABILIDAD/`.
