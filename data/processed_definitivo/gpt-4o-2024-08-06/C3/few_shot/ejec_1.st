PROGRAM PRG_Conversion
VAR_INPUT
    btnMarcha : BOOL; (* Contacto NA en paralelo *)
    btnParo : BOOL; (* Contacto NC en serie *)
END_VAR
VAR_OUTPUT
    motor : BOOL; (* Bobina motor *)
    lampara : BOOL; (* Bobina lámpara *)
END_VAR
VAR
    T1 : TON; (* Temporizador TON *)
END_VAR

(* Serie = AND, paralelo = OR, contacto NC = NOT *)
motor := ((btnMarcha OR motor) AND NOT btnParo);

(* Temporizador TON activado por el motor *)
T1(IN := motor, PT := T#10S);

(* La lámpara se activa cuando el temporizador alcanza el tiempo preestablecido *)
lampara := T1.Q;
END_PROGRAM