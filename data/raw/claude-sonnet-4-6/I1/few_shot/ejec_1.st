```st
FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; (* Habilita la secuencia normal del semaforo *)
END_VAR
VAR_OUTPUT
    luzV : BOOL; (* Luz verde *)
    luzA : BOOL; (* Luz amarilla *)
    luzR : BOOL; (* Luz roja *)
END_VAR
VAR
    estado     : INT;  (* Estado actual: 0=Verde, 1=Amarillo, 2=Rojo, 3=Amarillo intermitente *)
    tFase      : TON; (* Temporizador de fase normal *)
    tBlink     : TP;  (* Temporizador de pulso para amarillo intermitente *)
    blinkCiclo : BOOL; (* Disparo ciclico del parpadeo *)
END_VAR

IF NOT habilitado THEN
    (* --- Modo amarillo intermitente --- *)
    estado := 3;

    (* Genera ciclos de 1 s usando TP: cuando Q baja, se relanza *)
    tBlink(IN := NOT tBlink.Q AND NOT blinkCiclo, PT := T#1S);

    (* blinkCiclo alterna cada vez que el temporizador termina *)
    IF tBlink.Q THEN
        blinkCiclo := NOT blinkCiclo;
    END_IF;

    luzV := FALSE;
    luzA := blinkCiclo; (* Amarillo parpadea 1 s ON / 1 s OFF *)
    luzR := FALSE;

    (* Reinicia el temporizador de fase para que al habilitar empiece limpio *)
    tFase(IN := FALSE, PT := T#1S);

ELSE
    (* --- Modo secuencia normal --- *)
    tBlink(IN := FALSE, PT := T#1S); (* Mantiene el TP inactivo *)
    blinkCiclo := FALSE;

    CASE estado OF

        0: (* Verde 20 s *)
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            tFase(IN := TRUE, PT := T#20S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#20S); (* Resetea temporizador *)
                estado := 1;
            END_IF;

        1: (* Amarillo 4 s *)
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            tFase(IN := TRUE, PT := T#4S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#4S);
                estado := 2;
            END_IF;

        2: (* Rojo 15 s *)
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            tFase(IN := TRUE, PT := T#15S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#15S);
                estado := 0; (* Reinicia ciclo *)
            END_IF;

        3: (* Venia de modo intermitente: reinicia en verde *)
            estado := 0;
            tFase(IN := FALSE, PT := T#1S);
            luzV := FALSE;
            luzA := FALSE;
            luzR := FALSE;

        ELSE
            estado := 0; (* Estado invalido: ir a verde *)

    END_CASE;
END_IF;

END_FUNCTION_BLOCK
```