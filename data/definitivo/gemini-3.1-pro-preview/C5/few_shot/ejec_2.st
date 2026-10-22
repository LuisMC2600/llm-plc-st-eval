1. **Activación simultánea de kY y kD (riesgo de cortocircuito)**:
   - **Ubicación**: `CASE` estado 1 y 2.
   - **Por qué**: Al cumplirse `t1.Q` en el estado 1, se ejecuta `kD := TRUE` y se pasa al estado 2. El contactor `kY` recién se apaga en el estado 2 (durante el siguiente ciclo de scan). Esto provoca que ambos contactores estén activos simultáneamente, violando la restricción de seguridad.
   - **Corrección**: Al cumplirse `t1.Q` en el estado 1, se debe apagar el contactor de estrella (`kY := FALSE;`) y cambiar de estado, pero sin encender `kD` todavía.

2. **Ausencia del tiempo muerto (temporizador t2 no utilizado)**:
   - **Ubicación**: `CASE` estado 1 y transición al estado 2.
   - **Por qué**: El código pasa directamente de la temporización de 8 segundos a encender `kD`. El temporizador `t2` está declarado pero nunca se ejecuta, por lo que no se respeta el tiempo muerto de 100 ms exigido por la especificación.
   - **Corrección**: Crear un estado intermedio (ej. estado 2) en el que se ejecute `t2(IN := TRUE, PT := T#100MS);`. Dentro de ese estado, evaluar `IF t2.Q THEN`, encender el contactor de triángulo (`kD := TRUE;`) y pasar a un estado final (ej. estado 3).

3. **Falta de reseteo del temporizador t1**:
   - **Ubicación**: `CASE` estado 1.
   - **Por qué**: La llamada `t1(IN := TRUE, PT := T#8S);` tiene la entrada `IN` forzada a `TRUE`. Si el sistema se detiene con `btnParo` y se vuelve a arrancar, el temporizador nunca se habrá reseteado (su entrada `IN` nunca pasó a `FALSE`), por lo que `t1.Q` seguirá siendo `TRUE` y se saltará el tiempo de 8 segundos en el segundo arranque.
   - **Corrección**: Llamar a los temporizadores fuera del `CASE` vinculando su entrada al estado correspondiente (ej. `t1(IN := (estado = 1), PT := T#8S);`), o bien asegurarse de resetearlos explícitamente llamándolos con `IN := FALSE` en el estado 0 o en el bloque de paro.

4. **El botón de paro no desactiva el contactor principal (kM)**:
   - **Ubicación**: Bloque `IF btnParo THEN` al final del código.
   - **Por qué**: La rutina de paro apaga `kY`, `kD` y reinicia la máquina de estados, pero olvida apagar `kM`. El contactor principal quedaría enclavado indefinidamente.
   - **Corrección**: Añadir la instrucción `kM := FALSE;` dentro del bloque `IF btnParo THEN`.