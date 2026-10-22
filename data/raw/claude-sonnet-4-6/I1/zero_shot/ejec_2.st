```pascal
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
    (* Temporizadores TON estándar IEC 61131-3 *)
    tVerde      : TON; (* Temporiza la fase verde  - 20 s *)
    tAmarillo   : TON; (* Temporiza la fase amarilla - 4 s *)
    tRojo       : TON; (* Temporiza la fase roja   - 15 s *)
    tParpadeo   : TON; (* Temporiza el parpadeo amarillo - 1 s *)

    (* Estado de la secuencia normal *)
    (* 0 = Verde, 1 = Amarillo, 2 = Rojo *)
    estado      : INT := 0;

    (* Bit de parpadeo para amarillo intermitente *)
    parpadeo    : BOOL := FALSE;
END_VAR

(* ─────────────────────────────────────────────────────────────
   MODO DESHABILITADO: amarillo intermitente, resto apagado
   ───────────────────────────────────────────────────────────── *)
IF NOT habilitado THEN

    (* Reiniciar estado para que al habilitar arranque en verde *)
    estado := 0;

    (* Apagar temporizadores de secuencia normal *)
    tVerde(IN := FALSE,   PT := T#20S);
    tAmarillo(IN := FALSE, PT := T#4S);
    tRojo(IN := FALSE,    PT := T#15S);

    (* Temporizador de parpadeo: ciclo de 1 s *)
    tParpadeo(IN := TRUE, PT := T#1S);

    IF tParpadeo.Q THEN
        (* Reiniciar temporizador y conmutar estado de parpadeo *)
        tParpadeo(IN := FALSE, PT := T#1S);
        parpadeo := NOT parpadeo;
    END_IF;

    (* Salidas: solo amarillo parpadea *)
    luzV := FALSE;
    luzA := parpadeo;
    luzR := FALSE;

(* ─────────────────────────────────────────────────────────────
   MODO HABILITADO: secuencia Verde → Amarillo → Rojo → ...
   ───────────────────────────────────────────────────────────── *)
ELSE

    (* Detener temporizador de parpadeo y resetear bit *)
    tParpadeo(IN := FALSE, PT := T#1S);
    parpadeo := FALSE;

    CASE estado OF

        (* ── FASE VERDE ── *)
        0:
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;

            tVerde(IN := TRUE, PT := T#20S);

            IF tVerde.Q THEN
                (* Verde cumplido → pasar a amarillo *)
                tVerde(IN := FALSE, PT := T#20S); (* Reset temporizador *)
                estado := 1;
            END_IF;

        (* ── FASE AMARILLO ── *)
        1:
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;

            tAmarillo(IN := TRUE, PT := T#4S);

            IF tAmarillo.Q THEN
                (* Amarillo cumplido → pasar a rojo *)
                tAmarillo(IN := FALSE, PT := T#4S); (* Reset temporizador *)
                estado := 2;
            END_IF;

        (* ── FASE ROJO ── *)
        2:
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;

            tRojo(IN := TRUE, PT := T#15S);

            IF tRojo.Q THEN
                (* Rojo cumplido → volver a verde *)
                tRojo(IN := FALSE, PT := T#15S); (* Reset temporizador *)
                estado := 0;
            END_IF;

        (* ── ESTADO INVÁLIDO: recuperar a verde ── *)
        ELSE
            estado := 0;

    END_CASE;

END_IF;
```