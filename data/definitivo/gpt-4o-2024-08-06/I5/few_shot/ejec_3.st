```pascal
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de presencia de piezas *)
    sensorAltura : BOOL;    (* Sensor de altura de piezas *)
END_VAR
VAR_OUTPUT
    banda : BOOL;   (* Banda transportadora activa *)
    piston : BOOL;  (* Pistón para desviar piezas altas *)
    nAltas : INT;   (* Contador de piezas altas *)
    nBajas : INT;   (* Contador de piezas bajas *)
END_VAR
VAR
    tRetraso : TON; (* Temporizador para retraso de 2 segundos *)
    tPiston : TON;  (* Temporizador para activación de pistón por 1 segundo *)
    piezaAltaDetectada : BOOL; (* Indica si una pieza alta fue detectada *)
END_VAR

(* La banda siempre está activa *)
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

(* Control del pistón *)
IF tRetraso.Q THEN
    tPiston(IN := piezaAltaDetectada, PT := T#1S);
    piezaAltaDetectada := FALSE; (* Resetear la detección de pieza alta después del retraso *)
END_IF;

piston := tPiston.Q;
END_FUNCTION_BLOCK
```