```iecst
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Señal para incrementar el contador
    btnReset : BOOL;    // Señal para reiniciar el contador
END_VAR

VAR_OUTPUT
    loteListo : BOOL;   // Se activa al alcanzar el valor preestablecido
    cuenta : INT;       // Valor actual del conteo
END_VAR

VAR
    C1 : CTU;           // Instancia del contador ascendente
END_VAR

// Rama 1: Actualización del contador ascendente con PV = 12
C1(CU := sensorPieza, RESET := btnReset, PV := 12);

// Rama 2: La salida Q del contador activa la bobina loteListo
loteListo := C1.Q;

// Rama 3: Se transfiere el valor actual del contador a la salida cuenta
cuenta := C1.CV;

END_FUNCTION_BLOCK
```