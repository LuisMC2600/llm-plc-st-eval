```pascal
FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd  : BOOL; (* Boton marcha horaria *)
    btnRev  : BOOL; (* Boton marcha antihoraria *)
    btnParo : BOOL; (* Boton de paro *)
END_VAR
VAR_OUTPUT
    fwd : BOOL; (* Salida giro horario *)
    rev : BOOL; (* Salida giro antihorario *)
END_VAR

(* Logica de enclavamiento con paso obligatorio por paro *)

(* Paro: desactiva ambas salidas *)
IF btnParo THEN
    fwd := FALSE;
    rev := FALSE;

(* Marcha horaria: solo si rev no esta activa (no se permite inversion directa) *)
ELSIF btnFwd AND NOT rev THEN
    fwd := TRUE;

(* Marcha antihoraria: solo si fwd no esta activa (no se permite inversion directa) *)
ELSIF btnRev AND NOT fwd THEN
    rev := TRUE;
END_IF;

(* Seguridad hardware: garantiza exclusion mutua ante cualquier condicion imprevista *)
IF fwd AND rev THEN
    fwd := FALSE;
    rev := FALSE;
END_IF;

END_FUNCTION_BLOCK
```