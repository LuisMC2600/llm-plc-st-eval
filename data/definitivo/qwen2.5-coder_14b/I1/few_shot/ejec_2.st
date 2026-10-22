FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; (* Entrada para habilitar el semáforo *)
END_VAR
VAR_OUTPUT
    luzV : BOOL; (* Luz verde *)
    luzA : BOOL; (* Luz amarilla *)
    luzR : BOOL; (* Luz roja *)
END_VAR
VAR
    tVerde : TP; (* Temporizador para luz verde *)
    tAmarillo : TP; (* Temporizador para luz amarilla *)
    tRojo : TP; (* Temporizador para luz roja *)
    tIntermitente : TP; (* Temporizador para luz amarilla intermitente *)
    estado : INT := 0; (* Variable de estado para la secuencia del semáforo *)
END_VAR

(* Secuencia del semáforo cuando está habilitado *)
IF habilitado THEN
    CASE estado OF
        0: (* Estado verde *)
            tVerde(IN := TRUE, PT := T#20S);
            luzV := tVerde.Q;
            luzA := FALSE;
            luzR := FALSE;
            IF tVerde.Q THEN
                estado := 1;
            END_IF
        1: (* Estado amarillo *)
            tAmarillo(IN := TRUE, PT := T#4S);
            luzV := FALSE;
            luzA := tAmarillo.Q;
            luzR := FALSE;
            IF tAmarillo.Q THEN
                estado := 2;
            END_IF
        2: (* Estado rojo *)
            tRojo(IN := TRUE, PT := T#15S);
            luzV := FALSE;
            luzA := FALSE;
            luzR := tRojo.Q;
            IF tRojo.Q THEN
                estado := 0;
            END_IF
    END_CASE
ELSE
    (* Secuencia del semáforo cuando no está habilitado *)
    tIntermitente(IN := TRUE, PT := T#1S);
    luzV := FALSE;
    luzR := FALSE;
    luzA := tIntermitente.Q;
    IF tIntermitente.Q THEN
        tIntermitente(IN := FALSE);
    ELSE
        tIntermitente(IN := TRUE);
    END_IF
END_IF
END_FUNCTION_BLOCK