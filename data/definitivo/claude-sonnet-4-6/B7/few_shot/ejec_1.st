```pascal
FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto  : BOOL; (* TRUE = modo automatico, FALSE = modo manual *)
    btnManual : BOOL; (* Boton de mando manual de la bomba *)
    nivelBajo : BOOL; (* Senal de nivel bajo del deposito *)
END_VAR

(* Sin memoria entre ciclos: el resultado depende solo de las entradas actuales *)
(* En modo automatico la bomba sigue a nivelBajo; en manual sigue a btnManual *)
SelBomba := (modoAuto AND nivelBajo) OR (NOT modoAuto AND btnManual);
END_FUNCTION
```