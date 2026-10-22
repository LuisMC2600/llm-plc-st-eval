FUNCTION_BLOCK FB_D

(* ─────────────────────────────────────────────────────────────────────────
   Entradas del bloque
   ───────────────────────────────────────────────────────────────────────── *)
VAR_INPUT
    demanda : BOOL;   (* Señal de solicitud de bombeo (TRUE = hay demanda activa)  *)
    falla1  : BOOL;   (* Señal de falla de la bomba 1 (TRUE = bomba 1 en falla)    *)
    falla2  : BOOL;   (* Señal de falla de la bomba 2 (TRUE = bomba 2 en falla)    *)
END_VAR

(* ─────────────────────────────────────────────────────────────────────────
   Salidas del bloque
   ───────────────────────────────────────────────────────────────────────── *)
VAR_OUTPUT
    bomba1   : BOOL;  (* Comando de arranque para la bomba 1 (TRUE = arrancar)     *)
    bomba2   : BOOL;  (* Comando de arranque para la bomba 2 (TRUE = arrancar)     *)
    almFalla : BOOL;  (* Alarma de falla: TRUE cuando la bomba principal del turno
                         ha fallado y se ha activado (o intentado) el respaldo     *)
END_VAR

(* ─────────────────────────────────────────────────────────────────────────
   Variables internas
   ───────────────────────────────────────────────────────────────────────── *)
VAR
    turno : BOOL;    (* Bandera de turno: FALSE → bomba 2 es principal,
                                          TRUE  → bomba 1 es principal.
                        Persiste entre ciclos para mantener la alternancia.       *)
    fDem  : R_TRIG;  (* Detector de flanco ascendente sobre la señal de demanda;
                        se usa para cambiar el turno solo en cada nueva solicitud *)
END_VAR

(* ─────────────────────────────────────────────────────────────────────────
   SECCIÓN 1 – Detección de flanco ascendente en la demanda
   Cada vez que 'demanda' pasa de FALSE a TRUE se genera un pulso en fDem.Q,
   lo que dispara el cambio de turno (alternancia de bomba principal).
   ───────────────────────────────────────────────────────────────────────── *)
fDem(CLK := demanda);

(* ─────────────────────────────────────────────────────────────────────────
   SECCIÓN 2 – Alternancia de turno
   En el flanco ascendente de la demanda se invierte la bandera 'turno',
   seleccionando así la bomba principal para este nuevo ciclo de servicio.
   ───────────────────────────────────────────────────────────────────────── *)
IF fDem.Q THEN
    turno := NOT turno;   (* Invierte el turno: cambia la bomba principal *)
END_IF

(* ─────────────────────────────────────────────────────────────────────────
   SECCIÓN 3 – Lógica de control de bombas
   Solo se actúan las bombas mientras exista demanda activa.
   ───────────────────────────────────────────────────────────────────────── *)
IF demanda THEN

    (* ── Turno de bomba 1 como principal ─────────────────────────────────
       bomba1 arranca si NO tiene falla (es la principal y está sana).
       bomba2 arranca como respaldo SOLO si bomba1 falló y bomba2 está sana.
       almFalla se activa si la principal (bomba1) ha fallado.
       ─────────────────────────────────────────────────────────────────── *)
    IF turno THEN
        bomba1   := NOT falla1;              (* Principal: ON si no hay falla1          *)
        bomba2   := falla1 AND NOT falla2;   (* Respaldo:  ON solo si falla1 y no falla2*)
        almFalla := falla1;                  (* Alarma:    activa si la principal falló  *)

    (* ── Turno de bomba 2 como principal ─────────────────────────────────
       bomba2 arranca si NO tiene falla (es la principal y está sana).
       bomba1 arranca como respaldo SOLO si bomba2 falló y bomba1 está sana.
       almFalla se activa si la principal (bomba2) ha fallado.
       ─────────────────────────────────────────────────────────────────── *)
    ELSE
        bomba2   := NOT falla2;              (* Principal: ON si no hay falla2          *)
        bomba1   := falla2 AND NOT falla1;   (* Respaldo:  ON solo si falla2 y no falla1*)
        almFalla := falla2;                  (* Alarma:    activa si la principal falló  *)
    END_IF

(* ─────────────────────────────────────────────────────────────────────────
   SECCIÓN 4 – Sin demanda
   Cuando no hay solicitud de bombeo se apagan ambas bombas y se silencia
   la alarma de falla, dejando el sistema en reposo seguro.
   ───────────────────────────────────────────────────────────────────────── *)
ELSE
    bomba1   := FALSE;   (* Apagar bomba 1 *)
    bomba2   := FALSE;   (* Apagar bomba 2 *)
    almFalla := FALSE;   (* Silenciar alarma *)
END_IF

END_FUNCTION_BLOCK