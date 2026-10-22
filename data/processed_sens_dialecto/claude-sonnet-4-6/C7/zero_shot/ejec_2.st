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
   R   <- btnReset    (reset del contador)
   PV  = 12          (valor preestablecido del lote)
   ------------------------------------------------------- *)
C1(
    CU := sensorPieza,
    RESET  := btnReset,
    PV := 12
);

(* -------------------------------------------------------
   Rama 2: Bobina loteListo
   Se activa cuando C1.Q = TRUE (CV >= PV)
   ------------------------------------------------------- *)
loteListo := C1.Q;

(* -------------------------------------------------------
   Rama 3: Transferencia del valor actual a cuenta
   ------------------------------------------------------- *)
cuenta := C1.CV;
END_FUNCTION_BLOCK