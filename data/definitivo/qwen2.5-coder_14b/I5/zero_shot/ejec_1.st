```pascal
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; // Sensor de presencia de pieza
    sensorAltura : BOOL;    // Sensor de altura de pieza
END_VAR

VAR_OUTPUT
    banda : BOOL;          // Salida para activar la banda
    piston : BOOL;         // Salida para activar el pistón
END_VAR

VAR
    nAltas : INT := 0;      // Contador de piezas altas
    nBajas : INT := 0;      // Contador de piezas bajas
    timer1 : TON;           // Timer para el tiempo de espera (2s)
    timer2 : TON;           // Timer para el tiempo de activación del pistón (1s)
    estado : INT := 0;      // Estado de la máquina de estados
END_VAR

// Máquina de estados
CASE estado OF
    0: // Estado inicial
        banda := TRUE; // La banda funciona continuamente
        IF sensorPresencia THEN
            estado := 1; // Detectada pieza, iniciar temporizador
            timer1(IN := TRUE, PT := T#2S); // Iniciar temporizador de 2s
        END_IF

    1: // Esperando que la pieza llegue al desviador
        IF timer1.Q THEN
            IF sensorAltura THEN
                estado := 2; // Pieza alta, activar pistón
                timer2(IN := TRUE, PT := T#1S); // Iniciar temporizador de 1s
                nAltas := nAltas + 1; // Incrementar contador de piezas altas
            ELSE
                estado := 0; // Pieza baja, continuar
                nBajas := nBajas + 1; // Incrementar contador de piezas bajas
            END_IF
        END_IF

    2: // Activando el pistón
        piston := TRUE;
        IF timer2.Q THEN
            piston := FALSE; // Desactivar pistón
            estado := 0; // Volver al estado inicial
        END_IF

    ELSE
        estado := 0; // Estado desconocido, volver al inicial
END_CASE
```