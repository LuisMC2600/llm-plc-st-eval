FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; (* Señal de puerta abierta *)
    reset : BOOL; (* Reset del registro *)
END_VAR
VAR_OUTPUT
    aviso : BOOL; (* Aviso por 5 o mas aperturas *)
    nAperturas : INT; (* Contador de aperturas *)
END_VAR
VAR
    contador : CTU; (* Contador ascendente *)
END_VAR

(* Cuenta los flancos de subida y activa el aviso al llegar a 5 *)
contador(CU := puertaAbierta, RESET := reset, PV := 5);
aviso := contador.Q;
nAperturas := contador.CV;
END_FUNCTION_BLOCK