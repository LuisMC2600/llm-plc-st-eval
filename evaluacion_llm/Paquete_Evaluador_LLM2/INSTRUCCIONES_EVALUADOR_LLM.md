# Paquete para el segundo evaluador LLM

Contiene el mismo material y las mismas instrucciones que usó el primer evaluador LLM (Claude), sin cambios de contenido. Así las dos evaluaciones son comparables celda a celda.

- `entrada/diag_C1|C2|C5|C6.json`: 4 tareas de diagnóstico o requisito, con 24 respuestas cada una.
- `entrada/rub_<TAREA>.json`: 25 tareas de código para la rúbrica, con 24 respuestas cada una.
- Las respuestas van identificadas solo por código. No incluye la asignación sellada.

Uso: una tarea por conversación o llamada. Se pegan las instrucciones de la sección correspondiente y el JSON de esa tarea, y se pide la salida JSON indicada. Las 29 salidas se guardan como `salida/diag_<T>.json` y `salida/rub_<T>.json`, con exactamente el esquema descrito.

---

# Evaluación a ciegas — diagnóstico de código (C1, C5, C6) y requisito ambiguo (C2)

Actúas como un evaluador humano experto en programación de PLC (IEC 61131-3). Califica con el mismo criterio que aplicaría un docente cuidadoso. No intentes adivinar qué modelo produjo cada respuesta.

Entrada: `entrada/diag_<TAREA>.json` con el enunciado que recibieron los modelos, la clave de evaluación y 24 respuestas identificadas por código.
Primero lee el enunciado, la clave y las 24 respuestas completas; después califica cada una.

## Tareas de diagnóstico (C1, C5, C6): clave de 4 errores (E1–E4)
Para cada respuesta y cada error de la clave:
- `det`: "S" si la respuesta identifica el mismo defecto de la clave, con cualquier redacción y aunque lo ubique en otra línea; "N" si no. No cuenta una mención vaga que no señale el defecto concreto. Si el ítem de la clave tiene dos partes, basta con identificar una (anota en `obs` cuál faltó).
- `cor`: "S" si la corrección propuesta para ese defecto lo resolvería; "N" si no; "" (vacío) si el defecto no fue detectado.
- `adic`: número entero de defectos reales del código señalados que NO están en la clave (en C1 el hallazgo "luzV/luzR no se apagan en el estado 3" cuenta aquí). Un mismo punto repetido cuenta una vez.
- `inv`: número entero de cosas presentadas como error que no lo son (el código es correcto en ese punto o contradice la especificación). Un mismo punto repetido cuenta una vez.
- `obs`: una línea breve que justifique lo más relevante.
Califica lo que la respuesta dice, no lo que probablemente quiso decir. Si está cortada, califica lo que alcanzó a entregar.

## Tarea C2 (de requisito ambiguo a especificación)
- `es`: lista de 5 "S"/"N", presencia en la tabla de E/S (con cualquier nombre) de: [nivel del tanque superior, agua en el pozo / marcha en seco, botón de paro, mando de la bomba, luz de aviso].
- `tipos`: "S" si todos los tipos de dato de la tabla son tipos IEC 61131-3 válidos y coherentes con la señal.
- `pou`: uno de "FUNCTION", "FUNCTION_BLOCK", "PROGRAM", "Varios o ninguno" (el que la respuesta recomienda).
- `jus`: "S" si la justificación del POU es técnicamente coherente.
- `amb`: lista de 6 "S"/"N", si la respuesta plantea cada ambigüedad de la clave A1–A6 (con cualquier redacción).
- `adic`: entero, otras ambigüedades pertinentes no incluidas en la clave.
- `codigo_st`: "S" si la respuesta incluye código ST (el enunciado pedía no hacerlo).
- `obs`: una línea.

## Salida
Escribe `salida/diag_<TAREA>.json` con una lista JSON de 24 objetos, uno por código, en el mismo orden de la entrada:
- Diagnóstico: `{"codigo": "...", "det": ["S","N","S","S"], "cor": ["S","","N","S"], "adic": 0, "inv": 1, "obs": "..."}`
- C2: `{"codigo": "...", "es": [...5], "tipos": "S", "pou": "FUNCTION_BLOCK", "jus": "S", "amb": [...6], "adic": 1, "codigo_st": "N", "obs": "..."}`
Valida el archivo con python (24 objetos, códigos iguales a los de la entrada, valores permitidos) antes de terminar.


---

