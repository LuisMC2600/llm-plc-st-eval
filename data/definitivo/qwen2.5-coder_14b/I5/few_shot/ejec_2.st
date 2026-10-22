FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de presencia de pieza *)
    sensorAltura : BOOL; (* Sensor de altura de pieza *)
END_VAR
VAR_OUTPUT
    banda : BOOL; (* Salida de la banda transportadora *)
    piston : BOOL; (* Salida del pistón para desviar piezas altas *)
    nAltas : INT; (* Contador de piezas altas *)
    nBajas : INT; (* Contador de piezas bajas *)
END_VAR
VAR
    tEspera : TP; (* Temporizador para esperar 2 segundos *)
    tPiston : TP; (* Temporizador para activar el pistón durante 1 segundo *)
    piezaDetectada : BOOL; (* Bandera para indicar que una pieza ha sido detectada *)
END_VAR

(* La banda funciona continuamente *)
banda := TRUE;

(* Contador de piezas altas y bajas *)
IF sensorPresencia AND NOT piezaDetectada THEN
    piezaDetectada := TRUE;
    IF sensorAltura THEN
        nAltas := nAltas + 1;
    ELSE
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* Temporizador para esperar 2 segundos después de detectar una pieza *)
tEspera(IN := piezaDetectada, PT := T#2S);

(* Temporizador para activar el pistón durante 1 segundo *)
IF tEspera.Q THEN
    piston := TRUE;
    tPiston(IN := TRUE, PT := T#1S);
ELSE
    piston := FALSE;
END_IF;

(* Reiniciar la bandera de pieza detectada cuando el temporizador del pistón termina *)
IF tPiston.Q THEN
    piezaDetectada := FALSE;
END_IF;

END_FUNCTION_BLOCK