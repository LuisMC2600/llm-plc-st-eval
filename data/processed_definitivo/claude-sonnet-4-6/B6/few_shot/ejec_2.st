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
    tOn(IN := FALSE, PT := T#1S);
    tOff(IN := FALSE, PT := T#1S);
ELSE
    (* Fase encendida: activa tOn mientras parpadeo=TRUE *)
    tOn(IN := parpadeo, PT := T#1S);

    (* Fase apagada: activa tOff cuando tOn ha completado *)
    tOff(IN := tOn.Q, PT := T#1S);

    (* Al completar tOff, reinicia tOn para el siguiente ciclo *)
    IF tOff.Q THEN
        tOn(IN := FALSE, PT := T#1S);  (* Reinicia tOn *)
        tOff(IN := FALSE, PT := T#1S); (* Reinicia tOff *)
        parpadeo := TRUE;
    END_IF;

    (* Arranca el primer ciclo *)
    IF NOT parpadeo AND NOT tOn.Q AND NOT tOff.Q THEN
        parpadeo := TRUE;
    END_IF;
END_IF;

(* La lampara sigue el estado de parpadeo durante la fase encendida *)
lampara := alarma AND parpadeo AND NOT tOn.Q;
END_FUNCTION_BLOCK