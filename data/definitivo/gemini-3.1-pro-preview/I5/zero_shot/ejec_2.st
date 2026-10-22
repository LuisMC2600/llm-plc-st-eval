```iecst
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Detecta el paso de una pieza *)
    sensorAltura    : BOOL; (* Detecta si la pieza es alta *)
END_VAR
VAR_OUTPUT
    banda   : BOOL; (* Control de la banda transportadora *)
    piston  : BOOL; (* Control del pistón desviador *)
    nAltas  : INT;  (* Contador de piezas altas *)
    nBajas  : INT;  (* Contador de piezas bajas *)
END_VAR
VAR
    flancoPresencia : R_TRIG; (* Detector de flanco para contar solo una vez por pieza *)
    esperaPiston    : BOOL;   (* Marca para iniciar el retardo del pistón *)
    timerRetardo    : TON;    (* Temporizador para el tiempo de viaje (2s) *)
    timerPiston     : TP;     (* Temporizador para la duración del pistón (1s) *)
END_VAR

(* La banda está siempre activa *)
banda := TRUE;

(* Detectar el flanco de subida del sensor de presencia *)
flancoPresencia(CLK := sensorPresencia);

(* Lógica de clasificación y conteo al detectar una pieza *)
IF flancoPresencia.Q THEN
    IF sensorAltura THEN
        nAltas := nAltas + 1;
        esperaPiston := TRUE; (* Activa la bandera para iniciar el retardo *)
    ELSE
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* Temporizador TON: espera 2 segundos desde que se detecta la pieza alta *)
timerRetardo(IN := esperaPiston, PT := T#2S);

(* Cuando pasan los 2 segundos, se resetea la marca de espera *)
IF timerRetardo.Q THEN
    esperaPiston := FALSE;
END_IF;

(* Temporizador TP: genera un pulso de 1 segundo para el pistón *)
(* Se dispara exactamente cuando timerRetardo.Q se activa *)
timerPiston(IN := timerRetardo.Q, PT := T#1S);

(* Asignar la salida del temporizador al pistón *)
piston := timerPiston.Q;

END_FUNCTION_BLOCK
```