```iecst
FUNCTION_BLOCK FB_Alarmas
VAR_INPUT
    alm1 : BOOL; // Causa alarma 1 (Prioridad Alta)
    alm2 : BOOL; // Causa alarma 2 (Prioridad Media)
    alm3 : BOOL; // Causa alarma 3 (Prioridad Baja)
    ack1 : BOOL; // Reconocimiento alarma 1
    ack2 : BOOL; // Reconocimiento alarma 2
    ack3 : BOOL; // Reconocimiento alarma 3
END_VAR

VAR_OUTPUT
    sirena : BOOL;   // Sirena activa si hay alguna alarma presente
    codigoAlm : INT; // Código de la alarma de mayor prioridad (1, 2, 3 o 0 si no hay)
END_VAR

VAR
    estadoAlm1 : BOOL; // Estado retenido de la alarma 1
    estadoAlm2 : BOOL; // Estado retenido de la alarma 2
    estadoAlm3 : BOOL; // Estado retenido de la alarma 3
END_VAR

// 1. Lógica de retención (latch) y reconocimiento
// La alarma se activa si la causa está presente. 
// Se mantiene activa mientras no se reconozca (ack).
// Si la causa sigue presente, el ack no tiene efecto (almX domina).
estadoAlm1 := alm1 OR (estadoAlm1 AND NOT ack1);
estadoAlm2 := alm2 OR (estadoAlm2 AND NOT ack2);
estadoAlm3 := alm3 OR (estadoAlm3 AND NOT ack3);

// 2. Lógica de prioridad para el código de alarma
// Se evalúa en orden descendente de prioridad (1 -> 2 -> 3)
IF estadoAlm1 THEN
    codigoAlm := 1;
ELSIF estadoAlm2 THEN
    codigoAlm := 2;
ELSIF estadoAlm3 THEN
    codigoAlm := 3;
ELSE
    codigoAlm := 0;
END_IF;

// 3. Lógica de activación de la sirena
// Se enciende si cualquiera de los estados retenidos es verdadero
sirena := estadoAlm1 OR estadoAlm2 OR estadoAlm3;

END_FUNCTION_BLOCK
```