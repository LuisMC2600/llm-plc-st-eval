```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Contacto normalmente abierto sensor de pieza
    btnReset : BOOL; // Contacto normalmente abierto botón de reset
END_VAR

VAR_OUTPUT
    loteListo : BOOL; // Bobina que indica que el lote está listo
    cuenta : INT; // Variable que almacena el valor actual del contador
END_VAR

VAR
    C1 : CTU; // Contador ascendente
END_VAR

// Configuración del contador ascendente
C1.PV := 12; // Valor preestablecido del contador

// Rama 1: Conteo de piezas
IF sensorPieza THEN
    C1.CU := TRUE; // Alimenta la entrada de conteo
ELSE
    C1.CU := FALSE;
END_IF;

// Rama 2: Reset del contador
IF btnReset THEN
    C1.RESET := TRUE; // Alimenta la entrada de reset
ELSE
    C1.RESET := FALSE;
END_IF;

// Rama 3: Transferencia del valor del contador a la variable cuenta
cuenta := C1.CV; // Transfiere el valor actual del contador a la variable cuenta

// Rama 4: Control de la bobina loteListo
IF C1.Q THEN
    loteListo := TRUE; // Activa la bobina si el contador alcanza el valor preestablecido
ELSE
    loteListo := FALSE;
END_IF;

END_FUNCTION_BLOCK
```