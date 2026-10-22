```iecst
FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk    : BOOL; // Presión de aceite correcta
    tempOk    : BOOL; // Temperatura correcta
    sinAlm    : BOOL; // Ausencia de alarmas
    btnMarcha : BOOL; // Botón de arranque
    btnParo   : BOOL; // Botón de parada
END_VAR

VAR_OUTPUT
    comp         : BOOL; // Comando de arranque del compresor
    causaBloqueo : INT;  // Código del permisivo faltante (0=Ninguno, 1=Aceite, 2=Temp, 3=Alarma)
END_VAR

VAR
    tonOil     : TON;    // Temporizador para validar la presión de aceite
    trigMarcha : R_TRIG; // Detector de flanco de subida para el arranque
    permisivos : BOOL;   // Marca interna de todos los permisivos cumplidos
END_VAR

// 1. Temporizador: requiere 3 segundos continuos de pOilOk
tonOil(IN := pOilOk, PT := T#3S);

// 2. Lógica de diagnóstico de bloqueo (prioridad al número menor mediante IF-ELSIF)
IF NOT tonOil.Q THEN
    causaBloqueo := 1; // Falla 1: Presión de aceite no establecida
ELSIF NOT tempOk THEN
    causaBloqueo := 2; // Falla 2: Temperatura incorrecta
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; // Falla 3: Alarma activa
ELSE
    causaBloqueo := 0; // Sin fallas: Todos los permisivos OK
END_IF;

// 3. Evaluación global de permisivos
permisivos := (causaBloqueo = 0);

// 4. Detección de pulsación (transición FALSE a TRUE) del botón de marcha
trigMarcha(CLK := btnMarcha);

// 5. Lógica de control de marcha/paro del compresor
IF btnParo OR NOT permisivos THEN
    // El paro y la pérdida de permisivos tienen prioridad y detienen el equipo
    comp := FALSE;
ELSIF trigMarcha.Q AND permisivos THEN
    // Solo arranca con un nuevo flanco de subida si los permisivos están listos
    comp := TRUE;
END_IF;

END_FUNCTION_BLOCK
```