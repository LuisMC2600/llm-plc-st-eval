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
    bloqueEmerg : BOOL := FALSE; (* Enclavamiento por emergencia *)
END_VAR

(*
    Lógica de control:
    1. Si se activa la emergencia: parar motor y bloquear rearranque.
    2. El bloqueo de emergencia solo se libera cuando btnEmerg vuelve
       a FALSE (rearme manual implícito al soltar la seta).
    3. Si no hay bloqueo: SET con btnMarcha, RESET con btnParo.
*)

(* --- Gestión del enclavamiento de emergencia --- *)
IF btnEmerg THEN
    bloqueEmerg := TRUE;  (* Activar bloqueo *)
ELSIF NOT btnEmerg THEN
    bloqueEmerg := FALSE; (* Liberar bloqueo al soltar la seta *)
END_IF;

(* --- Lógica de marcha / paro con enclavamiento --- *)
IF bloqueEmerg OR btnParo THEN
    (* Paro prioritario: emergencia o botón de paro *)
    motorOn := FALSE;
ELSIF btnMarcha AND NOT bloqueEmerg THEN
    (* Arranque: solo si no hay bloqueo activo *)
    motorOn := TRUE;
END_IF;
(* Si ninguna condición aplica, motorOn conserva su valor anterior
   (efecto de memoria / auto-mantenimiento). *)

END_FUNCTION_BLOCK
```