# Evaluación a ciegas con la rúbrica de 5 criterios × 4 niveles

Actúas como un evaluador humano experto en programación de PLC (IEC 61131-3, CODESYS). Califica con el criterio de un docente cuidadoso, de forma consistente entre respuestas. No intentes adivinar qué modelo produjo cada respuesta.

Entrada: `entrada/rub_<TAREA>.json`: enunciado que recibieron los modelos, protocolo de prueba (pasos del harness con que se simuló), y 24 respuestas con: código ST extraído, resultado en CODESYS, mensajes del compilador si no compila, y las puntuaciones ya fijadas por regla (`funcional_fijo`, `iec_fijo`; null = la pones tú).
Primero lee el enunciado, el protocolo y las 24 respuestas; después puntúa cada una.

## Rúbrica (Insuficiente 0 · Básico 1 · Competente 2 · Excelente 3)
- **Corrección funcional.** 0: no implementa la lógica pedida o falla en el caso nominal. 1: funciona en el caso nominal pero falla en casos límite evidentes (flancos, reset, E-stop). 2: correcto en el caso nominal y en la mayoría de los casos límite; fallas menores sin riesgo. 3: correcto en todos los casos probados, incluidos límites y secuencias de fallo.
- **Cumplimiento IEC 61131-3.** 0: no compila; sintaxis o declaraciones inválidas. 1: compila solo tras correcciones menores, o usa extensiones fuera del estándar. 2: compila sin cambios; declaraciones y tipos correctos. 3: compila sin cambios y usa construcciones idiomáticas del estándar (POU adecuado, tipos TIME correctos, FB estándar bien instanciados).
- **Coherencia lógica.** 0: condiciones contradictorias, variables sin inicializar con efecto, o estados muertos que impiden operar. 1: lógica mayormente coherente con redundancias o condiciones muertas sin efecto grave. 2: sin contradicciones; inicialización correcta; transiciones completas. 3: además, robusta: interlocks completos, sin estados inalcanzables, comportamiento seguro ante entradas simultáneas.
- **Claridad estructural.** 0: sin estructura reconocible; nombres crípticos; sin comentarios. 1: estructura básica pero nombres pobres o comentarios ausentes/incorrectos. 2: nombres descriptivos, secciones ordenadas, comentarios útiles. 3: además, modularización adecuada (FB reutilizable, separación lógica/E/S) y comentarios que explican el porqué.
- **Mantenibilidad.** 0: valores mágicos por doquier; imposible modificar sin reescribir. 1: modificable con esfuerzo; constantes parcialmente parametrizadas. 2: parámetros como variables/constantes declaradas; cambios localizados. 3: además, diseño extensible (parámetros de entrada del FB, sin duplicación de lógica).

## Reglas de decisión (fijas)
- Si NO compila: Cumplimiento IEC = 0 y Corrección funcional = 0 (ya fijadas). Los otros tres criterios se puntúan igual leyendo el código.
- Si pasa TODOS los pasos del harness: Corrección funcional = 3 (ya fijada).
- Si compila pero falla pasos: Corrección funcional 0, 1 o 2 según la rúbrica, usando los pasos fallidos y el protocolo de prueba (los pasos se numeran desde 0).
- Si compila sola pero no se pudo simular (interfaz no conforme): Corrección funcional 0, 1 o 2 leyendo el código; nunca 3.
- Cumplimiento IEC cuando compila: 1 si usa extensiones fuera del estándar; 2 si declaraciones y tipos son correctos; 3 si además es idiomático.
- Repartir el código entre declaración e implementación no penaliza.
- Puntúa lo que el código es, no lo que el modelo probablemente quiso hacer.

## Salida
Escribe `salida/rub_<TAREA>.json`: lista JSON de 24 objetos, en el orden de la entrada:
`{"codigo": "...", "funcional": 0-3, "iec": 0-3, "coherencia": 0-3, "claridad": 0-3, "mantenibilidad": 0-3, "just_func_iec": "una línea (solo si alguna de esas dos no estaba fijada; si no, \"\")", "just_coherencia": "una línea", "just_claridad": "una línea", "just_mantenibilidad": "una línea"}`
`funcional` e `iec` deben copiar exactamente el valor fijado cuando no es null; cuando es null, respeta los rangos de las reglas (funcional 0–2; iec 1–3).
Valida el archivo con python antes de terminar (24 objetos, códigos iguales a la entrada, rangos y valores fijados respetados).
