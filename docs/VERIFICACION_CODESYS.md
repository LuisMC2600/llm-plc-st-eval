# Verificación de los 12 Harnesses en CODESYS Real (Pre-Fase 5)

**Proyecto:** «LLMs como Asistentes de Programación PLC en la Academia: Evaluación de Precisión y Confiabilidad» (FIE-UTP)  
**Autor:** Luis Montenegro · **Asesora:** Mgtr. Sofía Serracín Moreno  
**Fecha del informe:** 2026-09-25  
**Alcance:** Inventario de interfaces y tiempos de los 12 harnesses (`PRG_Test_B1.st` … `PRG_Test_I6.st`), mapa de compatibilidad estática sobre las 144 respuestas del piloto (`data/processed/`), auditoría de implementaciones de referencia, evaluación y propuesta de ampliación de `compilar_lote.py`, y análisis del hueco de cobertura sobre el banco de 30 tareas.

---

## 1. Inventario de interfaces y duraciones de los 12 harnesses

Cada harness es un `PROGRAM` en Structured Text (`PRG_Test_<ID>.st`) que instancia el `FUNCTION_BLOCK` bajo prueba (`fb`), aplica una secuencia determinista de entradas paso a paso (`0..ULTIMO_PASO`), evalúa las salidas al vencer el tiempo de asentamiento de cada paso (`tPaso.Q`) y registra el resultado individual en `resultado[0..ULTIMO_PASO]` (`1` = pasa, `2` = falla) y el veredicto global en `veredicto` (`1` = PASA, `2` = FALLA).

### 1.1 Tabla maestra de interfaces y tiempos

| Tarea | Harness (`PROGRAM`) | FB esperado (`FUNCTION_BLOCK`) | `VAR_INPUT` usadas por el harness | `VAR_OUTPUT` leídas por el harness | Variables extra de vigilancia / medida en el harness | `ULTIMO_PASO` (n.º pasos) | `T_ASENTAMIENTO` / `tEspera` por paso | Duración implicada por `.st` (nominal) | Duración medida en Python (`4 ms` / `10 ms` / `20 ms`) | Duración doc. previa (`ENMIENDAS`) | ¿Coincide `.st` con medida? |
|---|---|---|---|---|---|---:|---|---:|---:|---:|---|
| **B1** | `PRG_Test_B1` | `FB_Motor` | `btnMarcha: BOOL`<br>`btnParo: BOOL`<br>`btnEmerg: BOOL` | `motorOn: BOOL` | — | `6` (7 pasos: `0..6`) | Fijo: `T#200MS` ($\times 7$) | **1.40 s** | `1.424 s` / `1.460 s` / `1.660 s` | `1.6 s` (a 20 ms) | **Sí** (7 pasos completos; a 20 ms suma 1 scan extra por paso) |
| **B2** | `PRG_Test_B2` | `FB_Valvula` | `nivelAlto: BOOL` | `valvula: BOOL` | — | `5` (6 pasos: `0..5`) | Variable (`tEspera`):<br>`0`: 500 ms · `1`: 3 s · `2`: 3 s · `3`: 200 ms · `4`: 6 s · `5`: 200 ms | **12.90 s** | `12.924 s` / `12.980 s` / `13.060 s` | `12.9 s` | **Sí** (exacta) |
| **B3** | `PRG_Test_B3` | `FB_Contador` | `sensorPieza: BOOL`<br>`btnReset: BOOL` | `cuenta: INT`<br>`loteListo: BOOL` | Generador de flancos:<br>`FLANCOS_LOTE_A = 10`,<br>`FLANCOS_LOTE_B = 1`,<br>`T_PULSO = T#20MS` | `6` (7 pasos: `0..6`) | Variable (`tEspera`) + pulsos:<br>`0,1,3,6`: 200 ms · `2`: 500 ms · `4`: 19×20 ms + 200 ms · `5`: 2×20 ms + 200 ms | **2.12 s** (1.70 s espera + 0.42 s pulsos) | **`2.216 s` / `2.360 s` / `2.720 s`** | *Sin dato previo* | **Sí** (medida por primera vez; diferencia por 27 scans de reset) |
| **B4** | `PRG_Test_B4` | `FB_Giro` | `btnFwd: BOOL`<br>`btnRev: BOOL`<br>`btnParo: BOOL` | `fwd: BOOL`<br>`rev: BOOL` | `violacionInterlock: BOOL` (enclavada cada scan si `fwd AND rev`, enm. 4 y 9) | `9` (10 pasos: `0..9`) | Fijo: `T#150MS` ($\times 10$) | **1.50 s** | `1.556 s` / `1.590 s` / `1.780 s` | `1.5 s` | **Sí** (exacta; incluye pasos 8–9 desde reposo, enm. 9) |
| **B5** | `PRG_Test_B5` | `FB_Ventilador` | `quemadorOn: BOOL` | `ventilador: BOOL` | — | `8` (9 pasos: `0..8`) | Variable (`tEspera`):<br>`0,1,4,6`: 200 ms · `2,7`: 29 s · `3,8`: 1.2 s · `5`: 10 s | **71.20 s** | `71.236 s` / `71.290 s` / `71.500 s` | `71.2 s` | **Sí** (exacta; recorre los dos post-enfriamientos de 30 s, enm. 7) |
| **B6** | `PRG_Test_B6` | `FB_Baliza` | `alarma: BOOL` | `lampara: BOOL` | `tCrono: TON`, `duracion: TIME`, `nOn, nOff: INT`, `error: BOOL`, `lamparaEnPaso0, lamparaEnPaso2: BOOL` (enm. 1, 5, 6) | `2` (3 pasos: `0..2`) | Variable (`tEspera`):<br>`0`: 200 ms · `1`: 7 s · `2`: `T_REPOSO = T#2500MS` | **9.70 s** | `9.712 s` / `9.740 s` / `9.780 s` | `9.7 s` | **Sí** (exacta) |
| **I1** | `PRG_Test_I1` | `FB_Semaforo` | `habilitado: BOOL` | `luzV: BOOL`<br>`luzA: BOOL`<br>`luzR: BOOL` | `tCrono: TON`, `duracion: TIME`, `nOn, nOff: INT`, `error: BOOL`, `otraLuzPaso0, otraLuzPaso7: BOOL` (enm. 1, 6, 8) | `8` (9 pasos: `0..8`) | Variable (`tEspera`):<br>`0,1,8`: 200 ms · `2,5`: 20 s · `3,6`: 4 s · `4`: 15 s · `7`: 7 s | **70.60 s** | `70.640 s` / `70.720 s` / `70.900 s` | `70.6 s` | **Sí** (exacta; véase nota 1.2 sobre la cota gruesa de ~90 s) |
| **I2** | `PRG_Test_I2` | `FB_Llenado` | `nivelAlto: BOOL`<br>`nivelBajo: BOOL`<br>`btnInicio: BOOL`<br>`btnParo: BOOL` | `vLlenado: BOOL`<br>`motorMezcla: BOOL`<br>`vDescarga: BOOL` | — | `11` (12 pasos: `0..11`) | Variable (`tEspera`):<br>`0,1,5,6,7,8,10,11`: 200 ms · `2,4`: 1 s · `3`: 58.5 s · `9`: 500 ms | **62.60 s** | `62.648 s` / `62.720 s` / `62.980 s` | `62.6 s` | **Sí** (exacta; véase nota 1.2 sobre la cota gruesa de ~90 s) |
| **I3** | `PRG_Test_I3` | `FB_Alarmas` | `alm1, alm2, alm3: BOOL`<br>`ack1, ack2, ack3: BOOL` | `sirena: BOOL`<br>`codigoAlm: INT` | — | `9` (10 pasos: `0..9`) | Fijo: `T#150MS` ($\times 10$) | **1.50 s** | `1.556 s` / `1.590 s` / `1.780 s` | `1.5 s` | **Sí** (exacta; incluye paso 2 de ACK con causa activa, enm. 12) |
| **I4** | `PRG_Test_I4` | `FB_EstrellaTriangulo` | `btnMarcha: BOOL`<br>`btnParo: BOOL` | `kM: BOOL`<br>`kY: BOOL`<br>`kD: BOOL` | `interlock: BOOL` (enclavada), `tCrono: TON`, `duracionMuerto: TIME`, `muertoOK: BOOL` (`>= T#90MS`, enm. 2, 4, 5) | `5` (6 pasos: `0..5`) | Variable (`tEspera`):<br>`0,4,5`: 200 ms · `1`: 7.8 s · `2`: 500 ms · `3`: 300 ms | **9.20 s** | `9.224 s` / `9.260 s` / `9.380 s` | `9.2 s` | **Sí** (exacta) |
| **I5** | `PRG_Test_I5` | `FB_Clasificadora` | `sensorPresencia: BOOL`<br>`sensorAltura: BOOL` | `banda: BOOL`<br>`piston: BOOL`<br>`nAltas: INT`<br>`nBajas: INT` | — | `6` (7 pasos: `0..6`) | Variable (`tEspera`):<br>`0,2,3`: 200 ms · `1`: 300 ms · `4`: 1.5 s · `5,6`: 800 ms | **4.00 s** | `4.024 s` / `4.060 s` / `4.180 s` | `4.0 s` | **Sí** (exacta; ventanas alineadas con paso 3, enm. 11) |
| **I6** | `PRG_Test_I6` | `FB_Temperatura` | `rawTemp: INT` | `tempC: REAL`<br>`enfriador: BOOL`<br>`almSensor: BOOL` | `compTemp: BOOL` (omite comparar `tempC` fuera de `0..27648`) | `7` (8 pasos: `0..7`) | Fijo: `T#100MS` ($\times 8$) | **0.80 s** | `0.828 s` / `0.950 s` / `0.940 s` | `0.8 s` | **Sí** (exacta; paso 3 fuera de rango con enfriador ON, enm. 13) |

