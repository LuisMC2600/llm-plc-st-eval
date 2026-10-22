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
    puertaAbiertaAnterior : BOOL; (* Estado anterior de la puerta *)
END_VAR

(* Reinicio del registro *)
IF reset THEN
    nAperturas := 0;
    aviso := FALSE;
END_IF

(* Detección de transición de FALSE a TRUE *)
IF puertaAbierta AND NOT puertaAbiertaAnterior THEN
    nAperturas := nAperturas + 1;
END_IF

(* Actualización del estado anterior *)
puertaAbiertaAnterior := puertaAbierta;

(* Activación del aviso si se alcanzan 5 aperturas *)
IF nAperturas >= 5 THEN
    aviso := TRUE;
END_IF
END_FUNCTION_BLOCK