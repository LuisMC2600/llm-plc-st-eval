PROGRAM PRG_Conversion
VAR
    btnMarcha : BOOL; (* Contacto NA en paralelo *)
    btnParo : BOOL; (* Contacto NC en serie *)
    motor : BOOL; (* Bobina motor *)
    lampara : BOOL; (* Bobina lámpara *)
    T1 : TON; (* Temporizador TON *)
END_VAR

(* Serie = AND, paralelo = OR, contacto NC = NOT *)
motor := ((btnMarcha OR motor) AND NOT btnParo);

(* Configuración y ejecución del temporizador TON *)
T1(IN := motor, PT := T#10S);

(* Activación de la lámpara cuando T1.Q es TRUE *)
lampara := T1.Q;
END_PROGRAM