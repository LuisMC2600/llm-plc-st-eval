# Enmiendas a la tabla de pasos — aprobación condicionada

La tabla de secuencias de prueba queda **aprobada** con las cuatro enmiendas siguientes.
Aplícalas al escribir los 10 harnesses. Las enmiendas 1 y 2 corrigen fallos de
discriminación verificados por simulación: sin ellas, ciertos bloques defectuosos
pasarían como correctos.

---

## Enmienda 1 — B6 e I1 (intermitente): medir duraciones, no muestrear

**Problema verificado.** Muestrear la lámpara cada 1.1 s y exigir alternancia
`X, NOT X, X` no discrimina: una implementación con `T#1500MS` en lugar de `T#1S`
produce el mismo patrón que la correcta.

| Implementación | Muestras a 1.1 / 2.2 / 3.3 s | ¿Alterna? |
|---|---|---|
| Correcta 1 s / 1 s | OFF, ON, OFF | sí (correcto) |
| Defecto 1.5 s / 1.5 s | ON, OFF, ON | sí → **falso negativo** |
| Defecto 0.5 s / 0.5 s | ON, ON, ON | no (detectado) |
| Defecto 2 s / 2 s | ON, OFF, OFF | no (detectado) |

**Corrección.** Detectar flancos de la salida y cronometrar cada intervalo ON y OFF
completo; exigir 1 s ± 150 ms en ambos. Verificado contra seis implementaciones
sintéticas: discrimina las seis, incluido el caso 1.5/1.5.

Esquema del harness:

```
(* deteccion de flanco de la salida y medicion del intervalo *)
flancoSubida  := lampara AND NOT lamparaPrev;
flancoBajada  := NOT lampara AND lamparaPrev;
lamparaPrev   := lampara;

IF flancoSubida OR flancoBajada THEN
    IF primerFlancoVisto THEN
        duracion := tAcum;                  (* intervalo recien cerrado *)
        IF flancoBajada THEN                (* se cerro un intervalo ON  *)
            okON  := ABS(duracion - 1.0) <= TOL;
        ELSE                                (* se cerro un intervalo OFF *)
            okOFF := ABS(duracion - 1.0) <= TOL;
        END_IF
    END_IF
    primerFlancoVisto := TRUE;
    tAcum := 0;
END_IF
```

Descartar el primer intervalo (parcial, depende de cuándo se activó la alarma) y medir
al menos dos ciclos completos. Ventana de observación: 6 s.

Aplica igual al modo amarillo intermitente de I1, cuyo enunciado también especifica
1 s encendido y 1 s apagado.

---

## Enmienda 2 — I4: dos verificaciones independientes

**Problema verificado.** La comprobación de solapamiento (`kY AND kD`) detecta el
solapamiento, pero **no** detecta la ausencia de tiempo muerto: si `kY` cae y `kD` sube
en el mismo instante, no existe ningún scan con ambas en TRUE y la violación pasa
inadvertida.

| Escenario | ¿Bandera de solapamiento? | ¿Se detecta el defecto? |
|---|---|---|
| Correcto: 100 ms de tiempo muerto | no | — |
| Defecto: solapamiento de 40 ms | sí | sí |
| Defecto: tiempo muerto de 0 ms | **no** | **no, sin la 2.ª verificación** |

**Corrección.** Implementar las dos por separado:

1. **Seguridad (continua):** `IF kY AND kD THEN violacionInterlock := TRUE; END_IF`
   evaluada en cada scan, enclavada hasta el final del banco.
2. **Tiempo muerto (medida):** cronometrar el intervalo entre la caída de `kY` y la
   subida de `kD`; exigir ≥ 100 ms. Registrar el valor medido, no solo el veredicto.

---

## Enmienda 3 — Ciclo de la MainTask

El valor por defecto de 20 ms deja solo 5 scans dentro del tiempo muerto de 100 ms de
I4, insuficiente para la resolución que requiere la enmienda 2.

**Fijar el ciclo de la MainTask en 4–10 ms** para todos los proyectos de verificación,
y anotarlo en la bitácora: es un parámetro del entorno experimental y debe declararse
en la metodología del informe, igual que la temperatura de generación.

---

## Enmienda 4 — Banderas de seguridad enclavadas (B4 e I4)

La propiedad «nunca ambas salidas activas» debe evaluarse **en cada scan** y quedar
**enclavada**: una vez violada permanece TRUE hasta el final del banco. Si solo se
comprueba en los puntos de evaluación de cada paso, una violación transitoria entre
dos evaluaciones pasa inadvertida.

- B4: `IF fwd AND rev THEN violacionInterlock := TRUE; END_IF`
- I4: `IF kY AND kD THEN violacionInterlock := TRUE; END_IF`

El veredicto final exige, además de superar todos los pasos, que la bandera esté en
FALSE. Registrarla como columna propia en el CSV de resultados: una violación de
seguridad es cualitativamente distinta de un fallo funcional y conviene poder
contarlas por separado en los resultados.

---

## Corrección de la estimación de tiempos

La estimación preliminar contaba solo la espera dominante de cada tarea. Los totales
reales son mayores porque varias secuencias repiten ciclos completos:

| Tarea | Estimación previa | Estimación corregida | Motivo |
|---|---|---|---|
| I2 | ~61 s | ~90 s | el paro se prueba en dos fases distintas, cada una exige volver a entrar en la fase |
| I1 | ~43 s | ~90 s | ciclo completo (39 s) + intermitente + rehabilitación |
| B5 | ~30 s | ~70 s | reactivación durante el post-enfriamiento exige un segundo ciclo |

Total del piloto: aproximadamente **1 hora** de simulación desatendida para las 144
respuestas. Sigue siendo holgado frente a las ~24 horas de verificación manual.

---

## Aprobado sin cambios

El resto de la tabla queda aprobado tal cual. En particular, estos pasos atacan
correctamente el defecto probable de cada lógica y conviene conservarlos:

- **B3:** mantener el sensor alto varios ciclos (distingue conteo por flanco de conteo por nivel).
- **B4:** solicitar `btnRev` sin pasar por paro, y pulsar ambas órdenes a la vez.
- **B5:** reactivar el quemador durante el post-enfriamiento.
- **I3:** ACK con la causa todavía presente (no debe borrar) y ACK tras retirarla (sí debe).
- **I5:** pieza baja con presencia sostenida, para verificar que no cuenta por nivel.
- **I6:** punto a 77 °C dentro de la banda de histéresis, comprobado en ambos sentidos.
