# Guía para retomar o extender esta investigación

Esta guía está dirigida a quien quiera continuar el trabajo, ya sea un estudiante de la FIE, un
docente o un investigador. Por ejemplo, para evaluar modelos más recientes, añadir tareas, cambiar
de compilador o repetir el estudio con estudiantes. Complementa al `README.md`, que explica cómo
validar los resultados de la tesis, y a `docs/registro/INCIDENCIAS.md`, que documenta los
problemas que aparecieron durante el experimento y cómo se resolvieron.

---

## 1. Orden de lectura recomendado

1. **La tesis**, capítulos 3 y 4: diseño, instrumentos y resultados.
2. **`README.md`**: estructura del repositorio y validación en cuatro niveles.
3. **`docs/registro/INCIDENCIAS.md`**: las 35 incidencias. Es la mejor lista de errores que
   conviene no repetir.
4. **`docs/ENMIENDAS_HARNESSES.md`**: por qué los bancos de prueba fallaban antes de validarse y
   cómo detectarlo.
5. **`benchmark/Prompts_Banco_v1.md`** y **`benchmark/Banco_de_Pruebas_v1.xlsx`**: las 30 tareas,
   su nivel, tipo, POU, interfaz y taxonomía de constructos.
6. **`analisis/taxonomia_cwe/LEEME.md`**: cómo se clasificaron los fallos.

---

## 2. Principios del método

Estas reglas son las que hacen que los resultados sean comparables y auditables. Si se rompe
alguna, los resultados nuevos dejan de ser comparables con los de la tesis.

| Regla | Por qué |
|---|---|
| El dato primario (`data/raw/`, `data/definitivo/`) nunca se modifica. Todo análisis lee una copia derivada y escribe en archivos aparte. | Cualquier tercero puede comprobar con el SHA-256 que las respuestas no cambiaron. |
| Los enunciados se editan **solo** en `src/generar_prompts.py`, nunca en `tasks.json` ni en el documento de prompts. | Una sola fuente evita versiones divergentes. |
| Antes de cada lote se ejecuta `src/verificar_hashes.py`. | Garantiza que todos los modelos reciben exactamente las mismas instrucciones y que ninguna tarea ya ejecutada cambió. |
| Todo parámetro experimental vive en `src/config.yaml` (temperatura, topes, ejecuciones, modelos, rutas). | El código no contiene valores fijos; el parámetro es una variable de control documentada. |
| Los modelos se fijan con identificadores con fecha (snapshots), no con alias. | Un alias puede cambiar de modelo a mitad del experimento. |
| Un instrumento (banco de prueba, compilador, extractor, evaluador) se valida antes de usarse, con casos de resultado conocido. | En este trabajo varios bancos de prueba se equivocaban antes que el código evaluado (Tabla 3.7 de la tesis). |
| El análisis principal es estricto: las respuestas se evalúan tal como se entregaron. Las normalizaciones solo se usan en análisis de sensibilidad declarados aparte. | Separa los errores del modelo de los efectos del instrumento o del dialecto. |
| Cada lote deja evidencia: transcripción, configuración, `resumen.json` con SHA-256 de scripts y datos, y capturas. | Permite auditar qué se ejecutó, con qué versión y sobre qué datos. |
| Las claves de API solo se guardan en variables de entorno. | Evita filtrarlas al repositorio o a un chat (INC-22). |
| Un asistente de codificación puede preparar scripts, pero nunca escribe código ST del corpus ni es modelo evaluado. | Evita contaminar el objeto de estudio. |

---

## 3. Cómo extender el trabajo

### 3.1 Evaluar otros modelos

1. Añada el modelo en `src/config.yaml`, en `modelos:`, con su `id` exacto y su `proveedor`
   (`openai`, `anthropic`, `google` u `ollama`). Si el proveedor es otro, implemente una clase
   nueva en `src/clients.py`, siguiendo el patrón `ModelClient.generate()`, y regístrela en
   `crear_cliente()`.
2. **Modelos con razonamiento interno.** En algunos proveedores el tope de tokens cubre el
   razonamiento más la respuesta. Use `max_tokens_total` (como se hizo con Gemini, INC-28) y
   mantenga `generacion.max_tokens` como tope de la respuesta visible, común a todos.
3. **Modelos locales (Ollama).** Fije el contexto para que quepan la instrucción más larga y el
   tope de salida (8 192 tokens en este trabajo, INC-25). Registre el identificador exacto de
   la versión descargada.
4. **Calibre antes del lote grande.** `src/config_calibracion.yaml` y `src/ejecutar_calibracion.ps1`
   ejecutan B1 y A6 (la tarea más larga) en todos los modelos, con salida aislada. Compruebe que
   ninguna respuesta llegue truncada (`finish_reason`) y contraste el costo real con el estimado.
5. Lance cada modelo con `herramientas/ejecutar_con_evidencia.ps1 -Modelo <id> -Confirmar`, usando
   una carpeta de salida nueva. No mezcle respuestas nuevas con `data/definitivo/`.