### 1.2 Revisión de la heurística de duraciones (`ENMIENDAS_HARNESSES.md`) y medición de B3

1. **Medición de `PRG_Test_B3` (antes sin dato):**
   - La suma de los `tEspera` de los 7 pasos (`0..6`) es $5 \times 0.2\text{ s} + 1 \times 0.5\text{ s} + 1 \times 0.2\text{ s} = 1.70\text{ s}$.
   - Además, el temporizador `tPaso` se mantiene retenido (`IN := NOT pulsoReset AND NOT generando`) durante los pasos 4 y 5 mientras el generador determinista de flancos (`T_PULSO := T#20MS`) emite los pulsos:
     - En el **paso 4** (`FLANCOS_LOTE_A := 10`), `sensorPieza` parte de `FALSE` y realiza 19 conmutaciones de $20\text{ ms}$ ($10$ subidas y $9$ bajadas, terminando en el 10.º flanco ascendente): $19 \times 20\text{ ms} = 0.380\text{ s}$ más 1 scan por reinicio (`resetPulso`).
     - En el **paso 5** (`FLANCOS_LOTE_B := 1`), `sensorPieza` parte de `TRUE` (estado en que terminó el paso 4) y realiza 2 conmutaciones (`TRUE → FALSE` y `FALSE → TRUE`): $2 \times 20\text{ ms} = 0.040\text{ s}$ más 1 scan por reinicio.
   - **Duración nominal teórica en `.st`:** $1.70 + 0.38 + 0.04 = \mathbf{2.12\text{ s}}$.
   - **Duración real medida en el simulador de ciclo de scan (`validar_harness_B3.py`):**
     - Ciclo de `4 ms`: **2.216 s** (554 scans)
     - Ciclo de `10 ms`: **2.360 s** (236 scans)
     - Ciclo de `20 ms`: **2.720 s** (136 scans)
2. **Comprobación de la heurística «estimación > duración real $\Rightarrow$ falta un paso»:**
   - En los **12 harnesses**, la duración nominal obtenida sumando los `tEspera` del archivo `.st` coincide **exactamente** (al milisegundo, descontando el ciclo de scan de `pulsoReset := TRUE` entre pasos) con la duración medida en `validar_harness_*.py`.
   - En `I1` ($70.6\text{ s}$) e `I2` ($62.6\text{ s}$), la tabla preliminar al final de `ENMIENDAS_HARNESSES.md` mencionaba una cota gruesa de `~90 s`, pero **no falta ningún paso**:
     - En **I1**, para probar el reinicio en verde tras deshabilitar (Enmienda 8), el segundo ciclo avanza por verde ($20\text{ s}$, paso 5) y amarillo ($4\text{ s}$, paso 6) hasta entrar en rojo, y en ese instante deshabilita el semáforo (paso 7, $7\text{ s}$), sin necesidad de agotar los $15\text{ s}$ de rojo ($39 + 24 + 7 + 0.6 = 70.6\text{ s}$).
     - En **I2**, para probar el paro durante la mezcla (Enmienda 10), el segundo ciclo entra en mezcla en el paso 9, espera solo $500\text{ ms}$ para confirmar `motorMezcla = TRUE`, y aplica `btnParo` en el paso 10, sin esperar otros $60\text{ s}$ ($61.1 + 1.5 = 62.6\text{ s}$).
   - **Conclusión de la revisión estática de los 12 `.st`:** Ninguno de los 12 archivos `PRG_Test_*.st` presenta defectos ni requiere una Enmienda 14 antes de pasar a CODESYS.

---

## 2. Mapa de compatibilidad estática (`data/processed/` → harness)

Se analizaron de forma estática los **144 archivos `.st`** extraídos del piloto en `llm-plc-st-eval/data/processed/` (`2 modelos × 12 tareas × 2 estrategias × 3 corridas`), verificando para cada uno:
1. Presencia de cabecera de unidad de programa (`FUNCTION_BLOCK`, `PROGRAM`, `FUNCTION`) y nombre del identificador.
2. Presencia y validez de los bloques de declaración de interfaz (`VAR_INPUT ... END_VAR` y `VAR_OUTPUT ... END_VAR`).
3. Coincidencia exacta de nombres y tipos de datos IEC 61131-3 de todas las entradas y salidas utilizadas por el harness correspondiente.

### 2.1 Resumen global y desglose por modelo y estrategia

| Categoría | Total (de 144) | % | `claude-sonnet-4-6` `zero_shot` (36) | `claude-sonnet-4-6` `few_shot` (36) | `gpt-4o` `zero_shot` (36) | `gpt-4o` `few_shot` (36) |
|---|---:|---:|---:|---:|---:|---:|
| **Compatible** | **131** | **91.0 %** | 34 | 36 | 25 | 36 |
| **Incompatible** | **11** | **7.6 %** | 0 | 0 | 11 | 0 |
| **Sin FB extraíble** | **2** | **1.4 %** | 2 | 0 | 0 | 0 |
| **Total** | **144** | **100.0 %** | **36** | **36** | **36** | **36** |

> [!IMPORTANT]
> **Hallazgo clave sobre el efecto de `few_shot` en la interfaz:**  
> En la condición **`few_shot`**, el **100 % de las respuestas (72/72)** de ambos modelos producen una interfaz **100 % compatible** con el harness (`FUNCTION_BLOCK` con el nombre exacto y bloques `VAR_INPUT` / `VAR_OUTPUT` completos). La totalidad de las 11 interfaces incompatibles y de los 2 archivos sin FB extraíble en `data/processed/` ocurren exclusivamente en **`zero_shot`**.

### 2.2 Tabla por tarea (12 respuestas por tarea: 6 de Claude + 6 de GPT-4o)

| Tarea | FB esperado | Compatibles | Incompatibles | Sin FB extraíble | Detalle de las respuestas no compatibles |
|---|---|---:|---:|---:|---|
| **B1** | `FB_Motor` | **12** | 0 | 0 | Todas compatibles (`12/12`). |
| **B2** | `FB_Valvula` | **11** | 1 | 0 | `gpt-4o/B2/zero_shot/ejec_1`: declara `nivelAlto` y `valvula` en `VAR` local en vez de `VAR_INPUT`/`VAR_OUTPUT`. |
| **B3** | `FB_Contador` | **12** | 0 | 0 | Todas compatibles en interfaz (`12/12`). *(Nota: `gpt-4o/B3/zero_shot/ejec_2` incluye un bloque `INIT..END_INIT` inválido en el cuerpo).* |
| **B4** | `FB_Giro` | **12** | 0 | 0 | Todas compatibles (`12/12`). |
| **B5** | `FB_Ventilador` | **9** | 3 | 0 | `gpt-4o/B5/zero_shot/ejec_1, 2, 3`: declaran `quemadorOn` y `ventilador` en `VAR` local. |
| **B6** | `FB_Baliza` | **11** | 1 | 0 | `gpt-4o/B6/zero_shot/ejec_1`: declara `alarma` y `lampara` en `VAR` local. |
| **I1** | `FB_Semaforo` | **10** | 2 | 0 | `gpt-4o/I1/zero_shot/ejec_1`: cierra interfaz con `END_VAR_INPUT` y `END_VAR_OUTPUT` (inexistentes en IEC 61131-3).<br>`gpt-4o/I1/zero_shot/ejec_3`: declara `habilitado, luzV, luzA, luzR` en `VAR` local. |
| **I2** | `FB_Llenado` | **9** | 3 | 0 | `gpt-4o/I2/zero_shot/ejec_1, 2, 3`: declaran las 4 entradas y 3 salidas en `VAR` local. |
| **I3** | `FB_Alarmas` | **12** | 0 | 0 | Todas compatibles (`12/12`). |
| **I4** | `FB_EstrellaTriangulo` | **12** | 0 | 0 | Todas compatibles (`12/12`). |
| **I5** | `FB_Clasificadora` | **12** | 0 | 0 | Todas compatibles (`12/12`). |
| **I6** | `FB_Temperatura` | **9** | 1 | 2 | `claude-sonnet-4-6/I6/zero_shot/ejec_1, 2`: **sin FB extraíble** en `data/processed/` (solo quedó el cuerpo).<br>`gpt-4o/I6/zero_shot/ejec_3`: cierra interfaz con `END_VAR_INPUT` y `END_VAR_OUTPUT`. |

### 2.3 Detalle de las 13 respuestas no compatibles y observaciones estructurales

