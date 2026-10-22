FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto   : BOOL; (* Sensor de nivel alto *)
    nivelBajo   : BOOL; (* Sensor de nivel bajo *)
    btnInicio   : BOOL; (* Boton de inicio de proceso *)
    btnParo     : BOOL; (* Boton de paro de emergencia *)
END_VAR
VAR_OUTPUT
    vLlenado    : BOOL; (* Valvula de llenado *)
    motorMezcla : BOOL; (* Motor de mezcla *)
    vDescarga   : BOOL; (* Valvula de descarga *)
END_VAR
VAR
    estado      : INT;  (* Estado actual del proceso: 0=Reposo, 1=Llenado, 2=Mezcla, 3=Descarga *)
    tMezcla     : TON;  (* Temporizador de mezcla *)
END_VAR

(* Paro de emergencia: lleva todo a estado seguro y regresa a reposo *)
IF btnParo THEN
    estado      := 0;
    tMezcla(IN := FALSE, PT := T#60S);
END_IF

(* Maquina de estados del proceso de llenado *)
CASE estado OF

    0: (* REPOSO: espera pulsacion de inicio *)
        vLlenado    := FALSE;
        motorMezcla := FALSE;
        vDescarga   := FALSE;
        IF btnInicio AND NOT btnParo THEN
            estado := 1; (* Pasar a etapa de llenado *)
        END_IF

    1: (* LLENADO: abre valvula hasta alcanzar nivel alto *)
        vLlenado    := TRUE;
        motorMezcla := FALSE;
        vDescarga   := FALSE;
        IF nivelAlto THEN
            vLlenado := FALSE;
            estado   := 2; (* Pasar a etapa de mezcla *)
        END_IF

    2: (* MEZCLA: activa motor durante 60 segundos *)
        vLlenado    := FALSE;
        motorMezcla := TRUE;
        vDescarga   := FALSE;
        tMezcla(IN := TRUE, PT := T#60S); (* Arrancar temporizador *)
        IF tMezcla.Q THEN
            motorMezcla := FALSE;
            tMezcla(IN := FALSE, PT := T#60S); (* Resetear temporizador *)
            estado      := 3; (* Pasar a etapa de descarga *)
        END_IF

    3: (* DESCARGA: abre valvula hasta alcanzar nivel bajo *)
        vLlenado    := FALSE;
        motorMezcla := FALSE;
        vDescarga   := TRUE;
        IF nivelBajo THEN
            vDescarga := FALSE;
            estado    := 0; (* Volver a reposo *)
        END_IF

    ELSE (* Estado desconocido: ir a reposo de forma segura *)
        estado      := 0;
        vLlenado    := FALSE;
        motorMezcla := FALSE;
        vDescarga   := FALSE;

END_CASE
END_FUNCTION_BLOCK