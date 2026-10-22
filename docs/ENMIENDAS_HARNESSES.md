# Enmiendas a la tabla de pasos — aprobación condicionada

La tabla de secuencias de prueba queda **aprobada** con las trece enmiendas siguientes.
Aplícalas al escribir los 10 harnesses. Las enmiendas 5 a 13 se añadieron el 9 de
septiembre de 2026, al validar por simulación los nueve harnesses que estaban
sin validar. **Los nueve tenían al menos un defecto.** Las enmiendas 1 y 2 corrigen fallos de
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

## Enmienda 5 — I4: la implementación de la enmienda 2 tenía tres fallos

**Cómo se detectó.** Al escribir `codesys/validar_harness_I4.py` y ejecutar el harness
contra una implementación correcta y cuatro defectuosas, la implementación **correcta
resultó reprobada en los tres ciclos de tarea**. Es el mismo patrón que ya había
ocurrido con B3: un banco aparentemente correcto que reprueba al 100 % de las
implementaciones válidas.

| Fallo | Qué hacía | Consecuencia |
|---|---|---|
| 1 | El paso 2 esperaba 500 ms tras el paso 1 y exigía `NOT kD` | A los 8,3 s una implementación correcta ya tiene el triángulo dentro desde los 8,1 s. Residuo del muestreo que la enmienda 2 había descartado |
| 2 | `resetMed := TRUE` reiniciaba el cronómetro un ciclo tarde | La medida contaba de menos alrededor de un scan: 100 ms reales se medían como 96 ms (ciclo de 4 ms) u 80 ms (20 ms), contra un umbral estricto de 100 ms |
| 3 | Si `kY` caía y `kD` subía en el **mismo scan**, ambas condiciones se cumplían en ese ciclo y la medida leía el cronómetro sin reiniciar | Registraba **8 208 ms** de tiempo muerto y daba por bueno el defecto de 0 ms, que es exactamente el que la enmienda 2 persigue |

El fallo 3 es el más grave porque anulaba el propósito de la enmienda 2: el defecto de
tiempo muerto nulo pasaba la verificación de medida y, al no producir solapamiento,
tampoco lo veía la bandera de interlock. Solo se reprobaba de rebote, por el fallo 1.

**Corrección.** El tiempo muerto se mide por **diferencia de dos lecturas de un
cronómetro libre** que nunca se reinicia: se guarda `tCrono.ET` en la caída de `kY` y se
resta de `tCrono.ET` en la subida de `kD`. Eso elimina el retraso de un ciclo y hace que
el caso simultáneo mida 0 ms por construcción, sin necesidad de un caso especial. El
paso 2 pasa a comprobar que la transición se completó (`kM AND NOT kY AND kD`) y el
instante exacto queda a cargo de la medida en el paso 3.

**Umbral con tolerancia de un scan.** La cuantización del ciclo de scan es inevitable,
así que el umbral pasa de `>= T#100MS` a `>= T#90MS`: los 100 ms del enunciado menos un
ciclo de MainTask de hasta 10 ms (enmienda 3). Esta tolerancia es un parámetro del
entorno experimental y debe declararse en la metodología, igual que el ciclo de tarea.

**Evidencia tras la corrección** (`python validar_harness_I4.py`, salida completa en el
propio script): la implementación correcta obtiene veredicto 1 con tiempo muerto medido
de 100–110 ms en los ciclos de 4, 10 y 20 ms; los cuatro defectos obtienen veredicto 2
en el paso esperado; y la bandera de interlock se activa únicamente en el caso de
solapamiento, lo que confirma que las dos verificaciones de la enmienda 2 son
independientes y que ambas hacen falta.

**Alcance.** Esta enmienda corrige `PRG_Test_I4.st`. Los ocho harnesses que siguen sin
validar (B4, B5, B6, I1, I2, I3, I5, I6) pueden arrastrar defectos del mismo tipo:
ninguno debe usarse para recolectar datos antes de pasar por su validador.

---

## Enmienda 6 — B6: el muestreo del paso de reposo repetía el error de la enmienda 1

