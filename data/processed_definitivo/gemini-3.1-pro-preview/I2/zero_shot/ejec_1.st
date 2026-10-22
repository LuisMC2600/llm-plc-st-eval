FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    btnInicio : BOOL;
    btnParo : BOOL;
    nivelAlto : BOOL;
    nivelBajo : BOOL;
END_VAR

VAR_OUTPUT
    vLlenado : BOOL;
    motorMezcla : BOOL;
    vDescarga : BOOL;
END_VAR

VAR
    estado : INT := 0; // 0: Reposo, 1: Llenado, 2: Mezcla, 3: Descarga
    tonMezcla : TON;   // Temporizador para el motor de mezcla
END_VAR

// Lógica de paro prioritario: detiene el proceso y regresa a reposo
IF btnParo THEN
    estado := 0;
END_IF;

// Instancia del temporizador: se activa solo en el estado 2 (Mezcla)
tonMezcla(IN := (estado = 2), PT := T#60S);

// Máquina de estados del proceso
CASE estado OF
    0: // Reposo: Salidas en estado seguro (desactivadas)
        vLlenado := FALSE;
        motorMezcla := FALSE;
        vDescarga := FALSE;
        
        IF btnInicio THEN
            estado := 1;
        END_IF;
        
    1: // Llenado: Abre válvula hasta detectar nivel alto
        vLlenado := TRUE;
        motorMezcla := FALSE;
        vDescarga := FALSE;
        
        IF nivelAlto THEN
            estado := 2;
        END_IF;
        
    2: // Mezcla: Enciende motor durante 60 segundos
        vLlenado := FALSE;
        motorMezcla := TRUE;
        vDescarga := FALSE;
        
        IF tonMezcla.Q THEN
            estado := 3;
        END_IF;
        
    3: // Descarga: Abre válvula hasta detectar nivel bajo
        vLlenado := FALSE;
        motorMezcla := FALSE;
        vDescarga := TRUE;
        
        IF nivelBajo THEN
            estado := 0;
        END_IF;
        
ELSE
    // Protección contra estados inválidos
    estado := 0;
END_CASE;

END_FUNCTION_BLOCK