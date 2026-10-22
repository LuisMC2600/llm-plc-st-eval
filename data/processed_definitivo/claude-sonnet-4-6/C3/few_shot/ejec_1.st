PROGRAM PRG_Conversion
VAR_INPUT
    btnMarcha : BOOL; (* Contacto NA: arranque *)
    btnParo   : BOOL; (* Contacto NC: paro *)
END_VAR
VAR_OUTPUT
    motor   : BOOL; (* Bobina motor / contacto de enclavamiento *)
    lampara : BOOL; (* Bobina lámpara *)
END_VAR
VAR
    T1 : TON; (* Temporizador retardo a la conexión *)
END_VAR

(* Rama 1: (btnMarcha OR motor) AND NOT btnParo -> bobina motor *)
(* El contacto NA motor actúa como enclavamiento (auto-retención)  *)
motor := (btnMarcha OR motor) AND NOT btnParo;

(* Rama 2: contacto NA motor habilita el temporizador T1 (PT = 10 s) *)
T1(IN := motor, PT := T#10S);

(* Rama 3: contacto NA T1.Q -> bobina lámpara *)
lampara := T1.Q;

END_PROGRAM