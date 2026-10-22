FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; (* Señal de puerta abierta *)
    reset         : BOOL; (* Pone el registro en cero *)
END_VAR
VAR_OUTPUT
    aviso      : BOOL; (* Aviso al acumular 5 o mas aperturas *)
    nAperturas : INT;  (* Contador de aperturas *)
END_VAR
VAR
    rTrigPuerta : R_TRIG; (* Detector de flanco ascendente de la puerta *)
END_VAR

(* Detectar flanco ascendente: solo cuenta la transicion FALSE->TRUE *)
rTrigPuerta(CLK := puertaAbierta);

IF reset THEN
    (* Reset: pone el contador en cero y desactiva el aviso *)
    nAperturas := 0;
ELSIF rTrigPuerta.Q THEN
    (* Nueva apertura detectada: incrementar contador *)
    nAperturas := nAperturas + 1;
END_IF;

(* Activar aviso si se han acumulado 5 o mas aperturas *)
aviso := nAperturas >= 5;
END_FUNCTION_BLOCK