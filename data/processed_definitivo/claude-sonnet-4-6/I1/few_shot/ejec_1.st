FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; (* Habilitacion del semaforo *)
END_VAR
VAR_OUTPUT
    luzV : BOOL; (* Luz verde *)
    luzA : BOOL; (* Luz amarilla *)
    luzR : BOOL; (* Luz roja *)
END_VAR
VAR
    estado      : INT;  (* Estado de la secuencia: 0=Verde, 1=Amarillo, 2=Rojo *)
    tFase       : TON;  (* Temporizador de fase normal *)
    tParpadeo   : TP;   (* Temporizador de pulso para amarillo intermitente *)
    bParpadeoOn : BOOL; (* Bandera de ciclo de parpadeo activo *)
END_VAR

IF NOT habilitado THEN
    (* --- Modo inhabilitado: amarillo intermitente 1s ON / 1s OFF --- *)
    estado := 0;        (* Reinicio de estado para cuando se habilite de nuevo *)
    tFase(IN := FALSE, PT := T#20S); (* Resetea temporizador de fase *)

    (* Genera el parpadeo usando TP: cada vez que Q baja, relanza el pulso *)
    tParpadeo(IN := NOT tParpadeo.Q AND NOT bParpadeoOn, PT := T#1S);

    (* Alterna entre encendido y apagado cada segundo *)
    IF tParpadeo.Q THEN
        bParpadeoOn := NOT bParpadeoOn;
    END_IF;

    luzV := FALSE;
    luzA := bParpadeoOn; (* Amarillo parpadea *)
    luzR := FALSE;

ELSE
    (* --- Modo habilitado: secuencia Verde -> Amarillo -> Rojo --- *)
    tParpadeo(IN := FALSE, PT := T#1S); (* Resetea temporizador de parpadeo *)
    bParpadeoOn := FALSE;

    CASE estado OF

        0: (* Verde durante 20 segundos *)
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            tFase(IN := TRUE, PT := T#20S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#20S); (* Resetea temporizador *)
                estado := 1;
            END_IF;

        1: (* Amarillo durante 4 segundos *)
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            tFase(IN := TRUE, PT := T#4S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#4S); (* Resetea temporizador *)
                estado := 2;
            END_IF;

        2: (* Rojo durante 15 segundos *)
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            tFase(IN := TRUE, PT := T#15S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#15S); (* Resetea temporizador *)
                estado := 0; (* Reinicia la secuencia en verde *)
            END_IF;

        ELSE
            estado := 0; (* Estado invalido: vuelve a verde *)

    END_CASE;

END_IF;

END_FUNCTION_BLOCK