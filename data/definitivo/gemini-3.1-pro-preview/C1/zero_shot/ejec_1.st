1. **Condición de habilitación invertida**
   * **Línea/Sección:** `IF NOT habilitado THEN`
   * **Explicación:** El requerimiento indica que el ciclo normal del semáforo (verde, amarillo, rojo) debe ejecutarse "mientras habilitado esté activo". Al usar `NOT habilitado`, el ciclo se ejecuta cuando la variable es `FALSE`, lo cual es exactamente lo opuesto a lo solicitado.
   * **Corrección:** Cambiar la condición a `IF habilitado THEN`.

2. **Falta de reinicio del temporizador `t1` (Ausencia de flanco de subida)**
   * **Línea/Sección:** Dentro de los estados 0, 1 y 2 del `CASE` (ej. `t1(IN := TRUE, PT := T#20S);`).
   * **Explicación:** Un temporizador `TON` requiere un flanco de subida (transición de `FALSE` a `TRUE`) en su entrada `IN` para comenzar a contar. Como `IN` se mantiene siempre en `TRUE` al cambiar de estado, el temporizador nunca se reinicia. Una vez que `t1.Q` se vuelve `TRUE` en el estado 0, se mantendrá en `TRUE` en los siguientes estados, provocando que el semáforo salte por todos los estados de forma instantánea en un solo ciclo de scan.
   * **Corrección:** Reiniciar el temporizador justo antes de la transición de estado. Por ejemplo: `IF t1.Q THEN t1(IN := FALSE); estado := 1; END_IF`.

3. **Lógica de amarillo intermitente inalcanzable e inexistente**
   * **Línea/Sección:** Estado `3: luzA := parp;`, declaración de la variable `parp`, y la sección `ELSE`.
   * **Explicación:** El estado 3 nunca es llamado desde ningún otro estado, por lo que es código inalcanzable. Además, la variable `parp` nunca cambia de valor (siempre será `FALSE` por defecto al no tener lógica que la haga oscilar). Por último, cuando el semáforo se deshabilita (sección `ELSE`), simplemente se apagan todas las luces en lugar de activar el modo intermitente solicitado.
   * **Corrección:** Eliminar el estado 3. En la sección `ELSE`, implementar la lógica de intermitencia para `luzA` (por ejemplo, usando un generador de pulsos o evaluando una marca de reloj del sistema) y asegurar que `luzV` y `luzR` se fuercen a `FALSE`.

4. **Falta de reinicio de la máquina de estados al deshabilitar**
   * **Línea/Sección:** Sección `ELSE`.
   * **Explicación:** Cuando `habilitado` pasa a `FALSE`, el sistema apaga las luces pero la variable `estado` y el temporizador `t1` retienen sus últimos valores. Si el semáforo se vuelve a habilitar, reanudará su ciclo desde un estado y un tiempo intermedios, lo cual es un comportamiento errático para un semáforo (debería reiniciar su ciclo de forma segura).
   * **Corrección:** Dentro de la sección `ELSE`, agregar `estado := 0;` y `t1(IN := FALSE);` para garantizar que, al volver a habilitarse, el ciclo comience limpiamente desde el estado inicial.