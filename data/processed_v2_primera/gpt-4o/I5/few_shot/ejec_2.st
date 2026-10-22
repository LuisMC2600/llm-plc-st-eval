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
    tRetraso : TON;         (* Temporizador para retraso de 2 segundos *)
    tPulso : TON;           (* Temporizador para pulso de 1 segundo *)
    piezaAltaDetectada : BOOL; (* Indica si una pieza alta fue detectada *)
END_VAR

(* La banda transportadora siempre está activa *)
banda := TRUE;

(* Detectar pieza alta y activar temporizador de retraso *)
IF sensorPresencia AND sensorAltura THEN
    piezaAltaDetectada := TRUE;
    tRetraso(IN := TRUE, PT := T#2S);
ELSE
    tRetraso(IN := FALSE);
END_IF

(* Activar pistón después del retraso si una pieza alta fue detectada *)
IF tRetraso.Q THEN
    tPulso(IN := TRUE, PT := T#1S);
    IF NOT tPulso.Q THEN
        piston := TRUE;
    ELSE
        piston := FALSE;
        piezaAltaDetectada := FALSE; (* Resetear detección de pieza alta *)
        tPulso(IN := FALSE);
    END_IF
ELSE
    piston := FALSE;
END_IF

(* Contar piezas altas y bajas *)
IF sensorPresencia AND NOT sensorAltura THEN
    nBajas := nBajas + 1;
ELSIF sensorPresencia AND sensorAltura AND NOT piezaAltaDetectada THEN
    nAltas := nAltas + 1;
END_IF

END_FUNCTION_BLOCK