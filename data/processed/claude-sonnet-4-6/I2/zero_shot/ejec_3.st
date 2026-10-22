FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto  : BOOL; (* Sensor de nivel alto *)
    nivelBajo  : BOOL; (* Sensor de nivel bajo *)
    btnInicio  : BOOL; (* Botón de inicio (normalmente abierto) *)
    btnParo    : BOOL; (* Botón de paro  (normalmente abierto) *)
END_VAR

VAR_OUTPUT
    vLlenado    : BOOL; (* Válvula de llenado  *)
    motorMezcla : BOOL; (* Motor de mezcla     *)
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
   Lógica de paro: tiene prioridad sobre todo
   ───────────────────────────────────────────── *)
IF btnParo THEN
    etapa       := 0;
    vLlenado    := FALSE;
    motorMezcla := FALSE;
    vDescarga   := FALSE;
    tmrMezcla(IN := FALSE); (* Reinicia el temporizador *)
    RETURN;                  (* Sale del bloque de función *)
END_IF;

(* ─────────────────────────────────────────────
   Máquina de estados por etapas
   ───────────────────────────────────────────── *)
CASE etapa OF

    (* ── ETAPA 0: Reposo ── *)
    0:
        vLlenado    := FALSE;
        motorMezcla := FALSE;
        vDescarga   := FALSE;
        tmrMezcla(IN := FALSE); (* Mantiene temporizador reseteado *)

        IF btnInicio THEN
            etapa := 1; (* Avanza a llenado *)
        END_IF;

    (* ── ETAPA 1: Llenado ── *)
    1:
        vLlenado    := TRUE;
        motorMezcla := FALSE;
        vDescarga   := FALSE;

        IF nivelAlto THEN
            vLlenado := FALSE;
            etapa    := 2; (* Avanza a mezcla *)
        END_IF;

    (* ── ETAPA 2: Mezcla (60 s) ── *)
    2:
        vLlenado    := FALSE;
        motorMezcla := TRUE;
        vDescarga   := FALSE;

        (* Activa el temporizador mientras se está en esta etapa *)
        tmrMezcla(IN := TRUE, PT := T#60S);

        IF tmrMezcla.Q THEN
            motorMezcla := FALSE;
            tmrMezcla(IN := FALSE); (* Reinicia para próximo ciclo *)
            etapa := 3;             (* Avanza a descarga *)
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

    (* ── Estado no definido: seguridad ── *)
    ELSE
        etapa       := 0;
        vLlenado    := FALSE;
        motorMezcla := FALSE;
        vDescarga   := FALSE;

END_CASE;