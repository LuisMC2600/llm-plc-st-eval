FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura    : BOOL; (* TRUE = pieza alta *)
END_VAR

VAR_OUTPUT
    banda   : BOOL; (* Salida banda transportadora *)
    piston  : BOOL; (* Salida pistón desviador *)
    nAltas  : INT;  (* Contador de piezas altas *)
    nBajas  : INT;  (* Contador de piezas bajas *)
END_VAR

VAR
    tRetardo    : TON; (* Temporizador retardo 2 s hasta el desviador *)
    tPiston     : TON; (* Temporizador duración del pistón 1 s *)
    rPresencia  : R_TRIG; (* Flanco ascendente del sensor de presencia *)
    bPiezaAlta  : BOOL;  (* Memoriza si la pieza detectada es alta *)
    bEsperando  : BOOL;  (* TRUE mientras se espera el retardo de 2 s *)
END_VAR

(* ── Banda siempre activa ─────────────────────────────────────── *)
banda := TRUE;

(* ── Detección de flanco en sensorPresencia ───────────────────── *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    (* Nueva pieza detectada; registrar su tipo y arrancar retardo *)
    bPiezaAlta := sensorAltura;

    IF bPiezaAlta THEN
        nAltas := nAltas + 1; (* Contar pieza alta *)
        bEsperando := TRUE;   (* Activar espera del retardo *)
    ELSE
        nBajas := nBajas + 1; (* Contar pieza baja; no se desvía *)
    END_IF;
END_IF;

(* ── Temporizador de retardo: 2 s desde detección ────────────── *)
tRetardo(IN := bEsperando, PT := T#2S);

IF tRetardo.Q THEN
    (* Han pasado 2 s: activar pistón y arrancar su temporizador *)
    bEsperando := FALSE;
    tRetardo(IN := FALSE); (* Resetear temporizador de retardo *)
END_IF;

(* ── Temporizador de duración del pistón: 1 s ────────────────── *)
tPiston(IN := tRetardo.Q, PT := T#1S);
(* Nota: tRetardo.Q permanece TRUE un ciclo; el flanco es suficiente
   para que tPiston arranque con IN=TRUE en ese ciclo.             *)

piston := tPiston.IN AND NOT tPiston.Q;
(* El pistón está activo mientras tPiston cuenta y aún no terminó *)

IF tPiston.Q THEN
    tPiston(IN := FALSE); (* Resetear temporizador del pistón *)
END_IF;

END_FUNCTION_BLOCK