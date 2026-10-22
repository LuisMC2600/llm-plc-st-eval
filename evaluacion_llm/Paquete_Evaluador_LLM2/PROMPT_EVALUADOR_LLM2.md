# Prompts para el segundo evaluador LLM

Uso: abrir **una conversación nueva por tarea** (29 en total). Pegar el prompt que corresponda, sustituir `<<PEGAR AQUÍ EL CONTENIDO DE ...>>` por el contenido completo del JSON de la tarea (carpeta `entrada/`) y enviar.
Guardar la respuesta, sin cambios, como `salida/diag_<T>.json` o `salida/rub_<T>.json`.
Si el modelo corta la salida, escribir "continúa exactamente donde te quedaste" y unir las partes.
Mantener la misma configuración en las 29 conversaciones (modelo, temperatura baja si se puede elegir, sin búsqueda web).

---

## PROMPT A — Tareas de diagnóstico C1, C5 y C6

```
Actúas como evaluador experto en programación de PLC según IEC 61131-3. Vas a calificar, a ciegas, 24 respuestas que distintos asistentes dieron a una misma tarea de diagnóstico de código. Califica como lo haría un docente cuidadoso y aplica exactamente el mismo criterio a las 24. No intentes adivinar qué modelo produjo cada respuesta.

El JSON de abajo contiene: "enunciado" (lo que recibieron los asistentes, con el código defectuoso), "clave" (los 4 errores reales, E1 a E4, y a veces un hallazgo adicional aceptado) y "respuestas" (24 textos identificados por "codigo").

Primero lee el enunciado, la clave y las 24 respuestas completas. Después califica cada respuesta así:
- det: lista de 4 valores "S"/"N", uno por cada error E1–E4. "S" si la respuesta identifica ese mismo defecto concreto, con cualquier redacción y aunque lo ubique en otra línea. Una mención vaga que no señala el defecto concreto vale "N". Si el ítem de la clave tiene dos partes, basta con identificar una (indica en obs cuál faltó).
- cor: lista de 4 valores. "S" si la corrección propuesta para ese defecto lo resolvería de verdad, "N" si no, y "" (cadena vacía) si el defecto no fue detectado.
- adic: entero. Número de defectos reales del código que la respuesta señala y que NO están en la clave; si la clave menciona un hallazgo adicional aceptado, ese también cuenta aquí. Un mismo punto repetido cuenta una vez.
- inv: entero. Número de cosas que la respuesta presenta como error y no lo son (el código es correcto en ese punto o la afirmación contradice la especificación). Un mismo punto repetido cuenta una vez.
- obs: una línea breve que justifique lo más relevante.

Califica lo que la respuesta dice, no lo que probablemente quiso decir. Si una respuesta está cortada, califica lo que alcanzó a entregar.

Responde ÚNICAMENTE con una lista JSON válida de 24 objetos, en el mismo orden de la entrada, sin texto antes ni después y sin bloque de código markdown. Formato de cada objeto:
{"codigo": "C1-130", "det": ["S","N","S","S"], "cor": ["S","","N","S"], "adic": 0, "inv": 1, "obs": "..."}

Antes de responder, verifica que haya exactamente 24 objetos, que los códigos sean los de la entrada y que cor sea "" en cada posición donde det es "N".

<<PEGAR AQUÍ EL CONTENIDO DE entrada/diag_C1.json (o C5 o C6)>>
```

---

## PROMPT B — Tarea C2 (de requisito ambiguo a especificación)

```
Actúas como evaluador experto en programación de PLC según IEC 61131-3. Vas a calificar, a ciegas, 24 respuestas que distintos asistentes dieron a una misma tarea. Califica como lo haría un docente cuidadoso y aplica exactamente el mismo criterio a las 24. No intentes adivinar qué modelo produjo cada respuesta.

El JSON de abajo contiene: "enunciado" (un requisito ambiguo de un cliente; se pedía tabla de E/S, POU recomendado con justificación y lista de ambigüedades, sin código), "clave" (5 E/S esperadas y 6 ambigüedades A1–A6) y "respuestas" (24 textos identificados por "codigo").

Primero lee todo. Después califica cada respuesta así:
- es: lista de 5 "S"/"N". Indica si la tabla de E/S incluye, con cualquier nombre: [nivel del tanque superior, agua en el pozo / protección de marcha en seco, botón de paro, mando de la bomba, luz de aviso].
- tipos: "S" si todos los tipos de dato de la tabla son tipos IEC 61131-3 válidos y coherentes con la señal; "N" si alguno no lo es.
- pou: el POU que la respuesta recomienda, exactamente uno de "FUNCTION", "FUNCTION_BLOCK", "PROGRAM", "Varios o ninguno".
- jus: "S" si la justificación del POU es técnicamente coherente; "N" si no.
- amb: lista de 6 "S"/"N", una por cada ambigüedad A1–A6 de la clave, según si la respuesta la plantea, con cualquier redacción.
- adic: entero. Otras ambigüedades pertinentes que no están en la clave.
- codigo_st: "S" si la respuesta incluye código ST (el enunciado pedía no hacerlo); "N" si no.
- obs: una línea breve.

Responde ÚNICAMENTE con una lista JSON válida de 24 objetos, en el mismo orden de la entrada, sin texto antes ni después y sin bloque de código markdown. Formato de cada objeto:
{"codigo": "C2-183", "es": ["S","S","S","S","S"], "tipos": "S", "pou": "FUNCTION_BLOCK", "jus": "S", "amb": ["N","S","S","S","S","S"], "adic": 1, "codigo_st": "N", "obs": "..."}

Antes de responder, verifica que haya exactamente 24 objetos y que los códigos sean los de la entrada.

<<PEGAR AQUÍ EL CONTENIDO DE entrada/diag_C2.json>>
```

