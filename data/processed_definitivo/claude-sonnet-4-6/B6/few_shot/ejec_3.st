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

    (* Al completar tOff vuelve a fase encendida *)
    IF tOff.Q THEN
        parpadeo := FALSE; (* Reinicia para re-disparar tOn *)
    END_IF;

    (* Inicia ciclo: si ninguno esta corriendo, arranca fase encendida *)
    IF NOT tOn.IN AND NOT tOff.IN THEN
        parpadeo := TRUE;
    END_IF;
END_IF;

(* La lampara sigue el estado de parpadeo interno *)
lampara := parpadeo AND alarma;
END_FUNCTION_BLOCK