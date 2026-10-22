# Clasificación de Errores con Taxonomía CWE Adaptada a PLC

**Agente:** C (clasificación de errores) · **Fecha:** 2026-10-12 · **Estado:** Borrador para revisión del autor

**Productos en esta carpeta:** `clasificacion_fallos_cwe.csv` (249 filas, una por respuesta que no pasó el banco de prueba), `clasificacion_piloto_cwe.csv` (20 fallos del piloto), `mapa_pasos_harness.csv` (mapa paso → requisito, versión 2) y `mapa_pasos_harness_v1.csv` (versión 1), `juicio_llm.csv` (51 asignaciones por juicio con su justificación), `verificacion_mapa_pasos_v1.csv` (muestra de verificación), *scripts* `c01_verificar_tabla_causas.py`, `c02_clasificar_errores.py`, `c03_tablas_y_verificacion.py`, `c04_clasificar_piloto.py` y sus salidas de consola `salida_c0*.txt`.

**Comprobación previa:** `c01_verificar_tabla_causas.py` reproduce la tabla de causas de fallo del maestro (en el maestro v0.2 es la **Tabla 4.6**, no la 4.7): Gemini 2/0/7, Claude 22/0/14, GPT-4o 43/22/31, Qwen 72/6/30 (lógica/interfaz/no compila), 249 fallos, 518/600 compilan y 351/600 pasan. Todo cuadra (ver `salida_c01.txt`).

---

### Va en: 3.7.6 Clasificación de Errores (subsección nueva, a continuación de 3.7.5 Análisis Estadístico)

3.7.6 Clasificación de Errores

La propuesta aprobada comprometió la identificación de los tipos de error más frecuentes por modelo y por nivel de complejidad, tomando como referencia la taxonomía CWE (*Common Weakness Enumeration*) adaptada a la programación de PLC [@cwe]. La CWE es un catálogo de debilidades de *software* mantenido por MITRE, organizado en cuatro niveles de abstracción decreciente (pilares, clases, bases y variantes), en el que cada entrada indica además si es adecuada para clasificar casos concretos [@cwe]. Se empleó la versión 4.20, consultada el 12 de octubre de 2026. Debido a que el catálogo está orientado a la seguridad del *software* de propósito general y no contempla construcciones propias del control secuencial, como los temporizadores, la detección de flancos o los enclavamientos, se diseñó una taxonomía de diez categorías del dominio PLC, cada una con una definición operativa y su correspondencia con una o más entradas CWE (ver Tabla 4.9).

El universo de clasificación fueron las 249 respuestas de código que no superaron el banco de prueba (ver Tabla 4.6): 82 que no compilan, 28 con interfaz no conforme y 139 con fallo de lógica. Cada respuesta recibió una sola categoría primaria, determinada por la primera barrera que no superó, en el orden compilación, interfaz y comportamiento. Esto implica que un defecto de compilación oculta los defectos de lógica que la respuesta pudiera contener, de modo que las frecuencias describen la causa que impidió aprobar y no el inventario completo de defectos de cada respuesta.

Se fijó como regla que la clasificación descansara sobre evidencia automática y que el juicio solo interviniera donde esa evidencia no alcanzara, con tres métodos que quedan registrados en cada respuesta, tal como se resume en la Tabla 3.7. Para las 82 respuestas que no compilan se aplicaron 15 reglas deterministas, escritas como expresiones regulares en un *script* de Python, sobre todos los mensajes del compilador de CODESYS (ver INC-30). Cuando el mensaje era genérico, como «Se esperaba ';' en lugar de…», la regla buscaba además en el código la construcción que lo provoca, por ejemplo `ELSEIF` o un bloque `CONST`; las reglas se aplican en un orden fijo y gana la primera que coincide. Para las 28 respuestas con interfaz no conforme, la evidencia fue el mensaje de CODESYS al instanciarlas desde el banco de prueba («'x' no es ninguna entrada de 'FB'») en respuestas que compilan de forma aislada, conforme al criterio fijado en INC-15. Ambos casos se registraron como clasificación automática.

Para las 139 fallas de lógica se construyó un mapa tabulado de los 210 pasos de los 20 bancos de prueba implicados (C7 y C8 reutilizan los de B3 y B2), en el que cada paso recibe la categoría del requisito que comprueba según el comentario del propio banco (ver sección 3.7.2). Los pasos que verifican la función nominal sin aislar una causa se marcaron como nominales, y los que mezclan dos requisitos, como ambiguos. La categoría primaria de cada respuesta es la de su primer paso fallido, puesto que en una secuencia determinista los pasos posteriores pueden fallar en cascada; las categorías de todos los pasos fallidos se registraron aparte como presencia. Cuando el primer paso fallido resultó nominal o ambiguo, la categoría se asignó por juicio a partir de la lectura del código, con una justificación breve por respuesta.

Antes de aplicarlo, el mapa se contrastó con la lectura del código en una muestra estratificada de 36 respuestas, la primera de cada combinación de modelo y tarea entre las clasificadas por paso. La categoría del mapa coincidió con la del defecto observado en 29 de las 36 respuestas (80.6 %). Seis de las siete discrepancias se concentraron en pasos que comprueban más de un requisito, como el reposo inicial, donde un temporizador mal construido se manifiesta en el arranque, o la entrada en la fase de mezcla; la séptima correspondió a un paso cuya categoría no describía bien el requisito. Por ello, en la versión definitiva del mapa cuatro pasos se reclasificaron como ambiguos y uno cambió de categoría. Cabe destacar que el 80.6 % describe el mapa inicial y que la versión corregida no se validó sobre una muestra independiente {PEND: verificación de una segunda muestra de respuestas clasificadas por paso con el mapa v2}.

Con esta regla, 110 respuestas (44.2 %) se clasificaron de forma automática, 88 (35.3 %) por el paso del banco de prueba y 51 (20.5 %) por juicio; dentro de las fallas de lógica, el paso bastó en 88 de 139 casos (63.3 %). El juicio lo emitió un LLM, Claude (Anthropic), empleado como asistente de análisis, y no una persona. Cabe mencionar que este evaluador pertenece a la misma familia que uno de los modelos evaluados; no obstante, a diferencia de la rúbrica, el juicio no decide si una respuesta aprueba, sino únicamente en qué categoría cae un fallo ya establecido por CODESYS, y solo 10 de las 51 asignaciones corresponden a respuestas de Claude Sonnet 4.6 {PEND: revisión de las 51 asignaciones por juicio por el autor o por el evaluador oficial, en coherencia con INC-35}.

