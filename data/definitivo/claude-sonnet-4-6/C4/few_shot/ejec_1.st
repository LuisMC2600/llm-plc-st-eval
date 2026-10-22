## Descripción

`FB_D` implementa un control de arranque alternado con redundancia para dos bombas. Cada vez que llega una nueva solicitud de demanda (flanco ascendente), el bloque alterna el turno de prioridad entre las dos bombas, de modo que el desgaste se distribuye equitativamente a lo largo del tiempo. Cuando hay demanda activa, la bomba de turno arranca siempre que no presente falla; si la bomba prioritaria falla, la bomba secundaria entra automáticamente como respaldo, siempre que ella misma no esté también en falla. Si ninguna bomba está en demanda, ambas permanecen apagadas y la alarma se silencia. Este esquema es típico de estaciones de bombeo de agua, sistemas de presurización o plantas de tratamiento donde se requiere continuidad de servicio y mantenimiento preventivo equilibrado.

---

```
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL;  (* Señal de solicitud de caudal/presión *)
    falla1  : BOOL;  (* Fallo detectado en bomba 1 (p.ej. térmico, caudal) *)
    falla2  : BOOL;  (* Fallo detectado en bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1   : BOOL; (* Orden de marcha a bomba 1 *)
    bomba2   : BOOL; (* Orden de marcha a bomba 2 *)
    almFalla : BOOL; (* Alarma activa: la bomba de turno ha fallado *)
END_VAR
VAR
    turno : BOOL;   (* FALSE = turno de bomba 2 prioritaria,
                       TRUE  = turno de bomba 1 prioritaria *)
    fDem  : R_TRIG; (* Detector de flanco ascendente sobre 'demanda' *)
END_VAR

(* ── Detección de flanco ascendente de demanda ──────────────────────────
   fDem.Q vale TRUE únicamente durante el ciclo en que 'demanda'
   pasa de FALSE a TRUE; se usa para alternar el turno en cada
   nueva solicitud, no en cada ciclo de scan.                          *)
fDem(CLK := demanda);

(* ── Alternancia de turno ───────────────────────────────────────────────
   Con cada nuevo flanco de demanda se invierte la bomba prioritaria,
   distribuyendo las horas de funcionamiento entre ambas unidades.     *)
IF fDem.Q THEN
    turno := NOT turno;
END_IF

(* ── Lógica de arranque con redundancia ─────────────────────────────── *)
IF demanda THEN

    IF turno THEN
        (* Turno de bomba 1 como unidad principal *)
        bomba1 := NOT falla1;              (* Arranca bomba 1 si no falla *)
        bomba2 := falla1 AND NOT falla2;   (* Bomba 2 entra solo si bomba 1 falla
                                              y bomba 2 está sana              *)
        almFalla := falla1;                (* Alarma si la unidad prioritaria falla *)

    ELSE
        (* Turno de bomba 2 como unidad principal *)
        bomba2 := NOT falla2;              (* Arranca bomba 2 si no falla *)
        bomba1 := falla2 AND NOT falla1;   (* Bomba 1 entra solo si bomba 2 falla
                                              y bomba 1 está sana              *)
        almFalla := falla2;                (* Alarma si la unidad prioritaria falla *)
    END_IF

ELSE
    (* ── Sin demanda: apagado total y reset de alarma ───────────────── *)
    bomba1   := FALSE;
    bomba2   := FALSE;
    almFalla := FALSE;
END_IF

END_FUNCTION_BLOCK
```