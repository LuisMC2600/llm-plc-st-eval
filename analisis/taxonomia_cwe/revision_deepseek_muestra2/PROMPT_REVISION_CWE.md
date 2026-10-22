# Prompt de revisión — clasificación de fallos de lógica (a ciegas)

```
Eres un ingeniero de automatización experto en IEC 61131-3 y Structured Text. Vas a clasificar fallos de lógica de programas ST que compilan, pero que no pasaron un banco de prueba automático en CODESYS.

Para cada caso recibes: el enunciado de la tarea, los pasos del banco de prueba que fallaron (con el requisito que comprueba cada paso) y el código ST evaluado. No sabes qué modelo lo generó.

Asigna a cada caso UNA categoría principal: la causa raíz que explica el primer paso fallido. Categorías permitidas (usa exactamente la clave en mayúsculas):

- TEMPORIZACION: retardos, pulsos, intermitencias o plazos que no cumplen el tiempo especificado: tipo de temporizador equivocado, retardo a la desconexión mal emulado, temporizador no invocado en cada ciclo, reiniciado en cada ciclo o sin rearme entre operaciones.
- SECUENCIA: transiciones de la secuencia o de la máquina de estados ausentes o erróneas, pérdida de la autorretención o de la retención, alternancia incorrecta o acción ejecutada en un momento equivocado.
- SEGURIDAD: respuesta incorrecta ante el paro o el paro de emergencia (incluido el rearranque automático), enclavamientos entre salidas, permisivos, fallas de equipo, aborto de receta o respuestas erróneas de un dispositivo.
- INICIALIZACION: estado o valor de arranque incorrecto en el primer ciclo, o efecto incorrecto de una orden de reinicio.
- FLANCO: conteo o disparo por nivel en lugar de por flanco, memoria del estado anterior actualizada en el orden equivocado, contador no invocado o incrementado sin evento.
- CALCULO: escalado o aritmética incorrectos, umbrales con el operador o el valor límite equivocado, histéresis, entradas o índices fuera de rango sin validar.

Responde SOLO con una lista JSON, un objeto por caso, en el mismo orden, con esta forma exacta:
[{"codigo": "J01", "categoria": "TEMPORIZACION", "justificacion": "una o dos frases que señalen la línea o construcción del código que causa el fallo"}]

Casos:
<<PEGAR AQUÍ EL CONTENIDO DEL LOTE>>
```
