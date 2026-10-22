FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; (* Señal de estado de la puerta (TRUE = abierta) *)
    reset : BOOL;         (* Señal para reiniciar el contador y apagar el aviso *)
END_VAR

VAR_OUTPUT
    aviso : BOOL;         (* Indicador de alarma por 5 o más aperturas *)
    nAperturas : INT;     (* Registro del número de aperturas acumuladas *)
END_VAR

VAR
    flancoApertura : R_TRIG; (* Instancia para detectar el flanco de subida *)
END_VAR

(* Detección de la transición de FALSE a TRUE en la señal de la puerta *)
flancoApertura(CLK := puertaAbierta);

(* Lógica de reinicio y conteo de aperturas *)
IF reset THEN
    nAperturas := 0;
ELSIF flancoApertura.Q THEN
    nAperturas := nAperturas + 1;
END_IF;

(* Activación del aviso si se alcanzan 5 o más aperturas *)
aviso := (nAperturas >= 5);

END_FUNCTION_BLOCK