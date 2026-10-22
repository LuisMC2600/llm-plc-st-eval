```pascal
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Botón de marcha: TRUE = pulsado *)
    btnParo   : BOOL; (* Botón de paro: TRUE = pulsado *)
    btnEmerg  : BOOL; (* Paro de emergencia: TRUE = activado *)
END_VAR

VAR_OUTPUT
    motorOn : BOOL; (* Salida al contactor del motor *)
END_VAR

VAR
    bloqueado : BOOL; (* Enclavamiento por emergencia *)
END_VAR

(*
    Lógica de control:
    1. Si se activa la emergencia → parar motor y bloquear rearranque.
    2. Si se pulsa paro → parar motor (sin bloqueo).
    3. Si se pulsa marcha Y no hay bloqueo → arrancar motor (set).
    4. El motor se mantiene encendido por auto-retención (motorOn se conserva).
*)

(* --- Gestión del enclavamiento por emergencia --- *)
IF btnEmerg THEN
    bloqueado := TRUE;  (* Bloqueo permanente hasta reset manual *)
END_IF;

(* --- Paro: emergencia o botón de paro --- *)
IF btnEmerg OR btnParo THEN
    motorOn := FALSE;

(* --- Arranque: marcha pulsada, sin bloqueo y sin paro activo --- *)
ELSIF btnMarcha AND NOT bloqueado THEN
    motorOn := TRUE;

(* --- Auto-retención: si no hay orden nueva, mantener estado actual --- *)
(* (motorOn conserva su valor al no asignarse en otra rama) *)
END_IF;
```