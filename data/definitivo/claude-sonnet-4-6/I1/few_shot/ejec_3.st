```pascal
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
    estado     : INT;  (* Estado de la secuencia: 0=verde, 1=amarillo, 2=rojo *)
    tFase      : TON; (* Temporizador de cada fase normal *)
    tBlink     : TP;  (* Temporizador de pulso para amarillo intermitente *)
    bBlinkTrig : BOOL; (* Flanco para relanzar el pulso intermitente *)
END_VAR

IF habilitado THEN
    (* --- Secuencia normal: verde -> amarillo -> rojo -> verde --- *)

    CASE estado OF

        0: (* VERDE 20 s *)
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;
            tFase(IN := TRUE, PT := T#20S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#20S); (* Resetea temporizador *)
                estado := 1;
            END_IF;

        1: (* AMARILLO 4 s *)
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;
            tFase(IN := TRUE, PT := T#4S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#4S);
                estado := 2;
            END_IF;

        2: (* ROJO 15 s *)
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;
            tFase(IN := TRUE, PT := T#15S);
            IF tFase.Q THEN
                tFase(IN := FALSE, PT := T#15S);
                estado := 0; (* Reinicia ciclo *)
            END_IF;

        ELSE
            estado := 0; (* Estado invalido: vuelve a verde *)

    END_CASE;

    (* Asegura que el temporizador de blink quede inactivo *)
    bBlinkTrig := FALSE;
    tBlink(IN := FALSE, PT := T#1S);

ELSE
    (* --- Modo inhabilitado: amarillo intermitente 1 s ON / 1 s OFF --- *)
    luzV := FALSE;
    luzR := FALSE;

    (* Relanza el pulso cada vez que expira *)
    tBlink(IN := bBlinkTrig, PT := T#1S);

    IF NOT tBlink.Q AND NOT bBlinkTrig THEN
        (* Pulso inactivo y no disparado: lanzar nuevo pulso *)
        bBlinkTrig := TRUE;
    END_IF;

    IF tBlink.Q THEN
        (* Pulso expirado: apagar disparo para permitir nuevo ciclo *)
        bBlinkTrig := FALSE;
    END_IF;

    luzA := tBlink.Q; (* Amarillo encendido durante el pulso activo *)

    (* Al rehabilitar, reinicia la secuencia en verde *)
    tFase(IN := FALSE, PT := T#20S);
    estado := 0;

END_IF;

END_FUNCTION_BLOCK
```