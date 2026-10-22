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
    tRetardo    : TON; (* Temporizador retardo 2 s hasta el desviador *)
    tPiston     : TON; (* Temporizador duración del pistón 1 s *)
    rPresencia  : R_TRIG; (* Flanco ascendente del sensor de presencia *)
    bPiezaAlta  : BOOL;  (* Indica que la pieza detectada es alta *)
    bContado    : BOOL;  (* Evita contar la misma pieza más de una vez *)
END_VAR

(* ------------------------------------------------------------------ *)
(* 1. La banda funciona siempre                                        *)
(* ------------------------------------------------------------------ *)
banda := TRUE;

(* ------------------------------------------------------------------ *)
(* 2. Detectar flanco ascendente del sensor de presencia              *)
(* ------------------------------------------------------------------ *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    (* Capturar si la pieza es alta en el momento de la detección *)
    bPiezaAlta := sensorAltura;
    bContado   := FALSE; (* Reiniciar bandera de conteo *)

    IF bPiezaAlta THEN
        (* Arrancar el temporizador de retardo (2 s) *)
        tRetardo.IN := FALSE; (* Reset previo para reiniciar *)
    END_IF;
END_IF;

(* ------------------------------------------------------------------ *)
(* 3. Temporizador de retardo: 2 s desde la detección                 *)
(* ------------------------------------------------------------------ *)
tRetardo(IN := bPiezaAlta AND NOT tPiston.Q,
         PT := T#2S);

(* ------------------------------------------------------------------ *)
(* 4. Temporizador de pistón: 1 s de activación                       *)
(* ------------------------------------------------------------------ *)
tPiston(IN := tRetardo.Q,
        PT := T#1S);

(* ------------------------------------------------------------------ *)
(* 5. Activar pistón durante el tiempo definido                       *)
(* ------------------------------------------------------------------ *)
piston := tPiston.IN AND NOT tPiston.Q;
(* tPiston.IN=TRUE y Q=FALSE => dentro del período de 1 s            *)

(* ------------------------------------------------------------------ *)
(* 6. Cuando el pistón termina, limpiar estado y contar               *)
(* ------------------------------------------------------------------ *)
IF tPiston.Q AND NOT bContado THEN
    nAltas   := nAltas + 1;
    bContado   := TRUE;
    bPiezaAlta := FALSE; (* Liberar para la siguiente pieza *)
    tRetardo.IN := FALSE; (* Reiniciar temporizadores *)
    tPiston.IN  := FALSE;
END_IF;

(* ------------------------------------------------------------------ *)
(* 7. Contar piezas bajas (flanco de presencia + altura inactiva)     *)
(* ------------------------------------------------------------------ *)
IF rPresencia.Q AND NOT sensorAltura THEN
    nBajas := nBajas + 1;
END_IF;

END_FUNCTION_BLOCK
```