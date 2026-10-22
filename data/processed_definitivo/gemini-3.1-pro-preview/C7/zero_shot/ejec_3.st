FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Contacto normalmente abierto para conteo
    btnReset    : BOOL; // Contacto normalmente abierto para reinicio
END_VAR

VAR_OUTPUT
    loteListo   : BOOL; // Bobina que indica si el lote está completo
    cuenta      : INT;  // Valor actual del conteo
END_VAR

VAR
    C1          : CTU;  // Instancia del contador ascendente
END_VAR

// Rama 1: Actualización del contador ascendente con PV = 12
C1(
    CU := sensorPieza, 
    RESET := btnReset, 
    PV := 12
);

// Rama 2: La salida Q del contador activa la bobina loteListo
loteListo := C1.Q;

// Rama 3: Se transfiere el valor actual del contador a la variable cuenta
cuenta := C1.CV;

END_FUNCTION_BLOCK