---

## PROMPT C — Rúbrica de 5 criterios (25 tareas: B1…B8, I1…I8, A1…A6, C3, C7, C8)

```
Actúas como evaluador experto en programación de PLC según IEC 61131-3 y CODESYS. Vas a puntuar, a ciegas, 24 programas en Structured Text que distintos asistentes escribieron para una misma tarea. Puntúa como lo haría un docente cuidadoso y de forma consistente entre las 24 respuestas. No intentes adivinar qué modelo produjo cada respuesta.

El JSON de abajo contiene: "enunciado" (lo que recibieron los asistentes), "protocolo_prueba" (los pasos del banco de prueba con que se simuló cada programa en CODESYS, numerados desde 0) y "respuestas". Cada respuesta trae: "codigo", "codigo_st" (el programa), "resultado_codesys" (si compiló y cuántos pasos del banco pasó o falló), "mensajes_compilador" (si no compiló) y dos puntuaciones ya fijadas por regla, "funcional_fijo" e "iec_fijo" (null significa que la pones tú).

Primero lee el enunciado, el protocolo y las 24 respuestas. Después puntúa cada una con esta rúbrica (0 Insuficiente, 1 Básico, 2 Competente, 3 Excelente):
- Corrección funcional. 0: no implementa la lógica pedida o falla en el caso nominal. 1: funciona en el caso nominal pero falla en casos límite evidentes (flancos, reset, paro de emergencia). 2: correcto en el caso nominal y en la mayoría de los casos límite; fallas menores sin riesgo. 3: correcto en todos los casos probados, incluidos límites y secuencias de fallo.
- Cumplimiento IEC 61131-3. 0: no compila; sintaxis o declaraciones inválidas. 1: compila solo tras correcciones menores, o usa extensiones fuera del estándar. 2: compila sin cambios; declaraciones y tipos correctos. 3: compila sin cambios y usa construcciones idiomáticas del estándar (POU adecuado, tipos TIME correctos, bloques estándar como TON, R_TRIG o CTU bien instanciados).
- Coherencia lógica. 0: condiciones contradictorias, variables sin inicializar con efecto, o estados muertos que impiden operar. 1: lógica mayormente coherente, con redundancias o condiciones muertas sin efecto grave. 2: sin contradicciones; inicialización correcta; transiciones completas. 3: además robusta: interlocks completos, sin estados inalcanzables, comportamiento seguro ante entradas simultáneas.
- Claridad estructural. 0: sin estructura reconocible; nombres crípticos; sin comentarios. 1: estructura básica, pero nombres pobres o comentarios ausentes o incorrectos. 2: nombres descriptivos, secciones ordenadas, comentarios útiles. 3: además modularización adecuada (FB reutilizable, separación entre lógica y E/S) y comentarios que explican el porqué.
- Mantenibilidad. 0: valores mágicos por todas partes; imposible modificar sin reescribir. 1: modificable con esfuerzo; constantes parcialmente parametrizadas. 2: parámetros como variables o constantes declaradas; cambios localizados. 3: además diseño extensible (parámetros de entrada del FB, sin duplicación de lógica).

Reglas de decisión fijas:
- Si funcional_fijo o iec_fijo no son null, copia ese valor exactamente.
- Si el programa NO compila: funcional = 0 e iec = 0 (vienen fijados). Los otros tres criterios se puntúan igual, leyendo el código.
- Si pasa TODOS los pasos del banco: funcional = 3 (viene fijado).
- Si compila pero falla pasos: funcional 0, 1 o 2 según la rúbrica, usando qué pasos fallan y el protocolo.
- Si compila pero no se pudo simular (interfaz no conforme): funcional 0, 1 o 2 leyendo el código; nunca 3.
- Cumplimiento IEC cuando compila: 1 si usa extensiones fuera del estándar; 2 si declaraciones y tipos son correctos; 3 si además es idiomático.
- Repartir el código entre declaración e implementación no penaliza.
- Puntúa lo que el código es, no lo que el asistente probablemente quiso hacer.

Responde ÚNICAMENTE con una lista JSON válida de 24 objetos, en el mismo orden de la entrada, sin texto antes ni después y sin bloque de código markdown. Formato de cada objeto:
{"codigo": "B1-3577", "funcional": 3, "iec": 2, "coherencia": 2, "claridad": 2, "mantenibilidad": 1, "just_func_iec": "una línea, o \"\" si las dos estaban fijadas", "just_coherencia": "una línea", "just_claridad": "una línea", "just_mantenibilidad": "una línea"}

Antes de responder, verifica: 24 objetos; códigos iguales a los de la entrada; valores enteros entre 0 y 3; valores fijados copiados; cuando funcional no estaba fijado, que esté entre 0 y 2; cuando iec no estaba fijado, que esté entre 1 y 3.

<<PEGAR AQUÍ EL CONTENIDO DE entrada/rub_<TAREA>.json>>
```
