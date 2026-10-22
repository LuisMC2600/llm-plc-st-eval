FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; (* Condición de alarma activa *)
END_VAR

VAR_OUTPUT
    lampara : BOOL; (* Salida de la lámpara de baliza *)
END_VAR

VAR
    tonEncendido  : TON; (* Temporizador para tiempo encendida *)
    tonApagado    : TON; (* Temporizador para tiempo apagada *)
    estadoLampara : BOOL := FALSE; (* Estado interno del parpadeo *)
END_VAR

(* -------------------------------------------------------
   Lógica de baliza de alarma
   - Sin alarma: lámpara apagada, temporizadores reseteados
   - Con alarma:  parpadeo 1s ON / 1s OFF
   ------------------------------------------------------- *)

IF NOT alarma THEN
    (* Sin alarma: apagar lámpara y resetear todo *)
    estadoLampara := FALSE;
    tonEncendido(IN := FALSE, PT := T#1S);
    tonApagado(IN := FALSE, PT := T#1S);
ELSE
    (* Con alarma: gestionar ciclo de parpadeo *)
    IF NOT estadoLampara THEN
        (* Fase APAGADA: esperar 1 segundo *)
        tonEncendido(IN := FALSE, PT := T#1S); (* Mantener reseteado *)
        tonApagado(IN := TRUE,  PT := T#1S);

        IF tonApagado.Q THEN
            (* Fin del segundo apagada → pasar a encendida *)
            estadoLampara := TRUE;
            tonApagado(IN := FALSE, PT := T#1S); (* Resetear temporizador *)
        END_IF;
    ELSE
        (* Fase ENCENDIDA: esperar 1 segundo *)
        tonApagado(IN := FALSE, PT := T#1S);  (* Mantener reseteado *)
        tonEncendido(IN := TRUE,  PT := T#1S);

        IF tonEncendido.Q THEN
            (* Fin del segundo encendida → pasar a apagada *)
            estadoLampara := FALSE;
            tonEncendido(IN := FALSE, PT := T#1S); (* Resetear temporizador *)
        END_IF;
    END_IF;
END_IF;

(* Asignar estado interno a la salida *)
lampara := estadoLampara;

END_FUNCTION_BLOCK