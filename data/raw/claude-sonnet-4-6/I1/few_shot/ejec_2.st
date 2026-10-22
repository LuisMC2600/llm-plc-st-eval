```st
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
    estado     : INT;  (* 0=Verde, 1=Amarillo, 2=Rojo, 3=Amarillo intermitente *)
    tFase      : TON; (* Temporizador de fase normal *)
    tBlink     : TP;  (* Temporizador de pulso para intermitente *)
    blinkState : BOOL; (* Estado actual del parpadeo *)
END_VAR

(* --- Maquina de estados del semaforo --- *)

IF NOT habilitado THEN
    (* Modo amarillo intermitente: las demas luces apagadas *)
    estado := 3;
    tFase(IN := FALSE, PT := T#1S); (* Resetear temporizador de fase *)
END_IF

CASE estado OF

    0: (* VERDE - 20 segundos *)
        luzV := TRUE;
        luzA := FALSE;
        luzR := FALSE;
        tFase(IN := TRUE, PT := T#20S);
        IF tFase.Q THEN
            tFase(IN := FALSE, PT := T#20S); (* Reset temporizador *)
            estado := 1;
        END_IF

    1: (* AMARILLO - 4 segundos *)
        luzV := FALSE;
        luzA := TRUE;
        luzR := FALSE;
        tFase(IN := TRUE, PT := T#4S);
        IF tFase.Q THEN
            tFase(IN := FALSE, PT := T#4S); (* Reset temporizador *)
            estado := 2;
        END_IF

    2: (* ROJO - 15 segundos *)
        luzV := FALSE;
        luzA := FALSE;
        luzR := TRUE;
        tFase(IN := TRUE, PT := T#15S);
        IF tFase.Q THEN
            tFase(IN := FALSE, PT := T#15S); (* Reset temporizador *)
            estado := 0; (* Reinicia ciclo en verde *)
        END_IF

    3: (* AMARILLO INTERMITENTE - 1s ON / 1s OFF *)
        luzV := FALSE;
        luzR := FALSE;
        (* Pulso de 1 segundo para generar el parpadeo *)
        tBlink(IN := NOT tBlink.Q, PT := T#1S);
        IF tBlink.Q THEN
            blinkState := NOT blinkState; (* Alternar estado del parpadeo *)
        END_IF
        luzA := blinkState;
        (* Si se habilita de nuevo, reiniciar en verde *)
        IF habilitado THEN
            blinkState := FALSE;
            tBlink(IN := FALSE, PT := T#1S); (* Reset temporizador blink *)
            estado := 0;
        END_IF

    ELSE
        (* Estado desconocido: ir a verde por seguridad *)
        estado := 0;

END_CASE

END_FUNCTION_BLOCK
```