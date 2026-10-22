FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; (* Señal de demanda para activar una bomba *)
    falla1 : BOOL; (* Indica una falla en la bomba 1 *)
    falla2 : BOOL; (* Indica una falla en la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL; (* Control de la bomba 1 *)
    bomba2 : BOOL; (* Control de la bomba 2 *)
    almFalla : BOOL; (* Almacena la información de la última falla detectada *)
END_VAR
VAR
    turno : BOOL; (* Variable de estado para alternar entre bomba1 y bomba2 *)
    fDem : R_TRIG; (* Temporizador de flanco ascendente para detectar demanda *)
END_VAR

(* Configura el temporizador de flanco ascendente con la señal de demanda *)
fDem(CLK := demanda);

(* Si se detecta una demanda (flanco ascendente) *)
IF fDem.Q THEN
    (* Alterna el estado de la variable turno *)
    turno := NOT turno;
END_IF

(* Si hay una demanda *)
IF demanda THEN
    (* Si el turno está en TRUE *)
    IF turno THEN
        (* Activa bomba1 si no hay falla en bomba1 *)
        bomba1 := NOT falla1;
        (* Activa bomba2 si hay falla en bomba1 y no hay falla en bomba2 *)
        bomba2 := falla1 AND NOT falla2;
        (* Almacena la información de la última falla detectada *)
        almFalla := falla1;
    (* Si el turno está en FALSE *)
    ELSE
        (* Activa bomba2 si no hay falla en bomba2 *)
        bomba2 := NOT falla2;
        (* Activa bomba1 si hay falla en bomba2 y no hay falla en bomba1 *)
        bomba1 := falla2 AND NOT falla1;
        (* Almacena la información de la última falla detectada *)
        almFalla := falla2;
    END_IF
(* Si no hay demanda *)
ELSE
    (* Desactiva ambas bombas *)
    bomba1 := FALSE;
    bomba2 := FALSE;
    (* Limpia la información de la última falla detectada *)
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK