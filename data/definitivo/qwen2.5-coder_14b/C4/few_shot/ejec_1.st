### Descripción
El FUNCTION_BLOCK FB_D implementa un sistema de control para dos bombas (bomba1 y bomba2) que deben alternar su operación en función de una demanda y dos posibles fallas (falla1 y falla2). La lógica del bloque asegura que solo una bomba esté activa a la vez, y que la bomba seleccionada dependa del estado de la demanda y las fallas presentes. Además, mantiene un registro de la última falla detectada (almFalla). Este bloque podría ser útil en aplicaciones industriales donde se requiere un sistema de redundancia y control de fallas, como en sistemas de bombeo o de suministro de fluidos.

### Código comentado
```structured-text
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; (* Indica si hay una demanda de activación *)
    falla1 : BOOL;  (* Indica si hay una falla en el sistema 1 *)
    falla2 : BOOL;  (* Indica si hay una falla en el sistema 2 *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;  (* Controla la activación de la bomba 1 *)
    bomba2 : BOOL;  (* Controla la activación de la bomba 2 *)
    almFalla : BOOL; (* Almacena el estado de la última falla detectada *)
END_VAR
VAR
    turno : BOOL;   (* Variable de estado para alternar entre bombas *)
    fDem : R_TRIG;  (* Detector de flanco de subida en la demanda *)
END_VAR

(* Detecta el flanco de subida en la demanda *)
fDem(CLK := demanda);

(* Cambia el turno entre bombas cuando hay una demanda *)
IF fDem.Q THEN
    turno := NOT turno;
END_IF

(* Control de las bombas y almacenamiento de la última falla *)
IF demanda THEN
    IF turno THEN
        bomba1 := NOT falla1; (* Activa bomba1 si no hay falla1 *)
        bomba2 := falla1 AND NOT falla2; (* Activa bomba2 si hay falla1 y no hay falla2 *)
        almFalla := falla1; (* Almacena el estado de falla1 *)
    ELSE
        bomba2 := NOT falla2; (* Activa bomba2 si no hay falla2 *)
        bomba1 := falla2 AND NOT falla1; (* Activa bomba1 si hay falla2 y no hay falla1 *)
        almFalla := falla2; (* Almacena el estado de falla2 *)
    END_IF
ELSE
    bomba1 := FALSE; (* Desactiva bomba1 si no hay demanda *)
    bomba2 := FALSE; (* Desactiva bomba2 si no hay demanda *)
    almFalla := FALSE; (* Limpia el registro de falla *)
END_IF
END_FUNCTION_BLOCK
```