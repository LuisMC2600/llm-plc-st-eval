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
    causaBloqueo : INT;  // Código del permisivo faltante (0=Ninguno, 1=Aceite, 2=Temp, 3=Alarma)
END_VAR

VAR
    timerOil   : TON;    // Temporizador para validar la presión de aceite
    edgeMarcha : R_TRIG; // Detector de flanco de subida para el botón de marcha
    permisivos : BOOL;   // Bandera interna de todos los permisivos OK
END_VAR

// 1. Evaluación del tiempo de la presión de aceite (3 segundos continuos)
timerOil(IN := pOilOk, PT := T#3S);

// 2. Determinación de la causa de bloqueo (Prioridad al número menor)
IF NOT timerOil.Q THEN
    causaBloqueo := 1; // Falta presión de aceite o no ha transcurrido el tiempo
ELSIF NOT tempOk THEN
    causaBloqueo := 2; // Falta temperatura correcta
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; // Presencia de alarma
ELSE
    causaBloqueo := 0; // Todos los permisivos se cumplen
END_IF;

// 3. Consolidación de permisivos
permisivos := (causaBloqueo = 0);

// 4. Detección de la pulsación de marcha (transición FALSE a TRUE)
edgeMarcha(CLK := btnMarcha);

// 5. Lógica de arranque y paro del compresor
// El paro y la pérdida de permisivos tienen prioridad absoluta
IF btnParo OR NOT permisivos THEN
    comp := FALSE;
// Solo arranca con un nuevo flanco de subida si los permisivos están listos
ELSIF edgeMarcha.Q AND permisivos THEN
    comp := TRUE;
END_IF;

END_FUNCTION_BLOCK