FUNCTION SelBomba : BOOL
VAR_INPUT
    modoAuto : BOOL; (* Activa el modo automatico *)
    btnManual : BOOL; (* Boton de mando en modo manual *)
    nivelBajo : BOOL; (* Condicion de encendido en modo automatico *)
END_VAR

(* Estado de la bomba segun el modo seleccionado sin memoria *)
SelBomba := (modoAuto AND nivelBajo) OR (NOT modoAuto AND btnManual);
END_FUNCTION