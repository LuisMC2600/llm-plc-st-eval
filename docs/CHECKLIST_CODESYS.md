# Guía Paso a Paso de Verificación Manual en CODESYS V3.5 (`CHECKLIST_CODESYS.md`)

**Proyecto:** «LLMs como Asistentes de Programación PLC en la Academia: Evaluación de Precisión y Confiabilidad» (FIE-UTP)  
**Autor:** Luis Montenegro (Asesora: Mgtr. Sofía Serracín Moreno)  
**Fecha:** 2026-09-28  
**Propósito:** Lista de comprobación operativa para verificar en el simulador real de CODESYS V3.5 SP21 (`CODESYS Control Win V3 x64`) los 12 harnesses autoverificables (`PRG_Test_B1.st` a `PRG_Test_I6.st`) a ciclos de scan de `10 ms` y `4 ms`, antes de lanzar el lote automatizado del piloto (`data/processed/`, 144 archivos `.st`).

> **Nota metodológica (Regla 1 de `CLAUDE.md`):** Este documento no incluye código ST de las soluciones de los `FUNCTION_BLOCK` bajo prueba. Para cada prueba positiva y negativa debes emplear tus bloques de referencia (`FB_xxx`) o trasladar la lógica de prueba al bloque en tu proyecto CODESYS.

---

## 1. Procedimiento General en CODESYS V3.5 (aplica a los 12 harnesses)

### 1.1 Creación del proyecto base
1. Abrir **CODESYS V3.5 SP21 (64-bit)**.
2. Menú **`File > New Project...`** → seleccionar **`Standard project`**.
3. Nombre sugerido: `Verificacion_Harnesses_Piloto` → clic en **`OK`**.
4. En el cuadro **`Standard Project`**:
   - **Device:** seleccionar **`CODESYS Control Win V3 x64`** (o el dispositivo 32/64 bits instalado en tu equipo).
   - **PLC_PRG in:** **`Structured Text (ST)`**.
   - Clic en **`OK`**.

### 1.2 Cómo dividir un archivo `.st` en los dos paneles del editor CODESYS
En CODESYS V3.5, todo POU (`FUNCTION_BLOCK` o `PROGRAM`) se divide en dos paneles:
- **Panel superior (Declaración):** contiene desde el encabezado (`FUNCTION_BLOCK FB_xxx` o `PROGRAM PRG_Test_xx`) hasta el último `END_VAR` inclusive.
- **Panel inferior (Implementación):** contiene únicamente las sentencias ejecutables posteriores al último `END_VAR`, **sin** incluir la línea final `END_FUNCTION_BLOCK` ni `END_PROGRAM` (CODESYS cierra el POU internamente; dejar `END_FUNCTION_BLOCK` o `END_PROGRAM` en el panel inferior produce error de sintaxis).

#### A. Crear y pegar el `FUNCTION_BLOCK` bajo prueba (`FB_xxx`)
1. En el árbol **`Devices`**, clic derecho sobre **`Application`** → **`Add Object > POU...`**.
2. Configurar:
   - **Name:** nombre exacto del bloque (`FB_Motor`, `FB_Valvula`, etc.).
   - **Type:** **`Function block`**.
   - **Implementation language:** **`Structured Text (ST)`** → clic en **`Add`**.
3. **Panel superior:** pegar `FUNCTION_BLOCK FB_xxx` con sus bloques `VAR_INPUT`, `VAR_OUTPUT` y `VAR` hasta el último `END_VAR`.
4. **Panel inferior:** pegar el cuerpo lógico de tu implementación de referencia (o variante defectuosa para la prueba negativa), **excluyendo** `END_FUNCTION_BLOCK`.

#### B. Crear y pegar el harness (`PRG_Test_xx`)
1. Clic derecho sobre **`Application`** → **`Add Object > POU...`**.
2. Configurar:
   - **Name:** `PRG_Test_xx` (por ejemplo, `PRG_Test_B1`).
   - **Type:** **`Program`**.
   - **Implementation language:** **`Structured Text (ST)`** → clic en **`Add`**.
3. Abrir `codesys/PRG_Test_xx.st` en un editor de texto:
   - **Panel superior:** copiar desde `PROGRAM PRG_Test_xx` hasta el último `END_VAR` (línea previa al bloque de comentarios `(* ===... *)` de la lógica).
   - **Panel inferior:** copiar desde la primera sentencia tras `END_VAR` hasta la línea anterior a `END_PROGRAM` (**no** pegar `END_PROGRAM`).

### 1.3 Configuración de `MainTask` (`10 ms` y `4 ms`)
1. En el árbol **`Devices`**, expandir **`Task Configuration`** → doble clic en **`MainTask`**.
2. Verificar/ajustar los parámetros de la tarea:
   - **Type:** **`Cyclic`**.
   - **Interval:** **`t#10ms`** (o `10` con unidad `ms`) para la primera pasada; luego cambiar a **`t#4ms`** para la segunda pasada de verificación.
3. En la lista **`Program Calls`** de `MainTask`:
   - Seleccionar `PLC_PRG` y reemplazarlo (o eliminarlo y usar **`Add Call`**) por **`PRG_Test_xx`**.
   - Asegurarse de que **solo un** `PRG_Test_xx` esté activo en `MainTask` durante cada prueba.

### 1.4 Compilación, Simulación y Lectura de Resultados
1. **Compilar:** presionar **`F11`** (o **`Build > Generate Code`**). Confirmar en el panel **`Messages`** que el resultado sea **`0 errors, 0 warnings`**.
2. **Activar modo Simulación:** menú **`Online > Simulation`** (debe aparecer marcado con un check y el indicador rojo `Simulation` en la barra de estado inferior).
3. **Conectar al simulador:** menú **`Online > Login`** (**`Alt+F8`**) y confirmar descarga (`Yes`). El PLC entra en estado **`STOP`**.
4. **Arrancar el ciclo de scan:** presionar **`F5`** (**`Debug > Start`**). El estado pasa a **`RUN`**.
5. **Observar variables en tiempo real:** en el panel superior de `PRG_Test_xx`, expandir la tabla de monitoreo en línea y esperar hasta que:
   - `terminado = TRUE`
   - Leer `veredicto` (`1` = PASA, `2` = FALLA)
   - Expandir el arreglo `resultado` (`resultado[0]` .. `resultado[ULTIMO_PASO]`) y verificar que cada elemento coincida con la tabla esperada de esta guía.

### 1.5 Ejecución de la Prueba Negativa y Reinicio (`Reset cold`)
1. Salir de línea con **`Online > Logout`** (**`Ctrl+F8`**).
2. Introducir en el panel inferior de `FB_xxx` un defecto conocido (por ejemplo, uno de los defectos sintéticos listados en cada ficha).
3. Presionar **`F11`** para verificar compilación limpia.
4. Entrar en línea (**`Alt+F8`**) → elegir **`Login with online change`** o **`Login with download`**.
5. Ejecutar **`Online > Reset cold`** para garantizar que todas las instancias (`dut`, `tonPaso`, `paso`, `resultado`, banderas de interlock) vuelvan a su estado inicial `0 / FALSE`.
6. Presionar **`F5`** (**`Start`**), esperar a `terminado = TRUE` y comprobar que `veredicto = 2` y que el vector `resultado[i]` falle exactamente en el **paso clave** indicado.

---

