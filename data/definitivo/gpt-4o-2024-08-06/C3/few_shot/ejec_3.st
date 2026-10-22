```pascal
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

(* Configuración del temporizador TON *)
T1(IN := motor, PT := T#10S);

(* La lámpara se enciende cuando el temporizador alcanza el tiempo preestablecido *)
lampara := T1.Q;
END_PROGRAM
```