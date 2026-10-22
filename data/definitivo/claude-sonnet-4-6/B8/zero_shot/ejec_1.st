```pascal
FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; (* Señal de la puerta: TRUE = abierta *)
    reset         : BOOL; (* Reset del contador y aviso *)
END_VAR

VAR_OUTPUT
    aviso      : BOOL; (* TRUE cuando se alcanzan 5 o más aperturas *)
    nAperturas : INT;  (* Número de aperturas registradas *)
END_VAR

VAR
    puertaAbierta_prev : BOOL; (* Estado anterior para detección de flanco *)
END_VAR

(* ── Lógica principal ── *)

(* Reset tiene prioridad sobre el conteo *)
IF reset THEN
    nAperturas         := 0;
    aviso              := FALSE;
    puertaAbierta_prev := FALSE;

ELSE
    (* Detectar flanco ascendente: FALSE → TRUE *)
    IF puertaAbierta AND NOT puertaAbierta_prev THEN
        nAperturas := nAperturas + 1;
    END_IF;

    (* Activar aviso al alcanzar 5 o más aperturas *)
    aviso := (nAperturas >= 5);

END_IF;

(* Guardar estado actual para el siguiente ciclo *)
puertaAbierta_prev := puertaAbierta;

END_FUNCTION_BLOCK
```