```pascal
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL; (* Botón de marcha: TRUE = pulsado *)
    btnParo   : BOOL; (* Botón de paro: TRUE = pulsado   *)
    btnEmerg  : BOOL; (* Paro de emergencia: TRUE = activo *)
END_VAR

VAR_OUTPUT
    motorOn : BOOL; (* TRUE = motor en marcha *)
END_VAR

VAR
    bloqueado : BOOL; (* Enclavamiento post-emergencia *)
END_VAR

(*
    Lógica de control:
    1. Si se activa la emergencia: parar motor y activar enclavamiento.
    2. Si el enclavamiento está activo: el motor no puede arrancar.
       El enclavamiento solo se libera cuando btnEmerg vuelve a FALSE
       Y btnMarcha NO está pulsado (evita rearranque automático).
    3. Si se pulsa paro: apagar motor (sin enclavamiento).
    4. Si se pulsa marcha y no hay enclavamiento ni paro: arrancar y
       mantener motor (auto-retención por lógica de estado).
*)

(* --- Paso 1: Gestión de emergencia --- *)
IF btnEmerg THEN
    motorOn   := FALSE;
    bloqueado := TRUE;  (* Activar enclavamiento *)
END_IF;

(* --- Paso 2: Liberación del enclavamiento ---
   Solo se libera cuando la emergencia se ha retirado
   Y el botón de marcha no está pulsado en ese instante *)
IF bloqueado AND NOT btnEmerg AND NOT btnMarcha THEN
    bloqueado := FALSE;
END_IF;

(* --- Paso 3 y 4: Control normal (solo si no hay emergencia activa
   ni enclavamiento vigente) --- *)
IF NOT btnEmerg AND NOT bloqueado THEN

    IF btnParo THEN
        (* Paro normal: apagar motor *)
        motorOn := FALSE;

    ELSIF btnMarcha THEN
        (* Arranque: encender motor *)
        motorOn := TRUE;

    (* Si ningún botón está pulsado, motorOn conserva su estado
       anterior (auto-retención implícita por variable de estado) *)
    END_IF;

END_IF;
```