Finalmente, los 20 fallos sintácticos del estudio piloto se clasificaron en la misma taxonomía a partir del mensaje del analizador blark y de la detección estructural del cierre del POU, puesto que el piloto no dispone de mensajes de compilador ni de bancos de prueba. Los *scripts*, el mapa de pasos, la muestra de verificación y la clasificación por respuesta se conservan junto con los demás resultados del experimento {FALTA: ruta definitiva en el repositorio y referencia al Apéndice}.

Tabla 3.7: Evidencia y método de clasificación por tipo de fallo

| **Tipo de fallo (Tabla 4.6)** | **Respuestas** | **Evidencia** | **Regla** | **Método (respuestas)** |
|---|---|---|---|---|
| No compila | 82 | Mensajes de CODESYS y texto del código | 15 expresiones regulares aplicadas en orden fijo | Automático (82) |
| Interfaz no conforme | 28 | Mensaje de CODESYS al instanciar la respuesta desde el banco de prueba | Patrón «no es ninguna entrada» en respuestas que compilan solas | Automático (28) |
| Fallo de lógica | 139 | Primer paso fallido y su comentario en el banco de prueba; código cuando el paso no basta | Mapa de 210 pasos (versión 2) | Paso del banco (88); juicio de un LLM (51) |
| **Total** | **249** | | | **Automático 110 (44.2 %); paso 88 (35.3 %); juicio 51 (20.5 %)** |

Fuente: elaboración propia. Nota: al integrar, las Tablas 3.7 y 3.8 vigentes pasan a ser 3.8 y 3.9.

---

### Va en: 4.6 Patrones de Error (sección nueva, a continuación de 4.5 Análisis de Sensibilidad; las secciones 4.6 a 4.10 vigentes pasan a ser 4.7 a 4.11 y las Tablas 4.9 a 4.11 vigentes se renumeran a partir de 4.14)

4.6 Patrones de Error

La taxonomía empleada para clasificar los 249 fallos del criterio 1 se presenta en la Tabla 4.9. Sus diez categorías se agrupan según la barrera en que se detecta el defecto: tres corresponden a código que no compila, una a la interfaz del POU y seis al comportamiento observado en simulación. Cada categoría se acompaña de las entradas CWE que mejor la representan y del grado de correspondencia, que se calificó como directo cuando la entrada describe el mismo mecanismo, aproximado cuando lo describe de forma genérica e indirecto o sin equivalente cuando solo es posible asignar un pilar o una clase de alto nivel.

Tabla 4.9: Taxonomía de errores de programación de PLC y su correspondencia con la CWE

| **Categoría PLC** | **Definición operativa** | **Entradas CWE (versión 4.20)** | **Correspondencia** |
|---|---|---|---|
| Construcción o identificador no válido | El código usa una construcción inexistente en IEC 61131-3 o tomada de otro lenguaje (terminadores, bloques o palabras clave inventados, `ELSE:` en un CASE, métodos dentro del cuerpo), una palabra reservada como identificador, una variable sin declarar o un parámetro inexistente de un bloque estándar, y el compilador lo rechaza | CWE-710 Improper Adherence to Coding Standards; CWE-628 Function Call with Incorrectly Specified Arguments; CWE-561 Dead Code | Indirecta (pilar) |
| Conversión de tipos no conforme | Conversión entre TIME, REAL o INT implícita, con una función inexistente o aplicada en sentido contrario, o escrita con notación de molde ajena al ST (`REAL(x)`) | CWE-704 Incorrect Type Conversion or Cast | Directa |
| Dependencia del dialecto del compilador | Construcción admitida por la gramática o la biblioteca de IEC 61131-3 que el compilador de referencia rechaza (`END_STRUCT;`, entrada `R` del contador CTU) | CWE-758 Reliance on Undefined, Unspecified, or Implementation-Defined Behavior; CWE-589 Call to Non-ubiquitous API | Directa en el concepto |
| Interfaz de POU no conforme | El bloque compila aislado, pero declara como variables locales las entradas o salidas fijadas en el enunciado, de modo que no puede instanciarse ni conectarse | CWE-684 Incorrect Provision of Specified Functionality | Aproximada |
| Temporización incorrecta | Retardos, pulsos, intermitencias o plazos que no cumplen el tiempo especificado: tipo de temporizador equivocado, retardo a la desconexión mal emulado, temporizador no invocado en cada ciclo, reiniciado en cada ciclo o sin rearme entre operaciones | CWE-670 Always-Incorrect Control Flow Implementation; CWE-665 Improper Initialization (rearme) | Sin equivalente directo |
| Secuencia, memoria y estados | Transiciones de la secuencia o de la máquina de estados ausentes o erróneas, pérdida de la autorretención o de la retención, alternancia incorrecta o acción ejecutada en un momento equivocado | CWE-670 Always-Incorrect Control Flow Implementation; CWE-696 Incorrect Behavior Order | Aproximada |
| Paro, enclavamiento y condiciones anómalas | Respuesta incorrecta ante el paro o el paro de emergencia (incluido el rearranque automático), enclavamientos entre salidas, permisivos, fallas de equipo, aborto de receta o respuestas erróneas de un dispositivo | CWE-754 Improper Check for Unusual or Exceptional Conditions; CWE-696 Incorrect Behavior Order (prioridad del paro) | Aproximada |
| Inicialización y reinicio | Estado o valor de arranque incorrecto en el primer ciclo, o efecto incorrecto de una orden de reinicio | CWE-665 Improper Initialization; CWE-456 Missing Initialization of a Variable | Directa |
| Detección de flanco y conteo de eventos | Conteo o disparo por nivel en lugar de por flanco, memoria del estado anterior actualizada en el orden equivocado, contador no invocado o incrementado sin evento | CWE-372 Incomplete Internal State Distinction; CWE-670 Always-Incorrect Control Flow Implementation | Aproximada |
| Cálculo, umbral y validación de rango | Escalado o aritmética incorrectos, umbrales con el operador o el valor límite equivocado, histéresis, y entradas o índices fuera de rango sin validar | CWE-682 Incorrect Calculation; CWE-697 Incorrect Comparison; CWE-20 Improper Input Validation; CWE-129 Improper Validation of Array Index | Directa |