## 2. Resumen Rápido de Orden de Ejecución y Tiempos

Se recomienda ejecutar primero el **Bloque Base (`B1 → B2 → B3`)** —los tres harnesses que no requirieron ninguna enmienda en `ENMIENDAS_HARNESSES.md`— y posteriormente los **9 harnesses con enmiendas**, ordenados de menor a mayor tiempo de ejecución para agilizar la sesión en CODESYS:

| Orden | ID | Harness | FB bajo prueba | Pasos (`0..N`) | Duración a `10 ms` | Duración a `4 ms` | Enmiendas verificadas | Estado `10 ms` | Estado `4 ms` |
| :---: | :---: | :--- | :--- | :---: | :---: | :---: | :--- | :---: | :---: |
| **1** | **B1** | `PRG_Test_B1` | `FB_Motor` | `0..6` (7) | `1.46 s` | `1.42 s` | Ninguna (base limpia) | [ ] | [ ] |
| **2** | **B2** | `PRG_Test_B2` | `FB_Valvula` | `0..5` (6) | `12.98 s` | `12.92 s` | Ninguna (base limpia) | [ ] | [ ] |
| **3** | **B3** | `PRG_Test_B3` | `FB_Contador` | `0..6` (7) | `2.36 s` | `2.22 s` | Ninguna (base limpia) | [ ] | [ ] |
| **4** | **I6** | `PRG_Test_I6` | `FB_Temperatura` | `0..7` (8) | `0.95 s` | `0.83 s` | Enmienda 13 | [ ] | [ ] |
| **5** | **B4** | `PRG_Test_B4` | `FB_Giro` | `0..9` (10) | `1.59 s` | `1.56 s` | Enmiendas 3, 9 | [ ] | [ ] |
| **6** | **I3** | `PRG_Test_I3` | `FB_Alarmas` | `0..9` (10) | `1.59 s` | `1.56 s` | Enmienda 12 | [ ] | [ ] |
| **7** | **I5** | `PRG_Test_I5` | `FB_Clasificadora` | `0..6` (7) | `4.06 s` | `4.02 s` | Enmienda 5 | [ ] | [ ] |
| **8** | **I4** | `PRG_Test_I4` | `FB_EstrellaTriangulo` | `0..5` (6) | `9.26 s` | `9.22 s` | Enmienda 4 | [ ] | [ ] |
| **9** | **B6** | `PRG_Test_B6` | `FB_Baliza` | `0..2` (3) | `9.74 s` | `9.71 s` | Enmiendas 1, 8, 10 | [ ] | [ ] |
| **10** | **I2** | `PRG_Test_I2` | `FB_Llenado` | `0..11` (12) | `62.72 s` | `62.65 s` | Enmienda 6 | [ ] | [ ] |
| **11** | **I1** | `PRG_Test_I1` | `FB_Semaforo` | `0..8` (9) | `70.72 s` | `70.64 s` | Enmiendas 2, 8, 11 | [ ] | [ ] |
| **12** | **B5** | `PRG_Test_B5` | `FB_Ventilador` | `0..8` (9) | `71.29 s` | `71.24 s` | Enmienda 7 | [ ] | [ ] |

---

## 3. Parte A — Harnesses Base sin Enmiendas (`B1 → B2 → B3`)

---

### 3.1 Harness `B1` — Arranque/paro de motor con enclavamiento (`PRG_Test_B1.st`)

