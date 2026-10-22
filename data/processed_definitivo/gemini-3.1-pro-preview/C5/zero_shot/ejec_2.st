1. **Falta de desconexión del contactor principal (`kM`) al pulsar paro**
   * **Sección:** Bloque `IF btnParo THEN` (al final del código).
   * **Por qué es un error:** El requisito exige explícitamente que `btnParo` desactive *todos* los contactores en cualquier momento. El código actual apaga `kY` y `kD`, pero omite apagar `kM`, por lo que el motor seguiría recibiendo tensión.
   * **Corrección:** Añadir la instrucción `kM := FALSE;` dentro de la condición `IF btnParo THEN`.

2. **Activación simultánea de estrella (`kY`) y triángulo (`kD`)**
   * **Sección:** `CASE estado OF`, específicamente dentro del estado `1`.
   * **Por qué es un error:** Cuando el temporizador `t1` termina (`t1.Q` es TRUE), el código ejecuta `kD := TRUE;` inmediatamente. En ese momento de la ejecución, `kY` sigue estando en `TRUE` (ya que `kY` se apaga recién en el estado `2`, durante el siguiente ciclo de scan del PLC). Esto provoca un cortocircuito físico y viola la restricción de que jamás deben estar activos a la vez.
   * **Corrección:** En el estado `1`, al cumplirse `IF t1.Q THEN`, se debe apagar la estrella (`kY := FALSE;`) y cambiar de estado (`estado := 2;`), eliminando por completo la instrucción `kD := TRUE;` de esta sección.

3. **Ausencia del tiempo muerto de 100 milisegundos**
   * **Sección:** Transición entre el apagado de `kY` y el encendido de `kD` (falta de implementación en el `CASE`).
   * **Por qué es un error:** El requisito pide un tiempo muerto de 100 ms para permitir la extinción del arco eléctrico en los contactores. Aunque la variable `t2 : TON;` está declarada, nunca se utiliza en el código.
   * **Corrección:** Utilizar el estado `2` como estado de espera. En el estado `2`, llamar al temporizador `t2` configurado a 100 ms. Cuando `t2.Q` sea TRUE, entonces encender el triángulo (`kD := TRUE;`) y pasar a un estado final de marcha (por ejemplo, `estado := 3;`).

4. **Los temporizadores nunca se reinician (Reset)**
   * **Sección:** Estado `1` (`t1(IN := TRUE, PT := T#8S);`) y bloque de paro.
   * **Por qué es un error:** Al asignar la entrada del temporizador como `IN := TRUE` de forma constante (hardcoded), el temporizador arranca y termina, pero nunca vuelve a cero. Si se detiene el sistema con `btnParo` y se vuelve a iniciar con `btnMarcha`, `t1.Q` seguirá siendo TRUE desde el primer instante, saltándose los 8 segundos en el segundo arranque.
   * **Corrección:** Llamar a los temporizadores fuera de la estructura `CASE` vinculando su entrada `IN` a la condición lógica del estado (por ejemplo, `t1(IN := (estado = 1), PT := T#8S);` y `t2(IN := (estado = 2), PT := T#100MS);`), o bien asegurarse de reiniciarlos explícitamente llamándolos con `IN := FALSE` dentro del estado `0` y dentro del bloque `IF btnParo THEN`.