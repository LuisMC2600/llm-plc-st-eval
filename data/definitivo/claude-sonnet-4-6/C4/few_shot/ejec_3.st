## Descripción

`FB_D` implementa un control de arranque alternado con respaldo para dos bombas redundantes. Cada vez que llega un flanco ascendente de la señal de demanda, el bloque alterna el turno de prioridad entre las dos bombas, distribuyendo el desgaste de forma equitativa. Cuando hay demanda activa, la bomba de turno arranca siempre que no presente falla propia; si la bomba prioritaria falla, el bloque conmuta automáticamente a la bomba de respaldo (siempre que esta no falle también), y activa la alarma de falla. Si no hay demanda, ambas bombas permanecen apagadas y la alarma se silencia. Una aplicación típica sería un sistema de bombeo de agua o de transferencia de fluidos donde se requiere alta disponibilidad y mantenimiento predictivo equilibrado entre dos unidades.

---

## Código comentado

```pascal
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL;  (* Señal de solicitud de bombeo (TRUE = se requiere caudal) *)
    falla1  : BOOL;  (* Señal de falla de la bomba 1 (TRUE = bomba 1 en falla) *)
    falla2  : BOOL;  (* Señal de falla de la bomba 2 (TRUE = bomba 2 en falla) *)
END_VAR
VAR_OUTPUT
    bomba1   : BOOL; (* Comando de arranque de la bomba 1 *)
    bomba2   : BOOL; (* Comando de arranque de la bomba 2 *)
    almFalla : BOOL; (* Alarma activa cuando la bomba prioritaria está en falla *)
END_VAR
VAR
    turno : BOOL;   (* FALSE = turno de bomba 2 como prioritaria;
                       TRUE  = turno de bomba 1 como prioritaria *)
    fDem  : R_TRIG; (* Detector de flanco ascendente sobre la señal de demanda *)
END_VAR

(* ── Detección de flanco ascendente de demanda ───────────────────────────────
   Cada vez que demanda pasa de FALSE a TRUE se genera un pulso en fDem.Q.
   Esto permite alternar el turno exactamente una vez por cada nueva solicitud. *)
fDem(CLK := demanda);

(* ── Alternancia de turno ────────────────────────────────────────────────────
   En cada flanco ascendente de demanda se invierte la variable turno,
   cambiando qué bomba actúa como prioritaria en el siguiente ciclo de bombeo. *)
IF fDem.Q THEN
    turno := NOT turno;
END_IF

(* ── Lógica de arranque y respaldo ───────────────────────────────────────────
   Solo se activan bombas mientras la demanda esté presente. *)
IF demanda THEN

    (* ── Turno de bomba 1 como prioritaria ───────────────────────────────── *)
    IF turno THEN
        (* Bomba 1 arranca si no tiene falla propia *)
        bomba1 := NOT falla1;

        (* Bomba 2 entra como respaldo únicamente si bomba 1 falló
           y ella misma no presenta falla *)
        bomba2 := falla1 AND NOT falla2;

        (* Alarma activa si la bomba prioritaria (bomba 1) está en falla *)
        almFalla := falla1;

    (* ── Turno de bomba 2 como prioritaria ───────────────────────────────── *)
    ELSE
        (* Bomba 2 arranca si no tiene falla propia *)
        bomba2 := NOT falla2;

        (* Bomba 1 entra como respaldo únicamente si bomba 2 falló
           y ella misma no presenta falla *)
        bomba1 := falla2 AND NOT falla1;

        (* Alarma activa si la bomba prioritaria (bomba 2) está en falla *)
        almFalla := falla2;
    END_IF

(* ── Sin demanda: todo apagado ───────────────────────────────────────────────
   Se fuerzan a FALSE todas las salidas para garantizar estado seguro
   cuando no se requiere bombeo. *)
ELSE
    bomba1   := FALSE;
    bomba2   := FALSE;
    almFalla := FALSE;
END_IF

END_FUNCTION_BLOCK
```