1. **Subgrupo A — Variables de E/S declaradas como `VAR` locales (9 respuestas, todas de `gpt-4o` en `zero_shot`):**
   - Archivos: `B2/zero_shot/ejec_1`, `B5/zero_shot/ejec_1..3`, `B6/zero_shot/ejec_1`, `I1/zero_shot/ejec_3`, `I2/zero_shot/ejec_1..3`.
   - **Qué difiere:** El modelo respetó el nombre del `FUNCTION_BLOCK` y los nombres y tipos de todas las variables, pero las agrupó dentro de un único bloque `VAR ... END_VAR` local separándolas solo con comentarios (`// Variables de entrada`, `// Variables de salida`).
   - **Implicación metodológica:** Un analizador puramente sintáctico como `blark` **acepta** estos archivos (excepto `B2/ejec_1` y `B5/ejec_3` que además omitieron `END_FUNCTION_BLOCK`), porque un `FUNCTION_BLOCK` con solo variables locales es sintácticamente legal en IEC 61131-3. Sin embargo, en CODESYS **fallarán al compilar junto con el harness** porque una variable local `VAR` no puede pasarse como argumento de entrada en `fb(entrada := ...)` ni leerse externamente si el compilador restringe el acceso o la llamada formal. Es un defecto real de interfaz inducido por la ausencia de plantilla en `zero_shot`.

2. **Subgrupo B — Palabras clave alucinadas `END_VAR_INPUT` y `END_VAR_OUTPUT` (2 respuestas de `gpt-4o` en `zero_shot`):**
   - Archivos: `gpt-4o/I1/zero_shot/ejec_1.st` y `gpt-4o/I6/zero_shot/ejec_3.st`.
   - **Qué difiere:** Los nombres del FB (`FB_Semaforo`, `FB_Temperatura`) y los nombres y tipos de todas las variables coinciden con el harness, pero los bloques se cierran con `END_VAR_INPUT` y `END_VAR_OUTPUT` en lugar de `END_VAR`. En IEC 61131-3 todos los bloques `VAR_*` cierran con `END_VAR`, por lo que el panel de declaración de interfaz no compila en CODESYS.

3. **Subgrupo C — Sin FB extraíble en `data/processed/` (2 respuestas de `claude-sonnet-4-6` en `zero_shot`):**
   - Archivos: `claude-sonnet-4-6/I6/zero_shot/ejec_1.st` y `claude-sonnet-4-6/I6/zero_shot/ejec_2.st`.
   - **Qué ocurre:** En `data/processed/`, ambos archivos comienzan directamente en `(* ── Cuerpo del FUNCTION_BLOCK ── *)` / `IF rawTemp < RAW_MIN ...`, sin cabecera `FUNCTION_BLOCK` ni bloques `VAR..END_VAR`.
   - **Causa raíz verificada en `data/raw/`:** Al inspeccionar en modo lectura `data/raw/claude-sonnet-4-6/I6/zero_shot/ejec_1.st` y `ejec_2.st`, se comprobó que Claude dividió su respuesta en **dos bloques de código markdown separados** (` ```pascal ... ``` `): el primer bloque (~785 caracteres) contiene `FUNCTION_BLOCK FB_Temperatura` con `VAR_INPUT`, `VAR_OUTPUT` y `VAR CONSTANT` (cuya interfaz coincide al 100 % con el harness), y el segundo bloque (~1240 caracteres) contiene el cuerpo ejecutable (imitando los dos paneles separados del editor de CODESYS). Como `extraer_codigo.py` aplica `max(bloques, key=len)` cuando encuentra más de un bloque markdown, descartó el bloque de declaración por ser más corto que el cuerpo. Conforme a la Regla 2 y al Paso 2, **no se modificó nada** y se registran como `sin FB extraíble` en `resultados_harness.csv`, dejando documentada la causa para decisión de Luis y la asesora.

4. **Observación sobre las 17 respuestas que omiten `END_FUNCTION_BLOCK`:**
   - De las 17 respuestas del piloto con `cierra_pou = False` (14 de `claude-sonnet-4-6` `zero_shot` y 3 de `gpt-4o` `zero_shot`), se verificó que **ninguna está truncada a mitad de código**: todas cierran su última sentencia (`END_IF;`, `END_CASE;` o asignación final) y simplemente omiten la línea `END_FUNCTION_BLOCK` (convención nativa del editor de CODESYS).
   - Como en CODESYS la declaración va al panel superior y la implementación al inferior **sin** `END_FUNCTION_BLOCK` (y `compilar_lote.py` recorta `END_FUNCTION_BLOCK` cuando existe), las **13 respuestas de este grupo que tienen interfaz compatible** pueden importarse y compilarse directamente en CODESYS sin penalización artificial por parte del editor.

---

## 3. Implementaciones de referencia (prueba positiva y negativa de los harnesses)

### 3.1 Qué existe hoy en el repositorio

1. **En Python (`llm-plc-st-eval/codesys/validar_harness_B1.py` … `validar_harness_I6.py`):**
   - Existen las **12 implementaciones correctas** (13 contando las dos fases iniciales válidas de `B6`) y **53 implementaciones defectuosas sintéticas** (con cada defecto aislado para verificar un paso concreto de `resultado[]` o la bandera de interlock), pero están programadas como clases en **Python**, no en Structured Text (`.st`).
2. **En Structured Text (`.st` o embebido en scripts):**
   - **FBs correctos en ST para `B1..B6, I1..I6`:** **No existe ninguno** como referencia independiente en el repositorio. *(En `src/generar_prompts.py` solo aparecen los ejemplos `FB_Pasillo` y `FB_Lubricacion` del preámbulo few-shot y `CODIGO_C4` `FB_D` que corresponde a la tarea `I7`).*
   - **FBs defectuosos en ST:** Solo existen **3 bloques defectuosos compuestos** dentro de `src/generar_prompts.py` (usados como enunciado de las tareas de diagnóstico `C1`, `C5` y `C6`):
     - `CODIGO_C1` (`FB_Semaforo`, líneas 59–94 de `generar_prompts.py`, aplicable a **I1**): combina 4 errores a la vez (`IF NOT habilitado` invertido, `TON` sin reinicio, estado 3 inalcanzable, `parp` fijo).
     - `CODIGO_C5` (`FB_EstrellaTriangulo`, líneas 131–169 de `generar_prompts.py`, aplicable a **I4**): combina 4 errores a la vez (solapamiento `kY AND kD`, sin tiempo muerto, `t1` sin rearme en paro, `btnParo` no apaga `kM`).
     - `CODIGO_C6` (`FB_Temperatura`, líneas 171–192 de `generar_prompts.py`, aplicable a **I6**): combina 4 errores a la vez (división entera `rawTemp / 27648`, umbral invertido sin histéresis, omisión de `rawTemp < 0`, alarma enclavada y sin apagar `enfriador`).
   - Para las otras 9 tareas (**B1, B2, B3, B4, B5, B6, I2, I3, I5**) no hay ningún FB defectuoso en ST en el repositorio, y para **I1, I4, I6** los bloques `CODIGO_C1/C5/C6` acumulan todos los fallos juntos (por lo que sirven como prueba negativa global, pero no aíslan un paso a la vez como exige el criterio de éxito).

### 3.2 Lista de implementaciones de referencia en ST que faltan (para escribir por Luis)

Conforme a la **Regla 1** (*«No redactes FBs de solución. Si hace falta una implementación de referencia correcta, indícalo y la escribe Luis»*), a continuación se listan los **12 FBs correctos** (13 variantes incluyendo ambos arranques de B6) y los **53 FBs defectuosos aislados** (equivalentes 1:1 a las clases de `validar_harness_*.py`) que hacen falta en ST para verificar los 12 harnesses en CODESYS real:

