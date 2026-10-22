```pascal
FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; (* Señal de puerta abierta *)
    reset : BOOL;         (* Señal de reset *)
END_VAR
VAR_OUTPUT
    aviso : BOOL;         (* Señal de aviso *)
    nAperturas : INT;     (* Número de aperturas *)
END_VAR
VAR
    puertaAbiertaAnt : BOOL; (* Estado anterior de la puerta *)
END_VAR

(* Si se activa el reset, reiniciar el contador y desactivar el aviso *)
IF reset THEN
    nAperturas := 0;
    aviso := FALSE;
ELSE
    (* Detectar transición de FALSE a TRUE en puertaAbierta *)
    IF NOT puertaAbiertaAnt AND puertaAbierta THEN
        nAperturas := nAperturas + 1;
    END_IF;
    
    (* Activar aviso si el número de aperturas es 5 o más *)
    IF nAperturas >= 5 THEN
        aviso := TRUE;
    ELSE
        aviso := FALSE;
    END_IF;
END_IF;

(* Actualizar el estado anterior de la puerta *)
puertaAbiertaAnt := puertaAbierta;
END_FUNCTION_BLOCK
```