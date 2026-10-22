PROGRAM PRG_Conversion

VAR_INPUT
    btnMarcha : BOOL; (* Botón de marcha (NO) *)
    btnParo   : BOOL; (* Botón de paro (NC - normalmente cerrado) *)
END_VAR

VAR_OUTPUT
    motor   : BOOL; (* Bobina del motor *)
    lampara : BOOL; (* Bobina de la lámpara *)
END_VAR

VAR
    T1 : TON; (* Temporizador on-delay, 10 segundos *)
END_VAR

(* ---------------------------------------------------------------
   Rama 1: (btnMarcha OR motor) AND NOT btnParo --> motor
   Equivale al circuito de enclavamiento (seal-in) con paro.
   btnParo es normalmente cerrado, por lo que se niega en ST.
--------------------------------------------------------------- *)
motor := (btnMarcha OR motor) AND NOT btnParo;

(* ---------------------------------------------------------------
   Rama 2: motor activa el temporizador TON T1 (PT = 10 s)
--------------------------------------------------------------- *)
T1(IN := motor, PT := T#10S);

(* ---------------------------------------------------------------
   Rama 3: T1.Q (contacto NO del temporizador) --> lampara
--------------------------------------------------------------- *)
lampara := T1.Q;

END_PROGRAM