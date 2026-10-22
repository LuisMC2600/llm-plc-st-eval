FUNCTION_BLOCK FB_D

(* ─────────────────────────────────────────────────────────────────────────
   Entradas del bloque
   ───────────────────────────────────────────────────────────────────────── *)
VAR_INPUT
    demanda : BOOL;   (* Señal de solicitud de bombeo (TRUE = hay demanda) *)
    falla1  : BOOL;   (* Señal de falla de la bomba 1 (TRUE = bomba 1 en falla) *)
    falla2  : BOOL;   (* Señal de falla de la bomba 2 (TRUE = bomba 2 en falla) *)
END_VAR

(* ─────────────────────────────────────────────────────────────────────────
   Salidas del bloque
   ───────────────────────────────────────────────────────────────────────── *)
VAR_OUTPUT
    bomba1   : BOOL;  (* Comando de arranque de la bomba 1 (TRUE = arrancar) *)
    bomba2   : BOOL;  (* Comando de arranque de la bomba 2 (TRUE = arrancar) *)
    almFalla : BOOL;  (* Alarma de falla activa en la bomba principal del turno *)
END_VAR

(* ─────────────────────────────────────────────────────────────────────────
   Variables internas
   ───────────────────────────────────────────────────────────────────────── *)
VAR
    turno : BOOL;    (* Indicador de turno: FALSE = bomba 2 es principal,
                                            TRUE  = bomba 1 es principal *)
    fDem  : R_TRIG;  (* Detector de flanco ascendente sobre la señal de demanda *)
END_VAR

(* ─────────────────────────────────────────────────────────────────────────
   SECCIÓN 1 – Detección de flanco ascendente en la señal de demanda
   Cada vez que 'demanda' pasa de FALSE a TRUE se genera un pulso en fDem.Q,
   lo que indica un nuevo ciclo de solicitud de bombeo.
   ───────────────────────────────────────────────────────────────────────── *)
fDem(CLK := demanda);

(* ─────────────────────────────────────────────────────────────────────────
   SECCIÓN 2 – Alternancia de turno
   En cada flanco ascendente de demanda se invierte 'turno', logrando que
   las bombas se alternen como unidad principal en cada nueva solicitud.
   ───────────────────────────────────────────────────────────────────────── *)
IF fDem.Q THEN
    turno := NOT turno;
END_IF

(* ─────────────────────────────────────────────────────────────────────────
   SECCIÓN 3 – Lógica de control de bombas según demanda y turno
   ───────────────────────────────────────────────────────────────────────── *)
IF demanda THEN

    (* ── Turno de bomba 1 como unidad principal ── *)
    IF turno THEN
        (* Bomba 1 arranca si NO tiene falla propia *)
        bomba1 := NOT falla1;

        (* Bomba 2 actúa como respaldo: arranca solo si bomba 1 falló
           Y bomba 2 no tiene falla propia *)
        bomba2 := falla1 AND NOT falla2;

        (* Alarma activa si la unidad principal (bomba 1) está en falla *)
        almFalla := falla1;

    (* ── Turno de bomba 2 como unidad principal ── *)
    ELSE
        (* Bomba 2 arranca si NO tiene falla propia *)
        bomba2 := NOT falla2;

        (* Bomba 1 actúa como respaldo: arranca solo si bomba 2 falló
           Y bomba 1 no tiene falla propia *)
        bomba1 := falla2 AND NOT falla1;

        (* Alarma activa si la unidad principal (bomba 2) está en falla *)
        almFalla := falla2;
    END_IF

(* ─────────────────────────────────────────────────────────────────────────
   SECCIÓN 4 – Sin demanda: apagado total y silencio de alarma
   ───────────────────────────────────────────────────────────────────────── *)
ELSE
    bomba1   := FALSE;  (* Detener bomba 1 *)
    bomba2   := FALSE;  (* Detener bomba 2 *)
    almFalla := FALSE;  (* Desactivar alarma *)
END_IF

END_FUNCTION_BLOCK