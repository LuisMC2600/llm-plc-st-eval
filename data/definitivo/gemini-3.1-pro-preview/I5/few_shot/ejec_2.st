FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Detecta el paso de una pieza *)
    sensorAltura : BOOL;    (* Detecta si la pieza es alta *)
END_VAR
VAR_OUTPUT
    banda : BOOL;           (* Salida de la banda transportadora *)
    piston : BOOL;          (* Salida del piston desviador *)
    nAltas : INT;           (* Contador de piezas altas *)
    nBajas : INT;           (* Contador de piezas bajas *)
END_VAR
VAR
    flancoPresencia : R_TRIG; (* Detector de flanco para nueva pieza *)
    tpRetardo : TP;           (* Temporizador para el retardo de llegada (2s) *)
    finRetardo : F_TRIG;      (* Detector de fin del retardo *)
    tpPiston : TP;            (* Temporizador para la activacion del piston (1s) *)
    pulsoAlta : BOOL;         (* Marca interna para iniciar el retardo *)
END_VAR

(* La banda funciona continuamente *)
banda := TRUE;

(* Deteccion del paso de una nueva pieza *)
flancoPresencia(CLK := sensorPresencia);

pulsoAlta := FALSE;

(* Clasificacion y conteo al detectar la pieza *)
IF flancoPresencia.Q THEN
    IF sensorAltura THEN
        nAltas := nAltas + 1;
        pulsoAlta := TRUE; (* Inicia la secuencia de desvio *)
    ELSE
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* Genera un pulso de 2 segundos como retardo de llegada al desviador *)
tpRetardo(IN := pulsoAlta, PT := T#2S);

(* Detecta cuando terminan los 2 segundos de retardo *)
finRetardo(CLK := tpRetardo.Q);

(* Activa el piston durante 1 segundo justo al terminar el retardo *)
tpPiston(IN := finRetardo.Q, PT := T#1S);
piston := tpPiston.Q;

END_FUNCTION_BLOCK