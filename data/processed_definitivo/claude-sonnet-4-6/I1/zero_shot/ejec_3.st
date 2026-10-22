FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; (* Habilita la secuencia normal del semáforo *)
END_VAR

VAR_OUTPUT
    luzV : BOOL; (* Luz verde *)
    luzA : BOOL; (* Luz amarilla *)
    luzR : BOOL; (* Luz roja *)
END_VAR

VAR
    (* Temporizadores para cada fase *)
    tVerde     : TON; (* Temporizador fase verde  - 20 s *)
    tAmarillo  : TON; (* Temporizador fase amarilla - 4 s *)
    tRojo      : TON; (* Temporizador fase roja   - 15 s *)
    tBlink     : TON; (* Temporizador parpadeo amarillo - 1 s *)

    (* Estado de la secuencia normal *)
    (* 0 = Verde, 1 = Amarillo, 2 = Rojo *)
    estado     : INT := 0;

    (* Estado interno del parpadeo (TRUE = encendido, FALSE = apagado) *)
    blinkOn    : BOOL := FALSE;
END_VAR

(* ─────────────────────────────────────────────────────────────────────────── *)

IF NOT habilitado THEN
    (* ── Modo amarillo intermitente ─────────────────────────────────────── *)

    (* Reiniciar temporizadores de secuencia normal *)
    tVerde(IN := FALSE);
    tAmarillo(IN := FALSE);
    tRojo(IN := FALSE);

    (* Reiniciar estado para que al habilitar arranque en verde *)
    estado := 0;

    (* Temporizador de parpadeo: ciclo de 1 s *)
    tBlink(IN := TRUE, PT := T#1S);

    IF tBlink.Q THEN
        (* Conmutar estado del parpadeo y reiniciar temporizador *)
        blinkOn := NOT blinkOn;
        tBlink(IN := FALSE); (* Reset del temporizador *)
    END_IF;

    (* Asignar salidas: solo amarillo parpadea *)
    luzV := FALSE;
    luzA := blinkOn;
    luzR := FALSE;

ELSE
    (* ── Modo secuencia normal ───────────────────────────────────────────── *)

    (* Detener y resetear temporizador de parpadeo *)
    tBlink(IN := FALSE);
    blinkOn := FALSE;

    CASE estado OF

        0: (* ── Fase VERDE ── *)
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;

            tVerde(IN := TRUE, PT := T#20S);

            IF tVerde.Q THEN
                tVerde(IN := FALSE); (* Reset temporizador *)
                estado := 1;         (* Pasar a amarillo *)
            END_IF;

        1: (* ── Fase AMARILLA ── *)
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;

            tAmarillo(IN := TRUE, PT := T#4S);

            IF tAmarillo.Q THEN
                tAmarillo(IN := FALSE); (* Reset temporizador *)
                estado := 2;            (* Pasar a rojo *)
            END_IF;

        2: (* ── Fase ROJA ── *)
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;

            tRojo(IN := TRUE, PT := T#15S);

            IF tRojo.Q THEN
                tRojo(IN := FALSE); (* Reset temporizador *)
                estado := 0;        (* Volver a verde *)
            END_IF;

        ELSE
            (* Estado inválido: reiniciar en verde *)
            estado := 0;

    END_CASE;

END_IF;