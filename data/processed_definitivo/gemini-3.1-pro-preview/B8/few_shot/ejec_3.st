FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; (* Señal de puerta abierta *)
    reset : BOOL; (* Reinicia el registro y el aviso *)
END_VAR
VAR_OUTPUT
    aviso : BOOL; (* Activo al alcanzar 5 o mas aperturas *)
    nAperturas : INT; (* Contador de aperturas *)
END_VAR
VAR
    flancoApertura : R_TRIG; (* Detector de flanco de subida *)
END_VAR

(* Deteccion de la transicion de FALSE a TRUE *)
flancoApertura(CLK := puertaAbierta);

(* Logica de reinicio y conteo *)
IF reset THEN
    nAperturas := 0;
ELSIF flancoApertura.Q THEN
    nAperturas := nAperturas + 1;
END_IF;

(* Evaluacion del aviso *)
aviso := (nAperturas >= 5);
END_FUNCTION_BLOCK