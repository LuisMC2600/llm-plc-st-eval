# Fuentes consolidadas — 12 tareas del piloto

Archivo autoritativo para la fase de verificación en CODESYS. Reúne, por tarea:
el enunciado exacto enviado al modelo (zero-shot), el POU y las variables E/S,
el criterio de éxito funcional del banco, y la plantilla de harness que corresponde.

Generado desde `tasks.json` y `fuentes/Banco_de_Pruebas_v0.xlsx`. No editar a mano.

| ID | POU | Temporizadores | Plantilla de harness |
|----|-----|----------------|----------------------|
| B1 | FUNCTION_BLOCK FB_Motor | — | PRG_Test_B1.st (sin temporizadores) |
| B2 | FUNCTION_BLOCK FB_Valvula | T#5S | PRG_Test_B2.st (con temporizadores) |
| B3 | FUNCTION_BLOCK FB_Contador | — | PRG_Test_B1.st (sin temporizadores) |
| B4 | FUNCTION_BLOCK FB_Giro | — | PRG_Test_B1.st (sin temporizadores) |
| B5 | FUNCTION_BLOCK FB_Ventilador | T#30S | PRG_Test_B2.st (con temporizadores) |
| B6 | FUNCTION_BLOCK FB_Baliza | T#1S | PRG_Test_B2.st (con temporizadores) |
| I1 | FUNCTION_BLOCK FB_Semaforo | T#15S, T#1S, T#20S, T#4S | PRG_Test_B2.st (con temporizadores) |
| I2 | FUNCTION_BLOCK FB_Llenado | T#60S | PRG_Test_B2.st (con temporizadores) |
| I3 | FUNCTION_BLOCK FB_Alarmas | — | PRG_Test_B1.st (sin temporizadores) |
| I4 | FUNCTION_BLOCK FB_EstrellaTriangulo | T#100MS, T#8S | PRG_Test_B2.st (con temporizadores) |
| I5 | FUNCTION_BLOCK FB_Clasificadora | T#1S, T#2S | PRG_Test_B2.st (con temporizadores) |
| I6 | FUNCTION_BLOCK FB_Temperatura | — | PRG_Test_B1.st (sin temporizadores) |

---

## B1 — Arranque/paro de motor con enclavamiento

- **Nivel:** Básico
- **POU exigido:** `FUNCTION_BLOCK FB_Motor`
- **Variables E/S (del banco):** btnMarcha, btnParo, btnEmerg: BOOL → motorOn: BOOL
- **Constructos evaluados:** IF, enclavamiento booleano
- **Tiempos IEC del enunciado:** ninguno
- **Plantilla de harness:** `PRG_Test_B1.st (sin temporizadores)`
- **Práctica de laboratorio equivalente:** Práctica 1 clásica de todo curso de PLC.

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Motor arranca con pulso de marcha, se mantiene, cae con paro o E-stop; nunca rearranca solo tras E-stop.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa el control de arranque y paro de un motor trifásico. El motor debe arrancar al pulsar el botón de marcha y mantenerse encendido al soltarlo. Debe detenerse al pulsar el botón de paro o el paro de emergencia; tras un paro de emergencia el motor no debe rearrancar aunque el botón de marcha siga pulsado. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Motor con variables de entrada btnMarcha, btnParo, btnEmerg (BOOL) y salida motorOn (BOOL). Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```

---

## B2 — Válvula con retardo TON

- **Nivel:** Básico
- **POU exigido:** `FUNCTION_BLOCK FB_Valvula`
- **Variables E/S (del banco):** nivelAlto: BOOL → valvula: BOOL; T#5s
- **Constructos evaluados:** TON, IF
- **Tiempos IEC del enunciado:** T#5S
- **Plantilla de harness:** `PRG_Test_B2.st (con temporizadores)`
- **Práctica de laboratorio equivalente:** Práctica de temporizadores.

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Válvula abre solo tras 5 s continuos de nivel alto; cierra sin retardo al caer la señal.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa el control de una válvula de drenaje de un tanque. Cuando el sensor de nivel alto se active y permanezca activo durante 5 segundos continuos, la válvula debe abrir. Si el nivel deja de estar alto, la válvula debe cerrar de inmediato, sin retardo. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Valvula con variable de entrada nivelAlto (BOOL) y salida valvula (BOOL). Usa el tiempo T#5S. Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```

