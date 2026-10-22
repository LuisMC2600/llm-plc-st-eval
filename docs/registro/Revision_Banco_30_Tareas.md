# Revisión del banco de 30 tareas

*28 de septiembre de 2026. Primera actividad del reinicio desde el cierre de la Fase 3. Revisé los 60 prompts de `tasks.json`, el generador `generar_prompts.py` con sus claves de evaluación y el documento madre `Banco_de_Pruebas_v0.xlsx`, contra la taxonomía, el protocolo de prompting y la rúbrica de ese mismo libro. Todo sobre la copia congelada de `00_Linea_Base_Banco/`.*

---

## 1. Qué está bien y no hace falta tocar

La estructura de los prompts es impecable desde el punto de vista del control experimental. Los 30 prompts zero-shot comparten el mismo rol inicial, cada prompt few-shot es exactamente el prefijo de ejemplos seguido del cuerpo zero-shot, y solo existen dos prefijos, uno para T1 y otro para las complementarias, que difieren en una sola frase («…con el mismo formato»). Los dos ejemplos resueltos (`FB_Pasillo` con XOR y `FB_Lubricacion` con TP) no coinciden con ninguna tarea evaluada. El prompt más largo, el few-shot de C5, ronda los 1 050 tokens, muy por debajo del tope de 2 000 que fija el criterio 4 de representatividad. Los prompts describen qué debe hacer el sistema sin nombrar el bloque estándar que lo resuelve (ninguno dice «usa un TOF»), lo cual respeta la regla del protocolo.

Las claves de evaluación de las tareas no generativas existen y son buenas: C1, C5 y C6 con sus cuatro errores sembrados cada una, C2 con seis ambigüedades esperadas y C4 con su comportamiento real. Las tres claves de diagnóstico las comprobé contra el código sembrado y los cuatro errores de cada una están efectivamente presentes. El diseño intra-tarea de C7 frente a B3 y de C8 frente a B2 es correcto: la lógica de cada segmento Ladder es equivalente a su especificación en lenguaje natural.

Dato que condiciona todo lo demás: el log del piloto contiene únicamente **B1–B6 e I1–I6** (12 ejecuciones cada una). Solo esos 24 prompts están congelados por el dato primario. **Los otros 36 prompts (18 tareas) nunca se han enviado a ningún modelo**, así que corregirlos no rompe la comparabilidad con el piloto ni con el artículo CITDES.

---

## 2. Hallazgos

### 2.1 Trazabilidad del documento madre

`Banco_de_Pruebas_v0.xlsx` es del 20 de julio y sigue describiendo 26 tareas: no contiene C5–C8, todas figuran en estado «Borrador», y el protocolo dice «replicar el patrón en las 26 tareas». Además, varias especificaciones del libro no coinciden con el prompt que realmente se envía: A2 promete un STRUCT de receta y reanudación que el prompt no pide; A3 promete un checksum que el prompt sustituyó por eco; A6 promete forzado de salidas «una a una» y el prompt lo reduce a una única habilitación; I5 promete un retardo dependiente de la posición y el prompt lo fija en 2 s. Todas son simplificaciones razonables, pero el tribunal leerá el libro como la definición del banco y encontrará otra cosa en los datos.

### 2.2 El few-shot no demuestra la tarea en las complementarias

Las ocho tareas complementarias reciben los mismos dos ejemplos de generación de código que T1. Para C1, C5 y C6 (diagnóstico), C2 (especificación) y C4 (documentación), la salida pedida no es código, así que el «few-shot» no es una demostración de la tarea sino un simple cebado de formato, y en rigor puede empujar al modelo hacia la salida equivocada. Para C3, C7 y C8 los ejemplos son NL→ST y no LD→ST. Consecuencia: la comparación zero-shot/few-shot en T2 y T4, que ahora son tipos cuantitativos con n = 3, no mide lo mismo que en T1. Como C1–C8 nunca se ejecutaron, esto se puede corregir sin coste para el piloto.

### 2.3 Especificaciones ambiguas o no verificables en tareas no ejecutadas

Estas tareas tendrán que evaluarse por harness, y un harness necesita un comportamiento esperado único. Hoy no lo tienen:

| Tarea | Problema | Efecto sobre la verificación |
|---|---|---|
| B7 | «La conmutación entre modos no debe producir activaciones espurias» no está definida: con lógica combinacional pura, pasar a automático con `nivelBajo` activo enciende la bomba, y no se sabe si eso es espurio | Criterio no verificable; dos respuestas correctas pueden recibir veredictos opuestos |
| I8 | No existe botón de paro: el compresor solo se detiene perdiendo un permisivo | Especificación irreal para un compresor; las respuestas que añadan un paro se desvían de la interfaz |
| A1 | No se fija la forma del PID (ideal/ISA, paralela), el sentido de acción ni el tratamiento de `Ti = 0` | Solo es verificable por propiedades (estabilidad, límites, ausencia de windup), no por valores |
| A2 | No se dice qué reporta `fase` durante la descarga provocada por un abort, ni qué hace `btnInicio` con la receta en curso | El harness tendría que aceptar varias respuestas |
| A3 | `nIntentos` es variable interna (`VAR`), no salida; `txData` queda fijo en 100, así que un reintento es invisible desde fuera; no hay salida de éxito | El número de reintentos, que es el criterio de éxito de la tarea, no es observable desde el harness |
| A5 | La «marca de tiempo desde el arranque» obliga a usar `TIME()` (extensión de CODESYS, fuera del estándar) o un cronómetro propio; el valor inicial de `indice` antes del primer evento no está definido | Conflicto con el criterio 2 (IEC 61131-3) y ambigüedad en el primer paso |
| A6 | ¿El cambio de modo es por nivel (se acepta en cuanto `estadoSeguro` vuelve) o por evento? Además, con 3 entradas y 2 salidas no cumple la definición operativa de Avanzado (>15 variables o estructuras) | Ambigüedad de harness y problema de validez del nivel |

