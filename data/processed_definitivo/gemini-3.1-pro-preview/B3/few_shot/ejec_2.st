FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor fotoelectrico de piezas *)
    btnReset : BOOL; (* Boton de reinicio de cuenta *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Indicador de lote completo *)
    cuenta : INT; (* Cantidad actual de piezas *)
END_VAR
VAR
    contador : CTU; (* Bloque contador ascendente *)
END_VAR

(* El contador incrementa con el flanco de subida del sensor y se reinicia con el boton *)
contador(CU := sensorPieza, RESET := btnReset, PV := 12);

(* Asignacion de salidas *)
loteListo := contador.Q;
cuenta := contador.CV;
END_FUNCTION_BLOCK