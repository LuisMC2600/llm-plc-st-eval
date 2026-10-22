```iecst
FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd  : BOOL; // Botón para iniciar giro en sentido horario
    btnRev  : BOOL; // Botón para iniciar giro en sentido antihorario
    btnParo : BOOL; // Botón de paro (TRUE = detener motor)
END_VAR

VAR_OUTPUT
    fwd : BOOL; // Comando de salida para giro horario
    rev : BOOL; // Comando de salida para giro antihorario
END_VAR

(* 
   Lógica de control de giro:
   - Se utiliza un circuito de auto-retención (enclavamiento) para cada sentido.
   - La condición "NOT rev" en fwd y "NOT fwd" en rev garantiza que nunca 
     estén activas simultáneamente.
   - Al estar enclavado un sentido, presionar el botón del sentido opuesto 
     no tendrá efecto. Es obligatorio presionar btnParo primero.
*)

fwd := (btnFwd OR fwd) AND NOT rev AND NOT btnParo;
rev := (btnRev OR rev) AND NOT fwd AND NOT btnParo;

END_FUNCTION_BLOCK
```