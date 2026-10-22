 := confirmarForzado);

        (* Control de actuadores segun el modo activo *)
        CASE modoActivo OF
            0: (* Modo Automatico *)
                FOR i := 0 TO 7 DO
                    actuador[i] := cmdAuto[i];
                END_FOR;

            1: (* Modo Manual *)
                FOR i := 0 TO 7 DO
                    actuador[i] := cmdManual[