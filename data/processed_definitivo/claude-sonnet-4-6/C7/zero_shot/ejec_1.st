FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor de detección de pieza *)
    btnReset    : BOOL; (* Botón de reset del contador *)
END_VAR

VAR_OUTPUT
    loteListo : BOOL; (* Indica que el lote de 12 piezas está completo *)
    cuenta    : INT;  (* Valor actual del contador *)
END_VAR

VAR
    C1 : CTU; (* Contador ascendente IEC 61131-3 *)
END_VAR

(* -------------------------------------------------------
   Rama 1: Contador ascendente C1
   CU  <- sensorPieza (flanco ascendente cuenta una pieza)
   RESET <- btnReset  (reinicia el contador)
   PV  = 12           (tamaño del lote)
------------------------------------------------------- *)
C1(
    CU    := sensorPieza,
    RESET := btnReset,
    PV    := 12
);

(* -------------------------------------------------------
   Rama 2: Activar loteListo cuando el contador alcanza PV
   Equivale al contacto normalmente abierto de C1.Q
   alimentando la bobina loteListo
------------------------------------------------------- *)
loteListo := C1.Q;

(* -------------------------------------------------------
   Rama 3: Transferir el valor actual del contador
   a la variable de salida cuenta
------------------------------------------------------- *)
cuenta := C1.CV;

END_FUNCTION_BLOCK