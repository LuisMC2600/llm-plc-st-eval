1. **Falta de desconexión del contactor principal (`kM`) al pulsar paro.**
   - **Sección:** Bloque `IF btnParo THEN` (al final del código).
   - **Por qué es un error:** El requisito exige explícitamente que `btnParo` desactive *todos* los contactores. El código actual desactiva `kY` y `kD`, pero olvida desactivar `kM`, lo que dejaría el contactor principal enclavado y el motor recibiendo tensión.
   - **Corrección:** Añadir la instrucción `kM := FALSE;` dentro de la condición `IF btnParo THEN`.

2. **Activación simultánea de estrella (`kY`) y triángulo (`kD`) (Riesgo de cortocircuito).**
   - **Sección:** `CASE estado OF`, transición del estado 1 al estado 2.
   - **Por qué es un error:** En el estado 1, cuando el temporizador `t1.Q` se cumple, el código hace `kD := TRUE` y pasa al estado 2. La instrucción `kY := FALSE` se ejecuta recién al entrar al estado 2 (en el siguiente ciclo de scan del PLC). Esto significa que durante al menos un ciclo de programa, `kY` y `kD` estarán activos al mismo tiempo, violando la restricción de seguridad.
   - **Corrección:** En el estado 1, al cumplirse `t1.Q`, se debe ejecutar `kY := FALSE;` y *no* activar `kD` todavía.

3. **Omisión del tiempo muerto de 100 ms (temporizador `t2` sin utilizar).**
   - **Sección:** `CASE estado OF`, estados 1 y 2.
   - **Por qué es un error:** El requisito pide un tiempo muerto de 100 milisegundos entre la desconexión de `kY` y la conexión de `kD` para dar tiempo mecánico a la apertura de los contactos. El código actual ignora este paso por completo. Además, el temporizador `t2` fue declarado en las variables pero nunca se implementó en la lógica.
   - **Corrección:** Implementar un estado intermedio. Al cumplirse `t1.Q` en el estado 1, apagar `kY` y pasar al estado 2. En el estado 2, llamar al temporizador `t2(IN := TRUE, PT := T#100MS);`. Cuando `t2.Q` sea verdadero, ejecutar `kD := TRUE;` y pasar a un estado final de marcha (ej. estado 3).

4. **Falta de reseteo de los temporizadores (`t1` y el futuro `t2`).**
   - **Sección:** Bloque `IF btnParo THEN` y lógica interna del `CASE`.
   - **Por qué es un error:** Según el estándar IEC 61131-3, un temporizador `TON` necesita que su entrada `IN` pase a `FALSE` para reiniciarse. En este código, si se pulsa el botón de paro o se completa la secuencia, `t1` nunca recibe un `IN := FALSE`. Si se intenta un segundo arranque, el temporizador ya estará cumplido o no contará desde cero.
   - **Corrección:** Asegurar el reseteo llamando a `t1(IN := FALSE);` y `t2(IN := FALSE);` dentro del bloque `IF btnParo THEN` y en el estado 0. Una práctica aún mejor en IEC 61131-3 es instanciar los temporizadores fuera del `CASE`, vinculando su entrada `IN` a una condición booleana (por ejemplo, `t1(IN := (estado = 1), PT := T#8S);`).