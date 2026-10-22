FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Contacto NA para conteo *)
    btnReset : BOOL; (* Contacto NA para reset *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Bobina de lote completado *)
    cuenta : INT; (* Valor actual del contador *)
END_VAR
VAR
    C1 : CTU; (* Instancia del contador ascendente *)
END_VAR

(* Rama 1: Actualizacion del contador con PV = 12 *)
C1(CU := sensorPieza, RESET := btnReset, PV := 12);

(* Rama 2: La salida Q del contador alimenta la bobina loteListo *)
loteListo := C1.Q;

(* Rama 3: Transferencia del valor actual a la variable cuenta *)
cuenta := C1.CV;
END_FUNCTION_BLOCK