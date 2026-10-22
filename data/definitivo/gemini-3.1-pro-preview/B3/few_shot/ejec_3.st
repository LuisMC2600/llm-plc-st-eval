FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor de pieza *)
    btnReset : BOOL; (* Boton de reset *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Salida de lote completo *)
    cuenta : INT; (* Cuenta de piezas *)
END_VAR
VAR
    cPiezas : CTU; (* Contador ascendente *)
END_VAR

(* Incrementa con cada pieza, activa salida al llegar a 12 y permite reset *)
cPiezas(CU := sensorPieza, RESET := btnReset, PV := 12);
loteListo := cPiezas.Q;
cuenta := cPiezas.CV;
END_FUNCTION_BLOCK