| Tarea | POU (`FUNCTION_BLOCK`) | Variante a implementar en ST por Luis | Tipo de prueba | Propósito / Qué verifica en el harness | `veredicto` esperado | Paso(s) con fallo (`resultado[i] = 2`) |
|---|---|---|---|---|---:|---|
| **B1** | `FB_Motor` | **1. Referencia correcta** | Positiva | Enclavamiento con marcha; paro y E-stop apagan; memoria de bloqueo tras E-stop si marcha sigue en `TRUE`. | `1` | Ninguno (`[1,1,1,1,1,1,1]`) |
| B1 | `FB_Motor` | 2. Defecto: sin enclavamiento | Negativa | Salida puramente combinacional (`btnMarcha AND NOT btnParo AND NOT btnEmerg`); cae al soltar marcha. | `2` | Paso **2** (y **6** no, pero en paso 2 cae: `[1,1,2,1,1,1,2]`) |
| B1 | `FB_Motor` | 3. Defecto: rearranca tras E-stop | Negativa | Sin memoria de bloqueo tras emergencia; al liberar `btnEmerg` con `btnMarcha = TRUE` vuelve a arrancar. | `2` | Paso **6** (`[1,1,1,1,1,1,2]`) |
| B1 | `FB_Motor` | 4. Defecto: E-stop no domina | Negativa | Evalúa `IF btnMarcha` antes que `btnEmerg`, por lo que no apaga en emergencia con marcha pulsada. | `2` | Pasos **5, 6** (`[1,1,1,1,1,2,2]`) |
| B1 | `FB_Motor` | 5. Defecto: paro como NC | Negativa | Interpreta `btnParo` como normalmente cerrado (`NOT btnParo` apaga). | `2` | Pasos **1, 2, 4** (`[1,2,2,1,2,1,1]`) |
| **B2** | `FB_Valvula` | **1. Referencia correcta** | Positiva | `TON` con `PT := T#5S` alimentado por `nivelAlto`; `valvula := ton.Q`. | `1` | Ninguno (`[1,1,1,1,1,1]`) |
| B2 | `FB_Valvula` | 2. Defecto: `TOF` en vez de `TON` | Negativa | Abre de inmediato con `nivelAlto` y tarda 5 s en cerrar. | `2` | Pasos **1, 3, 5** (`[1,2,1,2,1,2]`) |
| B2 | `FB_Valvula` | 3. Defecto: preset corto (`T#2S`) | Negativa | Usa `T#2S` en lugar de `T#5S`; a los 3 s (paso 1) ya está abierta. | `2` | Paso **1** (`[1,2,1,1,1,1]`) |
| B2 | `FB_Valvula` | 4. Defecto: sin cierre inmediato | Negativa | Enclava `valvula := TRUE` al vencer el `TON` y no la apaga al caer `nivelAlto`. | `2` | Pasos **3, 5** (`[1,1,1,2,1,2]`) |
| B2 | `FB_Valvula` | 5. Defecto: un solo disparo (sin rearme) | Negativa | Bloquea el segundo ciclo tras haber abierto una vez. | `2` | Paso **4** (`[1,1,1,1,2,1]`) |
| **B3** | `FB_Contador` | **1. Referencia correcta** | Positiva | Incrementa `cuenta` solo en flanco ascendente de `sensorPieza`; `loteListo := (cuenta >= 12)`; `btnReset` pone ambos a 0/`FALSE`. | `1` | Ninguno (`[1,1,1,1,1,1,1]`) |
| B3 | `FB_Contador` | 2. Defecto: cuenta por nivel | Negativa | Incrementa `cuenta` en cada scan mientras `sensorPieza = TRUE`. | `2` | Pasos **1, 2, 3, 4, 5** (`[1,2,2,2,2,2,1]`) |
| B3 | `FB_Contador` | 3. Defecto: preset 10 en vez de 12 | Negativa | Activa `loteListo` con `cuenta >= 10` (se descubre en el paso 4 con 11 piezas). | `2` | Paso **4** (`[1,1,1,1,2,1,1]`) |
| B3 | `FB_Contador` | 4. Defecto: reset incompleto | Negativa | `btnReset` pone `cuenta := 0` pero olvida apagar `loteListo := FALSE`. | `2` | Paso **6** (`[1,1,1,1,1,1,2]`) |
| **B4** | `FB_Giro` | **1. Referencia correcta** | Positiva | Enclavamiento con interlock cruzado sobre el estado actual (`NOT rev` / `NOT fwd`) y paso obligatorio por `btnParo`. | `1` | Ninguno (`[1,1,1,1,1,1,1,1,1,1]`, `violacionInterlock = FALSE`) |
| B4 | `FB_Giro` | 2. Defecto: sin enclavamiento | Negativa | Las salidas caen al soltar `btnFwd` / `btnRev`. | `2` | Pasos **2, 3, 6** (`[1,1,2,2,1,1,2,1,1,1]`, `violacionInterlock = FALSE`) |
| B4 | `FB_Giro` | 3. Defecto: inversión directa sin paro | Negativa | Permite cambiar de `fwd` a `rev` directamente sin pulsar `btnParo`. | `2` | Pasos **3, 6** (`[1,1,1,2,1,1,2,1,1,1]`, `violacionInterlock = FALSE`) |
| B4 | `FB_Giro` | 4. Defecto: sin interlock cruzado | Negativa | Permite activar `fwd` y `rev` a la vez. | `2` | Pasos **3, 6, 8** + **`violacionInterlock = TRUE`** (`[1,1,1,2,1,1,2,1,2,1]`) |
| B4 | `FB_Giro` | 5. Defecto: carrera de interlock | Negativa | Evalúa el interlock contra el valor de la otra salida en el scan *anterior*; falla al pulsar ambas desde reposo (paso 8). | `2` | Paso **8** + **`violacionInterlock = TRUE`** (`[1,1,1,1,1,1,1,1,2,1]`) |
| **B5** | `FB_Ventilador` | **1. Referencia correcta** | Positiva | `TOF` con `PT := T#30S` alimentado por `quemadorOn`; rearma a 30 s completos si se reenciende durante el post-enfriamiento. | `1` | Ninguno (`[1,1,1,1,1,1,1,1,1]`) |
| B5 | `FB_Ventilador` | 2. Defecto: sin post-enfriamiento | Negativa | `ventilador := quemadorOn`. | `2` | Pasos **2, 5, 7** (`[1,1,2,1,1,2,1,2,1]`) |
| B5 | `FB_Ventilador` | 3. Defecto: `T#10S` en vez de `T#30S` | Negativa | Se apaga antes de los 29 s. | `2` | Pasos **2, 5, 7** (`[1,1,2,1,1,2,1,2,1]`) |
| B5 | `FB_Ventilador` | 4. Defecto: `T#60S` en vez de `T#30S` | Negativa | Sigue encendido a los 30.2 s. | `2` | Pasos **3, 8** (`[1,1,1,2,1,1,1,1,2]`) |
| B5 | `FB_Ventilador` | 5. Defecto: `TON` en vez de `TOF` | Negativa | Retardo a la conexión en lugar de desconexión. | `2` | Pasos **1, 2, 4, 5, 6, 7** (`[1,2,2,1,2,2,2,2,1]`) |
| B5 | `FB_Ventilador` | 6. Defecto: sin rearme del temporizador | Negativa | Acumula el tiempo apagado sin reiniciar cuando `quemadorOn` vuelve a `TRUE`. | `2` | Pasos **5, 7** (`[1,1,1,1,1,2,1,2,1]`) |
| B5 | `FB_Ventilador` | 7. Defecto: rearme corto (`15 s`) | Negativa | Primer ciclo dura 30 s, pero tras reactivar dura 15 s (Enmienda 7). | `2` | Paso **7** (`[1,1,1,1,1,1,1,2,1]`) |
| **B6** | `FB_Baliza` | **1a/1b. Referencia correcta (inicio OFF o inicio ON)** | Positiva | Oscilador 1 s ON / 1 s OFF con `alarma = TRUE`; apagado con `alarma = FALSE`. | `1` | Ninguno (`[1,1,1]`, `nOn=3..4, nOff=3`) |
| B6 | `FB_Baliza` | 2. Defecto: `1.5 s / 1.5 s` | Negativa | Falso negativo del muestreo a 1.1 s (Enmienda 1). | `2` | Paso **1** (`[1,2,1]`) |
| B6 | `FB_Baliza` | 3. Defecto: `0.5 s / 0.5 s` | Negativa | Parpadeo rápido fuera de tolerancia (`850..1150 ms`). | `2` | Paso **1** (`[1,2,1]`) |
| B6 | `FB_Baliza` | 4. Defecto: asimétrico `1 s ON / 2 s OFF` | Negativa | Intervalo OFF fuera de tolerancia. | `2` | Paso **1** (`[1,2,1]`) |
| B6 | `FB_Baliza` | 5. Defecto: fija (`lampara := alarma`) | Negativa | No oscila (`nOn = 0, nOff = 0`). | `2` | Paso **1** (`[1,2,1]`) |
| B6 | `FB_Baliza` | 6. Defecto: sigue parpadeando sin alarma | Negativa | Detectado por `lamparaEnPaso2` en ventana de 2.5 s (Enmienda 6). | `2` | Paso **2** (`[1,1,2]`) |
| **I1** | `FB_Semaforo` | **1. Referencia correcta** | Positiva | Verde 20 s → Amarillo 4 s → Rojo 15 s cíclico; deshabilitado parpadea `luzA` 1 s / 1 s con `luzV=luzR=FALSE`; rehabilitado reinicia en verde. | `1` | Ninguno (`[1,1,1,1,1,1,1,1,1]`) |
| I1 | `FB_Semaforo` | 2. Defecto: tiempos verde/rojo cambiados (15 s / 20 s) | Negativa | Falla en la transición de verde a amarillo. | `2` | Pasos **2, 5** (`[1,1,2,1,1,2,1,1,1]`) |
| I1 | `FB_Semaforo` | 3. Defecto: intermitente de `1.5 s` | Negativa | Detectado por la medida de intervalos en paso 7. | `2` | Paso **7** (`[1,1,1,1,1,1,1,2,1]`) |
| I1 | `FB_Semaforo` | 4. Defecto: sin intermitente (todo apagado) | Negativa | No genera flancos en `luzA` durante el paso 7. | `2` | Paso **7** (`[1,1,1,1,1,1,1,2,1]`) |
| I1 | `FB_Semaforo` | 5a/5b. Defecto: alterna amarillo y rojo (ambas fases) | Negativa | Detectado por `otraLuzPaso0` / `otraLuzPaso7` (Enmienda 8). | `2` | Pasos **0 y 7** (o **7** en fase inversa) |
| I1 | `FB_Semaforo` | 6. Defecto: no reinicia en verde al rehabilitar | Negativa | Continúa en rojo en el paso 8 (Enmienda 8). *(Además existe `CODIGO_C1` en `generar_prompts.py` como prueba negativa global).* | `2` | Paso **8** (`[1,1,1,1,1,1,1,1,2]`) |
| **I2** | `FB_Llenado` | **1. Referencia correcta** | Positiva | Reposo → llenado (`nivelAlto`) → mezcla (`T#60S`) → descarga (`nivelBajo`) → reposo; `btnParo` apaga todo y vuelve a reposo desde cualquier fase. | `1` | Ninguno (`[1,1,1,1,1,1,1,1,1,1,1,1]`) |
| I2 | `FB_Llenado` | 2. Defecto: mezcla corta (`T#30S`) | Negativa | A los 59.5 s (paso 3) ya pasó a descarga. | `2` | Paso **3** (`[1,1,1,2,1,1,1,1,1,1,1,1]`) |
| I2 | `FB_Llenado` | 3. Defecto: se salta la mezcla | Negativa | De llenado pasa directo a descarga. | `2` | Pasos **2, 3, 9** (`[1,1,2,2,1,1,1,1,1,2,1,1]`) |
| I2 | `FB_Llenado` | 4. Defecto: paro no apaga salidas | Negativa | Vuelve al estado 0 pero deja activas las válvulas/motor. | `2` | Pasos **7, 10** (`[1,1,1,1,1,1,1,2,1,1,2,1]`) |
| I2 | `FB_Llenado` | 5. Defecto: paro no actúa en mezcla | Negativa | `btnParo` funciona en llenado pero se ignora en mezcla (Enmienda 10). | `2` | Pasos **10, 11** (`[1,1,1,1,1,1,1,1,1,1,2,2]`) |
| I2 | `FB_Llenado` | 6. Defecto: no rearranca tras paro | Negativa | Queda bloqueado tras el primer `btnParo`. | `2` | Pasos **8, 9** (`[1,1,1,1,1,1,1,1,2,2,1,1]`) |
| **I3** | `FB_Alarmas` | **1. Referencia correcta** | Positiva | Retención individual; ACK solo borra si `NOT almN`; prioridad 1 > 2 > 3 en `codigoAlm`; `sirena` si hay alguna activa o retenida. | `1` | Ninguno (`[1,1,1,1,1,1,1,1,1,1]`) |
| I3 | `FB_Alarmas` | 2. Defecto: ACK borra con causa presente | Negativa | `ack3` borra `alm3` en el paso 2 aunque `alm3 = TRUE` (Enmienda 12). | `2` | Pasos **2, 3** (`[1,1,2,2,1,1,1,1,1,1]`) |
| I3 | `FB_Alarmas` | 3. Defecto: sin retención de alarma | Negativa | La alarma cae apenas desaparece `alm3` sin esperar `ack3`. | `2` | Paso **3** (`[1,1,1,2,1,1,1,1,1,1]`) |
| I3 | `FB_Alarmas` | 4. Defecto: prioridad invertida (3 > 2 > 1) | Negativa | Reporta la de número mayor en lugar de la de mayor prioridad. | `2` | Pasos **5, 6, 7** (`[1,1,1,1,1,2,2,2,1,1]`) |
| I3 | `FB_Alarmas` | 5. Defecto: sirena solo sigue a la causa | Negativa | Apaga `sirena` al caer `alm3` aunque el código siga retenido. | `2` | Paso **3** (`[1,1,1,2,1,1,1,1,1,1]`) |
| **I4** | `FB_EstrellaTriangulo` | **1. Referencia correcta** | Positiva | `kM + kY` 8 s → apaga `kY`, espera 100 ms (`duracionMuerto >= 90 ms`) → activa `kD`; `btnParo` apaga todo y rearma. | `1` | Ninguno (`[1,1,1,1,1,1]`, `interlock = FALSE`, `duracionMuerto = 100..110 ms`) |
| I4 | `FB_EstrellaTriangulo` | 2. Defecto: solapamiento `kY AND kD` | Negativa | Activa `kD` antes de apagar `kY` (Enmienda 2 y 4). | `2` | Paso **3** + **`interlock = TRUE`** (`[1,1,1,2,1,1]`) |
| I4 | `FB_EstrellaTriangulo` | 3. Defecto: tiempo muerto 0 ms | Negativa | `kY` cae y `kD` sube en el mismo scan (`interlock = FALSE`, pero `duracionMuerto = 0 ms`, Enmienda 5). | `2` | Paso **3** (`[1,1,1,2,1,1]`, `interlock = FALSE`) |
| I4 | `FB_EstrellaTriangulo` | 4. Defecto: temporizador sin rearme en paro | Negativa | Al rearrancar en el paso 5 salta a triángulo de inmediato. | `2` | Paso **5** (`[1,1,1,1,1,2]`) |
| I4 | `FB_EstrellaTriangulo` | 5. Defecto: el paro no apaga `kM` | Negativa | Deja `kM = TRUE` en el paso 4. *(Además existe `CODIGO_C5` en `generar_prompts.py` con los 4 defectos juntos).* | `2` | Paso **4** (`[1,1,1,1,2,1]`) |
| **I5** | `FB_Clasificadora` | **1. Referencia correcta** | Positiva | `banda := TRUE`; cuenta altas/bajas por flanco de `sensorPresencia`; desvía altas con pulso de 1 s tras retardo de 2 s. | `1` | Ninguno (`[1,1,1,1,1,1,1]`) |
| I5 | `FB_Clasificadora` | 2. Defecto: cuenta por nivel | Negativa | Incrementa `nBajas` en cada scan durante el paso 1 (presencia sostenida). | `2` | Pasos **1..6** (`[1,2,2,2,2,2,2]`) |
| I5 | `FB_Clasificadora` | 3. Defecto: pistón sin retardo (0 s) | Negativa | Activa `piston` al detectar la pieza alta en el paso 3. | `2` | Pasos **3, 5** (`[1,1,1,2,1,2,1]`) |
| I5 | `FB_Clasificadora` | 4. Defecto: retardo corto (`1.5 s`) | Negativa | El pistón ya está activo en $t = 2.4\text{ s}$ (paso 4) y ya cayó en $t = 3.2\text{ s}$ (paso 5). | `2` | Pasos **4, 5** (`[1,1,1,1,2,2,1]`) |
| I5 | `FB_Clasificadora` | 5. Defecto: pulso largo (`2 s`) | Negativa | El pistón sigue encendido en $t = 4.0\text{ s}$ (paso 6). | `2` | Paso **6** (`[1,1,1,1,1,1,2]`) |
| I5 | `FB_Clasificadora` | 6. Defecto: desvía también las bajas | Negativa | El desvío de la pieza baja del paso 1 aparece activo en el paso 4. | `2` | Paso **4** (`[1,1,1,1,2,1,1]`) |
| **I6** | `FB_Temperatura` | **1. Referencia correcta** | Positiva | Escalado `REAL` `0..27648 -> 0.0..100.0`; histéresis `>= 80.0` ON / `<= 75.0` OFF; fuera de rango `almSensor := TRUE` y `enfriador := FALSE`. | `1` | Ninguno (`[1,1,1,1,1,1,1,1]`) |
| I6 | `FB_Temperatura` | 2. Defecto: alarma no apaga enfriador | Negativa | En paso 3 (`rawTemp = 27649` con enfriador ON) activa alarma pero deja `enfriador = TRUE` (Enmienda 13). | `2` | Paso **3** (`[1,1,1,2,1,1,1,1]`) |
| I6 | `FB_Temperatura` | 3. Defecto: sin histéresis (umbral único en 80) | Negativa | Se apaga al bajar a 77 °C en el paso 2. | `2` | Paso **2** (`[1,1,2,1,1,1,1,1]`) |
| I6 | `FB_Temperatura` | 4. Defecto: división entera (`rawTemp / 27648`) | Negativa | `tempC` vale `0.0` en todo el rango. | `2` | Pasos **0, 1, 2, 4, 5** (`[2,2,2,1,2,2,1,1]`) |
| I6 | `FB_Temperatura` | 5. Defecto: omite límite inferior (`rawTemp < 0`) | Negativa | No activa `almSensor` con `rawTemp = -1` en el paso 6. | `2` | Paso **6** (`[1,1,1,1,1,1,2,1]`) |
| I6 | `FB_Temperatura` | 6. Defecto: alarma enclavada | Negativa | No limpia `almSensor` al regresar al rango en el paso 4. *(Además existe `CODIGO_C6` en `generar_prompts.py` con los 4 defectos juntos).* | `2` | Pasos **4, 5, 7** (`[1,1,1,1,2,2,1,2]`) |

