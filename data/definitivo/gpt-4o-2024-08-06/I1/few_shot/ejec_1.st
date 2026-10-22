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
    tCiclo : TON; (* Temporizador para el ciclo del semaforo *)
    tIntermitente : TON; (* Temporizador para el amarillo intermitente *)
    estado : INT; (* Estado del semaforo *)
    intermitente : BOOL; (* Estado de la luz amarilla intermitente *)
END_VAR

(* Logica del semaforo *)
IF habilitado THEN
    (* Control del ciclo del semaforo *)
    CASE estado OF
        0: (* Luz verde *)
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            tCiclo(IN := TRUE, PT := T#20S);
            IF tCiclo.Q THEN
                estado := 1;
                tCiclo(IN := FALSE);
            END_IF;
        1: (* Luz amarilla *)
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            tCiclo(IN := TRUE, PT := T#4S);
            IF tCiclo.Q THEN
                estado := 2;
                tCiclo(IN := FALSE);
            END_IF;
        2: (* Luz roja *)
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            tCiclo(IN := TRUE, PT := T#15S);
            IF tCiclo.Q THEN
                estado := 0;
                tCiclo(IN := FALSE);
            END_IF;
    END_CASE;
ELSE
    (* Control del amarillo intermitente *)
    luzV := FALSE;
    luzR := FALSE;
    tIntermitente(IN := TRUE, PT := T#1S);
    IF tIntermitente.Q THEN
        intermitente := NOT intermitente;
        tIntermitente(IN := FALSE);
    END_IF;
    luzA := intermitente;
    estado := 0; (* Reiniciar ciclo al habilitar *)
END_IF;
END_FUNCTION_BLOCK
```