FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; (* Habilitacion del semaforo *)
END_VAR
VAR_OUTPUT
    luzV : BOOL; (* Luz verde *)
    luzA : BOOL; (* Luz amarilla *)
    luzR : BOOL; (* Luz roja *)
END_VAR
VAR
    estado     : INT;  (* Estado de la secuencia: 0=Verde, 1=Amarillo, 2=Rojo *)
    tFase      : TON; (* Temporizador de fase normal *)
    tBlink     : TP;  (* Temporizador de pulso para amarillo intermitente *)
    blinkState : BOOL; (* Estado actual del parpadeo (ON/OFF) *)
END_VAR

IF NOT habilitado THEN
    (* --- Modo amarillo intermitente --- *)
    estado := 0; (* Reinicio de estado para cuando se habilite de nuevo *)
    luzV   := FALSE;
    luzR   := FALSE;

    (* Generar parpadeo: cada flanco de bajada de tBlink.Q relanza el pulso *)
    tBlink(IN := NOT tBlink.Q, PT := T#1S);
    blinkState := tBlink.Q;
    luzA := blinkState;

    (* Asegurar que el temporizador de fase no quede activo *)
    tFase(IN := FALSE, PT := T#20S);

ELSE
    (* --- Modo secuencia normal --- *)
    tBlink(IN := FALSE, PT := T#1S); (* Detener y resetear el temporizador de parpadeo *)
    blinkState := FALSE;

    CASE estado OF

        0: (* Verde: 20 segundos *)
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            tFase(IN := TRUE, PT := T#20S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#20S); (* Reset temporizador *)
                estado := 1;
            END_IF;

        1: (* Amarillo: 4 segundos *)
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            tFase(IN := TRUE, PT := T#4S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#4S); (* Reset temporizador *)
                estado := 2;
            END_IF;

        2: (* Rojo: 15 segundos *)
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            tFase(IN := TRUE, PT := T#15S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#15S); (* Reset temporizador *)
                estado := 0; (* Reinicia la secuencia *)
            END_IF;

        ELSE
            estado := 0; (* Estado invalido: volver a verde *)

    END_CASE;

END_IF;

END_FUNCTION_BLOCK