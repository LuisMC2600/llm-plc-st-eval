```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor de detección de pieza (contacto NA) *)
    btnReset    : BOOL; (* Botón de reset del contador (contacto NA) *)
END_VAR

VAR_OUTPUT
    loteListo : BOOL; (* Activa cuando se completa el lote (C1.Q) *)
    cuenta    : INT;  (* Valor actual del contador (C1.CV) *)
END_VAR

VAR
    C1 : CTU; (* Contador ascendente IEC 61131-3 *)
END_VAR

(* ---------------------------------------------------------------
   Rama 1: sensorPieza -> CU de C1 | btnReset -> RESET de C1
   Rama 2: C1.Q -> loteListo
   Rama 3: C1.CV -> cuenta
--------------------------------------------------------------- *)

(* Rama 1: llamada al contador CTU *)
C1(
    CU    := sensorPieza, (* Flanco ascendente de sensorPieza incrementa el contador *)
    RESET := btnReset,    (* btnReset pone CV a 0 y Q a FALSE *)
    PV    := 12           (* Valor preestablecido del lote *)
);

(* Rama 2: la salida Q del contador activa loteListo *)
loteListo := C1.Q;

(* Rama 3: transferencia del valor actual a la variable cuenta *)
cuenta := C1.CV;
```