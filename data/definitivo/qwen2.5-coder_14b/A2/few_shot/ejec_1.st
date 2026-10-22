FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA : BOOL; (* Nivel del componente A *)
    nivelB : BOOL; (* Nivel del componente B *)
    nivelVacio : BOOL; (* Nivel vacío del reactor *)
    btnInicio : BOOL; (* Botón de inicio *)
    btnAbort : BOOL; (* Botón de abortar *)
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
    inicioPulsado : BOOL := FALSE; (* Bandera para detectar pulsación de btnInicio *)
    abortPulsado : BOOL := FALSE; (* Bandera para detectar pulsación de btnAbort *)
END_VAR

(* Control de inicio *)
IF btnInicio AND NOT inicioPulsado AND fase = 0 THEN
    fase := 1;
    inicioPulsado := TRUE;
END_IF

(* Control de abort *)
IF btnAbort AND NOT abortPulsado THEN
    abortPulsado := TRUE;
    CASE fase OF
        1..4:
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
END_IF

(* Control de las fases *)
CASE fase OF
    1:
        vA := TRUE;
        IF nivelA THEN
            vA := FALSE;
            fase := 2;
        END_IF;
    2:
        vB := TRUE;
        IF nivelB THEN
            vB := FALSE;
            fase := 3;
        END_IF;
    3:
        calentador := TRUE;
        IF temp >= 60.0 THEN
            calentador := FALSE;
            fase := 4;
        END_IF;
    4:
        mezclador := TRUE;
        tMezclar(IN := TRUE, PT := T#120S);
        IF tMezclar.Q THEN
            mezclador := FALSE;
            fase := 5;
        END_IF;
    5:
        vDescarga := TRUE;
        IF nivelVacio THEN
            vDescarga := FALSE;
            fase := 0;
        END_IF;
    0:
        (* Reposo *)
        vA := FALSE;
        vB := FALSE;
        calentador := FALSE;
        mezclador := FALSE;
        vDescarga := FALSE;
        IF btnAbort THEN
            abortPulsado := TRUE;
        END_IF;
END_CASE

(* Reinicio de las banderas *)
IF NOT btnInicio THEN
    inicioPulsado := FALSE;
END_IF
IF NOT btnAbort THEN
    abortPulsado := FALSE;
END_IF

END_FUNCTION_BLOCK