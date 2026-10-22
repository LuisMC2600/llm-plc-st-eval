FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura : BOOL;    (* Sensor de pieza alta *)
END_VAR
VAR_OUTPUT
    banda : BOOL;           (* Salida de la banda transportadora *)
    piston : BOOL;          (* Salida del piston desviador *)
    nAltas : INT;           (* Contador de piezas altas *)
    nBajas : INT;           (* Contador de piezas bajas *)
END_VAR
VAR
    trigPresencia : R_TRIG; (* Flanco de subida del sensor de presencia *)
    pulsoAlta : BOOL;       (* Marca de deteccion de pieza alta *)
    tRetardo : TP;          (* Temporizador de retardo de llegada *)
    trigFinRetardo : F_TRIG;(* Flanco de bajada del retardo *)
    tPiston : TP;           (* Temporizador de activacion del piston *)
END_VAR

(* La banda funciona continuamente *)
banda := TRUE;

(* Detectar el paso de una nueva pieza *)
trigPresencia(CLK := sensorPresencia);

pulsoAlta := FALSE;
IF trigPresencia.Q THEN
    IF sensorAltura THEN
        nAltas := nAltas + 1;
        pulsoAlta := TRUE; (* Inicia la secuencia de desvio *)
    ELSE
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* Generar retardo de 2s desde la deteccion *)
tRetardo(IN := pulsoAlta, PT := T#2S);

(* Detectar el fin del retardo de 2s *)
trigFinRetardo(CLK := tRetardo.Q);

(* Activar el piston por 1s al terminar el retardo *)
tPiston(IN := trigFinRetardo.Q, PT := T#1S);
piston := tPiston.Q;

END_FUNCTION_BLOCK