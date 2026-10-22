```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Contacto normalmente abierto sensor de pieza
    btnReset : BOOL;    // Contacto normalmente abierto botón de reset
END_VAR

VAR_OUTPUT
    loteListo : BOOL; // Bobina que indica que el lote está listo
    cuenta : INT;      // Variable que almacena el valor actual del contador
END_VAR

VAR
    C1 : CTU;          // Contador ascendente
END_VAR

// Configuración del contador C1
C1.PV := 12;          // Valor preestablecido del contador

// Rama 1: Conteo de piezas
C1(CU := sensorPieza, RESET := btnReset);

// Rama 2: Indicación de lote listo
loteListo := C1.Q;

// Rama 3: Transferencia del valor actual del contador a la variable cuenta
cuenta := C1.CV;
END_FUNCTION_BLOCK
```

Este código en Structured Text (ST) implementa el comportamiento descrito en el Ladder Diagram, utilizando un FUNCTION_BLOCK llamado `FB_Contador` con las variables de entrada y salida especificadas. El contador ascendente `C1` se configura con un valor preestablecido de 12, y las ramas del programa se implementan según la descripción proporcionada.