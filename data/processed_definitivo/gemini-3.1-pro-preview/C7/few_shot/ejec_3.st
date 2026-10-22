FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Contacto NA para entrada de conteo *)
    btnReset : BOOL; (* Contacto NA para reset del contador *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Bobina indicadora de lote completo *)
    cuenta : INT; (* Valor actual del conteo *)
END_VAR
VAR
    C1 : CTU; (* Instancia del contador ascendente *)
END_VAR

(* Rama 1: Llamada al bloque contador con sus respectivas entradas y valor preestablecido *)
C1(CU := sensorPieza, RESET := btnReset, PV := 12);

(* Rama 2: El contacto de la salida Q del contador alimenta la bobina *)
loteListo := C1.Q;

(* Rama 3: Se transfiere el valor actual del contador a la salida *)
cuenta := C1.CV;
END_FUNCTION_BLOCK