### 3.2 Añadir o modificar tareas

1. Cada tarea se declara en `src/generar_prompts.py` con
   `tarea(id, nivel, titulo, enunciado, clave)`. El enunciado debe fijar el POU, los nombres y
   tipos exactos de las entradas y salidas y las constantes, y **no** nombrar el bloque estándar
   que la resuelve.
2. Respete los cinco criterios de representatividad de la tesis (sección 3.4.1): tarea real o de
   laboratorio, autocontenida, verificable por compilación y simulación, de tamaño controlado y
   no resuelta literalmente en internet.
3. **No modifique tareas ya ejecutadas.** Si cambia un enunciado, ya no es la misma tarea.
   Créela con un identificador nuevo.
4. Tras regenerar `tasks.json`, `python src/verificar_hashes.py` debe seguir mostrando
   `difieren: 0` para las tareas antiguas. Las opciones `--snapshot` y `--comparar` permiten
   guardar y comparar estados del banco.
5. Las tareas few-shot usan dos ejemplos ajenos al banco, específicos por tipo de tarea. Note
   que los ejemplos transmiten forma: el temporizador TP de un ejemplo fue copiado por los
   modelos en tareas que no lo necesitaban (sección 4.4.1 de la tesis).

### 3.3 Escribir un banco de prueba para una tarea nueva

Un banco de prueba es un `PROGRAM PRG_Test_<ID>` en ST que instancia el bloque, recorre pasos
numerados desde 0, escribe en `resultado[]` 1 (cumple) o 2 (falla) por paso y deja en
`veredicto` 1 o 2 al final. El comentario de cada paso debe decir qué requisito comprueba,
porque de ahí sale la clasificación de errores.

1. **Parta de una plantilla.** Use `codesys/PRG_Test_B1.st` para lógica sin temporizadores y
   `codesys/PRG_Test_B2.st` para tareas con temporizadores (asentamiento distinto por paso).
2. **Escriba antes el validador en Python** (`codesys/validar_harness_<ID>.py`). Debe reproducir
   el ciclo de scan a 4, 10 y 20 ms y ejecutar el banco contra una implementación correcta y
   varias defectuosas, prediciendo el veredicto y el paso de fallo de cada una.
3. **Compruebe las dos familias de defecto** documentadas en `docs/ENMIENDAS_HARNESSES.md`:
   - muestrear una señal inestable (una sola lectura de una señal periódica o en transición):
     mida duraciones o vigile con bandera enclavada;
   - que la secuencia no llegue al estado en que el defecto se manifiesta: añada el paso que
     falta, y cuente las ventanas desde el evento que las origina.
4. **Traduzca las implementaciones a dobles de prueba en ST** (`codesys/dobles/<ID>/nn_Nombre.st`)
   con `codesys/dobles/generar_dobles.py`, que también actualiza `dobles/manifiesto.json` con el
   veredicto y el paso esperados.
5. Ejecute `python codesys/lint_identificadores.py` desde `codesys/` para detectar palabras
   reservadas usadas como identificador (`DT` hizo fallar 54 dobles, INC-11 e INC-17).
6. **Verifique en CODESYS real**:
   ```powershell
   .\codesys\ejecutar_simular_lote.ps1 -Modo dobles -Tareas <ID> -Ciclos 4,10 -Salida data\results_codesys\harness_<ID>.csv
   ```
   El banco se da por válido cuando CODESYS coincide con Python en el veredicto, en el paso de
   fallo y en el vector `resultado[]` completo, en ambos ciclos.
7. Si la tarea reutiliza la lógica de otra (como C7 y C8 con B3 y B2), regístrela en
   `HARNESS_DE` de `codesys/simular_lote_sp22.py`.

### 3.4 Usar otro compilador o fabricante

Los bancos de prueba son ST estándar y se pueden reutilizar en otros entornos. Lo que depende de
CODESYS es la automatización (`compilar_lote_sp22.py` y `simular_lote_sp22.py`, que usan el motor
de scripts IronPython de CODESYS) y el dialecto. Al cambiar de entorno:

- reescriba solo la capa de automatización y mantenga el formato de los CSV de resultados, para
  reutilizar todo el análisis;
- repita los controles del instrumento (un bloque correcto y uno con errores sembrados) y la
  validación de los bancos con los dobles;
- espere diferencias de dialecto como las de este trabajo (`END_STRUCT;`, la entrada `R` del
  CTU, `METHOD` en texto) y trátelas como análisis de sensibilidad, no en el análisis principal.

### 3.5 Probar otras estrategias de prompting

Añada la estrategia en `experimento.estrategias` de `src/config.yaml` y su construcción en
`src/generar_prompts.py`, junto a `zero_shot()` y `few_shot()`. Conserve el enunciado idéntico
entre estrategias para que la comparación sea pareada. Las pruebas de McNemar y Wilcoxon de
`analisis/criterios_definitivo.py` asumen pares tarea × ejecución.

