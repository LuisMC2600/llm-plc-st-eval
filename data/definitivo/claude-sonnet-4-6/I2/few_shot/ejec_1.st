```st
FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto   : BOOL; (* Sensor de nivel alto *)
    nivelBajo   : BOOL; (* Sensor de nivel bajo *)
    btnInicio   : BOOL; (* Boton de inicio del proceso *)
    btnParo     : BOOL; (* Boton de paro de emergencia *)
END_VAR
VAR_OUTPUT
    vLlenado    : BOOL; (* Valvula de llenado *)
    motorMezcla : BOOL; (* Motor de mezcla *)
    vDescarga   : BOOL; (* Valvula de descarga *)
END_VAR
VAR
    etapa       : INT;  (* Etapa actual: 0=Reposo, 1=Llenado, 2=Mezcla, 3=Descarga *)
    tMezcla     : TON;  (* Temporizador de mezcla *)
END_VAR

(* Paro de emergencia: desactiva todo y regresa a reposo en cualquier etapa *)
IF btnParo THEN
    etapa       := 0;
    vLlenado    := FALSE;
    motorMezcla := FALSE;
    vDescarga   := FALSE;
    tMezcla(IN := FALSE, PT := T#60S); (* Reinicia el temporizador *)

ELSE
    CASE etapa OF

        0: (* Reposo: espera pulsacion de inicio *)
            vLlenado    := FALSE;
            motorMezcla := FALSE;
            vDescarga   := FALSE;
            IF btnInicio THEN
                etapa := 1;
            END_IF;

        1: (* Llenado: abre valvula hasta alcanzar nivel alto *)
            vLlenado    := TRUE;
            motorMezcla := FALSE;
            vDescarga   := FALSE;
            IF nivelAlto THEN
                vLlenado := FALSE;
                etapa    := 2;
            END_IF;

        2: (* Mezcla: activa motor durante 60 segundos *)
            vLlenado    := FALSE;
            motorMezcla := TRUE;
            vDescarga   := FALSE;
            tMezcla(IN := TRUE, PT := T#60S);
            IF tMezcla.Q THEN
                motorMezcla := FALSE;
                tMezcla(IN := FALSE, PT := T#60S); (* Reinicia temporizador *)
                etapa := 3;
            END_IF;

        3: (* Descarga: abre valvula hasta alcanzar nivel bajo *)
            vLlenado    := FALSE;
            motorMezcla := FALSE;
            vDescarga   := TRUE;
            IF nivelBajo THEN
                vDescarga := FALSE;
                etapa     := 0;
            END_IF;

        ELSE (* Estado no definido: regresa a reposo de forma segura *)
            etapa       := 0;
            vLlenado    := FALSE;
            motorMezcla := FALSE;
            vDescarga   := FALSE;

    END_CASE;
END_IF;

END_FUNCTION_BLOCK
```