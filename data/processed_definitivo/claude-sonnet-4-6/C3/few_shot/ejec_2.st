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
    T1 : TON; (* Temporizador on-delay, PT = 10 s *)
END_VAR

(* Rama 1: (btnMarcha OR motor) AND NOT btnParo -> bobina motor *)
(* El contacto NA motor actua como enclavamiento (seal-in) *)
motor := (btnMarcha OR motor) AND NOT btnParo;

(* Rama 2: contacto NA motor habilita el temporizador T1 *)
(* Cuando motor se desactiva, T1 se resetea automaticamente *)
T1(IN := motor, PT := T#10S);

(* Rama 3: contacto NA T1.Q -> bobina lampara *)
(* La lampara se enciende cuando el motor lleva 10 s activo *)
lampara := T1.Q;

END_PROGRAM