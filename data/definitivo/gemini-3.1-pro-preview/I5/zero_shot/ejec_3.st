```iecst
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor que detecta el paso de una pieza *)
    sensorAltura : BOOL;    (* Sensor que detecta si la pieza es alta *)
END_VAR

VAR_OUTPUT
    banda : BOOL;           (* Salida para activar la banda transportadora *)
    piston : BOOL;          (* Salida para activar el pistón desviador *)
    nAltas : INT := 0;      (* Contador de piezas altas *)
    nBajas : INT := 0;      (* Contador de piezas bajas *)
END_VAR

VAR
    trigPresencia : R_TRIG; (* Detector de flanco de subida para la presencia *)
    tonRetardo : TON;       (* Temporizador para el retardo de 2 segundos *)
    tpPiston : TP;          (* Temporizador de pulso para el pistón de 1 segundo *)
    esperandoPiston : BOOL := FALSE; (* Memoria para el retardo del pistón *)
END_VAR

(* 1. La banda funciona continuamente *)
banda := TRUE;

(* 2. Detección de nueva pieza (flanco de subida) *)
trigPresencia(CLK := sensorPresencia);

IF trigPresencia.Q THEN
    IF sensorAltura THEN
        (* Es una pieza alta *)
        nAltas := nAltas + 1;
        esperandoPiston := TRUE; (* Inicia el proceso de desvío *)
    ELSE
        (* Es una pieza baja *)
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* 3. Temporizador de retardo (2 segundos hasta llegar al desviador) *)
tonRetardo(IN := esperandoPiston, PT := T#2S);

(* Al cumplirse el tiempo de retardo, reseteamos la memoria de espera *)
IF tonRetardo.Q THEN
    esperandoPiston := FALSE;
END_IF;

(* 4. Temporizador del pistón (pulso de 1 segundo) *)
(* Se dispara con el flanco de subida de tonRetardo.Q *)
tpPiston(IN := tonRetardo.Q, PT := T#1S);

(* 5. Activación de la salida del pistón *)
piston := tpPiston.Q;

END_FUNCTION_BLOCK
```