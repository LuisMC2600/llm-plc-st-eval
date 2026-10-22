```pascal
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
    parpadeo : BOOL; (* Estado interno de parpadeo *)
END_VAR

(* Sin alarma: lampara apagada y temporizadores reiniciados *)
IF NOT alarma THEN
    parpadeo := FALSE;
    tOn(IN  := FALSE, PT := T#1S);
    tOff(IN := FALSE, PT := T#1S);
ELSE
    (* Fase encendida: activa tOn mientras parpadeo = TRUE *)
    tOn(IN := parpadeo, PT := T#1S);

    (* Al completarse tOn, pasa a fase apagada *)
    IF tOn.Q THEN
        parpadeo := FALSE;
        tOn(IN := FALSE, PT := T#1S); (* Reinicia tOn *)
    END_IF;

    (* Fase apagada: activa tOff mientras parpadeo = FALSE *)
    tOff(IN := NOT parpadeo, PT := T#1S);

    (* Al completarse tOff, pasa a fase encendida *)
    IF tOff.Q THEN
        parpadeo := TRUE;
        tOff(IN := FALSE, PT := T#1S); (* Reinicia tOff *)
    END_IF;
END_IF;

(* La lampara sigue el estado de parpadeo solo si hay alarma *)
lampara := alarma AND parpadeo;
END_FUNCTION_BLOCK
```