FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Contacto NA que alimenta CU *)
    btnReset : BOOL; (* Contacto NA que alimenta RESET *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Bobina que se activa cuando C1.Q es TRUE *)
    cuenta : INT; (* Valor actual del contador *)
END_VAR
VAR
    C1 : CTU; (* Contador ascendente *)
END_VAR

(* Configuración del contador *)
C1.PV := 12; (* Valor preestablecido a 12 *)

(* Rama 1: alimentar CU y RESET *)
IF sensorPieza THEN
    C1.CU := TRUE;
ELSE
    C1.CU := FALSE;
END_IF

IF btnReset THEN
    C1.RESET := TRUE;
ELSE
    C1.RESET := FALSE;
END_IF

(* Rama 2: alimentar loteListo *)
loteListo := C1.Q;

(* Rama 3: transferir C1.CV a cuenta *)
cuenta := C1.CV;

(* Actualizar el contador *)
C1();

END_FUNCTION_BLOCK