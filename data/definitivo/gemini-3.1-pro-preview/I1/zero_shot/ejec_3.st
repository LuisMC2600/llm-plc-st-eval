```iecst
FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL;
END_VAR
VAR_OUTPUT
    luzV : BOOL;
    luzA : BOOL;
    luzR : BOOL;
END_VAR
VAR
    estado : INT := 0; (* 0: Intermitente, 1: Verde, 2: Amarillo, 3: Rojo *)
    timerSecuencia : TON;
    timerParpadeo : TON;
    estadoParpadeo : BOOL;
    rTrigHabilitado : R_TRIG;
    tiempoFase : TIME;
END_VAR

(* Detectar flanco de subida para reiniciar la secuencia en verde *)
rTrigHabilitado(CLK := habilitado);
IF rTrigHabilitado.Q THEN
    estado := 1;
    estadoParpadeo := FALSE; (* Reiniciar estado del parpadeo *)
ELSIF NOT habilitado THEN
    estado := 0;
END_IF;

(* Asignar el tiempo correspondiente a la fase actual *)
CASE estado OF
    1: tiempoFase := T#20S;
    2: tiempoFase := T#4S;
    3: tiempoFase := T#15S;
END_CASE;

(* Temporizador principal de la secuencia (se auto-reinicia al terminar) *)
timerSecuencia(IN := habilitado AND NOT timerSecuencia.Q, PT := tiempoFase);

(* Cambio de estado al completarse el tiempo de la fase *)
IF timerSecuencia.Q THEN
    CASE estado OF
        1: estado := 2;
        2: estado := 3;
        3: estado := 1;
    END_CASE;
END_IF;

(* Temporizador para el parpadeo en modo deshabilitado (1s ON, 1s OFF) *)
timerParpadeo(IN := NOT habilitado AND NOT timerParpadeo.Q, PT := T#1S);
IF timerParpadeo.Q THEN
    estadoParpadeo := NOT estadoParpadeo;
END_IF;

(* Control de las salidas físicas según el estado activo *)
CASE estado OF
    0: (* Deshabilitado: Amarillo intermitente, demás apagadas *)
        luzV := FALSE;
        luzA := estadoParpadeo;
        luzR := FALSE;
    1: (* Secuencia: Verde *)
        luzV := TRUE;
        luzA := FALSE;
        luzR := FALSE;
    2: (* Secuencia: Amarillo *)
        luzV := FALSE;
        luzA := TRUE;
        luzR := FALSE;
    3: (* Secuencia: Rojo *)
        luzV := FALSE;
        luzA := FALSE;
        luzR := TRUE;
END_CASE;

END_FUNCTION_BLOCK
```