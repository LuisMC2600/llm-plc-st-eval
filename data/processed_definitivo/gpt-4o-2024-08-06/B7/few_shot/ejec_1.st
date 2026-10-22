FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL;   (* Modo automático *)
    btnManual : BOOL;  (* Botón manual *)
    nivelBajo : BOOL;  (* Sensor de nivel bajo *)
END_VAR

(* Selección de la fuente de mando de la bomba *)
(* En modo automático, la bomba enciende si nivelBajo está activo *)
(* En modo manual, la bomba sigue el estado del botón manual *)
SelBomba := (modoAuto AND nivelBajo) OR (NOT modoAuto AND btnManual);
END_FUNCTION