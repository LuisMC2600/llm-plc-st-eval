```iecst
FUNCTION_BLOCK FB_Compresor
VAR_INPUT
    pOilOk    : BOOL; // Presión de aceite correcta
    tempOk    : BOOL; // Temperatura correcta
    sinAlm    : BOOL; // Ausencia de alarmas
    btnMarcha : BOOL; // Botón de arranque
    btnParo   : BOOL; // Botón de detención
END_VAR

VAR_OUTPUT
    comp         : BOOL; // Comando de marcha del compresor
    causaBloqueo : INT;  // Indicador del permisivo faltante (0=OK, 1=Aceite, 2=Temp, 3=Alarma)
END_VAR

VAR
    tonOil      : TON;    // Temporizador para validar la presión de aceite
    rTrigMarcha : R_TRIG; // Detector de flanco de subida para el botón de marcha
    permisivos  : BOOL;   // Estado de todos los permisivos combinados
END_VAR

// 1. Evaluación del permisivo de aceite (3 segundos continuos)
tonOil(IN := pOilOk, PT := T#3S);

// 2. Detección de la pulsación de marcha (transición FALSE -> TRUE)
rTrigMarcha(CLK := btnMarcha);

// 3. Lógica de diagnóstico de bloqueo (prioridad al número menor)
IF NOT tonOil.Q THEN
    causaBloqueo := 1; // Falta presión de aceite (o no ha cumplido el tiempo)
ELSIF NOT tempOk THEN
    causaBloqueo := 2; // Falta temperatura correcta
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; // Alarma activa
ELSE
    causaBloqueo := 0; // Todos los permisivos se cumplen
END_IF;

// 4. Agrupación de permisivos
permisivos := (causaBloqueo = 0);

// 5. Lógica de control de marcha/paro del compresor
// El paro y la pérdida de permisivos tienen prioridad absoluta
IF btnParo OR NOT permisivos THEN
    comp := FALSE;
// Solo arranca con el flanco de subida si los permisivos están listos
ELSIF rTrigMarcha.Q AND permisivos THEN
    comp := TRUE;
END_IF;

END_FUNCTION_BLOCK
```