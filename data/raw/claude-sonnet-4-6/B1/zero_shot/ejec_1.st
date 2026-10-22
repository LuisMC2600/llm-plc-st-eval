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
    2. El bloqueo se mantiene mientras btnEmerg siga activo.
    3. Si se pulsa paro → apagar motor (sin bloqueo).
    4. Si se pulsa marcha y no hay bloqueo → encender motor (auto-retención).
*)

(* --- Gestión del enclavamiento de emergencia --- *)
IF btnEmerg THEN
    bloqueado := TRUE;   (* Activar bloqueo *)
    motorOn   := FALSE;  (* Parar motor inmediatamente *)
ELSIF NOT btnEmerg THEN
    bloqueado := FALSE;  (* Liberar bloqueo cuando se rearma la emergencia *)
END_IF;

(* --- Lógica de marcha / paro (solo si no hay bloqueo) --- *)
IF NOT bloqueado THEN
    IF btnParo THEN
        motorOn := FALSE; (* Paro normal *)
    ELSIF btnMarcha THEN
        motorOn := TRUE;  (* Arranque con auto-retención *)
    END_IF;
END_IF;

END_FUNCTION_BLOCK
```