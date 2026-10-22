FUNCTION_BLOCK SelBomba
VAR_INPUT
    modoAuto : BOOL; (* Modo automático *)
    btnManual : BOOL; (* Botón manual *)
    nivelBajo : BOOL; (* Nivel bajo *)
END_VAR
VAR_OUTPUT
    bomba : BOOL; (* Estado de la bomba *)
END_VAR

(* Selección de la fuente de mando *)
IF modoAuto THEN
    bomba := nivelBajo; (* En modo automático, la bomba está encendida si el nivel está bajo *)
ELSE
    bomba := btnManual; (* En modo manual, la bomba obedece al botón manual *)
END_IF
END_FUNCTION_BLOCK