---

## B3 — Contador de piezas con preset

- **Nivel:** Básico
- **POU exigido:** `FUNCTION_BLOCK FB_Contador`
- **Variables E/S (del banco):** sensorPieza, btnReset: BOOL → loteListo: BOOL; cuenta: INT
- **Constructos evaluados:** CTU, R_TRIG
- **Tiempos IEC del enunciado:** ninguno
- **Plantilla de harness:** `PRG_Test_B1.st (sin temporizadores)`
- **Práctica de laboratorio equivalente:** Práctica de contadores.

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Cuenta solo flancos ascendentes; loteListo en cuenta≥12; reset pone cuenta en 0.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa el conteo de piezas de una línea de producción. Cada vez que el sensor fotoeléctrico detecte una pieza (transición de FALSE a TRUE), la cuenta debe incrementarse en uno. Al llegar a 12 piezas debe activarse la salida de lote completo. Un botón de reset pone la cuenta en cero y desactiva la salida de lote. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Contador con variables de entrada sensorPieza, btnReset (BOOL) y salidas loteListo (BOOL) y cuenta (INT). Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```

---

## B4 — Inversión de giro con enclavamiento cruzado

- **Nivel:** Básico
- **POU exigido:** `FUNCTION_BLOCK FB_Giro`
- **Variables E/S (del banco):** btnFwd, btnRev, btnParo: BOOL → fwd, rev: BOOL
- **Constructos evaluados:** IF, interlock
- **Tiempos IEC del enunciado:** ninguno
- **Plantilla de harness:** `PRG_Test_B1.st (sin temporizadores)`
- **Práctica de laboratorio equivalente:** Práctica de inversión de giro (arrancadores).

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Nunca fwd AND rev; inversión solo pasando por paro.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa la inversión de giro de un motor. Con el botón btnFwd el motor gira en sentido horario (salida fwd); con btnRev, en sentido antihorario (salida rev). Ambas salidas jamás deben estar activas simultáneamente y, para invertir el sentido de giro, es obligatorio pasar primero por el paro (btnParo). Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Giro con variables de entrada btnFwd, btnRev, btnParo (BOOL) y salidas fwd, rev (BOOL). Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```

---

## B5 — Ventilador con retardo a la desconexión

- **Nivel:** Básico
- **POU exigido:** `FUNCTION_BLOCK FB_Ventilador`
- **Variables E/S (del banco):** quemadorOn: BOOL → ventilador: BOOL; T#30s
- **Constructos evaluados:** TOF
- **Tiempos IEC del enunciado:** T#30S
- **Plantilla de harness:** `PRG_Test_B2.st (con temporizadores)`
- **Práctica de laboratorio equivalente:** Práctica de TOF / post-enfriamiento.

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Ventilador acompaña al quemador y se apaga 30 s después del paro.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa el ventilador de enfriamiento de un horno. Mientras el quemador esté encendido, el ventilador debe funcionar. Al apagarse el quemador, el ventilador debe continuar funcionando 30 segundos adicionales y luego detenerse. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Ventilador con variable de entrada quemadorOn (BOOL) y salida ventilador (BOOL). Usa el tiempo T#30S. Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```

---

## B6 — Baliza intermitente

- **Nivel:** Básico
- **POU exigido:** `FUNCTION_BLOCK FB_Baliza`
- **Variables E/S (del banco):** alarma: BOOL → lampara: BOOL
- **Constructos evaluados:** 2×TON en oscilador
- **Tiempos IEC del enunciado:** T#1S
- **Plantilla de harness:** `PRG_Test_B2.st (con temporizadores)`
- **Práctica de laboratorio equivalente:** Práctica de osciladores con temporizadores.

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Ciclo estable de 1 s / 1 s solo con alarma activa.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa una baliza de alarma. Mientras la condición de alarma esté activa, la lámpara debe parpadear con un ciclo de 1 segundo encendida y 1 segundo apagada. Sin alarma, la lámpara permanece apagada. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Baliza con variable de entrada alarma (BOOL) y salida lampara (BOOL). Usa tiempos T#1S. Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```

