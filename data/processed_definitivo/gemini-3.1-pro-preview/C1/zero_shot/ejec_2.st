1. **Condición de habilitación invertida**
   * **Ubicación:** Línea `IF NOT habilitado THEN`
   * **Explicación:** El enunciado especifica que el ciclo normal del semáforo (verde, amarillo, rojo) debe ejecutarse "mientras habilitado esté activo". Al utilizar `NOT habilitado`, el ciclo se ejecuta cuando la señal es falsa (deshabilitado), lo cual es exactamente lo opuesto a lo solicitado.
   * **Corrección:** Cambiar la condición a `IF habilitado THEN`.

2. **Falta de reinicio (reset) del temporizador `t1` entre estados**
   * **Ubicación:** Dentro de los estados 0, 1 y 2 del `CASE` (ej. `t1(IN := TRUE, PT := T#20S);`).
   * **Explicación:** Un temporizador `TON` requiere que su entrada `IN` pase a `FALSE` para reiniciar su tiempo acumulado y su salida `Q`. Como en el código la entrada se fuerza siempre a `TRUE` (`IN := TRUE`) y nunca se apaga al transicionar, la salida `t1.Q` se quedará enclavada en `TRUE` tras el primer estado. Esto provocará que los siguientes estados se salten instantáneamente sin respetar los tiempos de 4s y 15s.
   * **Corrección:** Reiniciar el temporizador al cumplirse el tiempo, justo antes de asignar el nuevo estado. Por ejemplo: `IF t1.Q THEN t1(IN := FALSE); estado := 1; END_IF`.

3. **Modo de amarillo intermitente inaccesible y sin lógica de parpadeo**
   * **Ubicación:** Estado `3: luzA := parp;` y bloque `ELSE`.
   * **Explicación:** El estado 3 nunca se invoca en ninguna parte del programa. Cuando el semáforo no está habilitado (bloque `ELSE`), el código actual simplemente apaga todas las luces (`luzA := FALSE;`), ignorando por completo el modo intermitente. Además, la variable `parp` está declarada pero no tiene ninguna lógica asignada que la haga alternar entre `TRUE` y `FALSE`, por lo que su valor por defecto siempre será `FALSE`.
   * **Corrección:** En el bloque `ELSE`, en lugar de apagar `luzA`, se debe activar el modo intermitente (por ejemplo, forzando `estado := 3;` o controlando `luzA` directamente). Adicionalmente, se debe programar la lógica para que la variable `parp` oscile (usando una marca de reloj del PLC o un par de temporizadores adicionales).

4. **Falta de reinicio del ciclo al deshabilitar el semáforo**
   * **Ubicación:** Bloque `ELSE`.
   * **Explicación:** Cuando la señal `habilitado` se desactiva, el sistema detiene el ciclo pero no reinicia la variable `estado` ni el temporizador `t1`. Si el semáforo se vuelve a habilitar, reanudará su funcionamiento en el estado y con el tiempo exacto en el que fue interrumpido, en lugar de comenzar un ciclo limpio desde el inicio (luz verde).
   * **Corrección:** Dentro del bloque `ELSE`, se debe asegurar el reinicio de la máquina de estados y del temporizador principal agregando las instrucciones: `estado := 0;` y `t1(IN := FALSE);`.