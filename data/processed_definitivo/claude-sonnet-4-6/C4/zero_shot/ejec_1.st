FUNCTION_BLOCK FB_D

(* ─────────────────────────────────────────────────────────────────
   Entradas del bloque
   ───────────────────────────────────────────────────────────────── *)
VAR_INPUT
    demanda : BOOL;   (* Señal de demanda de bombeo (TRUE = se requiere caudal) *)
    falla1  : BOOL;   (* Señal de fallo de la Bomba 1 (TRUE = bomba en falla)   *)
    falla2  : BOOL;   (* Señal de fallo de la Bomba 2 (TRUE = bomba en falla)   *)
END_VAR

(* ─────────────────────────────────────────────────────────────────
   Salidas del bloque
   ───────────────────────────────────────────────────────────────── *)
VAR_OUTPUT
    bomba1   : BOOL;  (* Comando de arranque de la Bomba 1 (TRUE = arrancar)    *)
    bomba2   : BOOL;  (* Comando de arranque de la Bomba 2 (TRUE = arrancar)    *)
    almFalla : BOOL;  (* Alarma activa cuando la bomba prioritaria está en falla *)
END_VAR

(* ─────────────────────────────────────────────────────────────────
   Variables internas
   ───────────────────────────────────────────────────────────────── *)
VAR
    turno : BOOL;      (* Bit de turno: FALSE = prioridad Bomba 2,
                                        TRUE  = prioridad Bomba 1             *)
    fDem  : R_TRIG;    (* Detector de flanco ascendente sobre la señal demanda  *)
END_VAR

(* ─────────────────────────────────────────────────────────────────
   SECCIÓN 1 – Detección de flanco ascendente en la demanda
   Cada vez que 'demanda' pasa de FALSE a TRUE se genera un pulso
   en fDem.Q, lo que provoca la alternancia de turno.
   ───────────────────────────────────────────────────────────────── *)
fDem(CLK := demanda);

(* ─────────────────────────────────────────────────────────────────
   SECCIÓN 2 – Alternancia de turno
   Con cada nuevo flanco de demanda se invierte el bit 'turno',
   asegurando que las bombas se alternen como unidad prioritaria
   en cada ciclo de demanda consecutivo.
   ───────────────────────────────────────────────────────────────── *)
IF fDem.Q THEN
    turno := NOT turno;
END_IF

(* ─────────────────────────────────────────────────────────────────
   SECCIÓN 3 – Lógica de arranque y gestión de fallos
   ───────────────────────────────────────────────────────────────── *)
IF demanda THEN

    (* ── Rama A: turno = TRUE → Bomba 1 es la unidad prioritaria ── *)
    IF turno THEN
        (* Bomba 1 arranca si NO está en falla (es la prioritaria)   *)
        bomba1 := NOT falla1;

        (* Bomba 2 arranca como respaldo SOLO si Bomba 1 falló
           y Bomba 2 no tiene falla propia                           *)
        bomba2 := falla1 AND NOT falla2;

        (* Alarma activa si la unidad prioritaria (Bomba 1) falló    *)
        almFalla := falla1;

    (* ── Rama B: turno = FALSE → Bomba 2 es la unidad prioritaria ── *)
    ELSE
        (* Bomba 2 arranca si NO está en falla (es la prioritaria)   *)
        bomba2 := NOT falla2;

        (* Bomba 1 arranca como respaldo SOLO si Bomba 2 falló
           y Bomba 1 no tiene falla propia                           *)
        bomba1 := falla2 AND NOT falla1;

        (* Alarma activa si la unidad prioritaria (Bomba 2) falló    *)
        almFalla := falla2;
    END_IF

(* ─────────────────────────────────────────────────────────────────
   SECCIÓN 4 – Sin demanda: apagado total y reset de alarma
   Cuando no hay demanda ambas bombas se detienen y la alarma
   se desactiva, independientemente del estado de fallos.
   ───────────────────────────────────────────────────────────────── *)
ELSE
    bomba1   := FALSE;
    bomba2   := FALSE;
    almFalla := FALSE;
END_IF

END_FUNCTION_BLOCK