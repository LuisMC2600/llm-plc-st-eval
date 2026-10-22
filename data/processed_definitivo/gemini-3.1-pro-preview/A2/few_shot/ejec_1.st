FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA : BOOL; (* Nivel del componente A alcanzado *)
    nivelB : BOOL; (* Nivel del componente B alcanzado *)
    nivelVacio : BOOL; (* Reactor vacio *)
    btnInicio : BOOL; (* Boton para iniciar receta *)
    btnAbort : BOOL; (* Boton para abortar receta *)
    temp : REAL; (* Temperatura actual del reactor *)
END_VAR
VAR_OUTPUT
    vA : BOOL; (* Valvula de dosificacion A *)
    vB : BOOL; (* Valvula de dosificacion B *)
    calentador : BOOL; (* Calentador del reactor *)
    mezclador : BOOL; (* Mezclador del reactor *)
    vDescarga : BOOL; (* Valvula de descarga *)
    fase : INT; (* Fase actual de la receta (0 a 5) *)
END_VAR
VAR
    tMezcla : TON; (* Temporizador para la fase de mezcla *)
END_VAR

(* Logica de aborto: aplicable solo en fases 1 a 4 *)
IF btnAbort AND (fase >= 1 AND fase <= 4) THEN
    IF NOT nivelVacio THEN
        fase := 5; (* Pasa a descarga si hay producto *)
    ELSE
        fase := 0; (* Pasa a reposo si ya esta vacio *)
    END_IF;
END_IF;

(* Maquina de estados de la receta *)
CASE fase OF
    0: (* Fase 0: Reposo *)
        IF btnInicio THEN
            fase := 1;
        END_IF;
        
    1: (* Fase 1: Dosificar componente A *)
        IF nivelA THEN
            fase := 2;
        END_IF;
        
    2: (* Fase 2: Dosificar componente B *)
        IF nivelB THEN
            fase := 3;
        END_IF;
        
    3: (* Fase 3: Calentar *)
        IF temp >= 60.0 THEN
            fase := 4;
        END_IF;
        
    4: (* Fase 4: Mezclar *)
        IF tMezcla.Q THEN
            fase := 5;
        END_IF;
        
    5: (* Fase 5: Descargar *)
        IF nivelVacio THEN
            fase := 0;
        END_IF;
ELSE
    fase := 0; (* Seguridad: estado no definido vuelve a reposo *)
END_CASE;

(* Temporizador de mezcla: activo solo durante la fase 4 *)
tMezcla(IN := (fase = 4), PT := T#120S);

(* Asignacion de salidas segun la fase activa *)
vA := (fase = 1);
vB := (fase = 2);
calentador := (fase = 3);
mezclador := (fase = 4);
vDescarga := (fase = 5);

END_FUNCTION_BLOCK