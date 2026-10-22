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
    estado : INT := 0; (* 0: Verde, 1: Amarillo, 2: Rojo *)
    tFase : TON; (* Temporizador para las fases del semaforo *)
    tParpadeo : TON; (* Temporizador para el parpadeo *)
    estadoBlink : BOOL := TRUE; (* Estado de la luz intermitente *)
END_VAR

IF habilitado THEN
    (* Secuencia normal del semaforo *)
    CASE estado OF
        0: tFase(IN := TRUE, PT := T#20S); (* Verde *)
        1: tFase(IN := TRUE, PT := T#4S);  (* Amarillo *)
        2: tFase(IN := TRUE, PT := T#15S); (* Rojo *)
    END_CASE;

    (* Cambio de fase al terminar el tiempo *)
    IF tFase.Q THEN
        estado := (estado + 1) MOD 3;
        tFase(IN := FALSE); (* Reiniciar temporizador para la siguiente fase *)
    END_IF;

    (* Asignacion de salidas *)
    luzV := (estado = 0);
    luzA := (estado = 1);
    luzR := (estado = 2);

    (* Reiniciar variables del modo intermitente *)
    tParpadeo(IN := FALSE);
    estadoBlink := TRUE;
ELSE
    (* Modo deshabilitado: Amarillo intermitente *)
    estado := 0; (* Preparar reinicio en verde *)
    tFase(IN := FALSE); (* Reiniciar temporizador de secuencia *)

    (* Generador de pulsos de 1 segundo *)
    tParpadeo(IN := TRUE, PT := T#1S);
    IF tParpadeo.Q THEN
        estadoBlink := NOT estadoBlink;
        tParpadeo(IN := FALSE); (* Reiniciar temporizador de parpadeo *)
    END_IF;

    (* Asignacion de salidas *)
    luzV := FALSE;
    luzR := FALSE;
    luzA := estadoBlink;
END_IF;
END_FUNCTION_BLOCK