### 2.4 Ambigüedades en tareas del piloto (congeladas)

I3 no aclara si un ACK mantenido mientras la causa sigue presente borra la alarma en cuanto la causa desaparece. I5 no dice qué pasa si llega una segunda pieza alta antes de que termine el desvío de la primera. B1 no fija la polaridad de `btnParo`/`btnEmerg`, aunque el libro dice NC y el harness asume TRUE = pulsado. Estos prompts **no se tocan**; la ambigüedad se documenta y el harness debe ser tolerante o fijar la interpretación de forma explícita en la metodología.

### 2.5 Incoherencia entre I7 y C4

C4 entrega como «correcto» el código que resuelve I7, pero sus semánticas de alarma difieren. Según I7, `almFalla` se activa cuando falla la bomba principal en servicio; según el código de C4 y su clave, se activa ante cualquier falla con demanda, incluida la de la bomba de respaldo. Una de las dos definiciones tiene que ceder, porque el harness de I7 y la clave de C4 no pueden contradecirse.

### 2.6 Cobertura de la taxonomía

Los mínimos numéricos se cumplen: temporización, conteo, flancos, CASE, control continuo (I6, A1, A4) y seguridad (B1, B4, I2, I4, I8, A2, A6) superan lo exigido. Quedan tres huecos que la propia taxonomía declara y el banco no mide:

- **Ninguna tarea pide una FUNCTION.** La taxonomía dice que el POU se evalúa en sus tres formas y solo aparecen FB y PROGRAM (B7, C3).
- **Ninguna tarea deja el POU sin indicar.** La taxonomía propone «evaluar si el LLM elige el POU correcto (con y sin indicación)», pero todos los prompts lo imponen.
- **Nada mide la seguridad no solicitada.** El criterio transversal «¿el LLM incluye seguridad sin pedírsela?» no está operacionalizado en ninguna tarea ni en la rúbrica.

También hay que notar que STRUCT/ARRAY descansa en una sola tarea (A5) y que el conteo solo cubre CTU (sin CTD/CTUD).

### 2.7 Detalles menores

- La clave de C6 dice que la división entera «vale 0 en todo el rango válido». No es exacto: en `rawTemp = 27648` vale 1 y `tempC` da 100.0. Conviene precisarlo para que un modelo que lo señale no se puntúe como falso positivo.
- La nota metodológica del Markdown dice que hay claves «al final de C1, C2 y C4»; también las tienen C5 y C6.
- A5 pide `TYPE … END_TYPE` junto con el FB en una sola respuesta: `extraer_codigo.py` y `compilar_lote.py` deberán separar el DUT del POU para importarlo en CODESYS.

### 2.8 Verificabilidad del criterio 1

Existen harnesses para 12 tareas (las del piloto) y C7/C8 reutilizan los de B3/B2. **Faltan 11 harnesses nuevos** para B7, B8, I7, I8, A1–A6 y C3, que no existen ni como borrador; lo que la Fase 3 llamaba «11 validadores faltantes» se refería a validar los 12 existentes, no a estos. Sin ellos, la corrección funcional por censo cubre 14 de las 25 tareas que producen código. Para C4 hay una comprobación automática barata que hoy no está prevista: quitar los comentarios de la respuesta y comparar los tokens con el código original demuestra que «la lógica no se modificó».

---

## 3. Decisiones que te tocan

| # | Decisión | Mi recomendación |
|---|---|---|
| D1 | Actualizar el documento madre a v1 (30 tareas, especificaciones alineadas con los prompts reales, estado «Aprobado») | **Sí.** Es trazabilidad pura y no afecta a ningún dato |
| D2 | Few-shot de las complementarias | **Ejemplos específicos por tipo para T2 y T4** (un diagnóstico resuelto y una conversión LD→ST resuelta, ajenos al banco); T3 y T5 se quedan como están y se declara que su few-shot es solo cebado de formato |
| D3 | Precisar B7, I8, A1, A2, A3, A5 y A6 | **Sí, antes de escribir sus harnesses.** No están ejecutadas; cada ambigüedad que se deje ahora se convierte en un veredicto discutible después |
| D4 | Ambigüedades del piloto (I3, I5, B1) | **No tocar prompts.** Fijar la interpretación en la metodología y comprobar que los harnesses la aplican |
| D5 | I7 frente a C4 | Alinear a la semántica de **I7** (alarma solo por falla de la principal) y ajustar el código y la clave de C4 |
| D6 | Huecos de taxonomía | Aprovechar una tarea no ejecutada para pedir una **FUNCTION sin indicar el POU** (candidata: A4 o un escalado puro), y registrar la **seguridad no solicitada** como marca binaria en la muestra de criterios 3–5 sobre tareas que no la piden (B2, B3, B5, B6) |
| D7 | A6 como tarea avanzada | Recuperar el diseño del libro: forzado individual de N actuadores con `ARRAY` y confirmación, lo que además refuerza la cobertura de arreglos |
| D8 | Clave de C6 y nota del Markdown | Corregir; es texto de evaluador, no se envía al modelo |

Si apruebas D1–D8 tal como están, el trabajo concreto sería: crear `02_Banco_v1/` en esta carpeta con una copia del generador, aplicar los cambios solo a las 18 tareas no ejecutadas, regenerar y demostrar con `verificar_hashes.py` que los 24 prompts del piloto siguen idénticos byte a byte. Después, el total de ejecuciones sigue siendo 720 y la estimación de coste no cambia de forma apreciable.
