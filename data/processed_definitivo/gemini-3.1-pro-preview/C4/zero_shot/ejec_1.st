// Bloque de función para alternancia y respaldo de dos bombas
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; // Señal de petición de arranque del sistema (ej. presostato, nivel, etc.)
    falla1 : BOOL;  // Señal de falla de la bomba 1 (ej. guardamotor, térmico)
    falla2 : BOOL;  // Señal de falla de la bomba 2 (ej. guardamotor, térmico)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;   // Comando de arranque para la bomba 1
    bomba2 : BOOL;   // Comando de arranque para la bomba 2
    almFalla : BOOL; // Indicador de alarma (se activa si la bomba en turno falla)
END_VAR
VAR
    turno : BOOL;    // Memoria interna para alternar el turno (FALSE = Bomba 2, TRUE = Bomba 1)
    fDem : R_TRIG;   // Detector de flanco de subida para la señal de demanda
END_VAR

// 1. Detección del flanco de subida de la demanda
fDem(CLK := demanda);

// 2. Lógica de alternancia
// Cada vez que entra una nueva demanda, se invierte el turno para equilibrar el desgaste
IF fDem.Q THEN
    turno := NOT turno;
END_IF

// 3. Lógica de control de bombas y respaldo (Failover)
IF demanda THEN
    
    // Si hay demanda, evaluamos de quién es el turno
    IF turno THEN
        // TURNO DE LA BOMBA 1
        // La bomba 1 arranca si no tiene falla
        bomba1 := NOT falla1;
        // La bomba 2 entra al quite (respaldo) si la bomba 1 falla y la bomba 2 está sana
        bomba2 := falla1 AND NOT falla2;
        // Se activa la alarma si la bomba titular (bomba 1) presenta falla
        almFalla := falla1;
        
    ELSE
        // TURNO DE LA BOMBA 2
        // La bomba 2 arranca si no tiene falla
        bomba2 := NOT falla2;
        // La bomba 1 entra al quite (respaldo) si la bomba 2 falla y la bomba 1 está sana
        bomba1 := falla2 AND NOT falla1;
        // Se activa la alarma si la bomba titular (bomba 2) presenta falla
        almFalla := falla2;
    END_IF
    
ELSE
    // 4. Estado de reposo
    // Si no hay demanda, se apagan ambas bombas y se limpia la alarma de turno
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF

END_FUNCTION_BLOCK