**Cómo se detectó.** `codesys/validar_harness_B6.py` dio **veredicto 1 a una
implementación que seguía parpadeando después de retirarse la alarma**. El resto del
harness funcionaba: el caso de 1,5 s / 1,5 s, que es el falso negativo que motivó la
enmienda 1, quedaba correctamente reprobado, igual que los casos de 0,5 s, el
asimétrico y el que no parpadea; y las dos lecturas defendibles del enunciado —el
oscilador que arranca encendido y el que arranca apagado— pasaban ambas.

**Causa.** El paso 2 esperaba 200 ms y comprobaba la lámpara en un **único instante**.
La salida defectuosa es periódica, así que sorprenderla encendida o apagada depende de
la fase en ese instante concreto; en la simulación caía sistemáticamente en un tramo
apagado y el defecto pasaba como bueno en los tres ciclos de tarea.

Es el mismo error de muestreo que la enmienda 1 corrigió para el paso de observación,
sin corregirse también en los pasos de reposo. La lección se generaliza: **ante una
salida periódica, ningún criterio puede apoyarse en una sola lectura instantánea**.

**Corrección.** Se aplica la lógica de la enmienda 4: la condición se evalúa en cada
scan y queda enclavada en `lamparaEnPaso0` y `lamparaEnPaso2`, y la ventana del paso 2
pasa de 200 ms a **2,5 s**, más de dos períodos nominales completos. Cualquier parpadeo
indebido con semiperíodo por debajo de unos 2,5 s queda así registrado.

**Unificación de la medida.** Se adopta además en B6 el método de la enmienda 5:
diferencia de dos lecturas de un cronómetro libre en lugar de reiniciar un temporizador
con un ciclo de retraso. Con la tolerancia de ±150 ms el sesgo anterior no llegaba a ser
un defecto, pero era medible: con ciclo de 20 ms los intervalos se medían en 0,96–0,98 s
y ahora se miden en 1,00 s. No hay razón para conservar un sesgo conocido.

**Evidencia tras la corrección** (`python validar_harness_B6.py`): las dos
implementaciones correctas obtienen veredicto 1 y los cinco defectos veredicto 2, cada
uno en su paso, idéntico con 4, 10 y 20 ms.

**Coste en tiempo.** La secuencia de B6 pasa de 7,4 s a 9,7 s por respuesta evaluada.
Sobre las 24 respuestas de B6 del experimento definitivo son unos 55 s adicionales,
irrelevantes frente al total.

---

## Enmienda 7 — B5: el segundo ciclo de post-enfriamiento nunca se recorría

**Cómo se detectó.** `codesys/validar_harness_B5.py` dio **veredicto 1 a una
implementación que rearmaba el temporizador pero solo a 15 s** en lugar de 30 s. El
primer post-enfriamiento era correcto, así que los pasos 2 y 3 pasaban; el segundo
duraba la mitad y nadie lo miraba.

**Causa.** La secuencia reactivaba el quemador en el último paso y terminaba ahí.
Comprobaba que el temporizador se rearmaba —eso sí lo detectaba, en el paso 5—, pero
nunca que se rearmara a los **30 s completos**, porque el segundo post-enfriamiento no
se llegaba a recorrer. El paso final, además, no discriminaba nada: cualquier
implementación que superase el paso 1 lo superaba también.

La propia corrección de tiempos de este documento ya anticipaba el problema al estimar
B5 en ~70 s *«porque la reactivación durante el post-enfriamiento exige un segundo
ciclo»*. La secuencia real duraba **41 s**: ese segundo ciclo nunca se había
implementado.

**Corrección.** Tras la reactivación se añaden dos pasos que recorren el segundo
post-enfriamiento completo, con la misma pareja de comprobaciones que el primero: a los
29 s debe seguir encendido, a los 30,2 s debe estar apagado. La secuencia pasa a durar
**71,2 s**, acorde con la estimación.

**Evidencia tras la corrección** (`python validar_harness_B5.py`): la implementación
correcta obtiene veredicto 1 y los seis defectos veredicto 2 —sin post-enfriamiento,
10 s, 60 s, TON en vez de TOF, sin rearme, y rearme a 15 s—, idéntico con 4, 10 y 20 ms.

