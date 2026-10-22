```pascal
FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; // Alarma de prioridad alta
    alm2 : BOOL; // Alarma de prioridad media
    alm3 : BOOL; // Alarma de prioridad baja
    ack1 : BOOL; // Reconocimiento de alarma 1
    ack2 : BOOL; // Reconocimiento de alarma 2
    ack3 : BOOL; // Reconocimiento de alarma 3
END_VAR

VAR_OUTPUT
    sirena : BOOL; // Indica si la sirena está activa
    codigoAlm : INT; // Código de la alarma de mayor prioridad activa
END_VAR

VAR
    ret1 : BOOL; // Retención de la alarma 1
    ret2 : BOOL; // Retención de la alarma 2
    ret3 : BOOL; // Retención de la alarma 3
END_VAR

// Retención de alarmas
IF alm1 THEN
    ret1 := TRUE;
END_IF;

IF alm2 THEN
    ret2 := TRUE;
END_IF;

IF alm3 THEN
    ret3 := TRUE;
END_IF;

// Reconocimiento de alarmas
IF ack1 AND NOT alm1 THEN
    ret1 := FALSE;
END_IF;

IF ack2 AND NOT alm2 THEN
    ret2 := FALSE;
END_IF;

IF ack3 AND NOT alm3 THEN
    ret3 := FALSE;
END_IF;

// Determinación de la alarma de mayor prioridad
IF ret1 THEN
    codigoAlm := 1;
ELSIF ret2 THEN
    codigoAlm := 2;
ELSIF ret3 THEN
    codigoAlm := 3;
ELSE
    codigoAlm := 0;
END_IF;

// Activación de la sirena si hay alguna alarma retenida
sirena := ret1 OR ret2 OR ret3;

END_FUNCTION_BLOCK
```

Este código implementa la lógica de gestión de alarmas con prioridad, retención y reconocimiento individual conforme al estándar IEC 61131-3 utilizando Structured Text (ST).