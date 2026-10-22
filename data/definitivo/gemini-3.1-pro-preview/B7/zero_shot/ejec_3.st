```iecst
FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL;  // TRUE = Modo Automático, FALSE = Modo Manual
    btnManual : BOOL; // Comando de encendido en modo manual
    nivelBajo : BOOL; // Condición de encendido en modo automático
END_VAR

(* 
   Al no requerir memoria entre ciclos (lógica puramente combinacional), 
   una FUNCTION es la unidad de organización de programa (POU) más adecuada.
*)

IF modoAuto THEN
    // En modo automático, el estado depende de la señal de nivel bajo
    SelBomba := nivelBajo;
ELSE
    // En modo manual, el estado obedece directamente al botón
    SelBomba := btnManual;
END_IF;

// Nota: También se puede expresar como:
// SelBomba := (modoAuto AND nivelBajo) OR (NOT modoAuto AND btnManual);

END_FUNCTION
```