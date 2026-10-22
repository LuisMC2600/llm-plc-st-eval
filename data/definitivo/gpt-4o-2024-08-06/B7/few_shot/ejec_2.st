```pascal
FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL;    (* Modo automático *)
    btnManual : BOOL;   (* Botón manual *)
    nivelBajo : BOOL;   (* Sensor de nivel bajo *)
END_VAR

(* Selección de la fuente de mando de la bomba *)
IF modoAuto THEN
    SelBomba := nivelBajo; (* En modo automático, la bomba sigue el sensor de nivel bajo *)
ELSE
    SelBomba := btnManual; (* En modo manual, la bomba sigue el botón manual *)
END_IF;
END_FUNCTION
```