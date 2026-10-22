```pascal
FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd  : BOOL; (* Boton marcha sentido horario *)
    btnRev  : BOOL; (* Boton marcha sentido antihorario *)
    btnParo : BOOL; (* Boton de paro *)
END_VAR
VAR_OUTPUT
    fwd : BOOL; (* Salida sentido horario *)
    rev : BOOL; (* Salida sentido antihorario *)
END_VAR

(* Paro: desactiva ambas salidas *)
IF btnParo THEN
    fwd := FALSE;
    rev := FALSE;

(* Sentido horario: solo si rev no esta activa (paso previo por paro obligatorio) *)
ELSIF btnFwd AND NOT rev THEN
    fwd := TRUE;

(* Sentido antihorario: solo si fwd no esta activa (paso previo por paro obligatorio) *)
ELSIF btnRev AND NOT fwd THEN
    rev := TRUE;
END_IF;

(* Enclavamiento de seguridad: garantiza que nunca coincidan ambas salidas *)
IF fwd AND rev THEN
    fwd := FALSE;
    rev := FALSE;
END_IF;
END_FUNCTION_BLOCK
```