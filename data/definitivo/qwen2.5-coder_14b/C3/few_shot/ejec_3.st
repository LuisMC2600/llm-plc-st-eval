PROGRAM PRG_Conversion
VAR_INPUT
    btnMarcha : BOOL; (* Contacto NA *)
    btnParo : BOOL; (* Contacto NC *)
END_VAR
VAR_OUTPUT
    motor : BOOL; (* Bobina *)
    lampara : BOOL; (* Bobina *)
END_VAR
VAR
    T1 : TON; (* Temporizador *)
END_VAR

(* Rama 1: btnMarcha en paralelo con motor, ambos en serie con btnParo *)
motor := (btnMarcha OR motor) AND NOT btnParo;

(* Rama 2: motor alimenta el temporizador T1 con tiempo de 10 segundos *)
IF motor THEN
    T1(IN := TRUE, PT := T#10S);
ELSE
    T1(IN := FALSE);
END_IF;

(* Rama 3: contacto NA de T1.Q alimenta la bobina lampara *)
lampara := T1.Q;
END_PROGRAM