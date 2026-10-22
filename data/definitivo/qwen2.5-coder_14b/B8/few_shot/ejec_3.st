FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; (* Señal de puerta abierta *)
    reset : BOOL; (* Botón de reset *)
END_VAR
VAR_OUTPUT
    aviso : BOOL; (* Salida de aviso *)
    nAperturas : INT; (* Número de aperturas *)
END_VAR
VAR
    puertaAbiertaAnterior : BOOL; (* Estado anterior de la puerta abierta *)
END_VAR

(* Reinicio del registro *)
IF reset THEN
    nAperturas := 0;
    aviso := FALSE;
ELSE
    (* Detección de transición de FALSE a TRUE *)
    IF NOT puertaAbiertaAnterior AND puertaAbierta THEN
        nAperturas := nAperturas + 1;
    END_IF

    (* Activación del aviso si se alcanzan 5 aperturas *)
    aviso := nAperturas >= 5;
END_IF

(* Actualización del estado anterior de la puerta *)
puertaAbiertaAnterior := puertaAbierta;
END_FUNCTION_BLOCK