---

## 4. Estado de `compilar_lote.py`, evaluación del Scripting Engine y `diff` propuesto

### 4.1 Qué automatiza hoy `compilar_lote.py` y qué no

**Lo que ya hace hoy (`codesys/compilar_lote.py`):**
- Recorre una carpeta de archivos `.st` extrayendo `(modelo, tarea, estrategia, ejecucion)` de la ruta.
- Parte cada archivo con `partir_codigo(texto)` en `(declaracion, implementacion, nombre_pou)` cortando en el último `END_VAR` y eliminando `END_FUNCTION_BLOCK` / `END_PROGRAM` / `END_FUNCTION`.
- Estructura el bucle de creación de POU (`app.create_pou`), reemplazo de texto en los dos paneles (`textual_declaration.replace` y `textual_implementation.replace`), compilación y escritura de CSV en UTF-8 compatible con IronPython 2.7.

**Lo que NO hace hoy (y limitaciones técnicas detectadas):**
1. **`projects.create()` sin dispositivo ni aplicación:** En el ScriptEngine de CODESYS V3.5, `projects.create(ruta)` crea un archivo `.project` vacío sin `Device` (`CODESYS Control Win V3 x64`) ni `Application`, por lo que `proyecto.active_application` devuelve `None`. La forma más limpia y robusta en `--noUI` es abrir un **proyecto plantilla base** (`base_verificacion.project`, guardado una vez desde CODESYS con `CODESYS Control Win V3 x64` y `MainTask` cíclica en `T#10ms` o `T#4ms` llamando a `PLC_PRG`), o bien trabajar sobre una copia temporal de esa plantilla por respuesta.
2. **No importa el harness (`PRG_Test_<tarea>.st`):** Compila el FB en solitario. Al no incluir el harness en la compilación, no detecta fallos de enlace entre `PRG_Test_xx` y el FB (como las 9 respuestas que declaran entradas/salidas como `VAR` locales) ni permite ejecutar la simulación.
3. **No ejecuta la simulación ni lee `veredicto` y `resultado[]`:** No utiliza el módulo `online` (`online.create_online_application(app)`), no activa el modo simulación (`set_simulation_mode(True)`), no hace `login()` ni `start()`, ni monitorea `finalizado`, `veredicto` y `resultado[i]`.
4. **Doble lectura redundante en líneas 103–107 y ruta antigua:** En la línea 104 llama a `fh.read()` dos veces en la misma expresión y luego sobrescribe `texto` en las líneas 106–107; además apunta por defecto a `..\repositorio_piloto_limpio` en lugar de `..\data\processed`.

