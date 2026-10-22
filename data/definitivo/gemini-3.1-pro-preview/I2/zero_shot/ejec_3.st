```iecst
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

// Lógica de transición de estados y paro
IF btnParo THEN
    estado := 0; // El paro fuerza el estado de reposo
ELSE
    CASE estado OF
        0: // Etapa de Reposo
            IF btnInicio THEN
                estado := 1;
            END_IF;
            
        1: // Etapa de Llenado
            IF nivelAlto THEN
                estado := 2;
            END_IF;
            
        2: // Etapa de Mezcla
            IF tonMezcla.Q THEN
                estado := 3;
            END_IF;
            
        3: // Etapa de Descarga
            IF nivelBajo THEN
                estado := 0;
            END_IF;
    END_CASE;
END_IF;

// Control del temporizador (se activa solo en el estado 2)
tonMezcla(IN := (estado = 2), PT := T#60S);

// Control de salidas (al estar en estado 0 por btnParo, todas son FALSE)
vLlenado := (estado = 1);
motorMezcla := (estado = 2);
vDescarga := (estado = 3);

END_FUNCTION_BLOCK
```