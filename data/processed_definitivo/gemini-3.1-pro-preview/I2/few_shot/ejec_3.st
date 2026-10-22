FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    nivelAlto : BOOL; (* Sensor de nivel alto *)
    nivelBajo : BOOL; (* Sensor de nivel bajo *)
    btnInicio : BOOL; (* Boton de inicio del proceso *)
    btnParo : BOOL;   (* Boton de paro y reinicio *)
END_VAR
VAR_OUTPUT
    vLlenado : BOOL;    (* Valvula de llenado *)
    motorMezcla : BOOL; (* Motor de mezcla *)
    vDescarga : BOOL;   (* Valvula de descarga *)
END_VAR
VAR
    estado : INT := 0; (* 0: Reposo, 1: Llenado, 2: Mezcla, 3: Descarga *)
    tMezcla : TON;     (* Temporizador para el motor de mezcla *)
END_VAR

(* El boton de paro reinicia el proceso y lleva al estado de reposo *)
IF btnParo THEN
    estado := 0;
END_IF;

(* Maquina de estados del proceso *)
CASE estado OF
    0: (* Reposo *)
        IF btnInicio AND NOT btnParo THEN
            estado := 1;
        END_IF;
        
    1: (* Llenado *)
        IF nivelAlto THEN
            estado := 2;
        END_IF;
        
    2: (* Mezcla *)
        IF tMezcla.Q THEN
            estado := 3;
        END_IF;
        
    3: (* Descarga *)
        IF nivelBajo THEN
            estado := 0;
        END_IF;
END_CASE;

(* Temporizador de 60 segundos activo solo en el estado de mezcla *)
tMezcla(IN := (estado = 2), PT := T#60S);

(* Activacion de salidas segun el estado actual (estado seguro en reposo) *)
vLlenado := (estado = 1);
motorMezcla := (estado = 2);
vDescarga := (estado = 3);
END_FUNCTION_BLOCK