---

## Enmienda 8 — I1: dos defectos pasaban como correctos

**Cómo se detectó.** `codesys/validar_harness_I1.py` dio **veredicto 1 a dos
implementaciones defectuosas distintas**.

**Fallo 1: «las demás luces apagadas» se muestreaba en un instante.** Una implementación
que resuelve el intermitente alternando **amarillo y rojo** —error plausible: parpadear
entre el amarillo y la última luz activa— deja el rojo en antifase con el amarillo, de
modo que en el instante muestreado las demás están apagadas. Verificado: con el parpadeo
arrancando en amarillo encendido el defecto obtiene veredicto 1 en los tres ciclos de
tarea; con la fase contraria solo se detecta de rebote en el paso 0, es decir por suerte
de fase y no por mérito del banco. Es el mismo error de la enmienda 6.

**Fallo 2: el reinicio en verde no se estaba probando.** La secuencia deshabilitaba el
semáforo **mientras estaba en verde**, así que al rehabilitar una implementación que
reinicia y otra que continúa donde se quedó muestran exactamente lo mismo. Verificado: el
defecto «no reinicia» obtenía veredicto 1 en los tres ciclos. Para probar el reinicio hay
que interrumpir en una fase que **no** sea verde.

**Corrección.** La vigilancia de las luces verde y roja en los pasos deshabilitados pasa
a ser continua y enclavada (enmienda 6); y la secuencia recorre un **segundo ciclo hasta
el rojo** antes de deshabilitar, de modo que el reinicio en verde sea observable. Se
unifica además la medida de intervalos con el método de la enmienda 5. La secuencia pasa
de 46,6 s a **70,6 s**, dentro de la estimación de ~90 s.

**Evidencia tras la corrección** (`python validar_harness_I1.py`): la implementación
correcta obtiene veredicto 1 y los seis defectos veredicto 2 —tiempos intercambiados,
intermitente de 1,5 s, sin intermitente, intermitente con rojo en sus dos fases, y sin
reinicio—, idéntico con 4, 10 y 20 ms.

---

## Enmienda 9 — B4: la bandera de interlock no llegaba a dispararse nunca

**Cómo se detectó.** `codesys/validar_harness_B4.py` dio **veredicto 1, y sin levantar la
bandera**, a una implementación con una **carrera de interlock**: el enclavamiento cruzado
se evaluaba contra el valor de la otra salida en el scan *anterior*. Con el motor ya
girando se comporta bien, pero al pulsar las dos órdenes estando en reposo ambas salidas
se activan a la vez durante un scan.

**Causa.** La secuencia solo pulsaba las dos órdenes con el motor ya girando en reversa,
situación en la que la salida activa bloquea a la otra incluso con la comparación
retrasada. Nunca las pulsaba **desde el reposo**, que es el único caso en que la carrera
se manifiesta.

Es un fallo de **cobertura, no del mecanismo**: la enmienda 4 dejó el instrumento capaz
de detectar la violación transitoria, y el harness la evaluaba correctamente en cada scan
y la enclavaba. Pero una bandera enclavada solo puede atrapar lo que la secuencia
provoca, y la secuencia no la provocaba.

**Corrección.** Se añaden dos pasos que pulsan ambas órdenes desde el reposo. El paso 8
no exige un sentido concreto —el enunciado no dice cuál debe ganar si se piden los dos a
la vez— sino únicamente que no coexistan.

**Evidencia tras la corrección** (`python validar_harness_B4.py`): la implementación
correcta obtiene veredicto 1 y los cuatro defectos veredicto 2; la bandera se levanta
exactamente en los dos casos que violan el interlock, idéntico con 4, 10 y 20 ms.

---

## Enmienda 10 — I2: reprobaba lo correcto y solo probaba una de las dos fases del paro

**Cómo se detectó.** `codesys/validar_harness_I2.py` reveló dos fallos a la vez.

