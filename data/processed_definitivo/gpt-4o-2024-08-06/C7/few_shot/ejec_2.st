FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Contacto NA para conteo *)
    btnReset : BOOL; (* Contacto NA para reset *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Bobina activada cuando el conteo alcanza PV *)
    cuenta : INT; (* Valor actual del contador *)
END_VAR
VAR
    C1 : CTU; (* Contador ascendente *)
END_VAR

(* Configuración del contador ascendente *)
C1(CU := sensorPieza, RESET := btnReset, PV := 12);

(* Rama 2: activar loteListo cuando C1.Q es TRUE *)
loteListo := C1.Q;

(* Rama 3: transferir el valor actual del contador a cuenta *)
cuenta := C1.CV;
END_FUNCTION_BLOCK