Fuente: elaboración propia; nombres oficiales de las entradas según [@cwe].

La adaptación se apoyó en la estructura jerárquica del catálogo, pero sus límites deben declararse. La CWE describe debilidades del *software* de propósito general que pueden dar lugar a vulnerabilidades, de modo que carece de entradas para el comportamiento temporal y para la seguridad funcional de una máquina, que en un PLC son el núcleo de la especificación [@iec61508]. A razón de esto, la temporización incorrecta solo pudo asociarse a una clase genérica de flujo de control, y los enclavamientos y paros, a la clase de condiciones excepcionales no verificadas. Por otro lado, algunas entradas de uso común en otros lenguajes no aplican tal como están definidas: la variable sin inicializar (CWE-457) no se presenta en ST porque la norma asigna a toda variable el valor inicial por defecto de su tipo [@iec61131], y el defecto observado es, en cambio, que ese valor por defecto difiere del requerido, lo que corresponde a CWE-456. Finalmente, varias de las entradas asignadas son pilares o clases que MITRE desaconseja para clasificar casos concretos, lo que es en sí mismo un indicio de que el catálogo no llega al nivel de detalle del dominio.

Tabla 4.10: Fallos del criterio 1 por categoría de error y modelo

| **Categoría** | **Gemini** | **Claude** | **GPT-4o** | **Qwen** | **Total** | **%** |
|---|---|---|---|---|---|---|
| Construcción o identificador no válido | 6 | 8 | 15 | 26 | 55 | 22.1 |
| Conversión de tipos no conforme | 0 | 0 | 14 | 4 | 18 | 7.2 |
| Dependencia del dialecto | 1 | 6 | 2 | 0 | 9 | 3.6 |
| Interfaz de POU no conforme | 0 | 0 | 22 | 6 | 28 | 11.2 |
| Temporización incorrecta | 1 | 12 | 22 | 43 | 78 | 31.3 |
| Secuencia, memoria y estados | 0 | 4 | 5 | 9 | 18 | 7.2 |
| Paro, enclavamiento y condiciones anómalas | 1 | 1 | 7 | 6 | 15 | 6.0 |
| Inicialización y reinicio | 0 | 5 | 5 | 7 | 17 | 6.8 |
| Detección de flanco y conteo | 0 | 0 | 4 | 6 | 10 | 4.0 |
| Cálculo, umbral y rango | 0 | 0 | 0 | 1 | 1 | 0.4 |
| **Total** | **9** | **36** | **96** | **108** | **249** | **100** |

Fuente: elaboración propia (`clasificacion_fallos_cwe.csv`). Nota: las tres primeras filas corresponden a respuestas que no compilan, la cuarta a interfaz no conforme y las seis restantes a fallos de lógica (ver Tabla 4.6).

En la Tabla 4.10 se observa que la temporización incorrecta es la categoría más frecuente, con 78 de los 249 fallos (31.3 %), seguida de las construcciones o identificadores no válidos (55; 22.1 %) y de la interfaz no conforme (28; 11.2 %), mientras que los errores de cálculo prácticamente no aparecen como causa primaria (1 caso). Además, la temporización interviene en 93 de las 139 fallas de lógica (66.9 %) si se consideran todos los pasos fallidos y no solo el primero. Esto es congruente con la naturaleza del control secuencial, en el que buena parte de la especificación se expresa como comportamiento en el tiempo mediante temporizadores normalizados [@bolton] [@iec61131]. Esto implica que la verificación del ST generado debe centrarse en el comportamiento temporal, que ningún compilador comprueba: las 78 respuestas de esta categoría compilaron sin errores.

Los perfiles por modelo son distintos. En Gemini, 7 de sus 9 fallos son de compilación, 6 de ellos por el identificador `dt`, de modo que sus defectos se concentran en el léxico del estándar y no en la lógica. En Claude predominan la temporización (12 de 36) y el dialecto (6, cinco de ellos por `END_STRUCT;`). GPT-4o combina errores de forma, como la interfaz (22) y la conversión de tipos (14), con errores de comportamiento (22 de temporización). Qwen concentra la temporización (43, es decir, el 28.7 % de sus 150 respuestas de código) y la mayor cantidad de construcciones no válidas (26). Cabe destacar que la distancia entre los modelos no se explica por una sola categoría: GPT-4o y Qwen superan a Claude en siete de las diez categorías, y solo en la dependencia del dialecto la relación se invierte.

De los 82 fallos de compilación, 55 corresponden a construcciones o identificadores no válidos, 18 a conversiones de tipos y 9 a dependencia del dialecto. Entre los primeros, el uso de `dt` como identificador suma 21 casos: los 18 de A1 ya descritos (ver sección 4.5) y 3 de A4, cuyo enunciado no contiene esa abreviatura, lo que sugiere que el nombre responde también a un hábito de los modelos y no solo a la inducción del enunciado. Le siguen la variable de bucle sin declarar en A6 (10 casos: las 6 respuestas de GPT-4o y 4 de Qwen) y 22 construcciones inexistentes formadas por analogía con otros lenguajes: `ELSEIF` en lugar de `ELSIF` (5, Qwen), métodos escritos dentro del cuerpo del bloque (5, Qwen), `END_VAR_INPUT` (4, GPT-4o), bloques `CONST ... END_CONST` (4), `ELSE:` en un CASE (3, Claude) y `BEGIN` (1). Esto es congruente con las taxonomías de alucinación en generación de código [@halluc], con la tendencia a inventar funciones inexistentes reportada en ST [@metaindux] y con la baja representación del lenguaje en los datos de entrenamiento [@haag]. Cabe destacar que `END_VAR_INPUT` ya era uno de los fallos del piloto y que 19 de las 22 construcciones inventadas aparecieron sin ejemplos.

Las 18 conversiones de tipos no conformes (14 de GPT-4o) obedecen a tres mecanismos: la conversión de TIME a REAL implícita o con la función aplicada en sentido contrario (`REAL_TO_TIME` sobre una variable TIME, 5 casos), la función inexistente `REAL_TO_REAL` (5) y la notación de molde `REAL(x)`, ajena al ST (8). El estándar define las conversiones entre tipos como funciones explícitas y no contempla la notación de molde [@iec61131] [@john], de modo que el tipado estricto del ST actúa como barrera: un defecto que en un lenguaje de tipado débil se convertiría en un cálculo silenciosamente erróneo, en ST lo detiene el compilador. Esto implica que una retroalimentación del compilador dentro del ciclo de generación, como la que proponen los enfoques de verificación iterativa [@fakih] [@haag], permitiría detectar y corregir esta categoría, pero no los defectos de temporización, que no producen ningún mensaje del compilador.

