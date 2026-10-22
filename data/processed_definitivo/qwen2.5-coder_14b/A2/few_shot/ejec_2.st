FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA : BOOL; (* Nivel del componente A *)
    nivelB : BOOL; (* Nivel del componente B *)
    nivelVacio : BOOL; (* Nivel vacío del reactor *)
    btnInicio : BOOL; (* Botón de inicio *)
    btnAbort : BOOL; (* Botón de aborto *)
    temp : REAL; (* Temperatura del reactor *)
END_VAR
VAR_OUTPUT
    vA : BOOL; (* Válvula del componente A *)
    vB : BOOL; (* Válvula del componente B *)
    calentador : BOOL; (* Calentador *)
    mezclador : BOOL; (* Mezclador *)
    vDescarga : BOOL; (* Válvula de descarga *)
    fase : INT; (* Fase actual *)
END_VAR
VAR
    tMezclar : TP; (* Temporizador para mezclar *)
    inicioPulsado : BOOL := FALSE; (* Estado del botón de inicio *)
    abortPulsado : BOOL := FALSE; (* Estado del botón de aborto *)
END_VAR

(* Manejo del botón de inicio *)
IF btnInicio AND NOT inicioPulsado AND fase = 0 THEN
    inicioPulsado := TRUE;
    fase := 1;
END_IF;

(* Manejo del botón de aborto *)
IF btnAbort AND NOT abortPulsado THEN
    abortPulsado := TRUE;
    CASE fase OF
        1..5:
            vA := FALSE;
            vB := FALSE;
            calentador := FALSE;
            mezclador := FALSE;
            IF NOT nivelVacio THEN
                fase := 5;
            ELSE
                fase := 0;
            END_IF;
        5:
            IF NOT nivelVacio THEN
                fase := 5;
            ELSE
                fase := 0;
            END_IF;
    END_CASE;
END_IF;

(* Fase 1: Dosificar el componente A *)
IF fase = 1 THEN
    vA := TRUE;
    IF nivelA THEN
        vA := FALSE;
        fase := 2;
    END_IF;
END_IF;

(* Fase 2: Dosificar el componente B *)
IF fase = 2 THEN
    vB := TRUE;
    IF nivelB THEN
        vB := FALSE;
        fase := 3;
    END_IF;
END_IF;

(* Fase 3: Calentar *)
IF fase = 3 THEN
    calentador := TRUE;
    IF temp >= 60.0 THEN
        calentador := FALSE;
        fase := 4;
    END_IF;
END_IF;

(* Fase 4: Mezclar *)
IF fase = 4 THEN
    mezclador := TRUE;
    tMezclar(IN := TRUE, PT := T#120S);
    IF tMezclar.Q THEN
        mezclador := FALSE;
        fase := 5;
    END_IF;
END_IF;

(* Fase 5: Descargar *)
IF fase = 5 THEN
    vDescarga := TRUE;
    IF nivelVacio THEN
        vDescarga := FALSE;
        fase := 0;
    END_IF;
END_IF;

(* Reinicio de los botones *)
IF NOT btnInicio THEN
    inicioPulsado := FALSE;
END_IF;
IF NOT btnAbort THEN
    abortPulsado := FALSE;
END_IF;

END_FUNCTION_BLOCK