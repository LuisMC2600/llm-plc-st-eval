```pascal
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
    tRetardo : TON; (* Retardo de 2 s hasta el desviador *)
    tPulso   : TP;  (* Pulso de 1 s para el pistón *)
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

(* Retardo de 2 s: comienza cuando hay pieza alta pendiente *)
tRetardo(IN := piezaAlta, PT := T#2S);

(* Al cumplirse el retardo, lanzar pulso de 1 s y limpiar bandera *)
IF tRetardo.Q THEN
    piezaAlta := FALSE; (* Limpiar antes de bajar IN del TON *)
END_IF;

(* Pulso de 1 s para el pistón, disparado por el flanco de tRetardo.Q *)
tPulso(IN := tRetardo.Q, PT := T#1S);

piston := tPulso.Q;

END_FUNCTION_BLOCK
```