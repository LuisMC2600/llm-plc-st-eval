FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; (* Señal de puerta: TRUE = abierta *)
    reset         : BOOL; (* Reset: pone contador a 0 y desactiva aviso *)
END_VAR

VAR_OUTPUT
    aviso      : BOOL; (* TRUE cuando nAperturas >= 5 *)
    nAperturas : INT;  (* Número de aperturas registradas *)
END_VAR

VAR
    puertaAbierta_prev : BOOL; (* Valor de puertaAbierta en el ciclo anterior *)
END_VAR

(* ------------------------------------------------------------------ *)
(* Lógica principal                                                     *)
(* ------------------------------------------------------------------ *)

(* Reset tiene prioridad sobre cualquier otra acción *)
IF reset THEN
    nAperturas         := 0;
    aviso              := FALSE;
    puertaAbierta_prev := FALSE; (* Evita flanco espurio tras el reset *)

ELSE
    (* Detección de flanco ascendente: FALSE -> TRUE *)
    IF puertaAbierta AND NOT puertaAbierta_prev THEN
        nAperturas := nAperturas + 1;
    END_IF;

    (* Activar aviso al alcanzar o superar 5 aperturas *)
    IF nAperturas >= 5 THEN
        aviso := TRUE;
    END_IF;

END_IF;

(* Guardar estado actual para el próximo ciclo *)
puertaAbierta_prev := puertaAbierta;

END_FUNCTION_BLOCK