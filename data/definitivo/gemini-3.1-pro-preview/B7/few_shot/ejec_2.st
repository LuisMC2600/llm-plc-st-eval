FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL; (* Modo automatico activo *)
    btnManual : BOOL; (* Boton de mando manual *)
    nivelBajo : BOOL; (* Sensor de nivel bajo *)
END_VAR

(* Logica sin memoria: obedece al sensor en auto o al boton en manual *)
SelBomba := (modoAuto AND nivelBajo) OR (NOT modoAuto AND btnManual);
END_FUNCTION