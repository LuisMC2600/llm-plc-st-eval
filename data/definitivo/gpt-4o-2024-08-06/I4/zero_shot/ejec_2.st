```pascal
FUNCTION_BLOCK FB_EstrellaTriangulo
VAR
    // Entradas
    btnMarcha : BOOL;
    btnParo : BOOL;
    
    // Salidas
    kM : BOOL := FALSE;
    kY : BOOL := FALSE;
    kD : BOOL := FALSE;
    
    // Variables internas
    estado : INT := 0;
    timerEstrella : TON; // Temporizador para el modo estrella
    timerMuerto : TON;   // Temporizador para el tiempo muerto
END_VAR

// Inicialización de los temporizadores
timerEstrella(IN := FALSE, PT := T#8S);
timerMuerto(IN := FALSE, PT := T#100MS);

// Lógica de control
IF btnParo THEN
    // Si se presiona el botón de paro, desactivar todos los contactores
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := 0;
ELSIF btnMarcha THEN
    CASE estado OF
        0: // Estado inicial
            kM := TRUE; // Activar contactor principal
            kY := TRUE; // Activar contactor estrella
            timerEstrella(IN := TRUE); // Iniciar temporizador estrella
            estado := 1;
        
        1: // Esperando que termine el temporizador estrella
            IF timerEstrella.Q THEN
                kY := FALSE; // Desactivar contactor estrella
                timerEstrella(IN := FALSE); // Reiniciar temporizador estrella
                timerMuerto(IN := TRUE); // Iniciar temporizador muerto
                estado := 2;
            END_IF
        
        2: // Esperando que termine el tiempo muerto
            IF timerMuerto.Q THEN
                kD := TRUE; // Activar contactor triángulo
                timerMuerto(IN := FALSE); // Reiniciar temporizador muerto
                estado := 3;
            END_IF
        
        3: // Estado final, contactor triángulo activado
            // Mantener el estado hasta que se presione btnParo
            // o se desactive btnMarcha
            IF NOT btnMarcha THEN
                kM := FALSE;
                kD := FALSE;
                estado := 0;
            END_IF
    END_CASE
ELSE
    // Si btnMarcha no está activo, asegurarse de que todo esté apagado
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := 0;
END_IF
END_FUNCTION_BLOCK
```