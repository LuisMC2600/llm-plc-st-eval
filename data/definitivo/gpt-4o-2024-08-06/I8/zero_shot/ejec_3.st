```pascal
FUNCTION_BLOCK FB_Compresor
VAR
    // Entradas
    pOilOk : BOOL;       // Presión de aceite correcta
    tempOk : BOOL;       // Temperatura correcta
    sinAlm : BOOL;       // Sin alarmas
    btnMarcha : BOOL;    // Botón de marcha
    btnParo : BOOL;      // Botón de paro

    // Salidas
    comp : BOOL;         // Estado del compresor
    causaBloqueo : INT;  // Causa de bloqueo

    // Variables internas
    pOilOkTimer : TON;   // Temporizador para presión de aceite
    marchaLatch : BOOL;  // Latch para mantener el compresor en marcha
END_VAR

// Inicialización del temporizador
pOilOkTimer(IN := pOilOk, PT := T#3S);

// Lógica de causa de bloqueo
IF NOT pOilOkTimer.Q THEN
    causaBloqueo := 1; // Falta presión de aceite
ELSIF NOT tempOk THEN
    causaBloqueo := 2; // Falta temperatura correcta
ELSIF NOT sinAlm THEN
    causaBloqueo := 3; // Hay alarmas activas
ELSE
    causaBloqueo := 0; // No hay bloqueos
END_IF;

// Lógica de arranque y paro del compresor
IF btnParo THEN
    marchaLatch := FALSE; // Parar el compresor
ELSIF btnMarcha AND NOT marchaLatch AND (causaBloqueo = 0) THEN
    marchaLatch := TRUE; // Arrancar el compresor
END_IF;

// Actualizar el estado del compresor
comp := marchaLatch AND (causaBloqueo = 0);
```

Este código define un bloque de función `FB_Compresor` que controla el arranque y paro de un compresor basado en los permisivos especificados. Utiliza un temporizador para verificar la presión de aceite durante 3 segundos continuos y establece la lógica de bloqueo y control del compresor.