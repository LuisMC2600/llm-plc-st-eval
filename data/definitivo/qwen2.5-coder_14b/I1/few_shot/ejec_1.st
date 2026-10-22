FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; (* Semaforo habilitado *)
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
    estado : INT := 0; (* Estado actual del semáforo *)
END_VAR

(* Secuencia normal del semáforo *)
IF habilitado THEN
    CASE estado OF
        0: (* Verde *)
            tVerde(IN := TRUE, PT := T#20S);
            luzV := tVerde.Q;
            luzA := FALSE;
            luzR := FALSE;
            IF tVerde.Q THEN
                estado := 1;
            END_IF
        1: (* Amarillo *)
            tAmarillo(IN := TRUE, PT := T#4S);
            luzV := FALSE;
            luzA := tAmarillo.Q;
            luzR := FALSE;
            IF tAmarillo.Q THEN
                estado := 2;
            END_IF
        2: (* Rojo *)
            tRojo(IN := TRUE, PT := T#15S);
            luzV := FALSE;
            luzA := FALSE;
            luzR := tRojo.Q;
            IF tRojo.Q THEN
                estado := 0;
            END_IF
    END_CASE
ELSE
    (* Modo intermitente *)
    tIntermitente(IN := TRUE, PT := T#1S);
    luzV := FALSE;
    luzA := tIntermitente.Q;
    luzR := FALSE;
    IF tIntermitente.Q THEN
        tIntermitente(IN := FALSE);
    END_IF
END_IF

END_FUNCTION_BLOCK