FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; (* Señal para habilitar la secuencia normal *)
END_VAR

VAR_OUTPUT
    luzV : BOOL; (* Luz Verde *)
    luzA : BOOL; (* Luz Amarilla *)
    luzR : BOOL; (* Luz Roja *)
END_VAR

VAR
    estado : INT := 0; (* 0: Intermitente, 1: Verde, 2: Amarillo, 3: Rojo *)
    timerSecuencia : TON; (* Temporizador para la secuencia normal *)
    timerIntermitente : TON; (* Temporizador para el parpadeo *)
    estadoBlink : BOOL := FALSE; (* Estado auxiliar para la luz intermitente *)
    flancoHabilitado : R_TRIG; (* Detector de flanco de subida *)
END_VAR

(* Detectar cuando se activa la entrada para reiniciar la secuencia en verde *)
flancoHabilitado(CLK := habilitado);
IF flancoHabilitado.Q THEN
    estado := 1;
    timerSecuencia(IN := FALSE); (* Reset del temporizador principal *)
ELSIF NOT habilitado THEN
    estado := 0; (* Si se deshabilita, pasa a modo intermitente *)
END_IF;

(* Máquina de estados del semáforo *)
CASE estado OF
    0: (* Modo Deshabilitado: Amarillo intermitente *)
        luzV := FALSE;
        luzR := FALSE;
        timerSecuencia(IN := FALSE); (* Mantener apagado el timer principal *)
        
        (* Generador de pulsos: 1s encendido, 1s apagado *)
        timerIntermitente(IN := NOT timerIntermitente.Q, PT := T#1S);
        IF timerIntermitente.Q THEN
            estadoBlink := NOT estadoBlink;
        END_IF;
        luzA := estadoBlink;

    1: (* Modo Normal: Verde (20 segundos) *)
        luzV := TRUE;
        luzA := FALSE;
        luzR := FALSE;
        timerIntermitente(IN := FALSE); (* Reset del timer intermitente *)
        
        timerSecuencia(IN := TRUE, PT := T#20S);
        IF timerSecuencia.Q THEN
            estado := 2;
            timerSecuencia(IN := FALSE);
        END_IF;

    2: (* Modo Normal: Amarillo (4 segundos) *)
        luzV := FALSE;
        luzA := TRUE;
        luzR := FALSE;
        
        timerSecuencia(IN := TRUE, PT := T#4S);
        IF timerSecuencia.Q THEN
            estado := 3;
            timerSecuencia(IN := FALSE);
        END_IF;

    3: (* Modo Normal: Rojo (15 segundos) *)
        luzV := FALSE;
        luzA := FALSE;
        luzR := TRUE;
        
        timerSecuencia(IN := TRUE, PT := T#15S);
        IF timerSecuencia.Q THEN
            estado := 1;
            timerSecuencia(IN := FALSE);
        END_IF;
END_CASE;
END_FUNCTION_BLOCK