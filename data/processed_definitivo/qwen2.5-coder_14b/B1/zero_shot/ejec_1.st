FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL;  // Botón de marcha
    btnParo : BOOL;    // Botón de paro
    btnEmerg : BOOL;   // Botón de paro de emergencia
END_VAR

VAR_OUTPUT
    motorOn : BOOL;    // Estado del motor (encendido/apagado)
END_VAR

VAR
    emergenciaActiva : BOOL := FALSE;  // Bandera para indicar si hay una parada de emergencia
END_VAR

// Programa principal
IF btnEmerg THEN
    // Si se activa el botón de emergencia, detener el motor y activar la bandera de emergencia
    motorOn := FALSE;
    emergenciaActiva := TRUE;
ELSIF emergenciaActiva THEN
    // Si hay una parada de emergencia activa, mantener el motor apagado
    motorOn := FALSE;
ELSIF btnParo THEN
    // Si se presiona el botón de paro, detener el motor
    motorOn := FALSE;
ELSIF btnMarcha THEN
    // Si se presiona el botón de marcha, encender el motor
    motorOn := TRUE;
END_IF;