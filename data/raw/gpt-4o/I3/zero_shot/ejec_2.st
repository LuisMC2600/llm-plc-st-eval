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
    retAlm1 : BOOL; // Retención de alarma 1
    retAlm2 : BOOL; // Retención de alarma 2
    retAlm3 : BOOL; // Retención de alarma 3
END_VAR

// Retención de alarmas
IF alm1 THEN
    retAlm1 := TRUE;
END_IF;

IF alm2 THEN
    retAlm2 := TRUE;
END_IF;

IF alm3 THEN
    retAlm3 := TRUE;
END_IF;

// Reconocimiento de alarmas
IF ack1 AND NOT alm1 THEN
    retAlm1 := FALSE;
END_IF;

IF ack2 AND NOT alm2 THEN
    retAlm2 := FALSE;
END_IF;

IF ack3 AND NOT alm3 THEN
    retAlm3 := FALSE;
END_IF;

// Determinación de la alarma de mayor prioridad
IF retAlm1 THEN
    codigoAlm := 1;
ELSIF retAlm2 THEN
    codigoAlm := 2;
ELSIF retAlm3 THEN
    codigoAlm := 3;
ELSE
    codigoAlm := 0;
END_IF;

// Activación de la sirena si hay alguna alarma retenida
sirena := retAlm1 OR retAlm2 OR retAlm3;

END_FUNCTION_BLOCK
```

Este código implementa la gestión de tres alarmas con diferentes prioridades, asegurando que la sirena se active si alguna alarma está activa y retenida, y que el código de alarma refleje la alarma de mayor prioridad presente. Las alarmas se retienen hasta que se reconozcan y su causa haya desaparecido.