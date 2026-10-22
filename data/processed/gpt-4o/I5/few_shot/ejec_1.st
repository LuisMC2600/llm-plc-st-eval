FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de presencia de piezas *)
    sensorAltura : BOOL;    (* Sensor de altura de piezas *)
END_VAR
VAR_OUTPUT
    banda : BOOL;           (* Banda transportadora activa *)
    piston : BOOL;          (* Pistón para desviar piezas altas *)
    nAltas : INT;           (* Contador de piezas altas *)
    nBajas : INT;           (* Contador de piezas bajas *)
END_VAR
VAR
    tRetraso : TON;         (* Temporizador de retraso de 2 segundos *)
    tPulso : TP;            (* Temporizador de pulso de 1 segundo *)
    piezaDetectada : BOOL;  (* Indica si una pieza ha sido detectada *)
END_VAR

(* La banda está siempre activa *)
banda := TRUE;

(* Detectar una pieza y verificar su altura *)
IF sensorPresencia AND NOT piezaDetectada THEN
    piezaDetectada := TRUE;
    IF sensorAltura THEN
        nAltas := nAltas + 1;
        tRetraso(IN := TRUE, PT := T#2S);
    ELSE
        nBajas := nBajas + 1;
    END_IF;
ELSIF NOT sensorPresencia THEN
    piezaDetectada := FALSE;
END_IF;

(* Activar el pistón después del retraso si la pieza es alta *)
IF tRetraso.Q THEN
    tPulso(IN := TRUE, PT := T#1S);
    tRetraso(IN := FALSE);
END_IF;

(* Salida del pistón controlada por el pulso de 1 segundo *)
piston := tPulso.Q;

END_FUNCTION_BLOCK