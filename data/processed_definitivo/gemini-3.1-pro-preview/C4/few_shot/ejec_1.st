FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; (* Señal de peticion de arranque del sistema *)
    falla1 : BOOL;  (* Señal de falla de la bomba 1 *)
    falla2 : BOOL;  (* Señal de falla de la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;   (* Comando de activacion para la bomba 1 *)
    bomba2 : BOOL;   (* Comando de activacion para la bomba 2 *)
    almFalla : BOOL; (* Alarma de falla en la bomba titular del turno *)
END_VAR
VAR
    turno : BOOL;    (* Bandera para alternar el turno (TRUE = Bomba 1, FALSE = Bomba 2) *)
    fDem : R_TRIG;   (* Detector de flanco de subida para la señal de demanda *)
END_VAR

(* Deteccion del flanco de subida de la señal de demanda *)
fDem(CLK := demanda);

(* Alternancia de turno con cada nueva demanda para equilibrar el desgaste *)
IF fDem.Q THEN
    turno := NOT turno;
END_IF

(* Logica de control de bombas mientras exista demanda *)
IF demanda THEN
    IF turno THEN
        (* Turno de la bomba 1 como principal *)
        bomba1 := NOT falla1;            (* Enciende bomba 1 si no tiene falla *)
        bomba2 := falla1 AND NOT falla2; (* Respaldo: enciende bomba 2 si la 1 falla y la 2 esta disponible *)
        almFalla := falla1;              (* Activa alarma si la bomba titular (1) falla *)
    ELSE
        (* Turno de la bomba 2 como principal *)
        bomba2 := NOT falla2;            (* Enciende bomba 2 si no tiene falla *)
        bomba1 := falla2 AND NOT falla1; (* Respaldo: enciende bomba 1 si la 2 falla y la 1 esta disponible *)
        almFalla := falla2;              (* Activa alarma si la bomba titular (2) falla *)
    END_IF
ELSE
    (* Apagado general del sistema cuando no hay demanda *)
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK