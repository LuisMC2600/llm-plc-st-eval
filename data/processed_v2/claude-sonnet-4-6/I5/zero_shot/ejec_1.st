FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura    : BOOL; (* TRUE = pieza alta *)
END_VAR

VAR_OUTPUT
    banda   : BOOL; (* Banda transportadora siempre activa *)
    piston  : BOOL; (* Salida del desviador *)
    nAltas  : INT;  (* Contador piezas altas *)
    nBajas  : INT;  (* Contador piezas bajas *)
END_VAR

VAR
    rPresencia : R_TRIG; (* Flanco ascendente sensor presencia *)
    tRetardo   : TON;    (* Retardo 2 s: detección → desviador *)
    tPiston    : TON;    (* Duración pistón: 1 s *)

    (* Estados de la máquina:
       0 = reposo
       1 = esperando retardo (pieza alta en camino)
       2 = pistón activo                              *)
    nEstado : INT;
END_VAR

(* ── Banda siempre en marcha ──────────────────────────────────── *)
banda := TRUE;

(* ── Detección de flanco ascendente en sensorPresencia ───────── *)
rPresencia(CLK := sensorPresencia);

(* ── Máquina de estados ───────────────────────────────────────── *)
CASE nEstado OF

    0: (* Reposo: esperando nueva pieza *)
        tRetardo(IN := FALSE, PT := T#2S); (* Mantener reset *)
        tPiston (IN := FALSE, PT := T#1S); (* Mantener reset *)
        piston := FALSE;

        IF rPresencia.Q THEN
            IF sensorAltura THEN
                (* Pieza alta detectada *)
                nAltas  := nAltas + 1;
                nEstado := 1; (* Ir a esperar retardo *)
            ELSE
                (* Pieza baja detectada *)
                nBajas := nBajas + 1;
                (* Permanece en estado 0 *)
            END_IF;
        END_IF;

    1: (* Retardo 2 s: pieza viajando hacia el desviador *)
        tRetardo(IN := TRUE, PT := T#2S);
        piston := FALSE;

        IF tRetardo.Q THEN
            tRetardo(IN := FALSE, PT := T#2S); (* Reset retardo *)
            nEstado := 2; (* Activar pistón *)
        END_IF;

    2: (* Pistón activo durante 1 s *)
        tPiston(IN := TRUE, PT := T#1S);
        piston := TRUE;

        IF tPiston.Q THEN
            tPiston(IN := FALSE, PT := T#1S); (* Reset pistón *)
            piston  := FALSE;
            nEstado := 0; (* Volver a reposo *)
        END_IF;

ELSE
    (* Estado desconocido: recuperación segura *)
    nEstado := 0;

END_CASE;

END_FUNCTION_BLOCK