FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; (* Habilita la secuencia normal del semaforo *)
END_VAR
VAR_OUTPUT
    luzV : BOOL; (* Luz verde *)
    luzA : BOOL; (* Luz amarilla *)
    luzR : BOOL; (* Luz roja *)
END_VAR
VAR
    estado     : INT;  (* Estado de la secuencia: 0=Verde, 1=Amarillo, 2=Rojo *)
    tFase      : TON; (* Temporizador de cada fase de la secuencia normal *)
    tBlink     : TP;  (* Temporizador de pulso para amarillo intermitente *)
    blink      : BOOL; (* Estado actual del parpadeo amarillo *)
    prevHab    : BOOL; (* Valor anterior de habilitado para detectar flancos *)
END_VAR

IF habilitado THEN
    (* --- Secuencia normal: Verde -> Amarillo -> Rojo -> (repite) --- *)

    (* Al detectar flanco ascendente de habilitado, reiniciar en verde *)
    IF NOT prevHab THEN
        estado := 0;
        tFase(IN := FALSE, PT := T#20S); (* Reset del temporizador *)
    END_IF;

    CASE estado OF

        0: (* VERDE: 20 segundos *)
            tFase(IN := TRUE, PT := T#20S);
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#20S); (* Reset *)
                estado := 1;
            END_IF;

        1: (* AMARILLO: 4 segundos *)
            tFase(IN := TRUE, PT := T#4S);
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#4S); (* Reset *)
                estado := 2;
            END_IF;

        2: (* ROJO: 15 segundos *)
            tFase(IN := TRUE, PT := T#15S);
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#15S); (* Reset *)
                estado := 0; (* Reinicia ciclo en verde *)
            END_IF;

        ELSE
            estado := 0; (* Estado invalido: volver a verde *)

    END_CASE;

    (* Asegurar que el temporizador de parpadeo quede inactivo *)
    tBlink(IN := FALSE, PT := T#1S);
    blink := FALSE;

ELSE
    (* --- Modo inhabilitado: amarillo intermitente 1s ON / 1s OFF --- *)

    (* Apagar verde y rojo *)
    luzV := FALSE;
    luzR := FALSE;

    (* Asegurar que el temporizador de secuencia quede inactivo *)
    tFase(IN := FALSE, PT := T#20S);

    (* Generar pulso de 1 segundo repetitivo para el parpadeo *)
    tBlink(IN := NOT tBlink.Q, PT := T#1S);

    (* El pulso activo indica amarillo encendido *)
    luzA := tBlink.Q;

END_IF;

(* Guardar estado actual de habilitado para deteccion de flanco en proximo ciclo *)
prevHab := habilitado;

END_FUNCTION_BLOCK