---

## I1 — Semáforo con secuencia temporizada

- **Nivel:** Intermedio
- **POU exigido:** `FUNCTION_BLOCK FB_Semaforo`
- **Variables E/S (del banco):** habilitado: BOOL → luzV, luzA, luzR: BOOL
- **Constructos evaluados:** FSM con CASE, TON
- **Tiempos IEC del enunciado:** T#15S, T#1S, T#20S, T#4S
- **Plantilla de harness:** `PRG_Test_B2.st (con temporizadores)`
- **Práctica de laboratorio equivalente:** Práctica clásica de FSM.

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Secuencia y tiempos exactos; modo intermitente al deshabilitar.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa un semáforo vehicular cíclico: verde 20 segundos, amarillo 4 segundos, rojo 15 segundos, repitiendo la secuencia indefinidamente mientras la entrada habilitado esté activa. Si habilitado se desactiva, el semáforo debe pasar a amarillo intermitente (1 segundo encendido, 1 segundo apagado) con las demás luces apagadas; al habilitarse de nuevo, la secuencia reinicia en verde. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Semaforo con variable de entrada habilitado (BOOL) y salidas luzV, luzA, luzR (BOOL). Usa los tiempos T#20S, T#4S, T#15S y T#1S. Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```

---

## I2 — FSM de llenado multietapa

- **Nivel:** Intermedio
- **POU exigido:** `FUNCTION_BLOCK FB_Llenado`
- **Variables E/S (del banco):** nivelAlto, nivelBajo, btnInicio, btnParo: BOOL → vLlenado, motorMezcla, vDescarga: BOOL
- **Constructos evaluados:** FSM (CASE), TON, enum/INT de estado
- **Tiempos IEC del enunciado:** T#60S
- **Plantilla de harness:** `PRG_Test_B2.st (con temporizadores)`
- **Práctica de laboratorio equivalente:** Proyecto parcial típico de laboratorio.

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Estados en orden correcto; paro lleva a estado seguro definido; sin estados muertos.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa un proceso de llenado por etapas. En reposo, al pulsar btnInicio se abre la válvula de llenado (vLlenado) hasta que se active nivelAlto; después funciona el motor de mezcla (motorMezcla) durante 60 segundos; después se abre la válvula de descarga (vDescarga) hasta que se active nivelBajo; finalmente el proceso vuelve a reposo. El botón btnParo detiene el proceso en cualquier etapa, lleva todas las salidas a estado seguro (desactivadas) y regresa el proceso a reposo. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Llenado con variables de entrada nivelAlto, nivelBajo, btnInicio, btnParo (BOOL) y salidas vLlenado, motorMezcla, vDescarga (BOOL). Usa el tiempo T#60S. Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```

---

## I3 — Gestión de alarmas con prioridad

- **Nivel:** Intermedio
- **POU exigido:** `FUNCTION_BLOCK FB_Alarmas`
- **Variables E/S (del banco):** alm1..alm3, ack1..ack3: BOOL → sirena: BOOL, codigoAlm: INT
- **Constructos evaluados:** Arreglos/STRUCT, IF, flancos
- **Tiempos IEC del enunciado:** ninguno
- **Plantilla de harness:** `PRG_Test_B1.st (sin temporizadores)`
- **Práctica de laboratorio equivalente:** Práctica de señalización/HMI.

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Prioridad respetada; alarma retenida hasta ACK aun si la causa desaparece.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa la gestión de tres alarmas con prioridad: alm1 es de prioridad alta, alm2 media y alm3 baja. Cualquier alarma activa enciende la sirena. La salida codigoAlm debe reportar el número de la alarma de mayor prioridad presente (1, 2 o 3; 0 si no hay alarmas). Cada alarma debe quedar retenida (aunque su causa desaparezca) hasta que se reconozca individualmente con ack1, ack2 o ack3, respectivamente; el reconocimiento solo tiene efecto si la causa ya desapareció. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Alarmas con variables de entrada alm1, alm2, alm3, ack1, ack2, ack3 (BOOL) y salidas sirena (BOOL) y codigoAlm (INT). Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```

---

## I4 — Arranque estrella-triángulo

- **Nivel:** Intermedio
- **POU exigido:** `FUNCTION_BLOCK FB_EstrellaTriangulo`
- **Variables E/S (del banco):** btnMarcha, btnParo: BOOL → kM, kY, kD: BOOL
- **Constructos evaluados:** TON×2, FSM corta, interlock
- **Tiempos IEC del enunciado:** T#100MS, T#8S
- **Plantilla de harness:** `PRG_Test_B2.st (con temporizadores)`
- **Práctica de laboratorio equivalente:** Práctica de arrancadores reducidos.

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Nunca kY AND kD; tiempo muerto respetado; paro en cualquier momento.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa un arranque estrella-triángulo. Al pulsar btnMarcha se activan el contactor principal kM y el contactor de estrella kY. Después de 8 segundos se desactiva kY, se espera un tiempo muerto de 100 milisegundos y se activa el contactor de triángulo kD. Las salidas kY y kD jamás deben estar activas simultáneamente. El botón btnParo desactiva todos los contactores en cualquier momento. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_EstrellaTriangulo con variables de entrada btnMarcha, btnParo (BOOL) y salidas kM, kY, kD (BOOL). Usa los tiempos T#8S y T#100MS. Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```

