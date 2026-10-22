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
    tRetraso : TON;         (* Temporizador para retraso de 2 segundos *)
    tPulso : TP;            (* Temporizador para pulso de 1 segundo *)
    piezaAltaDetectada : BOOL; (* Indica si una pieza alta fue detectada *)
END_VAR

(* La banda transportadora siempre está activa *)
banda := TRUE;

(* Detectar y contar piezas altas y bajas *)
IF sensorPresencia THEN
    IF sensorAltura THEN
        (* Si la pieza es alta, incrementar el contador de piezas altas *)
        nAltas := nAltas + 1;
        piezaAltaDetectada := TRUE;
        tRetraso(IN := TRUE, PT := T#2S);
    ELSE
        (* Si la pieza es baja, incrementar el contador de piezas bajas *)
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* Activar el pistón después de 2 segundos si una pieza alta fue detectada *)
IF tRetraso.Q THEN
    tPulso(IN := piezaAltaDetectada, PT := T#1S);
    piezaAltaDetectada := FALSE; (* Resetear la detección de pieza alta *)
END_IF;

(* Salida del pistón activada por el pulso de 1 segundo *)
piston := tPulso.Q;
END_FUNCTION_BLOCK
```