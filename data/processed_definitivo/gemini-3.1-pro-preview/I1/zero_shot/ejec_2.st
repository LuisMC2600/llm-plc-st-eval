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
    timerIntermitente : TON;
    trigHabilitado : R_TRIG;
    estadoAmarillo : BOOL;
    tiempoActual : TIME;
    resetTimer : BOOL;
END_VAR

(* Detectar flanco de subida para reiniciar la secuencia en verde *)
trigHabilitado(CLK := habilitado);
IF trigHabilitado.Q THEN
    estado := 1;
    resetTimer := TRUE;
    estadoAmarillo := FALSE; (* Reiniciar estado del intermitente *)
END_IF;

(* Si se desactiva la entrada, pasar a modo intermitente *)
IF NOT habilitado THEN
    estado := 0;
END_IF;

(* Lógica de salidas y selección de tiempos según el estado *)
CASE estado OF
    0: (* Modo deshabilitado: Amarillo intermitente (1s ON, 1s OFF) *)
        luzV := FALSE;
        luzR := FALSE;
        tiempoActual := T#0S;
        
        (* Temporizador para alternar la luz amarilla cada 1 segundo *)
        timerIntermitente(IN := NOT timerIntermitente.Q, PT := T#1S);
        IF timerIntermitente.Q THEN
            estadoAmarillo := NOT estadoAmarillo;
        END_IF;
        luzA := estadoAmarillo;

    1: (* Secuencia: Verde (20s) *)
        luzV := TRUE;
        luzA := FALSE;
        luzR := FALSE;
        tiempoActual := T#20S;

    2: (* Secuencia: Amarillo (4s) *)
        luzV := FALSE;
        luzA := TRUE;
        luzR := FALSE;
        tiempoActual := T#4S;

    3: (* Secuencia: Rojo (15s) *)
        luzV := FALSE;
        luzA := FALSE;
        luzR := TRUE;
        tiempoActual := T#15S;
END_CASE;

(* Ejecución del temporizador principal de la secuencia *)
timerSecuencia(IN := (estado > 0) AND NOT resetTimer, PT := tiempoActual);

(* Limpiar la señal de reset para que el temporizador inicie en el siguiente ciclo *)
IF resetTimer THEN
    resetTimer := FALSE;
END_IF;

(* Transición al siguiente estado cuando se cumple el tiempo *)
IF timerSecuencia.Q THEN
    resetTimer := TRUE; (* Forzar el reinicio del temporizador *)
    CASE estado OF
        1: estado := 2;
        2: estado := 3;
        3: estado := 1;
    END_CASE;
END_IF;

END_FUNCTION_BLOCK