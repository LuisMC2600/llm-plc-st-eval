```pascal
FUNCTION_BLOCK FB_Baliza
VAR_INPUT
    alarma : BOOL;  // Variable de entrada que indica si hay una alarma
END_VAR

VAR_OUTPUT
    lampara : BOOL;  // Variable de salida que controla el estado de la lámpara
END_VAR

VAR
    timer : TON;  // Timer de conteo hacia arriba
    estado : BOOL;  // Variable para controlar el estado de parpadeo
END_VAR

// Inicialización del timer
IF timer.Q = FALSE THEN
    timer(IN := TRUE, PT := T#1S);
END_IF;

// Logica de parpadeo
IF alarma THEN
    lampara := estado;
    IF timer.Q THEN
        estado := NOT estado;  // Cambia el estado de la lámpara
        timer(IN := FALSE);  // Reinicia el timer
        timer(IN := TRUE);  // Reinicia el timer
    END_IF;
ELSE
    lampara := FALSE;  // Apaga la lámpara si no hay alarma
END_IF;
```

Este código implementa una baliza de alarma utilizando un FUNCTION_BLOCK en Structured Text (ST) conforme al estándar IEC 61131-3. La lámpara parpadea con un ciclo de 1 segundo encendida y 1 segundo apagada mientras la condición de alarma esté activa. Sin alarma, la lámpara permanece apagada.