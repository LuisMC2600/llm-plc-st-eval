```pascal
FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto  : BOOL; (* Sensor de nivel alto *)
    nivelBajo  : BOOL; (* Sensor de nivel bajo *)
    btnInicio  : BOOL; (* Botón de inicio (flanco o nivel) *)
    btnParo    : BOOL; (* Botón de paro (detiene todo) *)
END_VAR

VAR_OUTPUT
    vLlenado    : BOOL; (* Válvula de llenado *)
    motorMezcla : BOOL; (* Motor de mezcla *)
    vDescarga   : BOOL; (* Válvula de descarga *)
END_VAR

VAR
    (* Etapas del proceso *)
    eReposo    : BOOL := TRUE;  (* Etapa 0: reposo *)
    eLlenado   : BOOL := FALSE; (* Etapa 1: llenando *)
    eMezcla    : BOOL := FALSE; (* Etapa 2: mezclando *)
    eDescarga  : BOOL := FALSE; (* Etapa 3: descargando *)

    (* Temporizador para la mezcla *)
    tMezcla    : TON;
END_VAR

(* ─────────────────────────────────────────────
   PARO DE EMERGENCIA: tiene prioridad absoluta
   ───────────────────────────────────────────── *)
IF btnParo THEN
    (* Desactivar todas las salidas *)
    vLlenado    := FALSE;
    motorMezcla := FALSE;
    vDescarga   := FALSE;

    (* Resetear temporizador *)
    tMezcla(IN := FALSE, PT := T#60S);

    (* Volver a reposo *)
    eReposo  := TRUE;
    eLlenado := FALSE;
    eMezcla  := FALSE;
    eDescarga := FALSE;

ELSE
    (* ─────────────────────────────────────────
       ETAPA 0 – REPOSO
       ───────────────────────────────────────── *)
    IF eReposo THEN
        (* Todas las salidas apagadas *)
        vLlenado    := FALSE;
        motorMezcla := FALSE;
        vDescarga   := FALSE;

        (* Transición: btnInicio arranca el proceso *)
        IF btnInicio THEN
            eReposo  := FALSE;
            eLlenado := TRUE;
        END_IF;

    (* ─────────────────────────────────────────
       ETAPA 1 – LLENADO
       ───────────────────────────────────────── *)
    ELSIF eLlenado THEN
        vLlenado    := TRUE;  (* Abrir válvula de llenado *)
        motorMezcla := FALSE;
        vDescarga   := FALSE;

        (* Transición: nivel alto alcanzado *)
        IF nivelAlto THEN
            vLlenado := FALSE; (* Cerrar válvula antes de mezclar *)
            eLlenado := FALSE;
            eMezcla  := TRUE;
            tMezcla(IN := FALSE, PT := T#60S); (* Asegurar reset previo *)
        END_IF;

    (* ─────────────────────────────────────────
       ETAPA 2 – MEZCLA (60 s)
       ───────────────────────────────────────── *)
    ELSIF eMezcla THEN
        vLlenado    := FALSE;
        motorMezcla := TRUE;  (* Activar motor de mezcla *)
        vDescarga   := FALSE;

        (* Llamada al temporizador TON *)
        tMezcla(IN := TRUE, PT := T#60S);

        (* Transición: tiempo de mezcla cumplido *)
        IF tMezcla.Q THEN
            motorMezcla := FALSE;
            tMezcla(IN := FALSE, PT := T#60S); (* Resetear temporizador *)
            eMezcla   := FALSE;
            eDescarga := TRUE;
        END_IF;

    (* ─────────────────────────────────────────
       ETAPA 3 – DESCARGA
       ───────────────────────────────────────── *)
    ELSIF eDescarga THEN
        vLlenado    := FALSE;
        motorMezcla := FALSE;
        vDescarga   := TRUE;  (* Abrir válvula de descarga *)

        (* Transición: nivel bajo alcanzado (tanque vacío) *)
        IF nivelBajo THEN
            vDescarga := FALSE; (* Cerrar válvula *)
            eDescarga := FALSE;
            eReposo   := TRUE;  (* Volver a reposo *)
        END_IF;

    END_IF;

END_IF;
```