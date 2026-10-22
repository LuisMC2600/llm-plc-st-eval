FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Contacto NA para contar *)
    btnReset : BOOL; (* Contacto NA para resetear el contador *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Bobina que se activa cuando se alcanza el lote *)
    cuenta : INT; (* Valor actual del contador *)
END_VAR
VAR
    C1 : CTU; (* Contador ascendente *)
END_VAR

(* Configuración del contador *)
C1.PV := 12; (* Valor preestablecido del contador *)

(* Rama 1: Conteo *)
IF sensorPieza THEN
    C1.CU := TRUE; (* Incrementa el contador *)
ELSE
    C1.CU := FALSE;
END_IF

(* Rama 2: Reset *)
IF btnReset THEN
    C1.RESET := TRUE; (* Resetea el contador *)
ELSE
    C1.RESET := FALSE;
END_IF

(* Rama 3: Actualización del contador *)
C1(); (* Ejecuta el contador *)
cuenta := C1.CV; (* Transfiere el valor actual del contador a la variable cuenta *)

(* Rama 4: Lote listo *)
loteListo := C1.Q; (* La bobina se activa cuando se alcanza el valor preestablecido *)
END_FUNCTION_BLOCK