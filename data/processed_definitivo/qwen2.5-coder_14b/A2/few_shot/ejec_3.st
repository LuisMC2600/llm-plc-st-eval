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
    tMezclador : TP; (* Temporizador para el mezclador *)
    inicioPulsado : BOOL := FALSE; (* Bandera para detectar el pulso de inicio *)
    abortPulsado : BOOL := FALSE; (* Bandera para detectar el pulso de aborto *)
END_VAR

(* Control de inicio *)
IF btnInicio AND NOT inicioPulsado AND fase = 0 THEN
    inicioPulsado := TRUE;
    fase := 1;
ELSEIF NOT btnInicio THEN
    inicioPulsado := FALSE;
END_IF;

(* Control de aborto *)
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
            IF nivelVacio THEN
                fase := 0;
            END_IF;
    END_CASE;
ELSEIF NOT btnAbort THEN
    abortPulsado := FALSE;
END_IF;

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
        tMezclador(IN := TRUE, PT := T#120S);
        IF tMezclador.Q THEN
            mezclador := FALSE;
            fase := 5;
        END_IF;
    5:
        vDescarga := TRUE;
        IF nivelVacio THEN
            vDescarga := FALSE;
            fase := 0;
        END_IF;
    ELSE
        (* Reposo *)
        vA := FALSE;
        vB := FALSE;
        calentador := FALSE;
        mezclador := FALSE;
        vDescarga := FALSE;
END_CASE;
END_FUNCTION_BLOCK