En cuanto al dialecto, la clasificación identificó 9 casos y no 7: a las 7 respuestas con `END_STRUCT;` (ver sección 4.5) se suman 2 que conectan la entrada de reinicio del contador CTU con el nombre `R`, que es el que define la norma [@iec61131], mientras que la biblioteca estándar de CODESYS la denomina `RESET` {CITA: documentación de la biblioteca Standard de CODESYS, bloque CTU}. En una de ellas (Claude, C7) el propio enunciado nombraba la entrada como RESET, de modo que el modelo se apartó de la instrucción para seguir la norma. Esto es congruente con los trabajos que orientan la generación hacia un fabricante concreto [@autoplc] [@vendoraware] e implica que la cifra de 7 de 82 fallos atribuibles al dialecto (ver sección 4.5) es un mínimo {PEND: decidir si se actualiza a 9 de 82 y si se amplía el análisis de sensibilidad S2}.

La interfaz no conforme se concentró en GPT-4o (22 de 28) y en la estrategia *zero-shot* (26 de 28), con el mayor peso en las tareas complementarias C3 y C8 (11) y en B7 (4). Debido a que los ejemplos del *few-shot* muestran declaraciones `VAR_INPUT` y `VAR_OUTPUT` completas, su presencia prácticamente elimina este defecto, lo que es congruente con la mejora atribuida al aprendizaje en contexto en los aspectos de forma [@brown]. Esto implica que la interfaz es un problema de formato que el *prompting* resuelve, a diferencia de los defectos de comportamiento.

La lectura del código en las fallas de temporización resueltas por juicio y en la muestra de verificación permitió identificar cuatro mecanismos recurrentes: el uso de un temporizador de pulso (TP) como retardo o plazo, cuya salida se activa al instante y adelanta la transición; el retardo a la desconexión emulado con un TON, que enciende el ventilador de B5 durante 30 s al arrancar el bloque; temporizadores que solo se invocan en el ciclo de la transición, o que se invocan con la entrada en falso en cada ciclo, y por ello nunca vencen; y el rearme por asignación directa de la entrada sin invocar la instancia. Los cuatro contravienen la semántica de los bloques de temporización del estándar, cuya salida solo se actualiza cuando la instancia se ejecuta [@iec61131] [@john]. Esto es congruente con el uso incorrecto de interfaces de programación documentado en lenguajes de propósito general [@zhong], con la particularidad de que aquí la interfaz mal usada es un bloque normalizado del propio lenguaje.

Un indicador automático adicional, calculado sobre las 600 respuestas, ilustra el primero de esos mecanismos. Qwen declaró un TP en 30 de sus 75 respuestas *few-shot* y en ninguna de las 75 *zero-shot*, y ninguna de esas 30 respuestas pasó el banco de prueba; uno de los dos ejemplos de generación del *few-shot* (FB_Lubricacion) usa precisamente un TP (ver sección 3.4.2). En las 10 tareas en que adoptó el TP, Qwen acertó 5 de 30 sin ejemplos y 0 de 30 con ellos, mientras que en las 15 tareas restantes pasó de 16 a 21 de 45. De forma similar, las tres respuestas *few-shot* de Claude en I1, que fallaron (ver sección 4.4.1), generan el intermitente con un TP. Esto es congruente con que el modelo reproduce los patrones del contexto [@brown] y con la evidencia de que añadir ejemplos no siempre mejora la generación de código [@manyshot]. Esto implica que el efecto nulo del *few-shot* en Qwen (ver Tabla 4.4) es la suma de una mejora y de un deterioro de magnitud similar. Se trata de un análisis exploratorio, definido después de observar los datos, por lo que debe leerse como hipótesis.

La categoría de paro, enclavamiento y condiciones anómalas reúne 15 fallos primarios, pero interviene en 53 de las 139 fallas de lógica (38.1 %) si se consideran todos los pasos. Los casos primarios más repetidos son el rearranque del motor de B1 al liberar el paro de emergencia con la marcha pulsada, que el enunciado prohíbe expresamente (5 de las 6 respuestas de GPT-4o en B1 y 1 de Claude), y la inversión de giro de B4 sin pasar por el paro (5 respuestas de Qwen y 1 de Gemini). Esto es congruente con la exigencia de verificar de forma explícita las funciones relacionadas con la seguridad [@iec61508], y con lo que ya mostró la validación de los bancos de prueba: estos defectos solo se manifiestan cuando la prueba recorre la combinación de entradas exacta (ver Tabla 3.5). Esto implica que, en el laboratorio, la lógica de paro y enclavamiento es precisamente la que no debe delegarse en un LLM sin una prueba diseñada para provocar el caso límite.

Las demás categorías de comportamiento son menos frecuentes, pero muestran patrones nítidos. En inicialización (17), los casos se reparten entre el índice del buffer de A5, que debe valer -1 al arrancar (7 casos; en las respuestas leídas, el índice queda en el valor por defecto 0), y la bomba principal de I7, que en la primera demanda no es la bomba 1 (10 casos; en las respuestas leídas, porque el código conmuta la principal antes de su primer uso). En secuencia (18) destacan, en las respuestas leídas, la falta de retención de alarmas en I3, la secuencia de I2 condicionada a mantener pulsado el arranque y el modo mantenimiento de A6, que no apaga los actuadores al entrar. En detección de flanco (10), los defectos son el conteo por nivel, la memoria del estado anterior actualizada antes de la comparación, el contador incrementado sin evento y, en un caso, un CTU cuyas entradas se asignan pero cuya instancia nunca se invoca. Estos defectos afectan a los patrones básicos que la literatura didáctica de PLC presenta desde sus primeros capítulos, como la autorretención, la detección de flancos y el uso de temporizadores [@bolton] [@petruzella]. Esto implica, para el uso docente, que los errores del modelo coinciden con los contenidos que el estudiante necesita dominar para poder detectarlos.

Tabla 4.11: Fallos por categoría según nivel de complejidad y estrategia de *prompting*

