```pascal
FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd : BOOL; (* Boton para giro horario *)
    btnRev : BOOL; (* Boton para giro antihorario *)
    btnParo : BOOL; (* Boton de paro *)
END_VAR
VAR_OUTPUT
    fwd : BOOL; (* Salida para giro horario *)
    rev : BOOL; (* Salida para giro antihorario *)
END_VAR
VAR
    estado : INT; (* Estado del motor: 0 = Paro, 1 = Horario, 2 = Antihorario *)
END_VAR

(* Logica de control para inversion de giro del motor *)
IF btnParo THEN
    estado := 0; (* Parar el motor *)
ELSIF btnFwd AND (estado = 0) THEN
    estado := 1; (* Activar giro horario si el motor está parado *)
ELSIF btnRev AND (estado = 0) THEN
    estado := 2; (* Activar giro antihorario si el motor está parado *)
END_IF

(* Actualizar salidas segun el estado *)
fwd := (estado = 1);
rev := (estado = 2);
END_FUNCTION_BLOCK
```