```iecst
FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd  : BOOL; // Botón para giro en sentido horario
    btnRev  : BOOL; // Botón para giro en sentido antihorario
    btnParo : BOOL; // Botón de paro (prioridad a la desconexión)
END_VAR

VAR_OUTPUT
    fwd : BOOL; // Salida para motor en sentido horario
    rev : BOOL; // Salida para motor en sentido antihorario
END_VAR

(* 
   Lógica de control:
   - NOT btnParo: El paro tiene prioridad absoluta.
   - NOT rev / NOT fwd: Enclavamiento para evitar activación simultánea y obligar a pasar por paro.
   - NOT btnRev / NOT btnFwd: Evita problemas si se pulsan ambos botones a la vez estando el motor detenido.
   - (btnFwd OR fwd): Auto-retención (enclavamiento) de la señal.
*)

fwd := NOT btnParo AND NOT rev AND NOT btnRev AND (btnFwd OR fwd);
rev := NOT btnParo AND NOT fwd AND NOT btnFwd AND (btnRev OR rev);

END_FUNCTION_BLOCK
```