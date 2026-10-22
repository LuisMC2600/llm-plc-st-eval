PROGRAM PRG_Conversion
VAR_INPUT
    btnMarcha : BOOL; (* Contacto NA: arranque *)
    btnParo   : BOOL; (* Contacto NC: paro *)
END_VAR
VAR_OUTPUT
    motor   : BOOL; (* Bobina motor / contacto de enclavamiento *)
    lampara : BOOL; (* Bobina lampara *)
END_VAR
VAR
    T1 : TON; (* Temporizador, tiempo preestablecido 10 s *)
END_VAR

(* Rama 1: (btnMarcha OR motor) AND NOT btnParo -> bobina motor *)
(* Paralelo = OR, serie = AND, contacto NC = NOT *)
motor := (btnMarcha OR motor) AND NOT btnParo;

(* Rama 2: contacto NA motor habilita el temporizador TON T1 *)
T1(IN := motor, PT := T#10S);

(* Rama 3: contacto NA T1.Q alimenta la bobina lampara *)
lampara := T1.Q;

END_PROGRAM