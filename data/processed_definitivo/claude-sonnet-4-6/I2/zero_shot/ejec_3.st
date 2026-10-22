FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto  : BOOL; (* Sensor de nivel alto *)
    nivelBajo  : BOOL; (* Sensor de nivel bajo *)
    btnInicio  : BOOL; (* Botón de inicio del proceso *)
    btnParo    : BOOL; (* Botón de paro de emergencia *)
END_VAR

VAR_OUTPUT
    vLlenado    : BOOL; (* Válvula de llenado *)
    motorMezcla : BOOL; (* Motor de mezcla *)
    vDescarga   : BOOL; (* Válvula de descarga *)
END_VAR

VAR
    etapa       : INT;          (* Etapa actual del proceso: 0=Reposo, 1=Llenado, 2=Mezcla, 3=Descarga *)
    timerMezcla : TON;          (* Temporizador para la etapa de mezcla *)
END_VAR

(* ─────────────────────────────────────────────
   Máquina de estados del proceso de llenado
   ───────────────────────────────────────────── *)

(* Paro de emergencia: actúa en cualquier etapa *)
IF btnParo THEN
    etapa       := 0;
    vLlenado    := FALSE;
    motorMezcla := FALSE;
    vDescarga   := FALSE;
    timerMezcla(IN := FALSE, PT := T#60S); (* Resetea el temporizador *)
ELSE

    CASE etapa OF

        (* ── ETAPA 0: Reposo ── *)
        0:
            vLlenado    := FALSE;
            motorMezcla := FALSE;
            vDescarga   := FALSE;
            timerMezcla(IN := FALSE, PT := T#60S); (* Mantiene timer reseteado *)

            IF btnInicio THEN
                etapa := 1; (* Transición a llenado *)
            END_IF;

        (* ── ETAPA 1: Llenado ── *)
        1:
            vLlenado    := TRUE;
            motorMezcla := FALSE;
            vDescarga   := FALSE;

            IF nivelAlto THEN
                vLlenado := FALSE;
                etapa    := 2; (* Transición a mezcla *)
            END_IF;

        (* ── ETAPA 2: Mezcla (60 segundos) ── *)
        2:
            vLlenado    := FALSE;
            motorMezcla := TRUE;
            vDescarga   := FALSE;

            timerMezcla(IN := TRUE, PT := T#60S); (* Activa el temporizador *)

            IF timerMezcla.Q THEN
                motorMezcla := FALSE;
                timerMezcla(IN := FALSE, PT := T#60S); (* Resetea para próximo ciclo *)
                etapa := 3; (* Transición a descarga *)
            END_IF;

        (* ── ETAPA 3: Descarga ── *)
        3:
            vLlenado    := FALSE;
            motorMezcla := FALSE;
            vDescarga   := TRUE;

            IF nivelBajo THEN
                vDescarga := FALSE;
                etapa     := 0; (* Regresa a reposo *)
            END_IF;

        (* ── Estado no definido: regreso seguro a reposo ── *)
        ELSE
            etapa       := 0;
            vLlenado    := FALSE;
            motorMezcla := FALSE;
            vDescarga   := FALSE;

    END_CASE;

END_IF;