**Fallo 1: el paso «antes de los 60 s» reprobaba a la implementación correcta** en los
tres ciclos de tarea. Esperaba 59 800 ms contando desde el inicio de ese paso, pero la
mezcla no arranca ahí: arranca unos 200 ms antes, en el paso anterior, en cuanto el
bloque ve `nivelAlto`. El margen resultante era nulo y la evaluación caía justo en el
instante en que la mezcla termina, de modo que se observaba ya la descarga. Es el mismo
error que la enmienda 5 corrigió en I4: **una ventana calculada como si la fase empezara
en el límite del paso, cuando empieza antes**.

**Fallo 2: el último paso, etiquetado «paro en mezcla», nunca llegaba a la mezcla.**
Aplicaba `nivelAlto` y `btnParo` en el **mismo** paso, así que el paro alcanzaba al bloque
todavía en llenado: era un duplicado del paso anterior. Verificado: una implementación
cuyo paro funciona en llenado pero no durante la mezcla obtenía exactamente el mismo
resultado que la correcta. El paro en dos fases que este banco dice comprobar solo se
comprobaba en una.

La corrección de tiempos de este documento ya lo insinuaba al estimar I2 en ~90 s *«el
paro se prueba en dos fases distintas, cada una exige volver a entrar en la fase»*: la
secuencia real duraba 61,9 s porque esa segunda entrada nunca se hacía. Es la misma
señal que delató a B5 en la enmienda 7.

**Corrección.** La ventana de la mezcla pasa a tener margen explícito y simétrico de
0,5 s a cada lado de los 60 s, lo que además fija la tolerancia de discriminación. Y
entrar en la mezcla y aplicar el paro pasan a ser dos pasos separados, de modo que el
paro alcance al bloque realmente mezclando. Se añade un paso final que comprueba que tras
el paro el proceso permanece en reposo y no rearranca solo.

**Evidencia tras la corrección** (`python validar_harness_I2.py`): la implementación
correcta supera los doce pasos y los cinco defectos obtienen veredicto 2 en su paso,
idéntico con 4, 10 y 20 ms.

---

## Enmienda 11 — I5: tercera aparición del error de origen de la ventana

**Cómo se detectó.** `codesys/validar_harness_I5.py` reprobaba a la implementación
correcta en los tres ciclos de tarea.

**Causa.** El paso que decía comprobar «antes de 2 s» esperaba 1 800 ms contando desde su
propio inicio, pero la detección de la pieza alta ocurre 200 ms antes, en el paso
anterior. El tiempo efectivo desde la detección era de 2 000 ms exactos —justo el
instante en que el pistón se activa— y la evaluación lo encontraba ya activado.

Es el **tercer caso del mismo error**, tras I4 (enmienda 5) e I2 (enmienda 10). Conviene
enunciarlo como regla general: *el tiempo de una ventana se cuenta desde el evento que la
origina, no desde el paso en que se escribe.*

**Corrección.** Las tres ventanas del desvío se recalculan tomando como origen la
detección real, con margen explícito de 0,3 s a 0,5 s respecto a los flancos del pulso.
La secuencia sigue durando 4,0 s y ahora discrimina un retardo de 1,5 s, la ausencia de
retardo, un pulso de 2 s y el desvío indebido de las piezas bajas.

---

## Enmienda 12 — I3: el paso que este documento aprobaba no estaba implementado

**Cómo se detectó.** `codesys/validar_harness_I3.py` dio **veredicto 1 a una
implementación cuyo ACK borraba la alarma aunque la causa siguiera presente** —la
violación directa de la regla central del enunciado—. Los nueve pasos daban exactamente
el mismo resultado que con la implementación correcta.

**Causa.** En toda la secuencia no había un solo instante en que una entrada `ackN`
estuviera activa a la vez que su `almN`. Los reconocimientos se aplicaban siempre con la
causa ya retirada, de modo que la mitad de la regla no se ejercitaba nunca.

Lo notable es que **este mismo documento ya aprobaba ese paso** en su lista de secuencias
conservadas: *«I3: ACK con la causa todavía presente (no debe borrar) y ACK tras
retirarla (sí debe)»*. El paso estaba aprobado en el documento y ausente en el banco.

