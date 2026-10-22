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
    tVerde      : TON; (* Temporizador fase verde  - 20 s *)
    tAmarillo   : TON; (* Temporizador fase amarilla - 4 s *)
    tRojo       : TON; (* Temporizador fase roja   - 15 s *)
    tParpadeo   : TON; (* Temporizador parpadeo amarillo - 1 s *)

    (* Estado interno de la secuencia normal *)
    (* 0 = Verde, 1 = Amarillo, 2 = Rojo *)
    estado      : INT := 0;

    (* Bit de parpadeo para amarillo intermitente *)
    bitParpadeo : BOOL := FALSE;
END_VAR

(* ─────────────────────────────────────────────────────────────
   MODO INHABILITADO: amarillo intermitente, resto apagado
   ───────────────────────────────────────────────────────────── *)
IF NOT habilitado THEN

    (* Reiniciar la secuencia para que arranque en verde al volver *)
    estado := 0;

    (* Apagar temporizadores de secuencia normal *)
    tVerde(IN := FALSE,    PT := T#20S);
    tAmarillo(IN := FALSE, PT := T#4S);
    tRojo(IN := FALSE,     PT := T#15S);

    (* Parpadeo: el temporizador cuenta 1 s; al vencer, invierte el bit *)
    tParpadeo(IN := TRUE, PT := T#1S);
    IF tParpadeo.Q THEN
        bitParpadeo := NOT bitParpadeo;
        tParpadeo(IN := FALSE, PT := T#1S); (* Reinicia el temporizador *)
    END_IF;

    (* Salidas: solo amarillo parpadea *)
    luzV := FALSE;
    luzA := bitParpadeo;
    luzR := FALSE;

(* ─────────────────────────────────────────────────────────────
   MODO HABILITADO: secuencia Verde → Amarillo → Rojo → ...
   ───────────────────────────────────────────────────────────── *)
ELSE

    (* Detener temporizador de parpadeo y resetear bit *)
    tParpadeo(IN := FALSE, PT := T#1S);
    bitParpadeo := FALSE;

    CASE estado OF

        (* ── FASE VERDE (20 s) ── *)
        0:
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;

            tVerde(IN := TRUE, PT := T#20S);
            IF tVerde.Q THEN
                tVerde(IN := FALSE, PT := T#20S); (* Reinicia temporizador *)
                estado := 1;                       (* Pasa a amarillo *)
            END_IF;

        (* ── FASE AMARILLO (4 s) ── *)
        1:
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;

            tAmarillo(IN := TRUE, PT := T#4S);
            IF tAmarillo.Q THEN
                tAmarillo(IN := FALSE, PT := T#4S); (* Reinicia temporizador *)
                estado := 2;                         (* Pasa a rojo *)
            END_IF;

        (* ── FASE ROJO (15 s) ── *)
        2:
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;

            tRojo(IN := TRUE, PT := T#15S);
            IF tRojo.Q THEN
                tRojo(IN := FALSE, PT := T#15S); (* Reinicia temporizador *)
                estado := 0;                      (* Vuelve a verde *)
            END_IF;

        (* ── ESTADO INVÁLIDO: recuperación segura ── *)
        ELSE
            estado := 0;
            luzV := FALSE;
            luzA := FALSE;
            luzR := FALSE;

    END_CASE;

END_IF;

END_FUNCTION_BLOCK