El FUNCTION_BLOCK FB_D está diseñado para gestionar el control de dos bombas en un sistema de redundancia, donde se alterna el uso de las bombas cada vez que hay una nueva demanda de operación. Este bloque es útil en aplicaciones donde se requiere asegurar la continuidad del servicio, como en sistemas de suministro de agua o sistemas de refrigeración, donde es importante que al menos una bomba esté siempre operativa. El bloque también maneja situaciones de falla en las bombas, activando una alarma si alguna de las bombas falla. Si una bomba falla, el sistema intentará activar la otra bomba, siempre que esté disponible.

```pascal
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; (* Señal de demanda de operación *)
    falla1 : BOOL; (* Indica si la bomba 1 ha fallado *)
    falla2 : BOOL; (* Indica si la bomba 2 ha fallado *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL; (* Control de la bomba 1 *)
    bomba2 : BOOL; (* Control de la bomba 2 *)
    almFalla : BOOL; (* Alarma de falla de bomba *)
END_VAR
VAR
    turno : BOOL; (* Indica cuál bomba debe operar en el siguiente ciclo *)
    fDem : R_TRIG; (* Detector de flanco de subida para la señal de demanda *)
END_VAR

(* Detecta un flanco de subida en la señal de demanda *)
fDem(CLK := demanda);

(* Alterna el turno cada vez que hay un nuevo flanco de subida en la demanda *)
IF fDem.Q THEN
    turno := NOT turno;
END_IF

(* Lógica de control de bombas y manejo de fallas *)
IF demanda THEN
    IF turno THEN
        (* Si es el turno de la bomba 1 y no hay falla, activa bomba 1 *)
        bomba1 := NOT falla1;
        (* Si la bomba 1 falla, intenta activar la bomba 2 si no ha fallado *)
        bomba2 := falla1 AND NOT falla2;
        (* Activa la alarma si la bomba 1 falla *)
        almFalla := falla1;
    ELSE
        (* Si es el turno de la bomba 2 y no hay falla, activa bomba 2 *)
        bomba2 := NOT falla2;
        (* Si la bomba 2 falla, intenta activar la bomba 1 si no ha fallado *)
        bomba1 := falla2 AND NOT falla1;
        (* Activa la alarma si la bomba 2 falla *)
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