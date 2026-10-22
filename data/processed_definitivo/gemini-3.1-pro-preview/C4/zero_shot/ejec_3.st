FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; // Señal de petición de arranque (ej. presostato, interruptor de nivel, comando remoto)
    falla1 : BOOL;  // Señal de falla térmica o eléctrica de la bomba 1 (TRUE = en falla)
    falla2 : BOOL;  // Señal de falla térmica o eléctrica de la bomba 2 (TRUE = en falla)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;   // Comando de salida para energizar el contactor/variador de la bomba 1
    bomba2 : BOOL;   // Comando de salida para energizar el contactor/variador de la bomba 2
    almFalla : BOOL; // Señal de alarma que indica que la bomba líder actual ha fallado
END_VAR
VAR
    turno : BOOL;    // Memoria interna para alternar el turno (TRUE = turno bomba 1, FALSE = turno bomba 2)
    fDem : R_TRIG;   // Instancia del bloque detector de flanco de subida (Rising Trigger)
END_VAR

// 1. Detección de flanco de subida en la señal de demanda
fDem(CLK := demanda);

// 2. Lógica de alternancia (Flip-Flop)
// Cada vez que entra una nueva demanda, se invierte el turno para equilibrar el desgaste
IF fDem.Q THEN
    turno := NOT turno;
END_IF

// 3. Lógica principal de control y respaldo (Failover)
IF demanda THEN
    // Si hay demanda activa, evaluamos a quién le toca operar
    IF turno THEN
        // --- TURNO DE LA BOMBA 1 COMO LÍDER ---
        // La bomba 1 arranca si no tiene falla
        bomba1 := NOT falla1;
        // Si la bomba 1 falla, la bomba 2 entra como respaldo (siempre y cuando la 2 no esté en falla)
        bomba2 := falla1 AND NOT falla2;
        // Se activa la alarma si la bomba líder de este turno (bomba 1) presenta falla
        almFalla := falla1;
    ELSE
        // --- TURNO DE LA BOMBA 2 COMO LÍDER ---
        // La bomba 2 arranca si no tiene falla
        bomba2 := NOT falla2;
        // Si la bomba 2 falla, la bomba 1 entra como respaldo (siempre y cuando la 1 no esté en falla)
        bomba1 := falla2 AND NOT falla1;
        // Se activa la alarma si la bomba líder de este turno (bomba 2) presenta falla
        almFalla := falla2;
    END_IF
ELSE
    // 4. Estado de reposo
    // Si no hay demanda, se apagan ambas bombas y se limpia la alarma de falla de turno
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK