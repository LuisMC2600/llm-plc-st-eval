FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura    : BOOL; (* TRUE = pieza alta *)
END_VAR

VAR_OUTPUT
    banda   : BOOL; (* Banda transportadora activa *)
    piston  : BOOL; (* Desviador activo *)
    nAltas  : INT;  (* Contador de piezas altas *)
    nBajas  : INT;  (* Contador de piezas bajas *)
END_VAR

VAR
    tRetardo    : TON; (* Temporizador retardo 2 s hasta el desviador *)
    tPiston     : TON; (* Temporizador duración del pistón 1 s *)
    rPresencia  : R_TRIG; (* Flanco ascendente del sensor de presencia *)
    bPiezaAlta  : BOOL;   (* Indica que la pieza detectada es alta *)
    bEsperando  : BOOL;   (* TRUE mientras se espera el retardo *)
END_VAR

(* ── Banda siempre activa ─────────────────────────────────────── *)
banda := TRUE;

(* ── Detección de flanco en sensorPresencia ───────────────────── *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    (* Nueva pieza detectada *)
    IF sensorAltura THEN
        (* Pieza alta: registrar y armar retardo *)
        nAltas     := nAltas + 1;
        bPiezaAlta := TRUE;
        bEsperando := TRUE;
    ELSE
        (* Pieza baja: solo contar *)
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* ── Retardo de 2 s (pieza viaja hasta el desviador) ─────────── *)
tRetardo(IN := bEsperando, PT := T#2S);

IF tRetardo.Q THEN
    (* Han pasado 2 s: activar pistón y detener retardo *)
    bEsperando := FALSE;
    tRetardo(IN := FALSE);  (* Reset del temporizador de retardo *)
    bPiezaAlta := TRUE;     (* Señal para arrancar temporizador pistón *)
END_IF;

(* ── Activación del pistón durante 1 s ───────────────────────── *)
tPiston(IN := tRetardo.Q OR tPiston.Q AND NOT tPiston.ET = T#1S, PT := T#1S);
(* Nota: se usa el flanco de salida de tRetardo para arrancar tPiston *)
tPiston(IN := (tRetardo.Q), PT := T#1S);

piston := tPiston.Q OR (tRetardo.Q);

(* ── Salida limpia del pistón ─────────────────────────────────── *)
(* tPiston corre mientras su entrada IN sea TRUE;
   se mantiene TRUE hasta que ET alcance PT (1 s) *)
IF tPiston.ET >= T#1S THEN
    tPiston(IN := FALSE);   (* Reset del temporizador del pistón *)
    piston := FALSE;
END_IF;

END_FUNCTION_BLOCK