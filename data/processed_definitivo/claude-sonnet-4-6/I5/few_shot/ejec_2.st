FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura    : BOOL; (* TRUE = pieza alta *)
END_VAR
VAR_OUTPUT
    banda   : BOOL; (* Banda transportadora activa *)
    piston  : BOOL; (* Pistón desviador *)
    nAltas  : INT;  (* Contador de piezas altas *)
    nBajas  : INT;  (* Contador de piezas bajas *)
END_VAR
VAR
    rPresencia  : R_TRIG; (* Flanco ascendente de sensorPresencia *)
    tRetardo    : TON;    (* Retardo de 2 s hasta el desviador *)
    tPulso      : TP;     (* Pulso de 1 s del pistón *)
    bEsAlta     : BOOL;   (* Indica que la pieza detectada es alta *)
END_VAR

(* La banda funciona siempre *)
banda := TRUE;

(* Detectar flanco ascendente de presencia de pieza *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    IF sensorAltura THEN
        (* Pieza alta: registrar y armar retardo *)
        nAltas  := nAltas + 1;
        bEsAlta := TRUE;
    ELSE
        (* Pieza baja: solo contar *)
        nBajas  := nBajas + 1;
        bEsAlta := FALSE;
    END_IF;
END_IF;

(* Retardo de 2 s: arranca cuando hay pieza alta pendiente *)
tRetardo(IN := bEsAlta, PT := T#2S);

(* Al cumplirse el retardo, disparar el pulso del pistón y limpiar la bandera *)
IF tRetardo.Q THEN
    bEsAlta := FALSE; (* Evita rearrancar el retardo *)
END_IF;

(* Pulso de 1 s del pistón, iniciado por el flanco de salida del retardo *)
tPulso(IN := tRetardo.Q, PT := T#1S);
piston := tPulso.Q;

END_FUNCTION_BLOCK