### 4.2 Evaluación de ampliación con el Scripting Engine de CODESYS

La API de **CODESYS Scripting Engine (IronPython)** soporta de forma nativa todo el ciclo requerido mediante `--runscript` y `--noUI`:
- **Proyecto plantilla + `MainTask`:** Para evitar depender de los `DeviceId` internos de la subversión exacta instalada (`3.5.22.30`), Luis guarda una sola vez un proyecto vacío llamado `codesys/plantilla_10ms.project` (y `codesys/plantilla_4ms.project`) con:
  - Dispositivo `CODESYS Control Win V3 x64` con **Online → Simulation** marcado.
  - `MainTask` configurada como `Cyclic` con `Interval := T#10ms` (o `T#4ms`) y llamando a `PLC_PRG`.
- **Importación de FB + Harness:** En cada iteración, el script copia la plantilla a `%TEMP%\tmp_eval.project`, lo abre con `projects.open()`, crea el `FUNCTION_BLOCK` de la respuesta evaluada y vuelca el contenido de `PRG_Test_<tarea>.st` dentro de `PLC_PRG` (reemplazando la cabecera `PROGRAM PRG_Test_xx` por `PROGRAM PLC_PRG` para que `MainTask` lo ejecute directamente sin reconfigurar la llamada de tarea).
- **Compilación y lectura de errores:** `app.build()` y consulta de mensajes de la categoría *Build* (`{97F48D64-A2A3-4856-B640-75C046E37EA9}`).
- **Simulación y lectura de variables (`online`):**
  - `online_app = online.create_online_application(app)`
  - `online_app.login(OnlineChangeOption.Never, True)`
  - `online_app.start()`
  - Espera con `system.delay(200)` hasta que `online_app.read_value("PLC_PRG.finalizado") == "TRUE"` o se alcance el *timeout* de seguridad de la tarea (`DURACION_MAX[tarea]`).
  - Lectura de `PLC_PRG.veredicto`, `PLC_PRG.resultado[0]` … `PLC_PRG.resultado[ULTIMO_PASO]` (y `violacionInterlock` / `interlock` / `duracionMuerto` cuando existan).
  - `online_app.stop()` y `online_app.logout()`.

### 4.3 Propuesta de cambios (`diff` sobre `codesys/compilar_lote.py`)

> [!WARNING]
> **Esperando confirmación (Paso 4):** Este `diff` **no se ha aplicado** todavía a `codesys/compilar_lote.py`. Confírmame si estás de acuerdo con el enfoque de proyecto plantilla (`plantilla_10ms.project`) para aplicarlo.

