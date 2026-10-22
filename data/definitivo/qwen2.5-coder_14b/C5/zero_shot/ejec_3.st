1. **Error en la sección CASE estado OF:**
   - **Línea:** 20-22
   - **Explicación:** En el estado 1, se activa el temporizador `t1` y se espera que termine para pasar al estado 2. Sin embargo, no se desactiva el contactor `kY` antes de activar `kD`. Esto viola la regla de que `kY` y `kD` no deben estar activos simultáneamente.
   - **Corrección:** Desactivar `kY` antes de activar `kD` en el estado 1.

2. **Error en la sección CASE estado OF:**
   - **Línea:** 25
   - **Explicación:** En el estado 2, se desactiva `kY`, pero no se asegura que `kD` se mantenga activo después de que `t1` termine. Esto podría causar un comportamiento inesperado.
   - **Corrección:** Asegurar que `kD` se mantenga activo después de que `t1` termine.

3. **Error en la sección CASE estado OF:**
   - **Línea:** 20-22
   - **Explicación:** En el estado 1, se activa el temporizador `t1` y se espera que termine para pasar al estado 2. Sin embargo, no se respetan los 100 milisegundos de tiempo muerto antes de activar `kD`.
   - **Corrección:** Añadir un temporizador adicional para gestionar el tiempo muerto de 100 milisegundos.

4. **Error en la sección IF btnParo THEN:**
   - **Línea:** 30-32
   - **Explicación:** Al pulsar `btnParo`, se desactivan `kY` y `kD`, pero no se desactiva `kM`. Esto podría causar un comportamiento inesperado.
   - **Corrección:** Añadir la desactivación de `kM` al pulsar `btnParo`.

**Correcciones propuestas:**

```iec
FUNCTION_BLOCK FB_EstrellaTriangulo
VAR_INPUT
    btnMarcha : BOOL;
    btnParo : BOOL;
END_VAR
VAR_OUTPUT
    kM : BOOL;
    kY : BOOL;
    kD : BOOL;
END_VAR
VAR
    estado : INT;
    t1 : TON;
    t2 : TON;
    t3 : TON;  // Nuevo temporizador para el tiempo muerto
END_VAR

CASE estado OF
    0:
        IF btnMarcha THEN
            kM := TRUE;
            kY := TRUE;
            estado := 1;
        END_IF
    1:
        t1(IN := TRUE, PT := T#8S);
        IF t1.Q THEN
            kY := FALSE;  // Desactivar kY antes de activar kD
            t3(IN := TRUE, PT := T#100MS);  // Iniciar temporizador para el tiempo muerto
            estado := 2;
        END_IF
    2:
        IF t3.Q THEN  // Esperar el tiempo muerto
            kD := TRUE;
        END_IF
END_CASE

IF btnParo THEN
    kM := FALSE;  // Desactivar kM al pulsar btnParo
    kY := FALSE;
    kD := FALSE;
    estado := 0;
END_IF
END_FUNCTION_BLOCK
```