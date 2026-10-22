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
    (* Temporizadores para cada fase de la secuencia normal *)
    tVerde    : TON; (* Temporiza la fase verde  - 20 s *)
    tAmarillo : TON; (* Temporiza la fase amarilla - 4 s *)
    tRojo     : TON; (* Temporiza la fase roja   - 15 s *)

    (* Temporizador para el amarillo intermitente *)
    tIntermitente : TON; (* Temporiza cada semiciclo de 1 s *)

    (* Estado interno de la secuencia normal *)
    (* 0 = Verde, 1 = Amarillo, 2 = Rojo *)
    estado : INT := 0;

    (* Bit de parpadeo para el amarillo intermitente *)
    parpadeo : BOOL := FALSE;
END_VAR

(* ─────────────────────────────────────────────────────────────
   Lógica principal
   ───────────────────────────────────────────────────────────── *)

IF NOT habilitado THEN
    (* ── Modo amarillo intermitente ─────────────────────────── *)

    (* Reiniciar temporizadores de secuencia normal *)
    tVerde(IN    := FALSE, PT := T#20S);
    tAmarillo(IN := FALSE, PT := T#4S);
    tRojo(IN     := FALSE, PT := T#15S);

    (* Reiniciar estado para que al habilitar arranque en verde *)
    estado := 0;

    (* Temporizador de 1 s para el parpadeo *)
    tIntermitente(IN := TRUE, PT := T#1S);

    IF tIntermitente.Q THEN
        (* Conmutar el bit de parpadeo y reiniciar el temporizador *)
        parpadeo          := NOT parpadeo;
        tIntermitente(IN  := FALSE, PT := T#1S); (* Reset *)
        tIntermitente(IN  := TRUE,  PT := T#1S); (* Rearranque *)
    END_IF;

    (* Salidas: solo amarillo parpadea *)
    luzV := FALSE;
    luzA := parpadeo;
    luzR := FALSE;

ELSE
    (* ── Modo secuencia normal ───────────────────────────────── *)

    (* Detener y resetear el temporizador de intermitente *)
    tIntermitente(IN := FALSE, PT := T#1S);
    parpadeo := FALSE;

    CASE estado OF

        0: (* ── Verde ── *)
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;

            tVerde(IN := TRUE, PT := T#20S);

            IF tVerde.Q THEN
                tVerde(IN := FALSE, PT := T#20S); (* Reset *)
                estado := 1;                       (* Pasar a amarillo *)
            END_IF;

        1: (* ── Amarillo ── *)
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;

            tAmarillo(IN := TRUE, PT := T#4S);

            IF tAmarillo.Q THEN
                tAmarillo(IN := FALSE, PT := T#4S); (* Reset *)
                estado := 2;                         (* Pasar a rojo *)
            END_IF;

        2: (* ── Rojo ── *)
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;

            tRojo(IN := TRUE, PT := T#15S);

            IF tRojo.Q THEN
                tRojo(IN := FALSE, PT := T#15S); (* Reset *)
                estado := 0;                      (* Volver a verde *)
            END_IF;

        ELSE
            (* Estado inválido: reiniciar en verde *)
            estado := 0;

    END_CASE;

END_IF;
```