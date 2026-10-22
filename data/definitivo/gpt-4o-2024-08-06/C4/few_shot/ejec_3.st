El FUNCTION_BLOCK FB_D está diseñado para gestionar el control de dos bombas en un sistema redundante, donde se alterna el uso de las bombas para equilibrar el desgaste. El bloque responde a una señal de demanda, activando una de las bombas si no hay fallas. Si una bomba falla, la otra se activa automáticamente, siempre que esté operativa. Además, se genera una alarma si se detecta una falla en la bomba que debería estar activa. Este bloque es útil en aplicaciones industriales donde se requiere redundancia y alternancia en el uso de equipos para asegurar la continuidad del servicio y minimizar el riesgo de paradas por fallas.

```pascal
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; (* Señal de demanda para activar las bombas *)
    falla1 : BOOL;  (* Indica si hay una falla en la bomba 1 *)
    falla2 : BOOL;  (* Indica si hay una falla en la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;  (* Estado de la bomba 1: activa o inactiva *)
    bomba2 : BOOL;  (* Estado de la bomba 2: activa o inactiva *)
    almFalla : BOOL; (* Alarma de falla en la bomba activa *)
END_VAR
VAR
    turno : BOOL;   (* Variable para alternar el uso de las bombas *)
    fDem : R_TRIG;  (* Detector de flanco ascendente para la demanda *)
END_VAR

(* Detecta el flanco ascendente de la señal de demanda *)
fDem(CLK := demanda);

(* Alterna el turno de las bombas en cada nueva demanda *)
IF fDem.Q THEN
    turno := NOT turno;
END_IF

(* Lógica de control de las bombas y alarmas *)
IF demanda THEN
    IF turno THEN
        (* Si es el turno de la bomba 1 *)
        bomba1 := NOT falla1; (* Activa bomba 1 si no hay falla *)
        bomba2 := falla1 AND NOT falla2; (* Activa bomba 2 si falla 1 y no falla 2 *)
        almFalla := falla1; (* Alarma si hay falla en bomba 1 *)
    ELSE
        (* Si es el turno de la bomba 2 *)
        bomba2 := NOT falla2; (* Activa bomba 2 si no hay falla *)
        bomba1 := falla2 AND NOT falla1; (* Activa bomba 1 si falla 2 y no falla 1 *)
        almFalla := falla2; (* Alarma si hay falla en bomba 2 *)
    END_IF
ELSE
    (* Si no hay demanda, ambas bombas y la alarma están inactivas *)
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK
```