```pascal
FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; (* Condición de alarma activa *)
END_VAR

VAR_OUTPUT
    lampara : BOOL; (* Salida de la lámpara de baliza *)
END_VAR

VAR
    tonEncendida : TON; (* Temporizador para tiempo encendida *)
    tonApagada   : TON; (* Temporizador para tiempo apagada *)
    estadoLuz    : BOOL; (* Estado interno del parpadeo: TRUE=encendida *)
END_VAR

(* ─────────────────────────────────────────────
   Lógica principal
   ───────────────────────────────────────────── *)

IF NOT alarma THEN
    (* Sin alarma: apagar lámpara y resetear todo *)
    lampara      := FALSE;
    estadoLuz    := FALSE;
    tonEncendida(IN := FALSE, PT := T#1S);
    tonApagada  (IN := FALSE, PT := T#1S);

ELSE
    (* Con alarma: alternar entre encendida y apagada *)

    IF estadoLuz THEN
        (* Fase encendida: esperar 1 s y luego pasar a apagada *)
        tonApagada  (IN := FALSE, PT := T#1S); (* Mantener apagado el otro TON *)
        tonEncendida(IN := TRUE,  PT := T#1S);

        IF tonEncendida.Q THEN
            (* Tiempo encendida cumplido → cambiar a fase apagada *)
            estadoLuz := FALSE;
            tonEncendida(IN := FALSE, PT := T#1S); (* Reset *)
        END_IF;

    ELSE
        (* Fase apagada: esperar 1 s y luego pasar a encendida *)
        tonEncendida(IN := FALSE, PT := T#1S); (* Mantener apagado el otro TON *)
        tonApagada  (IN := TRUE,  PT := T#1S);

        IF tonApagada.Q THEN
            (* Tiempo apagada cumplido → cambiar a fase encendida *)
            estadoLuz := TRUE;
            tonApagada(IN := FALSE, PT := T#1S); (* Reset *)
        END_IF;

    END_IF;

    (* La salida refleja el estado interno del parpadeo *)
    lampara := estadoLuz;

END_IF;
```