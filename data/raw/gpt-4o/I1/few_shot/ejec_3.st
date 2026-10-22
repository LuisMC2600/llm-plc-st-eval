```pascal
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
    tVerde : TON; (* Temporizador para luz verde *)
    tAmarillo : TON; (* Temporizador para luz amarilla *)
    tRojo : TON; (* Temporizador para luz roja *)
    tIntermitente : TON; (* Temporizador para amarillo intermitente *)
    estado : INT; (* Estado del semaforo *)
END_VAR

(* Logica del semaforo *)
IF habilitado THEN
    CASE estado OF
        0: (* Estado verde *)
            tVerde(IN := TRUE, PT := T#20S);
            luzV := tVerde.Q;
            luzA := FALSE;
            luzR := FALSE;
            IF tVerde.Q THEN
                tVerde(IN := FALSE);
                estado := 1;
            END_IF;
        1: (* Estado amarillo *)
            tAmarillo(IN := TRUE, PT := T#4S);
            luzV := FALSE;
            luzA := tAmarillo.Q;
            luzR := FALSE;
            IF tAmarillo.Q THEN
                tAmarillo(IN := FALSE);
                estado := 2;
            END_IF;
        2: (* Estado rojo *)
            tRojo(IN := TRUE, PT := T#15S);
            luzV := FALSE;
            luzA := FALSE;
            luzR := tRojo.Q;
            IF tRojo.Q THEN
                tRojo(IN := FALSE);
                estado := 0;
            END_IF;
    END_CASE;
ELSE
    (* Estado amarillo intermitente *)
    tIntermitente(IN := TRUE, PT := T#1S);
    luzV := FALSE;
    luzA := tIntermitente.Q;
    luzR := FALSE;
    IF tIntermitente.Q THEN
        tIntermitente(IN := FALSE);
    END_IF;
    estado := 0; (* Reinicia el ciclo al habilitarse *)
END_IF;
END_FUNCTION_BLOCK
```