FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA : BOOL; (* Nivel del componente A alcanzado *)
    nivelB : BOOL; (* Nivel del componente B alcanzado *)
    nivelVacio : BOOL; (* Reactor vacio *)
    btnInicio : BOOL; (* Boton de inicio de receta *)
    btnAbort : BOOL; (* Boton de aborto de receta *)
    temp : REAL; (* Temperatura del reactor *)
END_VAR
VAR_OUTPUT
    vA : BOOL; (* Valvula de componente A *)
    vB : BOOL; (* Valvula de componente B *)
    calentador : BOOL; (* Calentador del reactor *)
    mezclador : BOOL; (* Mezclador del reactor *)
    vDescarga : BOOL; (* Valvula de descarga *)
    fase : INT; (* Fase actual de la receta (0 a 5) *)
END_VAR
VAR
    tMezcla : TON; (* Temporizador de mezclado *)
    trigInicio : R_TRIG; (* Flanco de subida para inicio *)
    trigAbort : R_TRIG; (* Flanco de subida para aborto *)
END_VAR

(* Deteccion de pulsaciones *)
trigInicio(CLK := btnInicio);
trigAbort(CLK := btnAbort);

(* Logica de aborto: activa en cualquier fase distinta de reposo *)
IF trigAbort.Q AND fase > 0 THEN
    IF NOT nivelVacio THEN
        fase := 5; (* Pasa a descarga si hay producto *)
    ELSE
        fase := 0; (* Vuelve a reposo si ya esta vacio *)
    END_IF;
END_IF;

(* Maquina de estados secuencial *)
CASE fase OF
    0: (* Fase 0: Reposo *)
        IF trigInicio.Q THEN
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
END_CASE;

(* Control del temporizador de mezcla *)
tMezcla(IN := (fase = 4), PT := T#120S);

(* Control de salidas basado en la fase activa *)
vA := (fase = 1);
vB := (fase = 2);
calentador := (fase = 3);
mezclador := (fase = 4);
vDescarga := (fase = 5);

END_FUNCTION_BLOCK