FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA : BOOL;      (* Sensor de nivel del componente A *)
    nivelB : BOOL;      (* Sensor de nivel del componente B *)
    nivelVacio : BOOL;  (* Sensor de reactor vacío *)
    btnInicio : BOOL;   (* Botón para iniciar la receta *)
    btnAbort : BOOL;    (* Botón para abortar la receta *)
    temp : REAL;        (* Temperatura actual del reactor *)
END_VAR

VAR_OUTPUT
    vA : BOOL;          (* Válvula del componente A *)
    vB : BOOL;          (* Válvula del componente B *)
    calentador : BOOL;  (* Actuador del calentador *)
    mezclador : BOOL;   (* Actuador del mezclador *)
    vDescarga : BOOL;   (* Válvula de descarga *)
    fase : INT := 0;    (* Fase actual de la receta (0 a 5) *)
END_VAR

VAR
    timerMezcla : TON;  (* Temporizador para la fase de mezcla *)
END_VAR

(* Actualización del temporizador: se activa solo durante la fase 4 *)
timerMezcla(IN := (fase = 4), PT := T#120S);

(* Lógica de Aborto: activa en cualquier fase de 1 a 5 *)
IF btnAbort AND (fase >= 1) AND (fase <= 5) THEN
    IF NOT nivelVacio THEN
        fase := 5; (* Si hay producto, pasa a descargar *)
    ELSE
        fase := 0; (* Si ya está vacío, pasa a reposo directo *)
    END_IF;
END_IF;

(* Máquina de estados de la receta secuencial *)
CASE fase OF
    0: (* Fase 0: Reposo *)
        IF btnInicio THEN
            fase := 1;
        END_IF;
        
    1: (* Fase 1: Dosificar A *)
        IF nivelA THEN
            fase := 2;
        END_IF;
        
    2: (* Fase 2: Dosificar B *)
        IF nivelB THEN
            fase := 3;
        END_IF;
        
    3: (* Fase 3: Calentar *)
        IF temp >= 60.0 THEN
            fase := 4;
        END_IF;
        
    4: (* Fase 4: Mezclar *)
        IF timerMezcla.Q THEN
            fase := 5;
        END_IF;
        
    5: (* Fase 5: Descargar *)
        IF nivelVacio THEN
            fase := 0;
        END_IF;
ELSE
    (* Estado seguro en caso de valor fuera de rango *)
    fase := 0; 
END_CASE;

(* Control de salidas físicas basado en la fase activa *)
(* Al evaluar al final, un aborto cierra las válvulas y actuadores de inmediato *)
vA := (fase = 1);
vB := (fase = 2);
calentador := (fase = 3);
mezclador := (fase = 4);
vDescarga := (fase = 5);

END_FUNCTION_BLOCK