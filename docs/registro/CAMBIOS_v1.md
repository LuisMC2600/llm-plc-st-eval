# Banco v1 — registro de cambios respecto a la línea base (v0)

*28 de septiembre de 2026. Aplica las decisiones D1–D3 y D5–D8 de `01_Revision_Banco/Revision_Banco_30_Tareas.md` (D4 quedó resuelta antes: el piloto se conserva). Todos los cambios se hicieron en `generar_prompts.py` de esta carpeta, nunca en `tasks.json`; la línea base de `00_Linea_Base_Banco/` no se tocó.*

## Integridad

`verificar_hashes.py` contra `llm-plc-st-eval/data/raw/log.jsonl`: **24/24 prompts del piloto idénticos byte a byte** (B1–B6 e I1–I6, zero-shot y few-shot). Contra la línea base cambian exactamente los prompts previstos y ningún otro: B7, I7, I8, A1, A2, A3, A5, A6 y C4 en ambas estrategias, y C1, C3, C5, C6, C7 y C8 solo en few-shot. B8, A4 y C2 quedan idénticas. Tipos, niveles y total se mantienen: 30 tareas, 60 prompts, 720 ejecuciones. El prompt más largo (few-shot de C5) tiene 3 909 caracteres, unos 1 300 tokens, bajo el tope de 2 000. `hashes_v1.json` guarda la huella de esta versión para comparaciones futuras.

El código ST nuevo (los cuatro ejemplos few-shot y el FB de C4) se validó con blark 0.8.3 y todo parsea. El FB de C4 se simuló contra la especificación de I7 en 3 000 secuencias aleatorias de 40 ciclos: 0 discrepancias.

## Cambios por decisión

**D1 — Documento madre.** `Banco_de_Pruebas_v1.xlsx`:

- La hoja del banco pasa a 30 tareas, con C5–C8 añadidas.
- Cada fila resume el prompt real y los títulos coinciden con `tasks.json`.
- Las 12 tareas del piloto quedan en estado «Aprobado v1 — congelada (piloto)» y las demás en «Aprobado v1».
- El protocolo describe el few-shot por tipo y ya dice «30 tareas».
- La rúbrica incorpora la marca de seguridad no solicitada (D6).

**D2 — Few-shot por tipo.**

- **T2 (C1, C5, C6):** recibe dos diagnósticos resueltos ajenos al banco, `FB_Calefactor` con 2 errores y `FB_Telerruptor` con 1. Los ejemplos tienen a propósito un número de errores distinto de los 4 de las tareas, para no sugerir cuántos buscar.
- **T4 (C3, C7, C8):** recibe dos conversiones LD→ST resueltas, `FB_Cinta` (serie, paralelo y contacto NC) y `FB_Piloto` (bobinas S/R y orden de ramas).
- En T2 y T4 el cierre pasa a ser «…con el mismo formato», porque ahora el formato coincide.
- T3 (C2) y T5 (C4) conservan los ejemplos de generación como cebado de formato, y así se declarará en la metodología.

**D3 — Precisión de especificaciones** (solo tareas nunca ejecutadas):

| Tarea | Cambio |
|---|---|
| B7 | Se elimina la cláusula no verificable de «activaciones espurias» y se declara la lógica sin memoria. Ver también D6 |
| I8 | Se añade `btnParo` (prioritario) a la interfaz; arranque por flanco de `btnMarcha`; sin rearranque automático; `causaBloqueo` evaluada en todo momento |
| A1 | Forma estándar del PID fijada, con e = SP − PV y derivada sobre el error; `Ti ≤ 0` desactiva la integral; anti-windup por clamping condicional definido en ambos límites |
| A2 | `btnInicio` solo desde reposo; abort definido por fase según `nivelVacio`; `fase` informa 5 durante la descarga por abort; abort sin efecto en reposo |
| A3 | Reintentos observables: salidas nuevas `ocupado` y `ok`, y `nIntentos` pasa de interna a salida; eco distinto = intento fallido inmediato; `txReq` se ignora durante un intercambio |
| A5 | La marca de tiempo se acumula con una entrada nueva `ciclo`, lo que elimina la dependencia de `TIME()` (no estándar); `indice = −1` sin eventos; salida nueva `nEventos` |

**D5 — I7 y C4 alineadas.** La especificación de I7 ahora fija que la primera demanda asigna `bomba1` como principal, que la de respaldo solo entra si no tiene falla, que la principal vuelve cuando su falla desaparece y que `almFalla` solo se activa por falla de la principal. El código de C4 y su clave implementan exactamente eso.

**D6 — Huecos de taxonomía.**

- B7 pasa a ser la única tarea con **POU a elección** (FUNCTION, FUNCTION_BLOCK o PROGRAM) y la primera en la que la respuesta idónea es una **FUNCTION**. Su clave puntúa la elección en el criterio 2: FUNCTION esperado, FB como máximo Competente, PROGRAM como máximo Básico.
- Efecto colateral: C3 queda como la única tarea que exige PROGRAM.
- **Seguridad no solicitada:** marca 1/0 en la submuestra de criterios 3–5 para B2, B3, B5 y B6. No altera ningún prompt.

**D7 — A6 enriquecida.** Pasa a manejar ocho actuadores con `ARRAY[0..7] OF BOOL` (mandos automático y manual por entrada), forzado individual por índice con flanco de confirmación en mantenimiento, anulación de forzados al salir o al perder `estadoSeguro`, y arranque en manual. Ahora cumple la definición operativa de Avanzado y refuerza la cobertura de arreglos, que antes descansaba solo en A5.

**D8 — Correcciones de evaluador.** La clave de C6 precisa que la división entera da 0 entre 0 y 27 647 y 100.0 exactamente en 27 648. La nota del Markdown lista todas las tareas con clave (C1, C2, C4, C5, C6 y B7).

## Consecuencias para lo que sigue

- Los harnesses por escribir son los de B7, B8, I7, I8, A1–A6 y C3. El de B7 debe detectar el POU elegido y envolver la llamada según el caso. I8, A3, A5 y A6 tienen interfaz nueva.
- C4 admite una comprobación automática de código intacto: quitar los comentarios y comparar tokens contra `CODIGO_C4`.
- El costo estimado de la Fase 4 no cambia de forma apreciable: los prompts few-shot de T2 crecen unos 780 caracteres y los de T4 unos 530, es decir, entre 150 y 270 tokens de entrada, en 18 llamadas por modelo (6 tareas × 3 corridas).

## Archivos

`generar_prompts.py` (fuente), `tasks.json` y `Prompts_Banco_v1.md` (derivados, no editar), `Banco_de_Pruebas_v1.xlsx`, `verificar_hashes.py`, `hashes_linea_base.json` (huella v0), `hashes_v1.json` (huella v1) y `SHA256SUMS.txt`.