```diff
--- a/llm-plc-st-eval/codesys/compilar_lote.py
+++ b/llm-plc-st-eval/codesys/compilar_lote.py
@@ -1,42 +1,66 @@
 # -*- coding: utf-8 -*-
 """
-Compilacion por lotes en CODESYS — ScriptEngine (IronPython).
+Compilacion y simulacion por lotes en CODESYS — ScriptEngine (IronPython).
 
-Automatiza la ETAPA 1 de la verificacion: importa cada respuesta .st como POU,
-compila y registra el resultado en un CSV. Sustituye el trabajo manual de
-abrir, pegar y pulsar F11 cientos de veces.
+Automatiza las ETAPAS 1 y 2 de la verificacion: sobre una copia limpia de un
+proyecto plantilla (con CODESYS Control Win V3 x64, modo Simulacion activo y
+MainTask ciclica en T#10ms o T#4ms llamando a PLC_PRG), importa el FB de la
+respuesta y el harness PRG_Test_<tarea>.st, compila, ejecuta en simulacion,
+espera a finalizado = TRUE (con timeout por tarea) y lee veredicto y resultado[].
 
 EJECUCION (linea de comandos de Windows, CODESYS cerrado):
 
   "C:\\Program Files\\CODESYS 3.5.x.x\\CODESYS\\Common\\CODESYS.exe" ^
       --runscript="<ruta>\\compilar_lote.py" ^
-      --scriptargs:"<carpeta_codigo_limpio> <csv_salida>" ^
+      --scriptargs:"<carpeta_processed> <csv_salida> <ruta_plantilla.project> <ciclo_ms>" ^
       --noUI
 """
 
 import os
 import sys
 import csv
 import re
+import shutil
+import time
+from System import Guid
 
 # --- Parametros -------------------------------------------------------------
 args = (system.get_script_args() if hasattr(system, "get_script_args") else sys.argv[1:])  # [API]
-CARPETA = args[0] if len(args) > 0 else r"..\repositorio_piloto_limpio"
-SALIDA = args[1] if len(args) > 1 else r"..\resultados_compilacion.csv"
+DIR_SCRIPT = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else "."
+CARPETA = args[0] if len(args) > 0 else os.path.join(DIR_SCRIPT, r"..\data\processed")
+SALIDA = args[1] if len(args) > 1 else os.path.join(DIR_SCRIPT, r"..\data\codesys_piloto\resultados_lote.csv")
+PLANTILLA = args[2] if len(args) > 2 else os.path.join(DIR_SCRIPT, "plantilla_10ms.project")
+CICLO_MS = args[3] if len(args) > 3 else "10"
+
+BUILD_CATEGORY = Guid("{97F48D64-A2A3-4856-B640-75C046E37EA9}")  # [API] Categoria Build
 
 # Tipo de POU esperado por tarea (del banco de pruebas).
 POU_ESPERADO = {
     "B1": "FunctionBlock", "B2": "FunctionBlock", "B3": "FunctionBlock",
     "B4": "FunctionBlock", "B5": "FunctionBlock", "B6": "FunctionBlock",
     "B7": "Program",       "B8": "FunctionBlock",
     "I1": "FunctionBlock", "I2": "FunctionBlock", "I3": "FunctionBlock",
     "I4": "FunctionBlock", "I5": "FunctionBlock", "I6": "FunctionBlock",
     "I7": "FunctionBlock", "I8": "FunctionBlock",
 }
+
+# Ultimo indice de resultado[] y timeout maximo de simulacion (segundos) por tarea
+HARNESS_META = {
+    "B1": (6,  10.0), "B2": (5,  25.0), "B3": (6,  10.0),
+    "B4": (9,  10.0), "B5": (8,  90.0), "B6": (2,  20.0),
+    "I1": (8,  90.0), "I2": (11, 80.0), "I3": (9,  10.0),
+    "I4": (5,  20.0), "I5": (6,  12.0), "I6": (7,  10.0),
+}
@@ -102,60 +126,102 @@
 for i, (ruta, modelo, tarea, estrategia, ejec) in enumerate(archivos, 1):
-    with open(ruta, "r") as fh:
-        texto = fh.read().decode("utf-8", "ignore") if hasattr(fh.read(), "decode") else None
     # IronPython 2.7: lectura simple y decodificacion explicita
     with open(ruta, "rb") as fh:
         texto = fh.read().decode("utf-8", "ignore")
 
+    id_resp = "%s_%s_%s_ejec_%s" % (tarea, modelo, estrategia, ejec)
     fila = {
-        "archivo": ruta, "modelo": modelo, "tarea": tarea,
-        "estrategia": estrategia, "ejecucion": ejec,
-        "compila": 0, "n_errores": "", "n_advertencias": "",
-        "primer_error": "", "nota": "",
+        "id_respuesta": id_resp, "tarea": tarea, "modelo": modelo,
+        "estrategia": estrategia, "corrida": ejec,
+        "compila (S/N)": "N", "error_compilacion": "", "ciclo_ms": CICLO_MS,
+        "veredicto": "", "pasos_fallidos": "",
+        "fecha": time.strftime("%Y-%m-%d"), "observaciones": "",
     }
 
     partido = partir_codigo(texto)
+    ruta_harness = os.path.join(DIR_SCRIPT, "PRG_Test_%s.st" % tarea)
     if partido is None:
-        fila["nota"] = "sin cabecera de POU o sin END_VAR; no importable"
-        fila["primer_error"] = "estructura de POU ausente"
+        fila["observaciones"] = "sin cabecera de POU o sin END_VAR; no importable"
+        fila["error_compilacion"] = "estructura de POU ausente"
         filas.append(fila)
         continue
+    if not os.path.exists(ruta_harness):
+        fila["observaciones"] = "sin harness PRG_Test_%s.st" % tarea
+        filas.append(fila)
+        continue
 
     decl, impl, nombre = partido
+    with open(ruta_harness, "rb") as fh:
+        h_decl, h_impl, _ = partir_codigo(fh.read().decode("utf-8", "ignore"))
+    # Renombrar la cabecera del harness a PLC_PRG para que MainTask lo invoque
+    h_decl = re.sub(r"^\s*PROGRAM\s+\w+", "PROGRAM PLC_PRG", h_decl, count=1, flags=re.I | re.M)
     tipo = POU_ESPERADO.get(tarea, "FunctionBlock")
+    ultimo_paso, timeout_s = HARNESS_META.get(tarea, (0, 30.0))
 
     proyecto = None
+    online_app = None
+    tmp_proj = os.path.join(os.environ.get("TEMP", "."), "tmp_eval_%d.project" % i)
     try:
-        proyecto = projects.create(r"%s\tmp_%s.project" %
-                                   (os.environ.get("TEMP", "."), i))       # [API]
+        shutil.copyfile(PLANTILLA, tmp_proj)
+        proyecto = projects.open(tmp_proj)                                  # [API]
 
         app = proyecto.active_application                                   # [API]
         pou = app.create_pou(nombre, PouType.__getattribute__(PouType, tipo))  # [API]
         pou.textual_declaration.replace(decl)                               # [API]
         pou.textual_implementation.replace(impl)                            # [API]
 
-        proyecto.build()                                                    # [API]
+        plc_prg = app.find("PLC_PRG", False)[0]                             # [API]
+        plc_prg.textual_declaration.replace(h_decl)                         # [API]
+        plc_prg.textual_implementation.replace(h_impl)                      # [API]
+
+        app.build()                                                         # [API]
+        objs_msg = system.get_message_objects(BUILD_CATEGORY, Severity.Error)  # [API]
+        n_err = len(objs_msg)
 
-        n_err = system.get_message_count(Severity.Error)                    # [API]
-        n_adv = system.get_message_count(Severity.Warning)                  # [API]
-
-        fila["n_errores"] = n_err
-        fila["n_advertencias"] = n_adv
-        fila["compila"] = 1 if n_err == 0 else 0
+        fila["compila (S/N)"] = "S" if n_err == 0 else "N"
         if n_err > 0:
-            msgs = system.get_messages(Severity.Error)                      # [API]
-            fila["primer_error"] = (str(msgs[0]) if msgs else "")[:300]
+            fila["error_compilacion"] = objs_msg[0].text[:300]
+        else:
+            # Etapa 2: Simulacion funcional
+            online_app = online.create_online_application(app)              # [API]
+            online_app.login(OnlineChangeOption.Never, True)                # [API]
+            if online_app.application_state != ApplicationState.run:        # [API]
+                online_app.start()                                          # [API]
+
+            t0 = time.time()
+            terminado = False
+            while (time.time() - t0) < timeout_s:
+                system.delay(200)                                           # [API]
+                val_fin = online_app.read_value("PLC_PRG.finalizado")       # [API]
+                if str(val_fin).upper() == "TRUE":
+                    terminado = True
+                    break
+
+            if terminado:
+                fila["veredicto"] = str(online_app.read_value("PLC_PRG.veredicto"))
+                fallos = []
+                for p_idx in range(ultimo_paso + 1):
+                    r_p = str(online_app.read_value("PLC_PRG.resultado[%d]" % p_idx))
+                    if r_p != "1":
+                        fallos.append(str(p_idx))
+                fila["pasos_fallidos"] = ",".join(fallos)
+            else:
+                fila["veredicto"] = "0"
+                fila["observaciones"] = "timeout simulacion (>%.1fs)" % timeout_s
 
     except Exception as e:
-        fila["nota"] = "excepcion del script: %s" % str(e)[:200]
+        fila["observaciones"] = "excepcion del script: %s" % str(e)[:200]
     finally:
+        if online_app is not None:
+            try:
+                if online_app.is_logged_in:
+                    online_app.stop()
+                    online_app.logout()
+            except Exception:
+                pass
         if proyecto is not None:
             try:
                 proyecto.close()                                            # [API]
             except Exception:
                 pass
```

---

## 5. Hueco de cobertura en el banco de 30 tareas y opciones metodológicas

### 5.1 Estado de cobertura de las 30 tareas (`src/generar_prompts.py` y `src/config.yaml`)

El banco definitivo congelado el 2026-09-09 consta de **30 tareas** (`720` respuestas en el estudio definitivo: `30 tareas × 4 modelos × 2 estrategias × 3 corridas`). Su situación frente a la verificación automatizada con harnesses es la siguiente:

| Grupo de tareas | Tareas | N.º tareas | Estado actual de verificación funcional (Criterio 1) |
|---|---|---:|---|
| **1. Con harness propio ya validado** | `B1, B2, B3, B4, B5, B6`<br>`I1, I2, I3, I4, I5, I6` | **12** | **Cubiertas al 100 %** por `PRG_Test_B1.st` … `PRG_Test_I6.st` (validadas en Python a 4, 10 y 20 ms). |
| **2. Reutilizan un harness existente** | `C7` (`FB_Contador`, Ladder → ST)<br>`C8` (`FB_Valvula`, Ladder → ST) | **2** | **Cubiertas al 100 %**: `C7` reutiliza `PRG_Test_B3.st` y `C8` reutiliza `PRG_Test_B2.st` por diseño expreso del banco. |
| **3. Tareas no ejecutables / clave documental** | `C1, C5, C6` (`T2_analisis`: diagnóstico de errores)<br>`C2` (`T3_interpretacion`: requisito ambiguo)<br>`C4` (`T5_documentacion`: documentar `FB_D`) | **5** | **No requieren harness ST**: se evalúan mediante clave de errores sembrados (`C1, C5, C6`), lista de ambigüedades (`C2`) y fidelidad documental + conservación del código (`C4`). |
| **4. Tareas de código ST SIN harness** | `B7, B8` (Básicas)<br>`I7, I8` (Intermedias)<br>`A1, A2, A3, A4, A5, A6` (Avanzadas)<br>`C3` (`T4_conversion`: `PROGRAM PRG_Conversion`) | **11** | **Hueco de cobertura actual**: generan código ST ejecutable pero no disponen de `PRG_Test_*.st`. |

### 5.2 Estimación de esfuerzo para escribir cada harness faltante

