```st
FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; (* Condicion de alarma activa *)
END_VAR
VAR_OUTPUT
    lampara : BOOL; (* Lampara de baliza *)
END_VAR
VAR
    tOn  : TON; (* Temporizador fase encendida *)
    tOff : TON; (* Temporizador fase apagada *)
    bParpadeo : BOOL; (* Estado interno del parpadeo *)
END_VAR

(* Sin alarma: lampara apagada y temporizadores reiniciados *)
IF NOT alarma THEN
    bParpadeo := FALSE;
    tOn(IN  := FALSE, PT := T#1S);
    tOff(IN := FALSE, PT := T#1S);
ELSE
    (* Fase encendida: activa tOn mientras bParpadeo es TRUE *)
    tOn(IN := bParpadeo, PT := T#1S);

    (* Fase apagada: activa tOff cuando tOn ha completado *)
    tOff(IN := tOn.Q, PT := T#1S);

    (* Al completar tOff, reiniciar ciclo volviendo a fase encendida *)
    IF tOff.Q THEN
        bParpadeo := FALSE; (* Fuerza reinicio de tOn en el proximo ciclo *)
    END_IF;

    (* Arranque del primer ciclo o reinicio tras fase apagada *)
    IF NOT tOn.IN AND NOT tOff.IN THEN
        bParpadeo := TRUE;
    END_IF;
END_IF;

(* La lampara sigue el estado interno de parpadeo *)
lampara := bParpadeo AND alarma;
END_FUNCTION_BLOCK
```