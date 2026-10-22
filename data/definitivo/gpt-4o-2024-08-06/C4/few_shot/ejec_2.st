El FUNCTION_BLOCK FB_D está diseñado para gestionar un sistema de bombeo redundante con dos bombas (bomba1 y bomba2) que se alternan en función de una señal de demanda. El bloque también maneja condiciones de falla para cada bomba y activa una alarma en caso de que alguna de las bombas falle. La lógica de alternancia asegura que, cada vez que se detecta una nueva demanda, se cambia la bomba activa, a menos que haya una falla en la bomba seleccionada, en cuyo caso se activa la otra bomba si está disponible. Este bloque es útil en aplicaciones industriales donde se requiere un sistema de bombeo redundante para asegurar la continuidad del servicio incluso en caso de fallas.

```pascal
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; (* Señal de demanda para activar el sistema de bombeo *)
    falla1 : BOOL; (* Indica si hay una falla en la bomba 1 *)
    falla2 : BOOL; (* Indica si hay una falla en la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL; (* Control de la bomba 1 *)
    bomba2 : BOOL; (* Control de la bomba 2 *)
    almFalla : BOOL; (* Alarma de falla si alguna bomba falla *)
END_VAR
VAR
    turno : BOOL; (* Variable para alternar entre las bombas *)
    fDem : R_TRIG; (* Detector de flanco de subida para la señal de demanda *)
END_VAR

(* Detecta un flanco de subida en la señal de demanda *)
fDem(CLK := demanda);

(* Si se detecta un nuevo flanco de subida en la demanda, alterna el turno *)
IF fDem.Q THEN
    turno := NOT turno;
END_IF

(* Lógica de control de bombas y alarma en función de la demanda y fallas *)
IF demanda THEN
    IF turno THEN
        (* Si es el turno de la bomba 1 y no hay falla, activa bomba 1 *)
        bomba1 := NOT falla1;
        (* Si hay falla en bomba 1, intenta activar bomba 2 si no está fallada *)
        bomba2 := falla1 AND NOT falla2;
        (* Activa la alarma si hay falla en bomba 1 *)
        almFalla := falla1;
    ELSE
        (* Si es el turno de la bomba 2 y no hay falla, activa bomba 2 *)
        bomba2 := NOT falla2;
        (* Si hay falla en bomba 2, intenta activar bomba 1 si no está fallada *)
        bomba1 := falla2 AND NOT falla1;
        (* Activa la alarma si hay falla en bomba 2 *)
        almFalla := falla2;
    END_IF
ELSE
    (* Si no hay demanda, apaga ambas bombas y resetea la alarma *)
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK
```