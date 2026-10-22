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
    bloqueEmerg : BOOL; (* Enclavamiento por emergencia *)
END_VAR

(*
    Lógica de control:
    1. Si se activa la emergencia → parar motor y bloquear rearranque.
    2. El bloqueo de emergencia solo se libera cuando btnEmerg vuelve
       a FALSE (emergencia restablecida) Y el botón de marcha NO está
       pulsado, evitando un arranque automático no deseado.
    3. Paro normal: btnParo detiene el motor sin bloquear el rearranque.
    4. Arranque: btnMarcha activa el motor si no hay bloqueo ni paro.
    5. Auto-retención: motorOn se mantiene mediante su propio estado.
*)

(* --- Gestión del enclavamiento de emergencia --- *)
IF btnEmerg THEN
    (* Activar bloqueo al detectar emergencia *)
    bloqueEmerg := TRUE;
ELSIF NOT btnEmerg AND NOT btnMarcha THEN
    (* Liberar bloqueo solo cuando la emergencia se restablece
       y el botón de marcha no está presionado *)
    bloqueEmerg := FALSE;
END_IF;

(* --- Lógica de arranque / paro del motor --- *)
IF btnEmerg OR btnParo OR bloqueEmerg THEN
    (* Prioridad de paro: emergencia, paro normal o bloqueo activo *)
    motorOn := FALSE;
ELSIF btnMarcha AND NOT bloqueEmerg THEN
    (* Arranque: condición de marcha sin bloqueo *)
    motorOn := TRUE;
END_IF;
(* Auto-retención implícita: motorOn conserva su valor TRUE
   mientras no se active ninguna condición de paro *)

END_FUNCTION_BLOCK
```