FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura    : BOOL; (* Sensor de pieza alta *)
END_VAR
VAR_OUTPUT
    banda   : BOOL; (* Banda transportadora activa *)
    piston  : BOOL; (* Piston desviador *)
    nAltas  : INT;  (* Contador de piezas altas *)
    nBajas  : INT;  (* Contador de piezas bajas *)
END_VAR
VAR
    tRetardo : TON; (* Temporizador de retardo 2 s hasta el desviador *)
    tPulso   : TP;  (* Temporizador de pulso 1 s del piston *)
    rPresencia : R_TRIG; (* Flanco ascendente del sensor de presencia *)
    piezaAlta  : BOOL;   (* Indica que la pieza detectada es alta *)
END_VAR

(* La banda funciona siempre *)
banda := TRUE;

(* Detectar flanco ascendente del sensor de presencia *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    IF sensorAltura THEN
        (* Pieza alta: registrar y armar retardo *)
        nAltas    := nAltas + 1;
        piezaAlta := TRUE;
    ELSE
        (* Pieza baja: solo contar *)
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* Retardo de 2 s: la pieza tarda ese tiempo en llegar al desviador *)
tRetardo(IN := piezaAlta, PT := T#2S);

(* Al cumplirse el retardo, lanzar pulso de 1 s en el piston *)
tPulso(IN := tRetardo.Q, PT := T#1S);

(* Activar piston durante el pulso *)
piston := tPulso.Q;

(* Una vez que el pulso termina, liberar el retardo y la bandera *)
IF tPulso.Q = FALSE AND tRetardo.Q = TRUE THEN
    piezaAlta := FALSE;
END_IF;

END_FUNCTION_BLOCK