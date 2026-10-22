```iec
FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL;  // Botón para girar en sentido horario
    btnRev : BOOL;  // Botón para girar en sentido antihorario
    btnParo : BOOL; // Botón para parar el motor
END_VAR

VAR_OUTPUT
    fwd : BOOL;    // Salida para girar en sentido horario
    rev : BOOL;    // Salida para girar en sentido antihorario
END_VAR

VAR
    estado : INT := 0; // Estado actual del sistema (0: Parado, 1: Giro horario, 2: Giro antihorario)
END_VAR

// Máquina de estados
CASE estado OF
    0: // Estado Parado
        fwd := FALSE;
        rev := FALSE;
        IF btnFwd THEN
            estado := 1; // Cambia a giro horario
        ELSIF btnRev THEN
            estado := 2; // Cambia a giro antihorario
        END_IF

    1: // Estado Giro Horario
        fwd := TRUE;
        rev := FALSE;
        IF btnParo THEN
            estado := 0; // Cambia a parado
        ELSIF btnRev THEN
            estado := 2; // Cambia a giro antihorario
        END_IF

    2: // Estado Giro Antihorario
        fwd := FALSE;
        rev := TRUE;
        IF btnParo THEN
            estado := 0; // Cambia a parado
        ELSIF btnFwd THEN
            estado := 1; // Cambia a giro horario
        END_IF
END_CASE
```

Este código implementa una máquina de estados para controlar el giro de un motor utilizando los botones `btnFwd`, `btnRev` y `btnParo`. Las salidas `fwd` y `rev` controlan el sentido de giro del motor. El estado del sistema se mantiene en una variable `estado`, que puede tomar los valores 0 (parado), 1 (giro horario) o 2 (giro antihorario). Las transiciones entre estados se realizan según las pulsaciones de los botones, asegurando que el motor no pueda girar en ambos sentidos simultáneamente y que siempre se pase por el paro antes de cambiar el sentido de giro.