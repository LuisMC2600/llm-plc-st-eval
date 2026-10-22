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
    1. Si se activa la emergencia → parar motor y bloquear rearranque.
    2. El bloqueo de emergencia solo se libera cuando btnEmerg vuelve
       a FALSE (emergencia restablecida) Y el botón de marcha NO está
       pulsado, evitando un arranque automático no deseado.
    3. Paro normal → apaga el motor sin bloqueo.
    4. Marcha → arranca solo si no hay bloqueo activo.
    5. Autoretención: motorOn se mantiene mientras no haya paro.
*)

(* --- Gestión del enclavamiento de emergencia --- *)
IF btnEmerg THEN
    (* Emergencia activa: bloquear y apagar *)
    bloqueEmerg := TRUE;
    motorOn     := FALSE;

ELSIF bloqueEmerg THEN
    (* Emergencia ya restablecida (btnEmerg = FALSE):
       liberar bloqueo solo si el botón de marcha no está pulsado *)
    IF NOT btnMarcha THEN
        bloqueEmerg := FALSE;
    END_IF;
    motorOn := FALSE; (* Motor permanece parado mientras haya bloqueo *)

ELSE
    (* Funcionamiento normal: sin emergencia ni bloqueo *)

    IF btnParo THEN
        (* Paro normal: apagar motor *)
        motorOn := FALSE;

    ELSIF btnMarcha THEN
        (* Arranque: activar motor *)
        motorOn := TRUE;

    END_IF;
    (* Si ningún botón está pulsado, motorOn conserva su valor → autoretención *)

END_IF;