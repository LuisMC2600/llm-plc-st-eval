### Descripción del Bloque de Función

El bloque de función `FB_D` implementa un sistema de control de alternancia y respaldo automático (configuración *duty/standby*) para un sistema de dos bombas. Su función principal es alternar la bomba de trabajo cada vez que se recibe una nueva señal de demanda, lo que garantiza un desgaste mecánico uniforme entre ambos equipos a lo largo del tiempo. Además, incorpora una lógica de redundancia o "relevo" por falla: si la bomba a la que le corresponde operar presenta una avería, el sistema arranca automáticamente la bomba de respaldo (siempre y cuando esta no esté fallada también) y emite una señal de alarma. Esta lógica es ideal para aplicaciones industriales y comerciales de alta disponibilidad, tales como estaciones de bombeo de agua potable, cárcamos de rebombeo o achique, y circuitos de recirculación de agua helada o caliente en sistemas HVAC.

---

### Código Estructurado (Structured Text) Comentado

```iecst
(* Bloque de función para alternancia y respaldo de 2 bombas *)
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; // Señal de petición de arranque del sistema
    falla1  : BOOL; // Señal de avería/falla de la bomba 1
    falla2  : BOOL; // Señal de avería/falla de la bomba 2
END_VAR
VAR_OUTPUT
    bomba1   : BOOL; // Comando de arranque para la bomba 1
    bomba2   : BOOL; // Comando de arranque para la bomba 2
    almFalla : BOOL; // Alarma activa si la bomba en turno presenta falla
END_VAR
VAR
    turno : BOOL;   // Memoria para alternar el turno (FALSE = Bomba 2, TRUE = Bomba 1)
    fDem  : R_TRIG; // Detector de flanco de subida para la señal de demanda
END_VAR

// 1. Detección de nueva demanda para la alternancia
fDem(CLK := demanda); // Evalúa si la demanda pasó de FALSE a TRUE

// 2. Lógica de alternancia de turno
IF fDem.Q THEN
    turno := NOT turno; // Invierte el turno cada vez que inicia una nueva demanda
END_IF

// 3. Lógica de control de operación y respaldo
IF demanda THEN
    
    IF turno THEN
        // --- TURNO DE LA BOMBA 1 ---
        // La bomba 1 arranca si no tiene falla
        bomba1 := NOT falla1;
        // La bomba 2 entra como respaldo si la bomba 1 falla (y la 2 está sana)
        bomba2 := falla1 AND NOT falla2;
        // Se activa la alarma si la bomba titular (bomba 1) falló
        almFalla := falla1;
        
    ELSE
        // --- TURNO DE LA BOMBA 2 ---
        // La bomba 2 arranca si no tiene falla
        bomba2 := NOT falla2;
        // La bomba 1 entra como respaldo si la bomba 2 falla (y la 1 está sana)
        bomba1 := falla2 AND NOT falla1;
        // Se activa la alarma si la bomba titular (bomba 2) falló
        almFalla := falla2;
    END_IF
    
ELSE
    // 4. Condición de reposo (Sin demanda)
    // Se apagan ambas bombas y se limpia la alarma de falla de turno
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF

END_FUNCTION_BLOCK
```