**Corrección.** Se añade un paso que aplica `ack3` con `alm3` todavía activa y exige que
la alarma no se borre. La secuencia pasa de 9 a 10 pasos.

---

## Enmienda 13 — I6: la alarma se probaba con el enfriador ya apagado

**Cómo se detectó.** `codesys/validar_harness_I6.py` dio **veredicto 1 a una
implementación que activaba la alarma pero no desactivaba el enfriador**, incumpliendo la
última frase del enunciado.

**Causa.** Los dos pasos de fuera de rango estaban al final de la secuencia, cuando el
enfriador llevaba ya tres pasos apagado. La condición «y se desactiva el enfriador» se
evaluaba sobre una salida que ya estaba en el valor esperado. Para observar que la alarma
*apaga* el enfriador hay que provocarla con el enfriador **encendido**.

**Corrección.** El primer paso de fuera de rango se adelanta y pasa a aplicarse justo
después de la banda de histéresis, con el enfriador encendido. La secuencia conserva sus
ocho pasos y sigue cubriendo los dos sentidos de la histéresis y los dos límites del
rango.

---

## Las dos familias de fallo, y cómo buscarlas

Los nueve harnesses validados el 9 de septiembre de 2026 tenían defectos de solo dos
tipos. Sirve como lista de comprobación para cualquier banco que se escriba en adelante.

**Familia A — muestreo de algo que no es estable en ese instante.** Un criterio se apoya
en una única lectura instantánea de una señal periódica o en transición. Aparece en las
enmiendas 1 (B6, intermitente), 6 (B6, paso de reposo) y 8 (I1, luces del intermitente).
La corrección es siempre la misma: o se mide la duración del intervalo, o se vigila de
forma continua con una bandera enclavada.

**Familia B — la secuencia no llega al estado en que el defecto se manifiesta.** El
mecanismo de detección es correcto pero nunca se le presenta el caso. Aparece en las
enmiendas 7 (B5, segundo post-enfriamiento), 9 (B4, ambas órdenes desde el reposo),
10 (I2, paro durante la mezcla), 12 (I3, ACK con causa presente) y 13 (I6, alarma con el
enfriador encendido). La corrección es añadir el paso que falta.

Un subtipo de la familia B, por su frecuencia, merece nombre propio: **el error de origen
de la ventana**, en las enmiendas 5 (I4), 10 (I2) y 11 (I5). La duración de un paso se
calcula como si la fase que se quiere observar empezara en el límite de ese paso, cuando
en realidad empezó antes. El resultado suele ser una evaluación justo en el instante de
la transición, que reprueba a las implementaciones correctas.

**Dos señales de alarma baratas.** Primera: si la estimación de tiempos de este documento
**supera** la duración real del harness, es probable que falte un paso que se dio por
implementado; delató a B5 (~70 s frente a 41 s) y a I2 (~90 s frente a 61,9 s). Segunda:
si un paso aplica en el mismo instante el estímulo que cambia de fase y el estímulo que
se quiere probar, la prueba se evalúa en la fase equivocada; delató a I2 y a I3.

---

## Corrección de la estimación de tiempos

La estimación preliminar contaba solo la espera dominante de cada tarea. Los totales
reales son mayores porque varias secuencias repiten ciclos completos:

| Tarea | Estimación previa | Estimación corregida | Motivo |
|---|---|---|---|
| I2 | ~61 s | ~90 s | el paro se prueba en dos fases distintas, cada una exige volver a entrar en la fase |
| I1 | ~43 s | ~90 s | ciclo completo (39 s) + intermitente + rehabilitación |
| B5 | ~30 s | ~70 s | reactivación durante el post-enfriamiento exige un segundo ciclo |

Duraciones ya **medidas** por simulación tras las enmiendas 5 a 8, no estimadas:
I6 0,8 s · B4 1,5 s · I3 1,5 s · B1 1,6 s · I5 4,0 s · I4 9,2 s ·
B6 9,7 s · B2 12,9 s · I2 62,6 s · I1 70,6 s · B5 71,2 s.

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
