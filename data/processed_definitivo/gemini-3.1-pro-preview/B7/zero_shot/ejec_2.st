FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL;  // TRUE = Modo Automático, FALSE = Modo Manual
    btnManual : BOOL; // Comando directo de la bomba en modo manual
    nivelBajo : BOOL; // Condición para encender la bomba en modo automático
END_VAR

(* 
   Al ser una lógica puramente combinacional sin memoria entre ciclos, 
   una FUNCTION es la POU más adecuada. El estado de la bomba se 
   asigna directamente al valor de retorno de la función (SelBomba).
*)

SelBomba := (modoAuto AND nivelBajo) OR (NOT modoAuto AND btnManual);

END_FUNCTION