PROGRAM PRG_Conversion
VAR_INPUT
    btnMarcha : BOOL; (* Contacto NA *)
    btnParo : BOOL; (* Contacto NC en la rama *)
END_VAR
VAR_OUTPUT
    motor : BOOL; (* Bobina *)
    lampara : BOOL; (* Bobina *)
END_VAR
VAR
    T1 : TON; (* Temporizador *)
END_VAR

(* Inicialización del temporizador *)
IF NOT T1.Q THEN
    T1(IN := FALSE, PT := T#10S);
END_IF

(* Rama 1: btnMarcha en paralelo con motor, ambos en serie con btnParo *)
motor := (btnMarcha OR motor) AND NOT btnParo;

(* Rama 2: motor alimenta el temporizador T1 *)
IF motor THEN
    T1(IN := TRUE);
ELSE
    T1(IN := FALSE);
END_IF

(* Rama 3: contacto NA de T1.Q alimenta la bobina lampara *)
lampara := T1.Q;

END_PROGRAM