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
    - btnParo y btnEmerg se asumen como contacto normalmente cerrado
      representado en lógica positiva: TRUE = fallo/paro activo.
    - bloqueado se activa con btnEmerg y solo se resetea manualmente
      (aquí se mantiene hasta un ciclo sin emergencia Y sin marcha,
       o bien puede requerir un reset explícito según la aplicación).
    - Para rearrancar tras emergencia se debe soltar btnEmerg
      y NO tener btnMarcha activo en ese mismo ciclo (reset seguro).
*)

(* 1. Activar enclavamiento si se detecta emergencia *)
IF btnEmerg THEN
    bloqueado := TRUE;
END_IF;

(* 2. Reset del enclavamiento: solo cuando NO hay emergencia
      Y NO hay botón de marcha pulsado (evita rearranque automático) *)
IF NOT btnEmerg AND NOT btnMarcha THEN
    bloqueado := FALSE;
END_IF;

(* 3. Lógica de marcha/paro con auto-retención (seal-in) *)
IF btnEmerg OR btnParo OR bloqueado THEN
    (* Paro prioritario: emergencia, paro normal o enclavamiento activo *)
    motorOn := FALSE;
ELSIF btnMarcha THEN
    (* Arranque: flanco o nivel, el motor se enciende *)
    motorOn := TRUE;
END_IF;
(* Si ninguna condición aplica, motorOn conserva su valor anterior
   → auto-retención implementada por la variable de salida misma *)

END_FUNCTION_BLOCK
```