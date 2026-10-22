```iecst
FUNCTION_BLOCK FB_Puerta
VAR_INPUT
    puertaAbierta : BOOL; (* Señal de estado de la puerta de seguridad *)
    reset : BOOL;         (* Pone a cero el contador y apaga el aviso *)
END_VAR

VAR_OUTPUT
    aviso : BOOL;         (* TRUE si se acumulan 5 o más aperturas *)
    nAperturas : INT;     (* Número acumulado de aperturas *)
END_VAR

VAR
    flancoApertura : R_TRIG; (* Detector de flanco de subida estándar IEC *)
END_VAR

(* Detectar transición de FALSE a TRUE en la señal de la puerta *)
flancoApertura(CLK := puertaAbierta);

(* Lógica de reinicio o incremento del contador *)
IF reset THEN
    nAperturas := 0;
ELSIF flancoApertura.Q THEN
    nAperturas := nAperturas + 1;
END_IF;

(* Evaluación de la salida de aviso (se desactiva automáticamente al resetear nAperturas) *)
aviso := (nAperturas >= 5);

END_FUNCTION_BLOCK
```