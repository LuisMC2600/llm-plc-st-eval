```iecst
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Contacto NA que alimenta la entrada de conteo
    btnReset : BOOL;    // Contacto NA que alimenta el reset del contador
END_VAR

VAR_OUTPUT
    loteListo : BOOL;   // Bobina que indica si se alcanzó el valor preestablecido
    cuenta : INT;       // Valor actual del contador
END_VAR

VAR
    C1 : CTU;           // Instancia del contador ascendente estándar
END_VAR

// Rama 1: Llamada al contador ascendente con límite de 12
C1(CU := sensorPieza, RESET := btnReset, PV := 12);

// Rama 2: Activación de la bobina loteListo con la salida Q del contador
loteListo := C1.Q;

// Rama 3: Transferencia del valor actual del contador a la salida cuenta
cuenta := C1.CV;

END_FUNCTION_BLOCK
```