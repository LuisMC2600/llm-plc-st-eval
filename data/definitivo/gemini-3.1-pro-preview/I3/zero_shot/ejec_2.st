```iecst
FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; // Causa de alarma 1 (Prioridad Alta)
    alm2 : BOOL; // Causa de alarma 2 (Prioridad Media)
    alm3 : BOOL; // Causa de alarma 3 (Prioridad Baja)
    ack1 : BOOL; // Reconocimiento alarma 1
    ack2 : BOOL; // Reconocimiento alarma 2
    ack3 : BOOL; // Reconocimiento alarma 3
END_VAR

VAR_OUTPUT
    sirena : BOOL;   // Sirena activa si hay alguna alarma presente
    codigoAlm : INT; // Código de alarma de mayor prioridad (1, 2, 3 o 0)
END_VAR

VAR
    memAlm1 : BOOL; // Memoria de retención alarma 1
    memAlm2 : BOOL; // Memoria de retención alarma 2
    memAlm3 : BOOL; // Memoria de retención alarma 3
END_VAR

// Gestión de retención y reconocimiento (Alarma 1)
// Se activa con la causa. El ACK solo funciona si la causa (alm1) ya desapareció.
IF alm1 THEN
    memAlm1 := TRUE;
ELSIF ack1 THEN
    memAlm1 := FALSE;
END_IF;

// Gestión de retención y reconocimiento (Alarma 2)
IF alm2 THEN
    memAlm2 := TRUE;
ELSIF ack2 THEN
    memAlm2 := FALSE;
END_IF;

// Gestión de retención y reconocimiento (Alarma 3)
IF alm3 THEN
    memAlm3 := TRUE;
ELSIF ack3 THEN
    memAlm3 := FALSE;
END_IF;

// Activación de la sirena (cualquier alarma retenida la enciende)
sirena := memAlm1 OR memAlm2 OR memAlm3;

// Evaluación de prioridad para el código de salida
IF memAlm1 THEN
    codigoAlm := 1; // Prioridad Alta
ELSIF memAlm2 THEN
    codigoAlm := 2; // Prioridad Media
ELSIF memAlm3 THEN
    codigoAlm := 3; // Prioridad Baja
ELSE
    codigoAlm := 0; // Sin alarmas
END_IF;

END_FUNCTION_BLOCK
```