```iecst
FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL;  (* TRUE = Modo Automático, FALSE = Modo Manual *)
    btnManual : BOOL; (* Comando de encendido en modo manual *)
    nivelBajo : BOOL; (* Condición de encendido en modo automático *)
END_VAR

(* 
   Al ser una lógica puramente combinacional sin memoria entre ciclos, 
   el tipo de POU más adecuado es una FUNCTION. El resultado se 
   devuelve en el propio nombre de la función.
*)
SelBomba := (modoAuto AND nivelBajo) OR (NOT modoAuto AND btnManual);

END_FUNCTION
```