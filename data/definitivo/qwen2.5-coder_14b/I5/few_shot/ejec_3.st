FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de presencia de pieza *)
    sensorAltura : BOOL; (* Sensor de altura de pieza *)
END_VAR
VAR_OUTPUT
    banda : BOOL; (* Banda transportadora activa *)
    piston : BOOL; (* Pistón para desviar piezas altas *)
    nAltas : INT; (* Contador de piezas altas *)
    nBajas : INT; (* Contador de piezas bajas *)
END_VAR
VAR
    tEspera : TP; (* Temporizador para esperar 2 segundos *)
    tPiston : TP; (* Temporizador para activar el pistón durante 1 segundo *)
    piezaDetectada : BOOL; (* Bandera para detectar pieza *)
END_VAR

(* La banda funciona continuamente *)
banda := TRUE;

(* Detectar pieza y esperar 2 segundos *)
IF sensorPresencia AND NOT piezaDetectada THEN
    tEspera(IN := TRUE, PT := T#2S);
    piezaDetectada := TRUE;
END_IF

(* Si la pieza es alta, activar el pistón durante 1 segundo *)
IF tEspera.Q AND sensorAltura THEN
    tPiston(IN := TRUE, PT := T#1S);
    nAltas := nAltas + 1;
ELSE
    nBajas := nBajas + 1;
END_IF

(* Activar el pistón *)
piston := tPiston.Q;

(* Reiniciar la bandera cuando la pieza ha sido procesada *)
IF tPiston.Q THEN
    piezaDetectada := FALSE;
END_IF
END_FUNCTION_BLOCK