| **Categoría** | **Básico** | **Intermedio** | **Avanzado** | **Complem.** | ***Zero-shot*** | ***Few-shot*** |
|---|---|---|---|---|---|---|
| Construcción o identificador no válido | 2 | 9 | 44 | 0 | 35 | 20 |
| Conversión de tipos no conforme | 0 | 5 | 13 | 0 | 8 | 10 |
| Dependencia del dialecto | 1 | 0 | 7 | 1 | 3 | 6 |
| Interfaz de POU no conforme | 8 | 6 | 3 | 11 | 26 | 2 |
| Temporización incorrecta | 25 | 37 | 13 | 3 | 29 | 49 |
| Secuencia, memoria y estados | 1 | 13 | 4 | 0 | 13 | 5 |
| Paro, enclavamiento y condiciones anómalas | 12 | 2 | 1 | 0 | 6 | 9 |
| Inicialización y reinicio | 0 | 10 | 7 | 0 | 9 | 8 |
| Detección de flanco y conteo | 4 | 5 | 0 | 1 | 4 | 6 |
| Cálculo, umbral y rango | 0 | 1 | 0 | 0 | 0 | 1 |
| **Total** | **53** | **88** | **92** | **16** | **133** | **116** |

Fuente: elaboración propia. Nota: los totales por nivel y por estrategia coinciden con los fallos que se derivan de las Tablas 4.4 y 4.5.

La Tabla 4.11 muestra que la naturaleza del fallo cambia con la complejidad. En el nivel básico domina la temporización (25 de 53) seguida de la seguridad (12), y en el intermedio, la temporización (37 de 88) y la secuencia (13). En el avanzado, en cambio, 64 de los 92 fallos (69.6 %) son de compilación: 44 por construcciones o identificadores no válidos, 13 por conversiones y 7 por dialecto. Esto es congruente con la caída de la compilación al 55.6 % en ese nivel (ver Tabla 4.5) y con que las tareas avanzadas exigen construcciones menos frecuentes del lenguaje, como estructuras, arreglos, aritmética con TIME y bucles. Esto implica que, al crecer la complejidad, la barrera se desplaza del comportamiento a la conformidad con el lenguaje, lo que refuerza la hipótesis de la escasa representación del ST en el entrenamiento [@haag].

En cuanto a la estrategia, los ejemplos redujeron la interfaz no conforme de 26 a 2 casos y las construcciones no válidas de 35 a 20, pero la temporización aumentó de 29 a 49. Este aumento tiene dos orígenes distintos. En Qwen (16 a 27) obedece en buena medida a la adopción del TP del ejemplo, descrita más arriba. En GPT-4o (7 a 15) refleja, más bien, un efecto de enmascaramiento: sin ejemplos, 20 de sus fallos eran de interfaz y ocultaban la lógica, y 13 de sus 15 fallos de temporización con ejemplos se dieron en tareas en las que, sin ejemplos, había fallado por interfaz. Esto no es anormal puesto que la clasificación registra la primera barrera; a razón de esto, la comparación entre estrategias por categoría debe leerse junto con el total de fallos, que bajó de 133 a 116.

Tabla 4.12: Entradas CWE asignadas a los 249 fallos

| **Entrada CWE** | **Nombre oficial** | **Nivel** | **Respuestas** | **Categorías PLC** |
|---|---|---|---|---|
| CWE-670 | Always-Incorrect Control Flow Implementation | Clase | 94 | Temporización (75), secuencia (16), flanco (3) |
| CWE-710 | Improper Adherence to Coding Standards | Pilar | 53 | Construcción |
| CWE-684 | Incorrect Provision of Specified Functionality | Clase | 28 | Interfaz |
| CWE-704 | Incorrect Type Conversion or Cast | Clase | 18 | Conversión |
| CWE-754 | Improper Check for Unusual or Exceptional Conditions | Clase | 15 | Paro y enclavamiento |
| CWE-665 | Improper Initialization | Clase | 13 | Inicialización (10), temporización (3) |
| CWE-456 | Missing Initialization of a Variable | Variante | 7 | Inicialización |
| CWE-372 | Incomplete Internal State Distinction | Base | 7 | Flanco |
| CWE-758 | Reliance on Undefined, Unspecified, or Implementation-Defined Behavior | Clase | 7 | Dialecto |
| CWE-589 | Call to Non-ubiquitous API | Variante | 2 | Dialecto |
| CWE-696 | Incorrect Behavior Order | Clase | 2 | Secuencia |
| CWE-628 | Function Call with Incorrectly Specified Arguments | Base | 1 | Construcción |
| CWE-561 | Dead Code | Base | 1 | Construcción |
| CWE-20 | Improper Input Validation | Clase | 1 | Cálculo |
| **Total** | | | **249** | |

Fuente: elaboración propia; nombres y niveles según [@cwe], versión 4.20.

Expresados en el vocabulario de la CWE, los mismos fallos se concentran en dos entradas, como se observa en la Tabla 4.12: CWE-670, con 94 casos (37.8 %), y el pilar CWE-710, con 53 (21.3 %). Además, 74 de los 249 fallos (29.7 %) quedaron asignados a entradas que MITRE desaconseja para clasificar casos concretos por ser demasiado generales, y ninguna entrada distingue un temporizador mal elegido de una transición de estado ausente. Esto es congruente con el propósito del catálogo, orientado a debilidades de seguridad del *software* general [@cwe], y no es anormal, puesto que la propia propuesta preveía adaptarlo al dominio. Esto implica que la taxonomía PLC es el instrumento útil para el diagnóstico y la enseñanza, mientras que la CWE cumple la función de puente con el vocabulario de la ingeniería de *software*.

Tabla 4.13: Clasificación de los 20 fallos sintácticos del estudio piloto

| **Subtipo (análisis sintáctico con blark)** | **GPT-4o** | **Claude** | **Total** | **Categoría PLC** | **Entrada CWE** |
|---|---|---|---|---|---|
| POU sin cerrar (falta `END_FUNCTION_BLOCK`) | 3 | 12 | 15 | Construcción o identificador no válido | CWE-710 |
| Construcción inexistente (`END_VAR_INPUT`/`END_VAR_OUTPUT`, sección INIT) | 3 | 0 | 3 | Construcción o identificador no válido | CWE-710 |
| Sección de declaración ausente | 0 | 2 | 2 | Construcción o identificador no válido {PEND: posible artefacto de extracción, INC-12} | CWE-710 |
| **Total** | **6** | **14** | **20** | | |

