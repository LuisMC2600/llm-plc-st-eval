```pascal
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
    tPulso : TON;           (* Temporizador de pulso de 1 segundo *)
    piezaAltaDetectada : BOOL; (* Indica si una pieza alta fue detectada *)
END_VAR

(* La banda transportadora siempre está activa *)
banda := TRUE;

(* Detectar y contar piezas *)
IF sensorPresencia THEN
    IF sensorAltura THEN
        nAltas := nAltas + 1;
        piezaAltaDetectada := TRUE;
        tRetraso(IN := TRUE, PT := T#2S);
    ELSE
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* Control del pistón para desviar piezas altas *)
IF piezaAltaDetectada AND tRetraso.Q THEN
    tPulso(IN := TRUE, PT := T#1S);
    piezaAltaDetectada := FALSE; (* Resetear la detección de pieza alta *)
END_IF;

piston := tPulso.Q;
END_FUNCTION_BLOCK
```