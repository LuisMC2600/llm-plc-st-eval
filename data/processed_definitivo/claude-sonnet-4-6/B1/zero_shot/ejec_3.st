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
    3. Si está bloqueado → no permitir arranque aunque btnMarcha esté activo.
    4. Si se pulsa marcha y no hay bloqueo ni paro → arrancar y retener (automantenimiento).
*)

(* --- Gestión del enclavamiento por emergencia --- *)
IF btnEmerg THEN
    bloqueado := TRUE;  (* Activa bloqueo; solo un reset manual lo limpia *)
END_IF;

(* --- Lógica de paro con prioridad sobre marcha --- *)
IF btnEmerg OR btnParo THEN
    motorOn := FALSE;   (* Paro inmediato en cualquier caso *)

(* --- Lógica de arranque: solo si no hay bloqueo activo --- *)
ELSIF btnMarcha AND NOT bloqueado THEN
    motorOn := TRUE;    (* Arranque + automantenimiento por la propia salida *)
END_IF;

(* Nota: el automantenimiento lo garantiza el PLC al conservar el valor
   de motorOn entre ciclos; no se necesita contacto auxiliar explícito
   en ST porque la variable retiene su estado hasta que se modifique. *)