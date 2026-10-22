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
    (* Fase encendida: activa tOn mientras parpadeo=TRUE *)
    tOn(IN := parpadeo, PT := T#1S);

    (* Fase apagada: activa tOff cuando tOn expira *)
    tOff(IN := tOn.Q, PT := T#1S);

    (* Al expirar tOff, reinicia el ciclo volviendo a encender *)
    IF tOff.Q THEN
        parpadeo := FALSE; (* Fuerza reinicio de tOn en el proximo ciclo *)
    END_IF;

    (* Inicia el ciclo si parpadeo esta apagado y tOff no esta corriendo *)
    IF NOT parpadeo AND NOT tOn.Q AND NOT tOff.IN THEN
        parpadeo := TRUE;
    END_IF;
END_IF;

(* La lampara sigue el estado de parpadeo solo durante alarma *)
lampara := alarma AND parpadeo;
END_FUNCTION_BLOCK