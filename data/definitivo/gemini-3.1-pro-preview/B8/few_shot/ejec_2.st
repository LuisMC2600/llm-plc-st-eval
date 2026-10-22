FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; (* Senal de puerta abierta *)
    reset : BOOL; (* Resetea el contador y el aviso *)
END_VAR
VAR_OUTPUT
    aviso : BOOL; (* Aviso de 5 o mas aperturas *)
    nAperturas : INT; (* Numero de aperturas registradas *)
END_VAR
VAR
    flancoApertura : R_TRIG; (* Detector de flanco ascendente *)
END_VAR

(* Deteccion de transicion de FALSE a TRUE *)
flancoApertura(CLK := puertaAbierta);

(* Logica de reseteo e incremento del contador *)
IF reset THEN
    nAperturas := 0;
ELSIF flancoApertura.Q THEN
    nAperturas := nAperturas + 1;
END_IF;

(* Activacion del aviso al acumular 5 o mas aperturas *)
aviso := (nAperturas >= 5);
END_FUNCTION_BLOCK