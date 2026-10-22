FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor de deteccion de pieza *)
    btnReset : BOOL; (* Boton de reinicio *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Salida de lote completo *)
    cuenta : INT; (* Cantidad de piezas contadas *)
END_VAR
VAR
    ctPiezas : CTU; (* Bloque contador ascendente *)
END_VAR

(* El contador incrementa con el flanco de subida del sensor *)
ctPiezas(CU := sensorPieza, R := btnReset, PV := 12);

(* Asignacion de salidas *)
loteListo := ctPiezas.Q;
cuenta := ctPiezas.CV;
END_FUNCTION_BLOCK