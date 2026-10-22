```pascal
FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL;   (* Modo automático *)
    btnManual : BOOL;  (* Botón manual *)
    nivelBajo : BOOL;  (* Sensor de nivel bajo *)
END_VAR

(* Selección de la fuente de mando de la bomba *)
IF modoAuto THEN
    (* Modo automático: la bomba enciende si el nivel es bajo *)
    SelBomba := nivelBajo;
ELSE
    (* Modo manual: la bomba sigue el estado del botón manual *)
    SelBomba := btnManual;
END_IF;
END_FUNCTION
```