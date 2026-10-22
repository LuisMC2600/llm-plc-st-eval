```pascal
FUNCTION_BLOCK FB_Batch
VAR_INPUT
    nivelA : BOOL; (* Sensor de nivel para componente A *)
    nivelB : BOOL; (* Sensor de nivel para componente B *)
    nivelVacio : BOOL; (* Sensor de nivel para tanque vacío *)
    btnInicio : BOOL; (* Botón de inicio de receta *)
    btnAbort : BOOL; (* Botón de aborto de receta *)
    temp : REAL; (* Temperatura actual del reactor *)
END_VAR
VAR_OUTPUT
    vA : BOOL; (* Válvula para componente A *)
    vB : BOOL; (* Válvula para componente B *)
    calentador : BOOL; (* Calentador del reactor *)
    mezclador : BOOL; (* Mezclador del reactor *)
    vDescarga : BOOL; (* Válvula de descarga *)
    fase : INT; (* Fase actual del proceso *)
END_VAR
VAR
    tMezcla : TON; (* Temporizador para la fase de mezcla *)
    recetaEnCurso : BOOL; (* Indicador de receta en curso *)
END_VAR

(* Inicialización de salidas y variables *)
vA := FALSE;
vB := FALSE;
calentador := FALSE;
mezclador := FALSE;
vDescarga := FALSE;

(* Control de fases del proceso *)
IF NOT recetaEnCurso THEN
    IF btnInicio THEN
        recetaEnCurso := TRUE;
        fase := 1;
    ELSE
        fase := 0;
    END_IF;
ELSE
    CASE fase OF
        1: (* Fase 1: Dosificación de A *)
            vA := NOT nivelA;
            IF nivelA THEN
                vA := FALSE;
                fase := 2;
            END_IF;
        2: (* Fase 2: Dosificación de B *)
            vB := NOT nivelB;
            IF nivelB THEN
                vB := FALSE;
                fase := 3;
            END_IF;
        3: (* Fase 3: Calentamiento *)
            calentador := temp < 60.0;
            IF temp >= 60.0 THEN
                calentador := FALSE;
                fase := 4;
                tMezcla(IN := TRUE, PT := T#120S);
            END_IF;
        4: (* Fase 4: Mezcla *)
            mezclador := tMezcla.Q;
            IF tMezcla.Q THEN
                mezclador := FALSE;
                fase := 5;
            END_IF;
        5: (* Fase 5: Descarga *)
            vDescarga := NOT nivelVacio;
            IF nivelVacio THEN
                vDescarga := FALSE;
                recetaEnCurso := FALSE;
                fase := 0;
            END_IF;
    END_CASE;
END_IF;

(* Manejo de aborto *)
IF btnAbort AND recetaEnCurso THEN
    vA := FALSE;
    vB := FALSE;
    calentador := FALSE;
    mezclador := FALSE;
    IF fase <> 5 THEN
        fase := 5;
    END_IF;
END_IF;

END_FUNCTION_BLOCK
```