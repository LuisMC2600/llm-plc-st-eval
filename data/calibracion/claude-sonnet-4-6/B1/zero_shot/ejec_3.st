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
    bloqueEmerg : BOOL := FALSE; (* Bloqueo activo tras emergencia *)
END_VAR

(*
    Lógica de control:
    1. Si se activa la emergencia → parar motor y activar bloqueo.
    2. El bloqueo se libera SOLO cuando btnEmerg vuelve a FALSE
       Y btnMarcha NO está pulsado (evita rearranque automático).
    3. Paro normal → apagar motor (sin bloqueo).
    4. Marcha → encender motor si no hay bloqueo ni paro activo.
    5. Autoenclavamiento: motorOn se mantiene al soltar btnMarcha.
*)

(* --- Paso 1: Gestión del bloqueo por emergencia --- *)
IF btnEmerg THEN
    (* Emergencia activa: bloquear y apagar *)
    bloqueEmerg := TRUE;
    motorOn     := FALSE;

ELSIF bloqueEmerg THEN
    (* Emergencia retirada: liberar bloqueo solo si btnMarcha no está pulsado *)
    IF NOT btnMarcha THEN
        bloqueEmerg := FALSE;
    END_IF;
    (* Motor permanece apagado mientras dure el bloqueo *)
    motorOn := FALSE;

ELSE
    (* --- Paso 2: Operación normal (sin emergencia ni bloqueo) --- *)

    IF btnParo THEN
        (* Paro normal: apagar motor *)
        motorOn := FALSE;

    ELSIF btnMarcha THEN
        (* Marcha: encender motor *)
        motorOn := TRUE;

    END_IF;
    (* Si ningún botón está pulsado, motorOn conserva su valor → autoenclavamiento *)

END_IF;
```