---

## I5 — Banda con clasificación por sensores

- **Nivel:** Intermedio
- **POU exigido:** `FUNCTION_BLOCK FB_Clasificadora`
- **Variables E/S (del banco):** sensorPresencia, sensorAltura: BOOL → banda, piston: BOOL; nAltas, nBajas: INT
- **Constructos evaluados:** TON, CTU×2, secuencia
- **Tiempos IEC del enunciado:** T#1S, T#2S
- **Plantilla de harness:** `PRG_Test_B2.st (con temporizadores)`
- **Práctica de laboratorio equivalente:** Práctica con módulo de banda (Fischertechnik/festo).

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Desvío sincronizado con la pieza correcta; conteos exactos.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa una banda transportadora clasificadora. La banda funciona continuamente (salida banda activa). El sensor sensorPresencia detecta el paso de cada pieza; si en ese momento sensorAltura está activo, la pieza es alta y debe desviarse: el pistón (salida piston) debe activarse durante 1 segundo, comenzando 2 segundos después de la detección (tiempo que tarda la pieza en llegar al desviador). Contar las piezas altas en nAltas y las bajas en nBajas. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Clasificadora con variables de entrada sensorPresencia, sensorAltura (BOOL) y salidas banda, piston (BOOL) y nAltas, nBajas (INT). Usa los tiempos T#2S y T#1S. Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```

---

## I6 — Escalado analógico con histéresis

- **Nivel:** Intermedio
- **POU exigido:** `FUNCTION_BLOCK FB_Temperatura`
- **Variables E/S (del banco):** rawTemp: INT → tempC: REAL, enfriador, almSensor: BOOL
- **Constructos evaluados:** Aritmética REAL, IF, histéresis
- **Tiempos IEC del enunciado:** ninguno
- **Plantilla de harness:** `PRG_Test_B1.st (sin temporizadores)`
- **Práctica de laboratorio equivalente:** Práctica de señales analógicas.

### Criterio de éxito funcional (de aquí se derivan los pasos del harness)

> Escalado correcto; conmutación solo en umbrales; sin oscilación entre 75-80.

### Enunciado exacto enviado al modelo (zero-shot)

```text
Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3.

Tarea: programa el acondicionamiento y control de una señal de temperatura. La entrada rawTemp entrega un valor entero de 0 a 27648 proporcional a 0.0–100.0 grados Celsius; calcula la temperatura en la salida tempC. El enfriador debe activarse cuando tempC sea mayor o igual a 80.0 y desactivarse cuando sea menor o igual a 75.0 (histéresis: entre ambos umbrales conserva su estado, sin oscilar). Si rawTemp es menor que 0 o mayor que 27648, debe activarse almSensor y desactivarse el enfriador. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Temperatura con variable de entrada rawTemp (INT) y salidas tempC (REAL), enfriador (BOOL) y almSensor (BOOL). Entrega únicamente el código, con la declaración completa de variables y comentarios breves.
```