| Tarea | POU exigido | Constructos / Tiempos | Complejidad técnica del harness + validador Python | Duración sim. por resp. | Esfuerzo estimado | Particularidades técnicas a tener en cuenta |
|---|---|---|---|---:|---:|---|
| **B7** | `PROGRAM PRG_Bomba` | Selector manual/auto sin activación espuria (sin timers) | **Baja** (plantilla B1, ~7 pasos) | ~1.4 s | **1.0 – 1.5 h** | Es un `PROGRAM`, no un `FUNCTION_BLOCK`. En CODESYS `PRG_Test_B7` puede llamar a `PRG_Bomba(...)` o acceder a `PRG_Bomba.var`, pero si el modelo declara variables en `VAR` local en vez de `VAR_INPUT`/`VAR_OUTPUT`, requiere lectura calificada `PRG_Bomba.bomba`. |
| **B8** | `FB_Puerta` | Conteo por flanco ascendente, preset $\ge 5$, `reset` | **Muy baja** (clon directo de `PRG_Test_B3`) | ~1.8 s | **0.5 – 1.0 h** | Idéntico a `B3` cambiando nombres de E/S (`puertaAbierta, reset` → `aviso, nAperturas`) y `FLANCOS_LOTE_A := 3` (cuenta=4, `aviso=FALSE`), `FLANCOS_LOTE_B := 1` (cuenta=5, `aviso=TRUE`). |
| **I7** | `FB_Duplex` | Alternancia de bombas en cada demanda + respaldo por `falla1`/`falla2` | **Media-baja** (plantilla B1, ~9 pasos) | ~1.5 s | **1.5 – 2.0 h** | Como el enunciado no impone cuál bomba es principal en el 1.er turno, el harness debe guardar cuál arrancó en el paso 1 (`b1Primera := fb.bomba1`) y exigir la opuesta en el siguiente flanco de demanda. |
| **I8** | `FB_Compresor` | Permisivo `pOilOk` con `TON` `T#3S`, prioridad `causaBloqueo` (1..3, 0), caída en marcha | **Media** (plantilla B2 + prioridades tipo I3, ~10 pasos) | ~9.5 s | **2.0 h** | Combina ventana temporal alrededor de 3 s (p. ej. 2.5 s y 3.5 s) con prueba de prelación `1 < 2 < 3` cuando faltan varios permisivos a la vez. |
| **A1** | `FB_PID` | PID discreto (`SP, PV, Kp, Ti, Td, ciclo`) + anti-windup por clamping `0..100` | **Alta** (lazos numéricos en `REAL`) | ~3.0 s | **4.0 – 5.0 h** | Existen varias discretizaciones legítimas (Euler hacia adelante/atrás, Tustin; derivada sobre error o sobre $-PV$). Un harness justo debe evaluar propiedades invariantes: (1) acción P pura ($T_i$ enorme, $T_d=0$), (2) clamping exacto en `0.0` y `100.0`, y (3) salida inmediata de saturación al invertir el signo del error (anti-windup), con bandas de tolerancia amplias. |
| **A2** | `FB_Batch` | Receta de 5 fases (`T#120S` en fase 4) + `btnAbort` con vaciado condicional | **Media** (similar a `I2` ampliado a 5 fases, ~14 pasos) | ~126 s | **2.5 – 3.0 h** | Debe probar `btnAbort` en dos situaciones: cuando aún no entró producto o tras vaciar, y con producto en el reactor (debe ir a fase 5 `vDescarga` hasta `nivelVacio` antes de fase 0). |
| **A3** | `FB_Com` | Petición `txReq`, espera eco `rxData=100` con `rxOk` en `T#500MS`, hasta 3 intentos → `error` | **Media-alta** (el harness actúa como esclavo emulado) | ~3.5 s | **3.0 h** | El harness debe probar: (1) eco correcto al 1.er intento, (2) eco tras 1 timeout + confirmación en el 2.º intento, y (3) 3 timeouts seguidos (o eco corrupto `rxData <> 100`) activando `error = TRUE` hasta nuevo `txReq`. Nota: no debe leer `nIntentos` desde fuera si el modelo la declaró en `VAR` interna como pide el enunciado. |
| **A4** | `FB_Rampa` | Rampa `+10 %/s` subiendo, `-20 %/s` bajando, `-40 %/s` con `paroRapido`, sin sobrepaso | **Media** (ventanas temporales y tolerancia en `REAL`) | ~8.0 s | **2.0 – 2.5 h** | Pasa `ciclo := T#10MS` (o `T#4MS` según `MainTask`) y comprueba valores intermedios de la rampa (p. ej. tras 2 s subiendo hacia 50 % debe estar en $20.0 \pm 1.0$) y ausencia de sobrepaso al llegar a `SPvel`. |
| **A5** | `FB_Registro` | Buffer circular `ARRAY[0..19] OF ST_Evento` (`codigo: INT, marca: TIME`) + `indice: INT` | **Alta** (requiere `TYPE ST_Evento` como DUT en CODESYS) | ~2.5 s | **3.5 – 4.0 h** | En CODESYS, la declaración `TYPE ST_Evento : STRUCT ... END_STRUCT END_TYPE` debe crearse como un objeto *DUT* aparte del `FUNCTION_BLOCK`. El harness debe emitir $\ge 22$ flancos de `nuevoEvento` para comprobar el envolvimiento circular (`indice` vuelve a `0, 1` y sobrescribe los más antiguos) y monotonía de `marca`. |
| **A6** | `FB_Modos` | Modos 0/1/2 con cambio condicionado a `estadoSeguro`, `habForzado` en modo 2, filtro `0..2` | **Media-baja** (plantilla B1, sin temporizadores, ~10 pasos) | ~1.5 s | **1.5 – 2.0 h** | Muy limpio de verificar: cambio aceptado con `estadoSeguro = TRUE`, rechazado con `FALSE`, ignorar `selector = -1` o `3`, y caída inmediata de `habForzado` al soltar `confirmarForzado` o salir de modo 2. |
| **C3** | `PROGRAM PRG_Conversion` | Conversión Ladder → ST: arranque/paro `motor` + `TON` `T1` de 10 s → `lampara` | **Baja** (plantilla B2, ~6 pasos) | ~12.0 s | **1.0 – 1.5 h** | Igual que `B7`, es un `PROGRAM` y su enunciado pide `variables btnMarcha, btnParo (BOOL de entrada), motor, lampara (BOOL de salida) y T1 (TON)`, por lo que algunos modelos declararán `VAR_INPUT`/`VAR_OUTPUT` y otros `VAR` local. |

- **Esfuerzo total estimado para cubrir las 11 tareas restantes:** **~22.5 a 27.5 horas** de desarrollo y validación por simulación (`validar_harness_*.py` + prueba en CODESYS).

### 5.3 Dos opciones metodológicas y recomendación

#### Opción A — Escribir los harnesses faltantes (cobertura total o selectiva de tareas discretas)
- **Variante A1 (Total — 11 harnesses nuevos):** Escribir `B7, B8, I7, I8, A1–A6, C3`. Automatiza el Criterio 1 en las 25 tareas ejecutables del banco ($25 \times 24 = 600$ respuestas en el estudio definitivo).
  - *Ventaja:* Uniformidad instrumental total en los tres niveles (Básico, Intermedio, Avanzado).
  - *Riesgo:* En **`A1` (PID)** existe riesgo real de falsos negativos por diferencias numéricas entre discretizaciones válidas de la literatura; en **`A5` (Buffer circular)** la creación del `TYPE ST_Evento` varía entre modelos (algunos no declaran el `TYPE` o cambian nombres de campos); y en **`B7`/`C3` (`PROGRAM`)** la ambigüedad entre `VAR_INPUT` y `VAR` local obliga a adaptar el harness según cómo haya declarado las variables cada modelo.
- **Variante A2 (Selectiva de alta fiabilidad — 7 harnesses nuevos: `B7, B8, I7, I8, A2, A4, A6`):** Cubre el 100 % de Básico (`B1–B8`), el 100 % de Intermedio (`I1–I8`) y las tareas avanzadas de comportamiento determinista (`A2, A4, A6`), dejando únicamente `A1`, `A3`, `A5` y `C3` para verificación interactiva asistida con protocolo fijo. Esfuerzo reducido a **~11–14 horas**.

#### Opción B — Declarar en la metodología que el instrumento autoverificable (`PRG_Test_*`) cubre el subconjunto de 14 tareas (Piloto + C7/C8) y evaluar el resto con protocolo manual en CODESYS
- **En qué consiste:** Mantener congelados los **12 harnesses actuales** (que cubren `B1–B6`, `I1–I6`, `C7` y `C8`, es decir, **14 tareas = 336 respuestas** del experimento definitivo y el **100 % de las 144 respuestas del piloto**), y evaluar las restantes tareas ejecutables en el simulador de CODESYS siguiendo la secuencia de pasos de las fichas de evaluación del banco (`Banco_de_Pruebas_v0.xlsx`), tal como contempla originalmente la propuesta aprobada.
- **Ventaja:** Cero retraso para entrar a la verificación en CODESYS del piloto; evita el riesgo de falsos negativos instrumentales en tareas numéricas abiertas como `A1` (PID) o con estructuras `TYPE` como `A5`; y es completamente defendible en el capítulo de Metodología (los harnesses autoverificables se presentan como instrumento de alta precisión para las 14 tareas de lógica discreta y temporizada con interfaz cerrada, validado además contra revisión manual en la Etapa 6).

> [!TIP]
> **Recomendación:**  
> 1. **Para el cierre inmediato del piloto (144 respuestas):** No hace falta ningún harness adicional, pues los 12 harnesses existentes cubren el **100 % del piloto (`B1–B6, I1–I6`)**. Conviene proceder de inmediato a verificar estos 12 harnesses en CODESYS real con `CHECKLIST_CODESYS.md`.  
> 2. **Para el experimento definitivo (720 respuestas):** Recomendamos una combinación pragmática entre la **Opción B** y la **Variante A2 ligera**: declarar en la metodología que la batería autoverificable cubre las tareas de interfaz de bloque cerrada y determinista, y —si deseas ampliar cobertura con mínimo esfuerzo y cero riesgo de falsos negativos— añadir únicamente **`B8`, `I7`, `I8` y `A6`** (~5.5 h en total, todos `FUNCTION_BLOCK` deterministas sin ambigüedad numérica ni `TYPE` externos), manteniendo `A1–A5`, `B7` y `C3` con protocolo guiado en simulación.
