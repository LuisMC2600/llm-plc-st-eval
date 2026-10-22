```pascal
FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto  : BOOL; (* Sensor de nivel alto *)
    nivelBajo  : BOOL; (* Sensor de nivel bajo *)
    btnInicio  : BOOL; (* Botón de inicio (flanco) *)
    btnParo    : BOOL; (* Botón de paro (nivel) *)
END_VAR

VAR_OUTPUT
    vLlenado    : BOOL; (* Válvula de llenado *)
    motorMezcla : BOOL; (* Motor de mezcla *)
    vDescarga   : BOOL; (* Válvula de descarga *)
END_VAR

VAR
    (* Etapas del proceso *)
    eEtapa : INT := 0;
    (*
        0 = Reposo
        1 = Llenado
        2 = Mezcla
        3 = Descarga
    *)

    (* Temporizador para la etapa de mezcla *)
    tonMezcla : TON;

    (* Detección de flanco ascendente en btnInicio *)
    rTrigInicio : R_TRIG;
END_VAR

(* ─────────────────────────────────────────────
   Detección de flanco ascendente en btnInicio
   ───────────────────────────────────────────── *)
rTrigInicio(CLK := btnInicio);

(* ─────────────────────────────────────────────
   Paro de emergencia: cualquier etapa
   ───────────────────────────────────────────── *)
IF btnParo THEN
    eEtapa      := 0;
    vLlenado    := FALSE;
    motorMezcla := FALSE;
    vDescarga   := FALSE;
    tonMezcla(IN := FALSE, PT := T#60S); (* Resetea temporizador *)
    RETURN; (* Sale del bloque sin ejecutar el resto *)
END_IF;

(* ─────────────────────────────────────────────
   Máquina de estados
   ───────────────────────────────────────────── *)
CASE eEtapa OF

    (* ── Etapa 0: Reposo ── *)
    0:
        vLlenado    := FALSE;
        motorMezcla := FALSE;
        vDescarga   := FALSE;
        tonMezcla(IN := FALSE, PT := T#60S); (* Mantiene temporizador reseteado *)

        IF rTrigInicio.Q THEN
            eEtapa := 1; (* Ir a llenado *)
        END_IF;

    (* ── Etapa 1: Llenado ── *)
    1:
        vLlenado    := TRUE;
        motorMezcla := FALSE;
        vDescarga   := FALSE;

        IF nivelAlto THEN
            vLlenado := FALSE;
            eEtapa   := 2; (* Ir a mezcla *)
        END_IF;

    (* ── Etapa 2: Mezcla (60 s) ── *)
    2:
        vLlenado    := FALSE;
        motorMezcla := TRUE;
        vDescarga   := FALSE;
        tonMezcla(IN := TRUE, PT := T#60S); (* Arranca/mantiene temporizador *)

        IF tonMezcla.Q THEN
            motorMezcla := FALSE;
            tonMezcla(IN := FALSE, PT := T#60S); (* Resetea para próximo ciclo *)
            eEtapa := 3; (* Ir a descarga *)
        END_IF;

    (* ── Etapa 3: Descarga ── *)
    3:
        vLlenado    := FALSE;
        motorMezcla := FALSE;
        vDescarga   := TRUE;

        IF nivelBajo THEN
            vDescarga := FALSE;
            eEtapa    := 0; (* Volver a reposo *)
        END_IF;

    (* ── Estado no definido: seguridad ── *)
    ELSE:
        eEtapa      := 0;
        vLlenado    := FALSE;
        motorMezcla := FALSE;
        vDescarga   := FALSE;

END_CASE;
```