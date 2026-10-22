FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Detecta el paso de una pieza *)
    sensorAltura    : BOOL; (* TRUE si la pieza es alta *)
END_VAR

VAR_OUTPUT
    banda   : BOOL; (* Activa la banda transportadora *)
    piston  : BOOL; (* Activa el desviador *)
    nAltas  : INT;  (* Contador de piezas altas *)
    nBajas  : INT;  (* Contador de piezas bajas *)
END_VAR

VAR
    rPresencia      : R_TRIG;       (* Flanco ascendente de sensorPresencia *)
    piezaAlta       : BOOL;         (* Indica que la pieza detectada es alta *)
    timerRetardo    : TON;          (* Retardo de 2 s hasta el desviador *)
    timerPiston     : TON;          (* Duración de 1 s del pistón *)
END_VAR

(* ─────────────────────────────────────────────
   La banda funciona siempre de forma continua
   ───────────────────────────────────────────── *)
banda := TRUE;

(* ─────────────────────────────────────────────
   Detección de flanco ascendente en sensorPresencia
   ───────────────────────────────────────────── *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    (* Nueva pieza detectada *)
    IF sensorAltura THEN
        (* Pieza alta: armar retardo y contabilizar *)
        piezaAlta := TRUE;
        nAltas    := nAltas + 1;
    ELSE
        (* Pieza baja: solo contabilizar *)
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* ─────────────────────────────────────────────
   Temporizador de retardo: 2 s desde la detección
   Se activa mientras piezaAlta esté pendiente y
   el pistón aún no haya comenzado su ciclo
   ───────────────────────────────────────────── *)
timerRetardo(IN := piezaAlta AND NOT timerPiston.Q,
             PT := T#2S);

(* ─────────────────────────────────────────────
   Temporizador del pistón: 1 s de activación
   Arranca cuando el retardo ha concluido
   ───────────────────────────────────────────── *)
timerPiston(IN := timerRetardo.Q,
            PT := T#1S);

(* ─────────────────────────────────────────────
   Salida del pistón activa durante el segundo
   temporizador
   ───────────────────────────────────────────── *)
piston := timerPiston.IN AND NOT timerPiston.Q;

(* ─────────────────────────────────────────────
   Cuando el pistón termina su ciclo, limpiar
   el flag y dejar que los temporizadores se
   reinicien en el siguiente ciclo de scan
   ───────────────────────────────────────────── *)
IF timerPiston.Q THEN
    piezaAlta := FALSE;
END_IF;

END_FUNCTION_BLOCK