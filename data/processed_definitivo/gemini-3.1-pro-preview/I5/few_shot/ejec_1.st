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
    tpRetardo : TP;         (* Temporizador para el retardo de 2s *)
    ftrigRetardo : F_TRIG;  (* Flanco de bajada para detectar fin del retardo *)
    tpPiston : TP;          (* Temporizador para el pulso del piston de 1s *)
    piezaAlta : BOOL;       (* Marca temporal de pieza alta detectada *)
END_VAR

(* La banda funciona continuamente *)
banda := TRUE;

(* Deteccion de una nueva pieza (flanco de subida) *)
trigPresencia(CLK := sensorPresencia);

(* Clasificacion y conteo *)
piezaAlta := FALSE;
IF trigPresencia.Q THEN
    IF sensorAltura THEN
        nAltas := nAltas + 1;
        piezaAlta := TRUE; (* Dispara la secuencia del desviador *)
    ELSE
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* Retardo de 2 segundos al detectar una pieza alta *)
tpRetardo(IN := piezaAlta, PT := T#2S);

(* El fin del retardo genera un flanco de bajada *)
ftrigRetardo(CLK := tpRetardo.Q);

(* Pulso de 1 segundo para activar el piston desviador tras el retardo *)
tpPiston(IN := ftrigRetardo.Q, PT := T#1S);
piston := tpPiston.Q;

END_FUNCTION_BLOCK