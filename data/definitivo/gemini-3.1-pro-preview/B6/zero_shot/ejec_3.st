```iecst
FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL; // Condicion de activacion de la alarma
END_VAR
VAR_OUTPUT
    lampara : BOOL; // Salida hacia la baliza luminosa
END_VAR
VAR
    ton_Encendido : TON; // Temporizador para el tiempo en estado encendido
    ton_Apagado : TON;   // Temporizador para el tiempo en estado apagado
END_VAR

// Generador de ciclo: ton_Encendido se activa con la alarma y se reinicia con ton_Apagado
ton_Encendido(IN := alarma AND NOT ton_Apagado.Q, PT := T#1S);

// ton_Apagado comienza a contar cuando ton_Encendido alcanza 1 segundo
ton_Apagado(IN := ton_Encendido.Q, PT := T#1S);

// La lampara se enciende si hay alarma, y se apaga durante el ciclo de ton_Apagado
lampara := alarma AND NOT ton_Encendido.Q;

END_FUNCTION_BLOCK
```