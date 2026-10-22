FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; (* Señal de puerta abierta *)
    reset         : BOOL; (* Reset del registro *)
END_VAR
VAR_OUTPUT
    aviso      : BOOL; (* Aviso por 5 o mas aperturas *)
    nAperturas : INT;  (* Contador de aperturas *)
END_VAR
VAR
    rTrigPuerta : R_TRIG; (* Detector de flanco ascendente *)
END_VAR

(* Detectar flanco ascendente de puertaAbierta *)
rTrigPuerta(CLK := puertaAbierta);

(* Reset tiene prioridad sobre el conteo *)
IF reset THEN
    nAperturas := 0;
ELSIF rTrigPuerta.Q THEN
    (* Incrementar solo en cada nueva apertura *)
    nAperturas := nAperturas + 1;
END_IF;

(* Activar aviso al alcanzar 5 o mas aperturas *)
aviso := nAperturas >= 5;

END_FUNCTION_BLOCK