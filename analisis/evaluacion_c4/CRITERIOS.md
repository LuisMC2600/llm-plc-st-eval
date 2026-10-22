# Evaluación cualitativa de la documentación de C4 — criterios fijados antes de leer las respuestas

Fijados el 2026-10-15 20:42 (hora de Panamá), antes de abrir las 24 respuestas.
Evaluador: Claude, como asistente de análisis. Se lee la respuesta cruda (data/definitivo, sin modificar).

Referencia del comportamiento de FB_D (del enunciado):
- R_TRIG sobre demanda: en cada flanco de subida se invierte turno; turno arranca en FALSE, así que la primera demanda deja turno = TRUE.
- turno = TRUE: bomba1 es la principal; bomba2 arranca como respaldo solo si falla1 y no falla2; almFalla = falla1.
- turno = FALSE: bomba2 es la principal; bomba1 es respaldo si falla2 y no falla1; almFalla = falla2.
- almFalla señala la falla de la bomba principal del turno (también si fallan ambas); la falla sola del respaldo no genera alarma.
- Sin demanda, todo apagado y sin alarma.

Criterios (por respuesta):
1. Descripción (párrafo): Sí = identifica la alternancia por demanda, el respaldo ante falla y la alarma, y propone una aplicación plausible; Parcial = falta uno de esos elementos; No = descripción errónea o ausente.
2. Cobertura: bloques del código con al menos un comentario pertinente, sobre 5 (a: declaraciones; b: flanco y alternancia de turno; c: rama turno = TRUE; d: rama turno = FALSE; e: sin demanda).
3. Errores técnicos: número de afirmaciones incorrectas sobre el comportamiento, en el párrafo o en los comentarios (se anotan).
4. Nivel: Intención = predominan comentarios que explican el propósito; Mixto; Paráfrasis = predominan comentarios que repiten la sintaxis.