- **FB bajo prueba:** `FB_Motor`
- **Archivo harness:** `codesys/PRG_Test_B1.st`
- **Entradas (`VAR_INPUT`):** `btnMarcha: BOOL`, `btnParo: BOOL`, `btnEmerg: BOOL`
- **Salidas (`VAR_OUTPUT`):** `motorOn: BOOL`
- **Constantes del harness:** `ULTIMO_PASO = 6` (7 pasos: `0..6`), `T_ASENTAMIENTO = T#200MS` fijo por paso.
- **Duración hasta `terminado = TRUE`:** `1.460 s` (146 scans a `10 ms`) | `1.424 s` (356 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_B1`
| Paso `i` | `btnMarcha` | `btnParo` | `btnEmerg` | Duración | Condición evaluada al vencer `tonPaso.Q` | Qué verifica |
| :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| `0` | `FALSE` | `FALSE` | `FALSE` | `200 ms` | `motorOn = FALSE` | Reposo inicial con motor apagado |
| `1` | `TRUE` | `FALSE` | `FALSE` | `200 ms` | `motorOn = TRUE` | Pulso de marcha arranca el motor |
| `2` | `FALSE` | `FALSE` | `FALSE` | `200 ms` | `motorOn = TRUE` | Enclavamiento tras soltar `btnMarcha` |
| `3` | `FALSE` | `TRUE` | `FALSE` | `200 ms` | `motorOn = FALSE` | Paro normal detiene el motor |
| `4` | `TRUE` | `FALSE` | `FALSE` | `200 ms` | `motorOn = TRUE` | Rearranque tras paro normal |
| `5` | `TRUE` | `FALSE` | `TRUE` | `200 ms` | `motorOn = FALSE` | Paro de emergencia domina sobre marcha |
| `6` | `TRUE` | `FALSE` | `FALSE` | `200 ms` | `motorOn = FALSE` | Al liberar emergencia con `btnMarcha=TRUE` sostenido, **no** rearranca solo |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..6]` | Paso clave de fallo |
| :--- | :---: | :--- | :---: |
| **Correcta (referencia)** | **`1`** | `[1, 1, 1, 1, 1, 1, 1]` | — |
| Defecto 1: sin enclavamiento (`motorOn := btnMarcha AND ...`) | **`2`** | `[1, 1, 2, 1, 1, 1, 2]` | Paso `2` (y `6`) |
| Defecto 2: rearranca al soltar E-stop con `btnMarcha = TRUE` | **`2`** | `[1, 1, 1, 1, 1, 1, 2]` | Paso `6` |
| Defecto 3: emergencia no domina sobre marcha | **`2`** | `[1, 1, 1, 1, 1, 2, 2]` | Paso `5` (y `6`) |
| Defecto 4: `btnParo` tratado como contacto NC (`AND btnParo`) | **`2`** | `[1, 2, 2, 1, 2, 1, 1]` | Paso `1` |

---

### 3.2 Harness `B2` — Temporizador de retardo a la conexión (`PRG_Test_B2.st`)

- **FB bajo prueba:** `FB_Valvula`
- **Archivo harness:** `codesys/PRG_Test_B2.st`
- **Entradas (`VAR_INPUT`):** `nivelAlto: BOOL`
- **Salidas (`VAR_OUTPUT`):** `valvula: BOOL`
- **Constantes del harness:** `ULTIMO_PASO = 5` (6 pasos: `0..5`).
- **Duración hasta `terminado = TRUE`:** `12.980 s` (1 298 scans a `10 ms`) | `12.924 s` (3 231 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_B2`
| Paso `i` | `nivelAlto` | `tEspera` | Tiempo acum. `nivelAlto=T` | Condición evaluada | Qué verifica |
| :---: | :---: | :---: | :---: | :---: | :--- |
| `0` | `FALSE` | `500 ms` | `0 s` | `valvula = FALSE` | Reposo inicial con válvula cerrada |
| `1` | `TRUE` | `3 000 ms` | `3.0 s` | `valvula = FALSE` | A los `3 s` (`< 5 s` del TON) sigue cerrada |
| `2` | `TRUE` | `3 000 ms` | `6.0 s` | `valvula = TRUE` | A los `6 s` acumulados (`> 5 s`) ya abrió |
| `3` | `FALSE` | `200 ms` | `0 s` | `valvula = FALSE` | Cierre inmediato al caer `nivelAlto` |
| `4` | `TRUE` | `6 000 ms` | `6.0 s` | `valvula = TRUE` | Segundo ciclo completo: el TON se rearmó y vuelve a abrir |
| `5` | `FALSE` | `200 ms` | `0 s` | `valvula = FALSE` | Cierre final |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..5]` | Paso clave de fallo |
| :--- | :---: | :--- | :---: |
| **Correcta (referencia)** | **`1`** | `[1, 1, 1, 1, 1, 1]` | — |
| Defecto 1: usa `TOF` en vez de `TON` (abre de inmediato) | **`2`** | `[1, 2, 1, 2, 1, 2]` | Paso `1` (y `3`, `5`) |
| Defecto 2: preset de `2 s` en vez de `5 s` | **`2`** | `[1, 2, 1, 1, 1, 1]` | Paso `1` |
| Defecto 3: válvula enclavada (no cierra al caer `nivelAlto`) | **`2`** | `[1, 1, 1, 2, 1, 2]` | Paso `3` (y `5`) |
| Defecto 4: temporizador no se rearma en el 2.° ciclo | **`2`** | `[1, 1, 1, 1, 2, 1]` | Paso `4` |

---

### 3.3 Harness `B3` — Contador de piezas con señal de lote (`PRG_Test_B3.st`)

- **FB bajo prueba:** `FB_Contador`
- **Archivo harness:** `codesys/PRG_Test_B3.st`
- **Entradas (`VAR_INPUT`):** `sensorPieza: BOOL`, `btnReset: BOOL`
- **Salidas (`VAR_OUTPUT`):** `loteListo: BOOL`, `cuenta: INT`
- **Constantes del harness:** `ULTIMO_PASO = 6` (7 pasos: `0..6`), `T_PULSO = T#20MS` (semiperíodo del generador de flancos), `FLANCOS_LOTE_A = 10`, `FLANCOS_LOTE_B = 1`.
- **Duración hasta `terminado = TRUE` (medida en Paso 1):** `2.360 s` (236 scans a `10 ms`) | `2.216 s` (554 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_B3`
| Paso `i` | Estímulo (`btnReset`, `sensorPieza`) | Espera tras flancos | Condición evaluada | Qué verifica |
| :---: | :--- | :---: | :---: | :--- |
| `0` | `btnReset=TRUE, sensorPieza=FALSE` | `200 ms` | `cuenta = 0 AND NOT loteListo` | Reset inicial deja cuenta en `0` |
| `1` | `btnReset=FALSE, sensorPieza=TRUE` (1.er flanco) | `200 ms` | `cuenta = 1 AND NOT loteListo` | Primer flanco de subida incrementa a `1` |
| `2` | `sensorPieza=TRUE` sostenido | `500 ms` | `cuenta = 1 AND NOT loteListo` | **No** cuenta por nivel alto sostenido |
| `3` | `sensorPieza=FALSE` (bajada) | `200 ms` | `cuenta = 1 AND NOT loteListo` | Flanco de bajada no incrementa |
| `4` | Tren de `10` flancos de subida (`T_PULSO=20ms`) | `+ 200 ms` | `cuenta = 11 AND NOT loteListo` | Con `11` piezas aún **no** se activa `loteListo` (detecta preset `< 12`) |
| `5` | `1` flanco adicional de subida (`T_PULSO=20ms`) | `+ 200 ms` | `cuenta = 12 AND loteListo` | Al llegar a `12` piezas se activa `loteListo = TRUE` |
| `6` | `btnReset=TRUE, sensorPieza=FALSE` | `200 ms` | `cuenta = 0 AND NOT loteListo` | El reset reinicia `cuenta = 0` y apaga `loteListo` |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..6]` | Paso clave de fallo |
| :--- | :---: | :--- | :---: |
| **Correcta (referencia)** | **`1`** | `[1, 1, 1, 1, 1, 1, 1]` | — |
| Defecto 1: cuenta por nivel (`IF sensorPieza THEN cuenta := cuenta + 1`) | **`2`** | `[1, 2, 2, 2, 2, 2, 1]` | Paso `2` (y `1`) |
| Defecto 2: preset `10` en vez de `12` (`loteListo := cuenta >= 10`) | **`2`** | `[1, 1, 1, 1, 2, 1, 1]` | Paso `4` |
| Defecto 3: `btnReset` reinicia `cuenta` pero no apaga `loteListo` | **`2`** | `[1, 1, 1, 1, 1, 1, 2]` | Paso `6` |

---

## 4. Parte B — Harnesses con Enmiendas (`ENMIENDAS_HARNESSES.md`), de más rápido a más lento

---

### 4.1 Harness `I6` — Control de temperatura con histéresis (`PRG_Test_I6.st`)

- **FB bajo prueba:** `FB_Temperatura`
- **Archivo harness:** `codesys/PRG_Test_I6.st`
- **Enmienda verificada:** **Enmienda 13** (reordenamiento de los pasos `1..4` para que el fallo de sensor en el paso `3` ocurra mientras el enfriador viene encendido del paso `2`, probando efectivamente que `almSensor` fuerza `enfriador = FALSE`).
- **Entradas (`VAR_INPUT`):** `rawTemp: INT`
- **Salidas (`VAR_OUTPUT`):** `tempC: REAL`, `enfriador: BOOL`, `almSensor: BOOL`
- **Constantes del harness:** `ULTIMO_PASO = 7` (8 pasos: `0..7`), `T_ASENTAMIENTO = T#100MS`, `TOL_TEMP = 0.1`.
- **Duración hasta `terminado = TRUE`:** `0.950 s` (95 scans a `10 ms`) | `0.828 s` (207 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_I6`
| Paso `i` | `rawTemp` | `tempC` esperada (`±0.1`) | `enfriador` | `almSensor` | Qué verifica |
| :---: | :---: | :---: | :---: | :---: | :--- |
| `0` | `13824` | `50.0 °C` | `FALSE` | `FALSE` | Escalado a mitad de rango (`27648 / 2`), enfriador apagado |
| `1` | `22119` | `80.0 °C` | `TRUE` | `FALSE` | Supera umbral alto (`>= 80 °C`), enciende enfriador |
| `2` | `21289` | `77.0 °C` | `TRUE` | `FALSE` | Banda de histéresis en bajada (`77 °C > 75 °C`): **retiene** enfriador encendido |
| `3` | `27649` | *(no se evalúa)* | `FALSE` | `TRUE` | **Enmienda 13:** fuera de rango alto con enfriador previo encendido → activa alarma y **apaga** enfriador |
| `4` | `20736` | `75.0 °C` | `FALSE` | `FALSE` | Retorno a rango en umbral bajo (`75 °C`): sin alarma y enfriador apagado |
| `5` | `21289` | `77.0 °C` | `FALSE` | `FALSE` | Banda de histéresis en subida (`77 °C < 80 °C`): mantiene enfriador apagado |
| `6` | `-1` | *(no se evalúa)* | `FALSE` | `TRUE` | Fuera de rango bajo (`< 0`) → activa `almSensor` |
| `7` | `0` | `0.0 °C` | `FALSE` | `FALSE` | Límite inferior exacto (`0` → `0.0 °C`), sin alarma |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..7]` | Paso clave de fallo |
| :--- | :---: | :--- | :---: |
| **Correcta (referencia)** | **`1`** | `[1, 1, 1, 1, 1, 1, 1, 1]` | — |
| Defecto 1: la alarma no apaga el enfriador (capturado por **Enmienda 13**) | **`2`** | `[1, 1, 1, 2, 1, 1, 1, 1]` | Paso `3` |
| Defecto 2: sin histéresis (`enfriador := tempC >= 80.0`) | **`2`** | `[1, 1, 2, 1, 1, 1, 1, 1]` | Paso `2` |
| Defecto 3: división entera en el escalado (`(rawTemp / 27648) * 100`) | **`2`** | `[2, 2, 2, 1, 2, 2, 1, 1]` | Paso `0` |
| Defecto 4: no comprueba límite inferior `rawTemp < 0` | **`2`** | `[1, 1, 1, 1, 1, 1, 2, 1]` | Paso `6` |
| Defecto 5: alarma enclavada (no se recupera al volver a rango) | **`2`** | `[1, 1, 1, 1, 2, 2, 1, 2]` | Paso `4` |

---

### 4.2 Harness `B4` — Inversor de giro con interlock (`PRG_Test_B4.st`)

- **FB bajo prueba:** `FB_Giro`
- **Archivo harness:** `codesys/PRG_Test_B4.st`
- **Enmiendas verificadas:**
  - **Enmienda 3:** el paso `8` (`btnFwd=TRUE, btnRev=TRUE` simultáneos desde reposo tras paro en paso `7`) verifica interlock sin depender de pasos previos.
  - **Enmienda 9:** el paso `8` exige únicamente `NOT (dut.fwd AND dut.rev)` (neutralidad ante las tres resoluciones válidas del enunciado: bloquear ambos, dar prioridad a `fwd` o dar prioridad a `rev`).
- **Entradas (`VAR_INPUT`):** `btnFwd: BOOL`, `btnRev: BOOL`, `btnParo: BOOL`
- **Salidas (`VAR_OUTPUT`):** `fwd: BOOL`, `rev: BOOL`
- **Variable adicional a monitorear en `PRG_Test_B4`:** `violacionInterlock: BOOL` (se enclava en `TRUE` si `dut.fwd AND dut.rev` ocurre en **cualquier scan**).
- **Constantes del harness:** `ULTIMO_PASO = 9` (10 pasos: `0..9`), `T_ASENTAMIENTO = T#150MS`.
- **Duración hasta `terminado = TRUE`:** `1.590 s` (159 scans a `10 ms`) | `1.556 s` (389 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_B4`
| Paso `i` | `btnFwd` | `btnRev` | `btnParo` | Condición evaluada | Qué verifica |
| :---: | :---: | :---: | :---: | :---: | :--- |
| `0` | `FALSE` | `FALSE` | `FALSE` | `NOT fwd AND NOT rev` | Reposo inicial |
| `1` | `TRUE` | `FALSE` | `FALSE` | `fwd AND NOT rev` | Arranque en avance (`fwd`) |
| `2` | `FALSE` | `FALSE` | `FALSE` | `fwd AND NOT rev` | Enclavamiento de `fwd` al soltar `btnFwd` |
| `3` | `FALSE` | `TRUE` | `FALSE` | `fwd AND NOT rev` | Pulsar `btnRev` en marcha `fwd` sin pasar por paro **no** invierte |
| `4` | `FALSE` | `FALSE` | `TRUE` | `NOT fwd AND NOT rev` | Paro detiene el motor |
| `5` | `FALSE` | `TRUE` | `FALSE` | `NOT fwd AND rev` | Desde reposo, `btnRev` arranca en reversa (`rev`) |
| `6` | `TRUE` | `TRUE` | `FALSE` | `NOT fwd AND rev` | Ambos botones con `rev` ya activo mantiene `rev` |
| `7` | `FALSE` | `FALSE` | `TRUE` | `NOT fwd AND NOT rev` | Segundo paro |
| `8` | `TRUE` | `TRUE` | `FALSE` | `NOT (fwd AND rev)` | **Enmiendas 3 y 9:** ambos botones desde reposo nunca activan `fwd` y `rev` a la vez |
| `9` | `FALSE` | `FALSE` | `TRUE` | `NOT fwd AND NOT rev` | Paro final |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..9]` | `violacionInterlock` | Paso clave de fallo |
| :--- | :---: | :--- | :---: | :---: |
| **Correcta (bloquea ambos en paso 8)** | **`1`** | `[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]` | `FALSE` | — |
| **Correcta (prioridad `fwd` en paso 8)** | **`1`** | `[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]` | `FALSE` | — |
| **Correcta (prioridad `rev` en paso 8)** | **`1`** | `[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]` | `FALSE` | — |
| Defecto 1: sin enclavamiento | **`2`** | `[1, 1, 2, 2, 1, 1, 2, 1, 1, 1]` | `FALSE` | Paso `2` |
| Defecto 2: invierte giro sin pasar por paro | **`2`** | `[1, 1, 1, 2, 1, 1, 2, 1, 1, 1]` | `FALSE` | Paso `3` |
| Defecto 3: sin interlock cruzado | **`2`** | `[1, 1, 1, 2, 1, 1, 2, 1, 2, 1]` | `TRUE` | Paso `3` / `8` + `violacionInterlock` |
| Defecto 4: carrera de interlock (usa `NOT rev` del scan previo) | **`2`** | `[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]` o `resultado[8]=2` | **`TRUE`** | Paso `8` (`violacionInterlock = TRUE`) |

---

### 4.3 Harness `I3` — Gestor de 3 alarmas con prioridad (`PRG_Test_I3.st`)

- **FB bajo prueba:** `FB_Alarmas`
- **Archivo harness:** `codesys/PRG_Test_I3.st`
- **Enmienda verificada:** **Enmienda 12** (`ULTIMO_PASO` ampliado de `8` a `9`; nuevo paso `2` con `alm3=TRUE, ack3=TRUE` verifica que reconocer con la causa aún activa **no** borra la alarma retenida).
- **Entradas (`VAR_INPUT`):** `alm1, alm2, alm3, ack1, ack2, ack3: BOOL`
- **Salidas (`VAR_OUTPUT`):** `sirena: BOOL`, `codigoAlm: INT`
- **Constantes del harness:** `ULTIMO_PASO = 9` (10 pasos: `0..9`), `T_ASENTAMIENTO = T#150MS`.
- **Duración hasta `terminado = TRUE`:** `1.590 s` (159 scans a `10 ms`) | `1.556 s` (389 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_I3`
| Paso `i` | `alm1..3` | `ack1..3` | `sirena` esperada | `codigoAlm` esperado | Qué verifica |
| :---: | :---: | :---: | :---: | :---: | :--- |
| `0` | `F, F, F` | `T, T, T` | `FALSE` | `0` | Limpieza inicial sin alarmas |
| `1` | `F, F, T` | `F, F, F` | `TRUE` | `3` | Disparo de alarma 3 |
| `2` | `F, F, T` | `F, F, T` | `TRUE` | `3` | **Enmienda 12:** `ack3=TRUE` con `alm3=TRUE` activa **no** borra la alarma |
| `3` | `F, F, F` | `F, F, F` | `TRUE` | `3` | Al desaparecer `alm3` sin `ack3`, la alarma permanece retenida |
| `4` | `F, F, F` | `F, F, T` | `FALSE` | `0` | `ack3=TRUE` con `alm3=FALSE` borra la alarma 3 |
| `5` | `F, T, T` | `F, F, F` | `TRUE` | `2` | `alm2` y `alm3` simultáneas → prioridad 2 sobre 3 (`codigoAlm = 2`) |
| `6` | `T, T, T` | `F, F, F` | `TRUE` | `1` | Las tres activas → máxima prioridad 1 (`codigoAlm = 1`) |
| `7` | `F, T, T` | `T, F, F` | `TRUE` | `2` | Cae `alm1` y se reconoce `ack1` → pasa a mostrar `codigoAlm = 2` |
| `8` | `F, F, T` | `T, T, F` | `TRUE` | `3` | Cae `alm2` y se reconoce `ack2` → pasa a mostrar `codigoAlm = 3` |
| `9` | `F, F, F` | `T, T, T` | `FALSE` | `0` | Caen todas y se reconocen → reposo (`sirena=FALSE, codigoAlm=0`) |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..9]` | Paso clave de fallo |
| :--- | :---: | :--- | :---: |
| **Correcta (referencia)** | **`1`** | `[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]` | — |
| Defecto 1: ACK borra aunque la causa siga activa (**Enmienda 12**) | **`2`** | `[1, 1, 2, 2, 1, 1, 1, 1, 1, 1]` | Paso `2` (y `3`) |
| Defecto 2: sin retención (se apaga al caer `alm_i` sin ACK) | **`2`** | `[1, 1, 1, 2, 1, 1, 1, 1, 1, 1]` | Paso `3` |
| Defecto 3: prioridad invertida (`3 > 2 > 1`) | **`2`** | `[1, 1, 1, 1, 1, 2, 2, 2, 1, 1]` | Paso `6` (y `5`, `7`) |
| Defecto 4: `sirena` depende solo de entradas `alm_i` y no de retenidas | **`2`** | `[1, 1, 1, 2, 1, 1, 1, 1, 1, 1]` | Paso `3` |

---

### 4.4 Harness `I5` — Clasificadora por altura en banda (`PRG_Test_I5.st`)

- **FB bajo prueba:** `FB_Clasificadora`
- **Archivo harness:** `codesys/PRG_Test_I5.st`
- **Enmienda verificada:** **Enmienda 5** (el paso `3` con `sensorPresencia=TRUE, sensorAltura=TRUE` dura `200 ms` y comprueba explícitamente `NOT dut.piston`, detectando implementaciones que activan el pistón sin el retardo de `2 s`).
- **Entradas (`VAR_INPUT`):** `sensorPresencia: BOOL`, `sensorAltura: BOOL`
- **Salidas (`VAR_OUTPUT`):** `banda: BOOL`, `piston: BOOL`, `nAltas: INT`, `nBajas: INT`
- **Constantes del harness:** `ULTIMO_PASO = 6` (7 pasos: `0..6`).
- **Duración hasta `terminado = TRUE`:** `4.060 s` (406 scans a `10 ms`) | `4.024 s` (1 006 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_I5`
| Paso `i` | `sensorPresencia` | `sensorAltura` | `tEspera` | Salidas esperadas (`banda, piston, nAltas, nBajas`) | Qué verifica |
| :---: | :---: | :---: | :---: | :---: | :--- |
| `0` | `FALSE` | `FALSE` | `200 ms` | `T, F, 0, 0` | Banda activa, pistón retraído, contadores en `0` |
| `1` | `TRUE` | `FALSE` | `300 ms` | `T, F, 0, 1` | Pieza baja sostenida `300 ms`: cuenta solo `1` (por flanco) |
| `2` | `FALSE` | `FALSE` | `200 ms` | `T, F, 0, 1` | Pieza baja se retira; pistón nunca se activa |
| `3` | `TRUE` | `TRUE` | `200 ms` | `T, F, 1, 1` | **Enmienda 5:** pieza alta detectada (`t=0.7 s`), `nAltas=1`, pistón **aún `FALSE`** |
| `4` | `FALSE` | `FALSE` | `1 500 ms` | `T, F, 1, 1` | `1.7 s` desde el flanco (`< 2.0 s` de retardo): pistón sigue `FALSE` |
| `5` | `FALSE` | `FALSE` | `800 ms` | `T, T, 1, 1` | `2.5 s` desde el flanco (mitad del pulso `[2.0 s .. 3.0 s]`): **`piston = TRUE`** |
| `6` | `FALSE` | `FALSE` | `800 ms` | `T, F, 1, 1` | `3.3 s` desde el flanco (`> 3.0 s`): pulso de `1 s` terminado, `piston = FALSE` |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..6]` | Paso clave de fallo |
| :--- | :---: | :--- | :---: |
| **Correcta (referencia)** | **`1`** | `[1, 1, 1, 1, 1, 1, 1]` | — |
| Defecto 1: cuenta por nivel en vez de flanco | **`2`** | `[1, 2, 2, 2, 2, 2, 2]` | Paso `1` |
| Defecto 2: pistón se activa de inmediato sin retardo (**Enmienda 5**) | **`2`** | `[1, 1, 1, 2, 1, 2, 1]` | Paso `3` (y `5`) |
| Defecto 3: retardo de `1.5 s` en vez de `2 s` | **`2`** | `[1, 1, 1, 1, 2, 2, 1]` | Paso `4` |
| Defecto 4: pulso de `2 s` en vez de `1 s` | **`2`** | `[1, 1, 1, 1, 1, 1, 2]` | Paso `6` |
| Defecto 5: desvía también las piezas bajas | **`2`** | `[1, 1, 1, 1, 2, 1, 1]` | Paso `4` |

---

### 4.5 Harness `I4` — Arranque estrella-triángulo (`PRG_Test_I4.st`)

- **FB bajo prueba:** `FB_EstrellaTriangulo`
- **Archivo harness:** `codesys/PRG_Test_I4.st`
- **Enmienda verificada:** **Enmienda 4** (cronómetro `tonMuerto` mide la ventana real con `kM=TRUE, kY=FALSE, kD=FALSE` durante la transición estrella → triángulo y exige `duracionMuerto >= T#90MS` en el paso `3`, garantizando que no pase una transición instantánea de `0 ms`).
- **Entradas (`VAR_INPUT`):** `btnMarcha: BOOL`, `btnParo: BOOL`
- **Salidas (`VAR_OUTPUT`):** `kM: BOOL`, `kY: BOOL`, `kD: BOOL`
- **Variables adicionales a monitorear en `PRG_Test_I4`:** `interlock: BOOL` (se enclava si `kY AND kD`), `duracionMuerto: TIME`, `muertoOK: BOOL`.
- **Constantes del harness:** `ULTIMO_PASO = 5` (6 pasos: `0..5`), `T_MUERTO_MIN = T#90MS`.
- **Duración hasta `terminado = TRUE`:** `9.260 s` (926 scans a `10 ms`) | `9.224 s` (2 306 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_I4`
| Paso `i` | `btnMarcha` | `btnParo` | `tEspera` | Condición evaluada | Qué verifica |
| :---: | :---: | :---: | :---: | :---: | :--- |
| `0` | `FALSE` | `FALSE` | `200 ms` | `NOT kM AND NOT kY AND NOT kD` | Reposo inicial |
| `1` | `TRUE` | `FALSE` | `7 800 ms` | `kM AND kY AND NOT kD` | A los `7.8 s` (`< 8.0 s`) sigue en estrella (`kM + kY`) |
| `2` | `TRUE` | `FALSE` | `500 ms` | `kM AND NOT kY AND kD` | A los `8.3 s` acumulados (`> 8.1 s`) ya conmutó a triángulo (`kM + kD`) |
| `3` | `TRUE` | `FALSE` | `300 ms` | `kM AND NOT kY AND kD AND muertoOK` | **Enmienda 4:** régimen triángulo + tiempo muerto medido `>= 90 ms` |
| `4` | `FALSE` | `TRUE` | `200 ms` | `NOT kM AND NOT kY AND NOT kD` | Paro desenergiza los tres contactores |
| `5` | `TRUE` | `FALSE` | `200 ms` | `kM AND kY AND NOT kD` | Rearranque vuelve a iniciar en estrella (temporizador rearmado) |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..5]` | `interlock` | `duracionMuerto` (`10ms` / `4ms`) | Paso clave de fallo |
| :--- | :---: | :--- | :---: | :---: | :---: |
| **Correcta (referencia)** | **`1`** | `[1, 1, 1, 1, 1, 1]` | `FALSE` | `T#110ms` / `T#100ms` | — |
| Defecto 1: solapamiento `kY` y `kD` simultáneos | **`2`** | `[1, 1, 1, 2, 1, 1]` | **`TRUE`** | `T#0ms` | Paso `3` + `interlock` |
| Defecto 2: tiempo muerto de `0 ms` (conmutación directa `kY -> kD`, **Enmienda 4**) | **`2`** | `[1, 1, 1, 2, 1, 1]` | `FALSE` | `T#0ms` | Paso `3` (`muertoOK=FALSE`) |
| Defecto 3: temporizador de estrella no se rearma tras paro | **`2`** | `[1, 1, 1, 1, 1, 2]` | `FALSE` | `T#110ms` / `T#100ms` | Paso `5` |
| Defecto 4: `btnParo` apaga `kY/kD` pero deja `kM` encendido | **`2`** | `[1, 1, 1, 1, 2, 1]` | `FALSE` | `T#110ms` / `T#100ms` | Paso `4` |

---

### 4.6 Harness `B6` — Baliza intermitente de alarma (`PRG_Test_B6.st`)

- **FB bajo prueba:** `FB_Baliza`
- **Archivo harness:** `codesys/PRG_Test_B6.st`
- **Enmiendas verificadas:**
  - **Enmienda 1:** ventana de medición extendida a `7 s` en el paso `1` y criterio simétrico `nOn >= 2 AND nOff >= 2 AND NOT error` (acepta tanto balizas que inician en `TRUE` como en `FALSE` al activar `alarma`).
  - **Enmienda 8:** cada semiperíodo completo (`fSubida` y `fBajada` cuando `enVentana = TRUE`) debe estar dentro de `[T#850MS .. T#1150MS]`.
  - **Enmienda 10:** banderas `lamparaEnPaso0` y `lamparaEnPaso2` vigiladas scan a scan garantizan que la lámpara no oscile mientras `alarma = FALSE`.
- **Entradas (`VAR_INPUT`):** `alarma: BOOL`
- **Salidas (`VAR_OUTPUT`):** `lampara: BOOL`
- **Variables adicionales a monitorear en `PRG_Test_B6`:** `nOn: INT`, `nOff: INT`, `error: BOOL`, `lamparaEnPaso0: BOOL`, `lamparaEnPaso2: BOOL`.
- **Constantes del harness:** `ULTIMO_PASO = 2` (3 pasos: `0..2`), `TOL_MIN = T#850MS`, `TOL_MAX = T#1150MS`.
- **Duración hasta `terminado = TRUE`:** `9.740 s` (974 scans a `10 ms`) | `9.712 s` (2 428 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_B6`
| Paso `i` | `alarma` | `tEspera` | Condición evaluada | Qué verifica |
| :---: | :---: | :---: | :---: | :--- |
| `0` | `FALSE` | `200 ms` | `NOT lampara AND NOT lamparaEnPaso0` | **Enmienda 10:** lámpara apagada en todo scan con `alarma = FALSE` |
| `1` | `TRUE` | `7 000 ms` | `nOn >= 2 AND nOff >= 2 AND NOT error` | **Enmiendas 1 y 8:** al menos 2 semiperíodos ON y 2 OFF dentro de `[850 ms .. 1150 ms]` |
| `2` | `FALSE` | `2 500 ms` | `NOT lampara AND NOT lamparaEnPaso2` | **Enmienda 10:** se apaga inmediatamente al caer `alarma` y no vuelve a encender |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..2]` | `nOn, nOff, error` en Paso 1 | Paso clave de fallo |
| :--- | :---: | :--- | :---: | :---: |
| **Correcta (arranca apagada: `1s OFF -> 1s ON`)** | **`1`** | `[1, 1, 1]` | `nOn=3, nOff=3, error=FALSE` | — |
| **Correcta (arranca encendida: `1s ON -> 1s OFF`)** | **`1`** | `[1, 1, 1]` | `nOn=4, nOff=3, error=FALSE` | — |
| Defecto 1: semiperíodo de `1.5 s / 1.5 s` | **`2`** | `[1, 2, 1]` | `nOn=2, nOff=2, error=TRUE` | Paso `1` |
| Defecto 2: semiperíodo de `0.5 s / 0.5 s` | **`2`** | `[1, 2, 1]` | `nOn=7, nOff=7, error=TRUE` | Paso `1` |
| Defecto 3: asimétrico `1 s ON / 2 s OFF` (**Enmienda 8**) | **`2`** | `[1, 2, 1]` | `nOn=3, nOff=2, error=TRUE` | Paso `1` |
| Defecto 4: lámpara fija sin parpadear (`lampara := alarma`) | **`2`** | `[1, 2, 1]` | `nOn=0, nOff=0, error=FALSE` | Paso `1` |
| Defecto 5: sigue parpadeando sin alarma (**Enmienda 10**) | **`2`** | `[2, 1, 2]` o `[1, 1, 2]` | `lamparaEnPaso2 = TRUE` | Paso `2` (y `0`) |

---

### 4.7 Harness `I2` — Secuencia de llenado, mezcla y descarga (`PRG_Test_I2.st`)

- **FB bajo prueba:** `FB_Llenado`
- **Archivo harness:** `codesys/PRG_Test_I2.st`
- **Enmienda verificada:** **Enmienda 6** (`ULTIMO_PASO` ampliado de `7` a `11`; los pasos `8..11` verifican rearranque tras paro y paro de seguridad durante la etapa `MEZCLA` con el temporizador de `60 s` activo).
- **Entradas (`VAR_INPUT`):** `nivelAlto: BOOL`, `nivelBajo: BOOL`, `btnInicio: BOOL`, `btnParo: BOOL`
- **Salidas (`VAR_OUTPUT`):** `vLlenado: BOOL`, `motorMezcla: BOOL`, `vDescarga: BOOL`
- **Constantes del harness:** `ULTIMO_PASO = 11` (12 pasos: `0..11`).
- **Duración hasta `terminado = TRUE`:** `62.720 s` (6 272 scans a `10 ms`) | `62.648 s` (15 662 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_I2`
| Paso `i` | `nivelAlto` | `nivelBajo` | `btnInicio` | `btnParo` | `tEspera` | Salidas (`vLlenado, motorMezcla, vDescarga`) | Qué verifica |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| `0` | `F` | `F` | `F` | `F` | `200 ms` | `F, F, F` | Reposo inicial |
| `1` | `F` | `F` | `T` | `F` | `200 ms` | `T, F, F` | `btnInicio` abre válvula de llenado |
| `2` | `T` | `F` | `F` | `F` | `1 000 ms` | `F, T, F` | `nivelAlto` cierra llenado e inicia mezcla |
| `3` | `T` | `F` | `F` | `F` | `58 500 ms` | `F, T, F` | A `59.5 s` de mezcla (`< 60 s`) sigue mezclando |
| `4` | `T` | `F` | `F` | `F` | `1 000 ms` | `F, F, T` | A `60.5 s` (`> 60 s`) termina mezcla y abre descarga |
| `5` | `T` | `T` | `F` | `F` | `200 ms` | `F, F, F` | `nivelBajo = TRUE` (tanque vacío) cierra descarga y vuelve a reposo |
| `6` | `F` | `F` | `T` | `F` | `200 ms` | `T, F, F` | Nuevo inicio de llenado |
| `7` | `F` | `F` | `F` | `T` | `200 ms` | `F, F, F` | `btnParo` durante llenado apaga todo |
| `8` | `F` | `F` | `T` | `F` | `200 ms` | `T, F, F` | **Enmienda 6:** rearranque desde reposo tras paro |
| `9` | `T` | `F` | `F` | `F` | `500 ms` | `F, T, F` | **Enmienda 6:** entra nuevamente a etapa `MEZCLA` |
| `10` | `T` | `F` | `F` | `T` | `200 ms` | `F, F, F` | **Enmienda 6:** `btnParo` durante `MEZCLA` detiene el motor y vuelve a reposo |
| `11` | `F` | `F` | `F` | `F` | `200 ms` | `F, F, F` | **Enmienda 6:** al soltar `btnParo` permanece en reposo |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..11]` | Paso clave de fallo |
| :--- | :---: | :--- | :---: |
| **Correcta (referencia)** | **`1`** | `[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]` | — |
| Defecto 1: mezcla de `30 s` en vez de `60 s` | **`2`** | `[1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1]` | Paso `3` |
| Defecto 2: salta la etapa de mezcla (pasa directo a descarga) | **`2`** | `[1, 1, 2, 2, 1, 1, 1, 1, 1, 2, 1, 1]` | Paso `2` (y `3`, `9`) |
| Defecto 3: `btnParo` cambia estado pero no apaga salidas | **`2`** | `[1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 2, 1]` | Paso `7` (y `10`) |
| Defecto 4: `btnParo` ignorado en etapa `MEZCLA` (**Enmienda 6**) | **`2`** | `[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2]` | Paso `10` (y `11`) |
| Defecto 5: `btnParo` bloquea el FB permanentemente | **`2`** | `[1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1]` | Paso `8` (y `9`) |

---

### 4.8 Harness `I1` — Semáforo peatonal de 3 fases (`PRG_Test_I1.st`)

- **FB bajo prueba:** `FB_Semaforo`
- **Archivo harness:** `codesys/PRG_Test_I1.st`
- **Enmiendas verificadas:**
  - **Enmienda 2:** en el paso `6` el semáforo queda en `ROJO` antes de deshabilitarlo en el paso `7` (`7 s` de amarillo intermitente) y volver a habilitarlo en el paso `8`, exigiendo que reinicie en `VERDE` y no continúe en `ROJO`.
  - **Enmienda 8:** verifica tanto `fSubida` (`tOff`) como `fBajada` (`tOn`) del amarillo intermitente dentro de `[T#850MS .. T#1150MS]` con `nOn >= 2 AND nOff >= 2`.
  - **Enmienda 11:** banderas `otraLuzPaso0` y `otraLuzPaso7` acumuladas scan a scan detectan si `luzV` o `luzR` se encienden en cualquier instante del modo deshabilitado.
- **Entradas (`VAR_INPUT`):** `habilitado: BOOL`
- **Salidas (`VAR_OUTPUT`):** `luzV: BOOL`, `luzA: BOOL`, `luzR: BOOL`
- **Variables adicionales a monitorear en `PRG_Test_I1`:** `nOn: INT`, `nOff: INT`, `error: BOOL`, `otraLuzPaso0: BOOL`, `otraLuzPaso7: BOOL`.
- **Constantes del harness:** `ULTIMO_PASO = 8` (9 pasos: `0..8`), `TOL_MIN = T#850MS`, `TOL_MAX = T#1150MS`.
- **Duración hasta `terminado = TRUE`:** `70.720 s` (7 072 scans a `10 ms`) | `70.640 s` (17 660 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_I1`
| Paso `i` | `habilitado` | `tEspera` | Condición evaluada | Qué verifica |
| :---: | :---: | :---: | :---: | :--- |
| `0` | `FALSE` | `200 ms` | `NOT luzV AND NOT luzR AND NOT otraLuzPaso0` | **Enmienda 11:** deshabilitado inicial sin verde ni rojo en ningún scan |
| `1` | `TRUE` | `200 ms` | `luzV AND NOT luzA AND NOT luzR` | Al habilitar, arranca en fase `VERDE` |
| `2` | `TRUE` | `20 000 ms` | `NOT luzV AND luzA AND NOT luzR` | Tras `20.2 s` (`> 20 s` de verde), está en `AMARILLO` |
| `3` | `TRUE` | `4 000 ms` | `NOT luzV AND NOT luzA AND luzR` | Tras `4 s` adicionales (`24.2 s`), está en `ROJO` |
| `4` | `TRUE` | `15 000 ms` | `luzV AND NOT luzA AND NOT luzR` | Tras `15 s` adicionales (`39.2 s`), inicia 2.° ciclo en `VERDE` |
| `5` | `TRUE` | `20 000 ms` | `NOT luzV AND luzA AND NOT luzR` | `AMARILLO` del 2.° ciclo (`59.2 s`) |
| `6` | `TRUE` | `4 000 ms` | `NOT luzV AND NOT luzA AND luzR` | **Enmienda 2:** `ROJO` del 2.° ciclo (`63.2 s`) antes de deshabilitar |
| `7` | `FALSE` | `7 000 ms` | `NOT luzV AND NOT luzR AND NOT otraLuzPaso7 AND nOn>=2 AND nOff>=2 AND NOT error` | **Enmiendas 8 y 11:** amarillo intermitente `1 s / 1 s` sin encender `luzV` ni `luzR` en ningún scan |
| `8` | `TRUE` | `200 ms` | `luzV AND NOT luzA AND NOT luzR` | **Enmienda 2:** al rehabilitar desde intermitente, reinicia en `VERDE` |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..8]` | Paso clave de fallo |
| :--- | :---: | :--- | :---: |
| **Correcta (referencia)** | **`1`** | `[1, 1, 1, 1, 1, 1, 1, 1, 1]` | — |
| Defecto 1: tiempos intercambiados (`15 s` verde / `20 s` rojo) | **`2`** | `[1, 1, 2, 1, 1, 2, 1, 1, 1]` | Paso `2` (y `5`) |
| Defecto 2: intermitente a `1.5 s / 1.5 s` en vez de `1 s / 1 s` | **`2`** | `[1, 1, 1, 1, 1, 1, 1, 2, 1]` | Paso `7` |
| Defecto 3: apaga todo cuando `habilitado = FALSE` (sin intermitente) | **`2`** | `[1, 1, 1, 1, 1, 1, 1, 2, 1]` | Paso `7` |
| Defecto 4: alterna amarillo y rojo al deshabilitar (arranca en `R`) | **`2`** | `[2, 1, 1, 1, 1, 1, 1, 2, 1]` | Paso `0` y `7` (`otraLuzPaso7=TRUE`) |
| Defecto 5: alterna amarillo y rojo en fase opuesta (arranca en `A`, **Enmienda 11**) | **`2`** | `[1, 1, 1, 1, 1, 1, 1, 2, 1]` | Paso `7` (`otraLuzPaso7=TRUE`) |
| Defecto 6: al rehabilitar continúa en `ROJO` en vez de reiniciar en `VERDE` (**Enmienda 2**) | **`2`** | `[1, 1, 1, 1, 1, 1, 1, 1, 2]` | Paso `8` |

---

### 4.9 Harness `B5` — Ventilador con post-enfriamiento (`PRG_Test_B5.st`)

- **FB bajo prueba:** `FB_Ventilador`
- **Archivo harness:** `codesys/PRG_Test_B5.st`
- **Enmienda verificada:** **Enmienda 7** (`ULTIMO_PASO` ampliado de `7` a `8`; tras el re-encendido del quemador en el paso `6`, el paso `7` mide `29 s` con `ventilador = TRUE` antes de que el paso `8` verifique el apagado a los `30.2 s`, comprobando que el post-enfriamiento se rearmó a los `30 s` completos).
- **Entradas (`VAR_INPUT`):** `quemadorOn: BOOL`
- **Salidas (`VAR_OUTPUT`):** `ventilador: BOOL`
- **Constantes del harness:** `ULTIMO_PASO = 8` (9 pasos: `0..8`).
- **Duración hasta `terminado = TRUE`:** `71.290 s` (7 129 scans a `10 ms`) | `71.236 s` (17 809 scans a `4 ms`).

#### Secuencia de pasos de `PRG_Test_B5`
| Paso `i` | `quemadorOn` | `tEspera` | Tiempo acum. post-enfriamiento | Condición evaluada | Qué verifica |
| :---: | :---: | :---: | :---: | :---: | :--- |
| `0` | `FALSE` | `200 ms` | — | `ventilador = FALSE` | Reposo inicial con ventilador apagado |
| `1` | `TRUE` | `200 ms` | — | `ventilador = TRUE` | Encendido inmediato con `quemadorOn = TRUE` |
| `2` | `FALSE` | `29 000 ms` | `29.0 s` | `ventilador = TRUE` | A los `29 s` de apagar el quemador (`< 30 s`) sigue encendido |
| `3` | `FALSE` | `1 200 ms` | `30.2 s` | `ventilador = FALSE` | A los `30.2 s` acumulados (`> 30 s`) ya se apagó |
| `4` | `TRUE` | `200 ms` | — | `ventilador = TRUE` | Segundo encendido del quemador |
| `5` | `FALSE` | `10 000 ms` | `10.0 s` | `ventilador = TRUE` | `10 s` en el segundo post-enfriamiento: sigue encendido |
| `6` | `TRUE` | `200 ms` | *(rearme)* | `ventilador = TRUE` | Re-encendido del quemador a mitad del post-enfriamiento |
| `7` | `FALSE` | `29 000 ms` | `29.0 s` | `ventilador = TRUE` | **Enmienda 7:** a los `29 s` del nuevo apagado sigue encendido (rearme completo) |
| `8` | `FALSE` | `1 200 ms` | `30.2 s` | `ventilador = FALSE` | **Enmienda 7:** a los `30.2 s` del nuevo apagado se apaga |

#### Valores esperados en CODESYS (`10 ms` y `4 ms`)
| Variante probada | `veredicto` | `resultado[0..8]` | Paso clave de fallo |
| :--- | :---: | :--- | :---: |
| **Correcta (referencia)** | **`1`** | `[1, 1, 1, 1, 1, 1, 1, 1, 1]` | — |
| Defecto 1: sin post-enfriamiento (`ventilador := quemadorOn`) | **`2`** | `[1, 1, 2, 1, 1, 2, 1, 2, 1]` | Paso `2` |
| Defecto 2: post-enfriamiento de `10 s` en vez de `30 s` | **`2`** | `[1, 1, 2, 1, 1, 2, 1, 2, 1]` | Paso `2` |
| Defecto 3: post-enfriamiento de `60 s` en vez de `30 s` | **`2`** | `[1, 1, 1, 2, 1, 1, 1, 1, 2]` | Paso `3` (y `8`) |
| Defecto 4: usa `TON` en vez de `TOF` | **`2`** | `[1, 2, 2, 1, 2, 2, 2, 2, 1]` | Paso `1` |
| Defecto 5: `TOF` no se rearma tras el primer ciclo | **`2`** | `[1, 1, 1, 1, 1, 2, 1, 2, 1]` | Paso `5` |
| Defecto 6: tras re-encendido en paso `6` solo post-enfría `15 s` (**Enmienda 7**) | **`2`** | `[1, 1, 1, 1, 1, 1, 1, 2, 1]` | Paso `7` |

---

## 5. Registro de Verificación en CODESYS Real

Completa esta tabla conforme termines cada prueba en CODESYS V3.5 SP21:

| Harness | Compila `0 err` (`F11`) | `10 ms` Ref. (`veredicto=1`) | `10 ms` Defecto (`veredicto=2`) | `4 ms` Ref. (`veredicto=1`) | `4 ms` Defecto (`veredicto=2`) | Observaciones en simulador CODESYS |
| :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| `PRG_Test_B1` | [ ] | [ ] | [ ] | [ ] | [ ] | |
| `PRG_Test_B2` | [ ] | [ ] | [ ] | [ ] | [ ] | |
| `PRG_Test_B3` | [ ] | [ ] | [ ] | [ ] | [ ] | |
| `PRG_Test_I6` | [ ] | [ ] | [ ] | [ ] | [ ] | |
| `PRG_Test_B4` | [ ] | [ ] | [ ] | [ ] | [ ] | |
| `PRG_Test_I3` | [ ] | [ ] | [ ] | [ ] | [ ] | |
| `PRG_Test_I5` | [ ] | [ ] | [ ] | [ ] | [ ] | |
| `PRG_Test_I4` | [ ] | [ ] | [ ] | [ ] | [ ] | |
| `PRG_Test_B6` | [ ] | [ ] | [ ] | [ ] | [ ] | |
| `PRG_Test_I2` | [ ] | [ ] | [ ] | [ ] | [ ] | |
| `PRG_Test_I1` | [ ] | [ ] | [ ] | [ ] | [ ] | |
| `PRG_Test_B5` | [ ] | [ ] | [ ] | [ ] | [ ] | |