Fuente: elaboración propia a partir de `resultados_sintaxis_cruzado.csv`; subtipos según la sección 4.2.

Los 20 fallos del piloto, todos en *zero-shot*, caen en una sola categoría de la taxonomía, como se observa en la Tabla 4.13, mientras que en el experimento definitivo las construcciones no válidas representan el 22.1 % de los fallos y la categoría dominante es la temporización. Esto es congruente con el alcance del instrumento del piloto, que verifica sintaxis y no comportamiento (ver sección 3.3), y con la advertencia de que las pruebas poco exigentes subestiman los errores del código generado [@evalplus]. Esto implica que el piloto observó solo la capa más superficial de los defectos, y que el patrón de analogía que allí se describió persiste en el experimento definitivo, aunque deja de ser el principal.

---

### Va en: Tabla 3.8 de la sección 3.10 (Desviaciones respecto a la Propuesta Aprobada), sustituye la fila «Clasificación de errores» con el marcador **[PENDIENTE: por realizar]**

| **Aspecto** | **Propuesta aprobada** | **Ejecución** | **Motivo** |
|---|---|---|---|
| Clasificación de errores | Taxonomía CWE adaptada a la programación de PLC, aplicada por el investigador | Taxonomía de diez categorías PLC mapeadas a CWE 4.20 (ver sección 3.7.6); clasificación automática de los fallos de compilación e interfaz (110), por paso del banco de prueba en las fallas de lógica (88) y por juicio de un LLM (Claude) sobre el código en los 51 casos que la evidencia automática no resolvía | Reproducibilidad: la evidencia de CODESYS y de los bancos de prueba resolvió el 79.5 % sin juicio; el juicio, realizado por un LLM y no por el investigador, se limitó al 20.5 % restante y se declara como tal {PEND: revisión humana de esas 51 asignaciones} |

Nota: en el maestro v0.2 la tabla de desviaciones es la **Tabla 3.8** (sección 3.10); pasará a ser 3.9 si se integra la Tabla 3.7 nueva.

### Va en: 4.10 Amenazas a la Validez (opcional; añadir antes de la última oración del párrafo)

La clasificación de errores asigna una sola categoría por respuesta según la primera barrera que no superó, de modo que los defectos de compilación ocultan los de lógica; el mapa de pasos coincidió con la lectura del código en el 80.6 % de una muestra de verificación, y el 20.5 % de las asignaciones procede del juicio de un LLM de la misma familia que uno de los modelos evaluados.

### Va en: 4.4.3 Causas de Fallo (opcional; añadir al final del párrafo)

La sección 4.6 desagrega estas causas por patrón de error y las relaciona con la taxonomía CWE.

---

## Notas para el autor

**Decisiones que debe tomar**

1. **Ubicación y numeración.** Se propone 3.7.6 para el método y una sección nueva 4.6 «Patrones de Error» tras la 4.5 (Sensibilidad), porque usa los casos de `dt` y `END_STRUCT;` que allí se introducen. La alternativa es una subsección 4.4.5 dentro de 4.4, junto a la Tabla 4.6, que evita renumerar 4.6–4.10. En ambos casos se renumeran tablas: la nueva Tabla 3.7 desplaza a 3.8 y 3.9 las vigentes, y las Tablas 4.9–4.13 nuevas desplazan a 4.14–4.16 las vigentes 4.9–4.11.
2. **Revisión del juicio.** Las 51 asignaciones por juicio (`juicio_llm.csv`) las hizo un LLM de la familia Claude. Conviene que el autor o el evaluador oficial (DeepSeek) revisen al menos una muestra, por coherencia con INC-35. El juicio no cambia ningún veredicto; solo la categoría.
3. **Mapa v1 frente a v2.** El 80.6 % de concordancia corresponde al mapa v1. La v2 corrige los pasos A2-8, I2-2, I5-0 y B5-0 (pasan a ambiguos) y A3-7 (de cálculo a condiciones anómalas). Si se quiere una cifra de exactitud para la v2, hace falta una segunda muestra independiente. Ambas versiones se pueden reproducir con `c02_clasificar_errores.py --mapa ...`.
4. **Dialecto: 7 o 9 de 82.** La clasificación encontró 2 casos más de dialecto (`R` en lugar de `RESET` en el CTU: Gemini B3 *few-shot* ejec 1 y Claude C7 *zero-shot* ejec 2). Hay que decidir si se corrige la frase de la sección 4.5 («explica 7 de los 82 fallos de compilación») y si se extiende el análisis S2 a esos 2 casos.
5. **Métodos embebidos (5 respuestas de Qwen).** Se clasificaron como construcción no válida, porque además usan formas ajenas a la norma (`: VOID`, `RETURN` con valor); pero la edición 3 de IEC 61131-3 admite `METHOD` dentro de un FUNCTION_BLOCK y CODESYS los exige como objetos separados, de modo que podrían argumentarse como dialecto. La decisión cambia el conteo de dialecto (9 → 14).
6. **Piloto, «2 sin declaración».** Según la BITACORA (2026-09-30) e INC-12, las 2 respuestas de Claude en I6 que el piloto contó como «sin declaración» provienen de que el extractor v1 conservó solo uno de dos bloques de código. El artículo CITDES y la sección 4.2 las presentan como omisión del modelo. Decidir si se añade una nota en 4.2 y en la Tabla 4.13.
7. **Indicador del TP.** El hallazgo de que Qwen adopta el TP del ejemplo en 30 de 75 respuestas *few-shot* (0 aprueban) es nuevo y exploratorio. Decidir si se presenta en 4.6 (como está) o también en la discusión de 4.4.1, donde explicaría el efecto nulo del *few-shot* en Qwen.
8. **Presencia frente a causa primaria.** Las cifras de presencia (temporización en 93 de 139, seguridad en 53 de 139) incluyen pasos que pueden fallar en cascada; se presentan como «requisitos afectados», no como defectos independientes.

**Marcadores abiertos**

