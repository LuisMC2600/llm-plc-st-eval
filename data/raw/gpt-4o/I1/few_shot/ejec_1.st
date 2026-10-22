```pascal
FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; (* Habilita el funcionamiento del semáforo *)
END_VAR
VAR_OUTPUT
    luzV : BOOL; (* Luz verde del semáforo *)
    luzA : BOOL; (* Luz amarilla del semáforo *)
    luzR : BOOL; (* Luz roja del semáforo *)
END_VAR
VAR
    tCiclo : TON; (* Temporizador para el ciclo del semáforo *)
    tIntermitente : TON; (* Temporizador para el amarillo intermitente *)
    estado : INT; (* Estado actual del semáforo *)
END_VAR

(* Inicialización de variables *)
IF NOT habilitado THEN
    (* Modo amarillo intermitente *)
    tIntermitente(IN := TRUE, PT := T#1S);
    luzV := FALSE;
    luzR := FALSE;
    luzA := tIntermitente.Q;
    estado := 0; (* Reinicia el estado para cuando se habilite de nuevo *)
ELSE
    (* Modo ciclo normal del semáforo *)
    tIntermitente(IN := FALSE);
    CASE estado OF
        0: (* Luz verde *)
            tCiclo(IN := TRUE, PT := T#20S);
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            IF tCiclo.Q THEN
                estado := 1;
                tCiclo(IN := FALSE);
            END_IF;
        1: (* Luz amarilla *)
            tCiclo(IN := TRUE, PT := T#4S);
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            IF tCiclo.Q THEN
                estado := 2;
                tCiclo(IN := FALSE);
            END_IF;
        2: (* Luz roja *)
            tCiclo(IN := TRUE, PT := T#15S);
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            IF tCiclo.Q THEN
                estado := 0;
                tCiclo(IN := FALSE);
            END_IF;
    END_CASE;
END_IF;
END_FUNCTION_BLOCK
```