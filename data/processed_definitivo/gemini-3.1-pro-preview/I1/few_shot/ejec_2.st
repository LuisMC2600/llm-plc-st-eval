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
    estado : INT := 0; (* 0: Intermitente, 1: Verde, 2: Amarillo, 3: Rojo *)
    tSecuencia : TON;  (* Temporizador para la secuencia normal *)
    tBlink1 : TON;     (* Temporizador 1 para parpadeo (tiempo encendido) *)
    tBlink2 : TON;     (* Temporizador 2 para parpadeo (tiempo apagado) *)
    tiempoActual : TIME;
    transicion : BOOL;
END_VAR

(* Control de estado principal *)
IF NOT habilitado THEN
    estado := 0;
ELSIF estado = 0 THEN
    estado := 1; (* Reinicia en verde al habilitarse *)
END_IF;

(* Asignacion de tiempos y luces segun el estado *)
CASE estado OF
    0: (* Amarillo intermitente *)
        luzV := FALSE;
        luzA := NOT tBlink1.Q;
        luzR := FALSE;
    1: (* Verde *)
        tiempoActual := T#20S;
        luzV := TRUE;
        luzA := FALSE;
        luzR := FALSE;
    2: (* Amarillo *)
        tiempoActual := T#4S;
        luzV := FALSE;
        luzA := TRUE;
        luzR := FALSE;
    3: (* Rojo *)
        tiempoActual := T#15S;
        luzV := FALSE;
        luzA := FALSE;
        luzR := TRUE;
END_CASE;

(* Actualizacion de temporizadores *)
tSecuencia(IN := habilitado AND NOT transicion, PT := tiempoActual);
transicion := tSecuencia.Q;

tBlink1(IN := (estado = 0) AND NOT tBlink2.Q, PT := T#1S);
tBlink2(IN := tBlink1.Q, PT := T#1S);

(* Transiciones de la secuencia normal *)
IF transicion THEN
    CASE estado OF
        1: estado := 2;
        2: estado := 3;
        3: estado := 1;
    END_CASE;
END_IF;
END_FUNCTION_BLOCK