- `{PEND: verificación de una segunda muestra con el mapa v2}` (3.7.6).
- `{PEND: revisión de las 51 asignaciones por juicio...}` (3.7.6 y Tabla 3.8).
- `{FALTA: ruta definitiva en el repositorio y referencia al Apéndice}` (3.7.6).
- `{CITA: documentación de la biblioteca Standard de CODESYS, bloque CTU}` (4.6). Se comprobó en la ayuda en línea de la biblioteca Standard de CODESYS (distribuida por ABB) que el CTU tiene entradas `CU`, `RESET` y `PV`, pero esa fuente no está en `LISTA_REFERENCIAS.md`.
- `{PEND: decidir si se actualiza a 9 de 82...}` (4.6).
- `{PEND: posible artefacto de extracción, INC-12}` (Tabla 4.13).

**IDs CWE.** Todos los IDs y nombres oficiales usados (CWE-20, 129, 372, 456, 457, 561, 589, 628, 665, 670, 682, 684, 696, 697, 704, 710, 754, 758) se verificaron en cwe.mitre.org (versión 4.20) el 2026-10-12, junto con su nivel de abstracción y su uso para mapeo. También se verificaron, sin usarse en la tabla final, CWE-681, 686, 691, 1068, 1164, 1245, 1284, 193 y 362. No queda ningún ID sin verificar.

**Figuras sugeridas.** (a) Barras apiladas horizontales de la Tabla 4.10 (categoría por modelo, 300 dpi, matplotlib), agrupando por barrera (compilación, interfaz, comportamiento). (b) Mapa de calor categoría × nivel (Tabla 4.11). (c) Barras de respuestas con TP por modelo y estrategia (sección 6 de `salida_c03.txt`).

**Cálculos nuevos y sus *scripts*** (todos leen solo `insumos/` y escriben en esta carpeta):

- `c01_verificar_tabla_causas.py` → `salida_c01.txt`: reproduce Tabla 4.6, criterios 1 y 2, casos `dt` y `END_STRUCT;`, y la coherencia entre `tabla_definitivo.csv` y la simulación por modelo (0 diferencias).
- `c02_clasificar_errores.py` → `clasificacion_fallos_cwe.csv` y `salida_c02.txt` (mapa v2); con `--mapa mapa_pasos_harness_v1.csv --salida clasificacion_fallos_cwe_mapa_v1.csv` reproduce la v1 (`salida_c02_mapa_v1.txt`).
- `c03_tablas_y_verificacion.py` → `salida_c03.txt`: concordancia del mapa v1 (y comprobación de que la muestra sigue la regla de selección), porcentajes por método, Tablas 4.10–4.12, presencia por paso, subtipos de compilación e indicador del TP.
- `c04_clasificar_piloto.py` → `clasificacion_piloto_cwe.csv` y `salida_c04.txt` (Tabla 4.13).
- Columnas de `clasificacion_fallos_cwe.csv`: modelo, modelo_corto, tarea, nivel, estrategia, ejec, c1_categoria, categoria_plc, categoria_nombre, cwe_id, cwe_nombre, metodo (automatico / paso_harness / juicio), subtipo, paso_primario, pasos_fallidos, categorias_todos_pasos y evidencia (regla y mensaje de CODESYS, paso y requisito, o justificación del juicio).

**Discrepancias encontradas**

- La instrucción mencionaba la «Tabla 4.7» para las causas de fallo; en el maestro v0.2 es la **Tabla 4.6** (la 4.7 es lenguaje natural frente a LD). La tabla de desviaciones es la **Tabla 3.8** de la sección 3.10, no la «Tabla 3.10».
- Dialecto: 9 de 82 según esta clasificación frente a 7 de 82 en la sección 4.5 e INC-34 (ver decisión 4).
- `dt`: 21 respuestas en total (`caso_dt = 1`), 18 en A1 y 3 en A4 (Gemini 1, Qwen 2); el maestro e INC-33 solo mencionan las de A1. El enunciado de A4 no contiene «dt», lo que matiza la amenaza a la validez de la sección 4.10.
- Piloto: «2 sin declaración» como omisión del modelo (artículo y 4.2) frente a artefacto de extracción (BITACORA, INC-12).
- Piloto en CODESYS: según la BITACORA (2026-09-30), la recompilación del piloto en CODESYS dio 134/144 y en Claude *zero-shot* solo fallaron las 2 respuestas de I6; es decir, las 12 respuestas de Claude sin `END_FUNCTION_BLOCK` compilaron en el entorno de fabricante. No se llevó al texto porque esa recompilación no figura en el maestro; si se incorpora, matiza la Tabla 4.13 (el defecto más frecuente del piloto no impide compilar en CODESYS).
- Observada de paso, fuera del alcance de esta tarea: INC-33 e INC-34 citan el criterio 1 como 56.0 % → 58.0 % (S1) y 56.0 % → 56.3 % (S2), mientras que la Tabla 4.8 del maestro da 58.5 % → 60.4 % y 58.8 %; probablemente las cifras de las incidencias son anteriores a la inclusión de C7 y C8.

**Riesgos para la defensa**

- **El evaluador del juicio pertenece a la familia de un modelo evaluado.** Mitigación declarada: el juicio no decide el aprobado, se limita al 20.5 % de los casos y está justificado caso por caso en `juicio_llm.csv`; se recomienda revisión humana.
- **La CWE no es una taxonomía de PLC.** Un jurado puede objetar que el 29.7 % de las asignaciones usa entradas que MITRE desaconseja para mapear. La respuesta es que eso es un resultado: la propuesta preveía la adaptación y la Tabla 4.12 muestra por qué hacía falta.
- **Regla del primer paso fallido.** Clasifica el requisito que falló primero, no siempre el mecanismo; la verificación mostró un 80.6 % de coincidencia con la lectura del código en el mapa inicial, y los pasos de reposo y de entrada en fase fueron los menos discriminantes.
- **Enmascaramiento.** La categoría primaria es la primera barrera; comparar categorías entre estrategias o modelos sin mirar el total puede llevar a conclusiones erróneas (caso de GPT-4o en temporización).
- **Categorías mixtas.** Algunas categorías describen un requisito (seguridad, secuencia) y otras un mecanismo (conversión, dialecto); las definiciones operativas de la Tabla 4.9 fijan la frontera, pero puede haber preguntas sobre casos límite (por ejemplo, un temporizador mal construido que se manifiesta en el arranque se clasificó como temporización y no como inicialización).
- **Tamaños pequeños por celda.** Las tablas por categoría son descriptivas; no se aplicaron pruebas de significancia por categoría y no deberían añadirse sin corrección por comparaciones múltiples.
- **Análisis del TP definido a posteriori.** Debe presentarse como exploratorio.

