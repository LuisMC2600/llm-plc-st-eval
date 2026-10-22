```iecst
FUNCTION_BLOCK FB_Llenado
VAR_INPUT
    btnInicio : BOOL;   // Botón para iniciar el proceso
    btnParo : BOOL;     // Botón para detener el proceso y llevar a estado seguro
    nivelAlto : BOOL;   // Sensor de nivel alto
    nivelBajo : BOOL;   // Sensor de nivel bajo
END_VAR

VAR_OUTPUT
    vLlenado : BOOL;    // Válvula de llenado
    motorMezcla : BOOL; // Motor del mezclador
    vDescarga : BOOL;   // Válvula de descarga
END_VAR

VAR
    estado : INT := 0;  // Máquina de estados (0:Reposo, 1:Llenado, 2:Mezcla, 3:Descarga)
    timerMezcla : TON;  // Temporizador para la etapa de mezcla
END_VAR

// 1. Condición de paro prioritario
IF btnParo THEN
    estado := 0;
END_IF;

// 2. Máquina de estados secuencial
CASE estado OF
    0: // Etapa 0: Reposo
        IF btnInicio AND NOT btnParo THEN
            estado := 1;
        END_IF;
        
    1: // Etapa 1: Llenado
        IF nivelAlto THEN
            estado := 2;
        END_IF;
        
    2: // Etapa 2: Mezcla
        IF timerMezcla.Q THEN
            estado := 3;
        END_IF;
        
    3: // Etapa 3: Descarga
        IF nivelBajo THEN
            estado := 0;
        END_IF;
ELSE
    // Protección contra estados inválidos
    estado := 0; 
END_CASE;

// 3. Control de salidas (Garantiza estado seguro si no es su etapa activa)
vLlenado := (estado = 1);
motorMezcla := (estado = 2);
vDescarga := (estado = 3);

// 4. Actualización del temporizador (Se activa únicamente en la etapa 2)
timerMezcla(IN := (estado = 2), PT := T#60S);

END_FUNCTION_BLOCK
```