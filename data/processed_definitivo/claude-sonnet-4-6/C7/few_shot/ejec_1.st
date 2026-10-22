FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Contacto NA: entrada de conteo *)
    btnReset    : BOOL; (* Contacto NA: reset del contador *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Bobina: activada cuando C1.Q = TRUE *)
    cuenta    : INT;  (* Valor actual del contador C1.CV *)
END_VAR
VAR
    C1 : CTU; (* Contador ascendente *)
END_VAR

(* Rama 1: sensorPieza -> CU, btnReset -> RESET, PV = 12 *)
C1(CU := sensorPieza, RESET := btnReset, PV := 12);

(* Rama 2: C1.Q alimenta la bobina loteListo *)
loteListo := C1.Q;

(* Rama 3: transferencia del valor actual a cuenta *)
cuenta := C1.CV;

END_FUNCTION_BLOCK