## Trazabilidad de cifras

| **Cifra** | **Origen** |
|---|---|
| 600 respuestas de código; 249 que no pasan; 82 / 28 / 139 por tipo; 518/600 compilan; 351/600 pasan | `insumos/datos/results/tabla_definitivo.csv` vía `c01_verificar_tabla_causas.py` (`salida_c01.txt`); coinciden con Tablas 4.3 y 4.6 del maestro |
| Gemini 2/0/7, Claude 22/0/14, GPT-4o 43/22/31, Qwen 72/6/30 | Ídem; Tabla 4.6 del maestro |
| 18 respuestas de A1 con `dt`; 21 en total (3 en A4); 7 con `END_STRUCT;` | `tabla_definitivo.csv` (`caso_dt`, `caso_end_struct`) vía c01; sección 4.5 e INC-33/34 del maestro |
| 15 reglas para no compila; conteos por regla (`dt` 21, variable no declarada 10, `ELSEIF` 5, METHOD 5, `END_VAR_INPUT` 4, `CONST` 4, `ELSE:` 3, `BEGIN` 1, CASE superpuesto 1, `PTR` 1, TIME→REAL 5, `REAL_TO_REAL` 5, `REAL(x)` 8, `END_STRUCT;` 7, CTU `R` 2) | `c02_clasificar_errores.py` sobre `tabla_definitivo.csv` (`errores_texto`) y `processed_definitivo/`; `salida_c02.txt` y sección 5 de `salida_c03.txt` |
| 22 construcciones inventadas, 19 en *zero-shot* | Sección 5 de `salida_c03.txt` (suma de subtipos `ELSEIF`, METHOD, `END_VAR_INPUT`, `CONST`, `ELSE:`, `BEGIN` por estrategia) |
| 28 interfaz no conforme con mensaje «no es ninguna entrada»; 26 *zero-shot*; GPT-4o 22; C3 y C8 11; B7 4 | `results_codesys/definitivo_*.csv` (columna `nota`) vía c01 y c02; Tablas 3e y 3d de `salida_c03.txt` |
| 210 pasos en 20 bancos de prueba; 9 ambiguos y 37 nominales (v2) | `mapa_pasos_harness.csv`, elaborado a partir de `insumos/datos/codesys_harness/PRG_Test_*.st` |
| Concordancia del mapa v1: 29/36 (80.6 %), 7 discrepancias | `verificacion_mapa_pasos_v1.csv` vía c03 (sección 1 de `salida_c03.txt`); muestra derivada de `clasificacion_fallos_cwe_mapa_v1.csv` |
| Métodos: automático 110 (44.2 %), paso 88 (35.3 %), juicio 51 (20.5 %); paso 88/139 (63.3 %) en lógica; 10 juicios sobre respuestas de Claude | Sección 2 de `salida_c03.txt` |
| Tabla 4.10 (categoría × modelo), 31.3 %, 22.1 %, 11.2 %; Qwen temporización 28.7 % de 150 | Secciones 3a–3c de `salida_c03.txt` |
| Presencia: temporización 93/139 (66.9 %); paro y enclavamiento 53/139 (38.1 %) | Sección 4 de `salida_c03.txt` |
| Tabla 4.11 (nivel y estrategia); 64/92 (69.6 %) de compilación en avanzado; totales 53/88/92/16 y 133/116 | Secciones 3d y 3e de `salida_c03.txt`; contrastados con Tablas 4.4 y 4.5 del maestro |
| GPT-4o *zero-shot*: 20 fallos de interfaz; temporización 7 → 15 (GPT-4o) y 16 → 27 (Qwen); 13 de 15 en tareas con interfaz no conforme sin ejemplos | Secciones 3f y 3f-bis de `salida_c03.txt` |
| Tabla 4.12 (CWE): 94 (37.8 %) CWE-670; 53 (21.3 %) CWE-710; 74 (29.7 %) en entradas desaconsejadas | Secciones 3h y 3h-bis de `salida_c03.txt`; nivel y uso para mapeo de cwe.mitre.org (versión 4.20, consulta del 2026-10-12) |
| Casos de seguridad: B1 (GPT-4o 5, Claude 1), B4 (Qwen 5, Gemini 1), I8, I7, A3 (1 cada uno) | `clasificacion_fallos_cwe.csv` (filas con `categoria_plc = SEGURIDAD`) |
| Inicialización: A5 7, I7 10; flanco 10; GPT-4o y Qwen superan a Claude en 7 de 10 categorías | `clasificacion_fallos_cwe.csv`; sección 3a de `salida_c03.txt` |
| TP: Qwen 30/75 *few-shot* y 0/75 *zero-shot*; 0/30 aprueban; 10 tareas; 5/30 → 0/30 y 16/45 → 21/45; 43 respuestas con TP, 9 aprueban (20.9 %) frente a 342/557 (61.4 %); Claude I1 *few-shot* con TP | Sección 6 de `salida_c03.txt` (regex `: TP;` sobre `processed_definitivo/`, sin comentarios) |
| Qwen 21/75 en ambas estrategias; Claude I1 3/3 → 0/3 | Tabla 4.4 y sección 4.4.1 del maestro |
| 20 fallos del piloto: 15 / 3 / 2; GPT-4o 6, Claude 14; todos *zero-shot* | `insumos/datos/results/resultados_sintaxis_cruzado.csv` vía `c04_clasificar_piloto.py` (`salida_c04.txt`); sección 4.2 del maestro y `Articulo_CITDES_final.md` |
| «2 sin declaración» como artefacto de extracción | `insumos/docs/BITACORA.md` (entrada del 2026-09-30) e INC-12 |
| Ejemplo FB_Lubricacion con TP | `insumos/docs/Prompts_Banco_v1.md` (*prompt few-shot* de B1) y sección 3.4.2 del maestro |
| A4 sin «dt» en el enunciado | `Prompts_Banco_v1.md` (0 apariciones en A4; 4 en A1) |
| CTU de CODESYS con entrada `RESET` | Ayuda en línea de la biblioteca Standard de CODESYS (consultada el 2026-10-12); pendiente de cita aprobada |
| Compilación del avanzado 55.6 % | Tabla 4.5 del maestro |
| CWE versión 4.20 y nombres oficiales | cwe.mitre.org, páginas de definición de cada entrada, consultadas el 2026-10-12 |
