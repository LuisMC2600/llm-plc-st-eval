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
    codigoAlm : INT; // Código de la alarma de mayor prioridad (1, 2, 3 o 0)
END_VAR

VAR
    memAlm1 : BOOL; // Memoria de retención para alarma 1
    memAlm2 : BOOL; // Memoria de retención para alarma 2
    memAlm3 : BOOL; // Memoria de retención para alarma 3
END_VAR

// 1. Lógica de retención y reconocimiento de alarmas
// La alarma se activa si la causa está presente.
// Se mantiene retenida mientras no se reciba el 'ack' correspondiente.
// Si la causa sigue presente, el 'ack' no tiene efecto (almX fuerza el TRUE).
memAlm1 := alm1 OR (memAlm1 AND NOT ack1);
memAlm2 := alm2 OR (memAlm2 AND NOT ack2);
memAlm3 := alm3 OR (memAlm3 AND NOT ack3);

// 2. Lógica de activación de la sirena
// Se enciende si cualquiera de las alarmas retenidas está activa
sirena := memAlm1 OR memAlm2 OR memAlm3;

// 3. Lógica de prioridad para el código de alarma
// Se evalúa en orden descendente de prioridad (Alta -> Media -> Baja)
IF memAlm1 THEN
    codigoAlm := 1;
ELSIF memAlm2 THEN
    codigoAlm := 2;
ELSIF memAlm3 THEN
    codigoAlm := 3;
ELSE
    codigoAlm := 0; // Ninguna alarma activa
END_IF;

END_FUNCTION_BLOCK
```