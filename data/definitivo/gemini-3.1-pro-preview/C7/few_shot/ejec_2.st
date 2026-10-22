FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Contacto NA para conteo *)
    btnReset : BOOL; (* Contacto NA para reset *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Bobina indicadora de lote *)
    cuenta : INT; (* Valor actual del contador *)
END_VAR
VAR
    C1 : CTU; (* Instancia del contador ascendente *)
END_VAR

(* Rama 1: Llamada al bloque contador con sus parametros *)
C1(CU := sensorPieza, RESET := btnReset, PV := 12);

(* Rama 2: La salida Q del contador alimenta la bobina *)
loteListo := C1.Q;

(* Rama 3: Se transfiere el valor actual CV a la salida *)
cuenta := C1.CV;
END_FUNCTION_BLOCK