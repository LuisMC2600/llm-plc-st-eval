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

// Configuración de los temporizadores
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
            kM := TRUE;
            kY := TRUE;
            timerEstrella(IN := TRUE);
            estado := 1;
        
        1: // Esperando el tiempo de estrella
            IF timerEstrella.Q THEN
                kY := FALSE;
                timerEstrella(IN := FALSE);
                timerMuerto(IN := TRUE);
                estado := 2;
            END_IF
        
        2: // Tiempo muerto entre estrella y triángulo
            IF timerMuerto.Q THEN
                kD := TRUE;
                timerMuerto(IN := FALSE);
                estado := 3;
            END_IF
        
        3: // Modo triángulo
            // Mantenerse en este estado hasta que se presione el botón de paro
            // No se requiere acción adicional
    END_CASE
ELSE
    // Si no se presiona ningún botón, asegurar que los contactores estén desactivados
    kM := FALSE;
    kY := FALSE;
    kD := FALSE;
    estado := 0;
END_IF
END_FUNCTION_BLOCK
```