### 3.6 Evaluar los criterios 3 a 5 y las tareas no ejecutables

- **Con evaluadores LLM:** `evaluacion_llm/Paquete_Evaluador_LLM2/` contiene las instrucciones,
  las entradas anonimizadas y `evaluar_deepseek.py`. Ejecute primero `--estimar` para conocer
  el costo, y use un evaluador que no pertenezca a la familia de ningún modelo evaluado.
- **Con evaluadores humanos:** `evaluacion_manual/preparar_fichas.py` y
  `evaluacion_rubrica/preparar_rubrica.py` codifican y barajan las respuestas con semilla fija y
  sellan la asignación (`_SELLADO_*`). `construir_fichas.py` y `construir_ficha_rubrica.py`
  generan las fichas de Excel y las páginas HTML. Las fichas vacías de `Evaluador1/` y
  `Evaluador2/` sirven como plantilla.
- **Calcular resultados y concordancia:** `analizar_fichas.py` y `analizar_rubrica.py` reciben
  como argumentos las dos fichas que se quieren comparar.

### 3.7 Añadir análisis

Agregue el cálculo a un script nuevo en `analisis/` que lea `data/results/` y escriba su salida
en `analisis/salidas/`. Conviene que, como `analisis_v03_spyder.py`, recalcule primero las cifras
ya publicadas y se detenga si alguna no coincide: así cualquier error de carga se detecta antes
de producir resultados nuevos.

---

## 4. Errores que conviene no repetir

| Incidencia | Qué pasó | Cómo evitarlo |
|---|---|---|
| INC-05 | CODESYS no compila los POU que nada referencia: un bloque con errores daba «0 errores». | Instanciar cada respuesta desde un programa envoltorio y compilar controles antes de cada lote. |
| INC-10 | La simulación heredaba el veredicto de la anterior. | Descarga completa, reinicio en frío y comprobar que el veredicto parte de cero. |
| INC-12 | El extractor descartaba la declaración en respuestas de dos bloques. | Verificar la extracción como subcadena exacta del original y revisar los patrones no reconocidos. |
| INC-25 | Ollama recorta en silencio las instrucciones que exceden su contexto. | Fijar el contexto y comprobarlo con `ollama ps`. |
| INC-28 | El razonamiento de Gemini agotaba el tope y truncaba las respuestas. | Sonda previa y tope total separado del tope de respuesta visible. |
| INC-30 | El simulador guardaba solo el primer mensaje de error. | Registrar todos los mensajes distintos del compilador. |
| INC-33 | 18 de 24 respuestas de A1 usaron `dt` (palabra reservada), inducidas por el enunciado. | No escribir abreviaturas que coincidan con palabras reservadas en los enunciados. |
| INC-07 | Se midió con una versión anterior de un script que no llegó al disco. | Registrar el SHA-256 de cada script en la evidencia y comprobarlo tras cada cambio. |
| INC-32 | Comandos pegados en bloque en PowerShell se mezclaron. | Ejecutar los lotes de uno en uno, con lanzadores `.ps1`. |

---

## 5. Recursos de referencia

Valores observados en este trabajo, útiles para planificar:

- **Generación:** 720 respuestas en unos 138 minutos efectivos (4 lotes). Costo de USD 8.68 con
  precios de lista; las consolas de los proveedores registraron unos USD 9.52 incluyendo la
  calibración y las pruebas.
- **CODESYS:** la compilación de 720 extracciones tomó 12.5 minutos. La simulación tomó entre
  36.5 y 51.9 minutos por modelo (138 simulaciones), y el banco más largo (A2) dura 125.6 s.
- **Evaluación con DeepSeek:** unos USD 2.32 en total, entre rúbrica, diagnóstico y clasificación.
- **Hardware local para Qwen 2.5 Coder 14B:** GPU de 12 GB (RTX 3060), con latencia mediana de
  12.5 s por respuesta.

---

## 6. Líneas abiertas

Las que señala la tesis (sección 5.3), con el punto de partida en este repositorio:

- **Otros fabricantes y modelos especializados en ST de distintos tamaños**, para separar el
  efecto del dialecto, de la especialización y de la escala. Ver las secciones 3.1 y 3.4 de
  esta guía.
- **Lenguajes gráficos del estándar** (LD, SFC, FBD) y **estudios con estudiantes** en las
  prácticas de laboratorio de PLC, midiendo el efecto sobre el aprendizaje. El banco y las
  rúbricas sirven como material de partida.
- **Sistemas con RAG o verificación iterativa**, para medir qué categorías de error corrige el
  lazo y cuáles persisten (en este trabajo, la temporización no produce ningún mensaje del
  compilador). La taxonomía de `analisis/taxonomia_cwe/` permite comparar por categoría.
- **Panel de jueces expertos humanos** para contrastar la clasificación de errores y los
  criterios de claridad y mantenibilidad, en los que la concordancia entre evaluadores fue
  moderada.

---

Si usa este material, cítelo según `CITATION.cff`.
