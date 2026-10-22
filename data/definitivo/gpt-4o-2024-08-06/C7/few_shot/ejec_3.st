```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Contacto NA para conteo *)
    btnReset : BOOL; (* Contacto NA para reset *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Bobina activada por C1.Q *)
    cuenta : INT; (* Valor actual del contador *)
END_VAR
VAR
    C1 : CTU; (* Contador ascendente *)
END_VAR

(* Configuración del contador *)
C1(CU := sensorPieza, RESET := btnReset, PV := 12);

(* Rama 2: Activación de la bobina loteListo cuando C1.Q es TRUE *)
loteListo := C1.Q;

(* Rama 3: Transferencia del valor actual del contador a la salida cuenta *)
cuenta := C1.CV;
END_FUNCTION_BLOCK
```