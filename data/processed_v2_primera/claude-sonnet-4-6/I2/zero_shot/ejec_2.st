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
    (* Etapas del proceso *)
    etapa : INT := 0;
    (*
        0 = Reposo
        1 = Llenado
        2 = Mezcla
        3 = Descarga
    *)

    (* Temporizador para la etapa de mezcla *)
    tmrMezcla : TON;
END_VAR

(* ─────────────────────────────────────────────
   Lógica principal del proceso por etapas
   ───────────────────────────────────────────── *)

(* Paro de emergencia: cualquier etapa → reposo *)
IF btnParo THEN
    etapa       := 0;
    vLlenado    := FALSE;
    motorMezcla := FALSE;
    vDescarga   := FALSE;
    tmrMezcla(IN := FALSE); (* Reinicia el temporizador *)

ELSE

    CASE etapa OF

        (* ── Etapa 0: Reposo ── *)
        0:
            vLlenado    := FALSE;
            motorMezcla := FALSE;
            vDescarga   := FALSE;
            tmrMezcla(IN := FALSE); (* Mantiene temporizador reseteado *)

            IF btnInicio THEN
                etapa := 1; (* Ir a llenado *)
            END_IF;

        (* ── Etapa 1: Llenado ── *)
        1:
            vLlenado    := TRUE;
            motorMezcla := FALSE;
            vDescarga   := FALSE;

            IF nivelAlto THEN
                vLlenado := FALSE;
                etapa    := 2; (* Ir a mezcla *)
            END_IF;

        (* ── Etapa 2: Mezcla (60 segundos) ── *)
        2:
            vLlenado    := FALSE;
            motorMezcla := TRUE;
            vDescarga   := FALSE;

            (* Activa el temporizador mientras se está en esta etapa *)
            tmrMezcla(IN := TRUE, PT := T#60S);

            IF tmrMezcla.Q THEN
                motorMezcla := FALSE;
                tmrMezcla(IN := FALSE); (* Resetea para próximo ciclo *)
                etapa := 3;             (* Ir a descarga *)
            END_IF;

        (* ── Etapa 3: Descarga ── *)
        3:
            vLlenado    := FALSE;
            motorMezcla := FALSE;
            vDescarga   := TRUE;

            IF nivelBajo THEN
                vDescarga := FALSE;
                etapa     := 0; (* Volver a reposo *)
            END_IF;

        (* ── Estado no definido: forzar reposo ── *)
        ELSE
            etapa       := 0;
            vLlenado    := FALSE;
            motorMezcla := FALSE;
            vDescarga   := FALSE;

    END_CASE;

END_IF;

END_FUNCTION_BLOCK