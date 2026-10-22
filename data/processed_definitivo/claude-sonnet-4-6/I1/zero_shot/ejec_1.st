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
    tVerde      : TON; (* Temporizador fase verde:   20 s *)
    tAmarillo   : TON; (* Temporizador fase amarilla: 4 s *)
    tRojo       : TON; (* Temporizador fase roja:    15 s *)
    tParpadeo   : TON; (* Temporizador parpadeo:      1 s *)

    (* Estado de la máquina de estados *)
    (* 0 = Verde, 1 = Amarillo, 2 = Rojo, 3 = Amarillo intermitente *)
    estado      : INT := 0;

    (* Bit auxiliar para el parpadeo del amarillo intermitente *)
    parpadeoOn  : BOOL := FALSE;
END_VAR

(* ─────────────────────────────────────────────────────────────────────────── *)
(*  Lógica principal                                                           *)
(* ─────────────────────────────────────────────────────────────────────────── *)

IF NOT habilitado THEN
    (* ── Modo amarillo intermitente ─────────────────────────────────────── *)

    (* Si veníamos de la secuencia normal, reiniciamos al estado intermitente *)
    IF estado <> 3 THEN
        estado     := 3;
        parpadeoOn := FALSE;
        (* Apagar temporizadores de secuencia normal *)
        tVerde(IN := FALSE, PT := T#20S);
        tAmarillo(IN := FALSE, PT := T#4S);
        tRojo(IN := FALSE, PT := T#15S);
        (* Arrancar temporizador de parpadeo *)
        tParpadeo(IN := FALSE, PT := T#1S);
    END_IF;

    (* Temporizador de parpadeo: alterna cada 1 s *)
    tParpadeo(IN := TRUE, PT := T#1S);
    IF tParpadeo.Q THEN
        parpadeoOn := NOT parpadeoOn; (* Invertir estado del parpadeo *)
        tParpadeo(IN := FALSE, PT := T#1S); (* Reiniciar temporizador *)
    END_IF;

    (* Salidas: solo amarillo parpadea, verde y rojo apagados *)
    luzV := FALSE;
    luzA := parpadeoOn;
    luzR := FALSE;

ELSE
    (* ── Secuencia normal cíclica ────────────────────────────────────────── *)

    (* Si veníamos del modo intermitente, reiniciar en verde *)
    IF estado = 3 THEN
        estado := 0;
        parpadeoOn := FALSE;
        tParpadeo(IN := FALSE, PT := T#1S); (* Detener parpadeo *)
    END_IF;

    CASE estado OF

        0: (* ── VERDE 20 s ─────────────────────────────────────────────── *)
            tVerde(IN := TRUE, PT := T#20S);
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            IF tVerde.Q THEN
                tVerde(IN := FALSE, PT := T#20S); (* Reiniciar temporizador *)
                estado := 1;                       (* Pasar a amarillo *)
            END_IF;

        1: (* ── AMARILLO 4 s ────────────────────────────────────────────── *)
            tAmarillo(IN := TRUE, PT := T#4S);
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            IF tAmarillo.Q THEN
                tAmarillo(IN := FALSE, PT := T#4S); (* Reiniciar temporizador *)
                estado := 2;                         (* Pasar a rojo *)
            END_IF;

        2: (* ── ROJO 15 s ───────────────────────────────────────────────── *)
            tRojo(IN := TRUE, PT := T#15S);
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            IF tRojo.Q THEN
                tRojo(IN := FALSE, PT := T#15S); (* Reiniciar temporizador *)
                estado := 0;                      (* Volver a verde *)
            END_IF;

        ELSE
            (* Estado inesperado: forzar reinicio en verde *)
            estado := 0;

    END_CASE;

END_IF;