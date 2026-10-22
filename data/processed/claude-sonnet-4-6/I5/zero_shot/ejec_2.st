FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura    : BOOL; (* TRUE = pieza alta *)
END_VAR

VAR_OUTPUT
    banda   : BOOL; (* Salida banda transportadora *)
    piston  : BOOL; (* Salida pistón desviador *)
    nAltas  : INT;  (* Contador de piezas altas *)
    nBajas  : INT;  (* Contador de piezas bajas *)
END_VAR

VAR
    tRetardo    : TON; (* Temporizador retardo 2 s hasta el desviador *)
    tPiston     : TON; (* Temporizador duración del pistón 1 s *)
    rPresencia  : R_TRIG; (* Flanco ascendente del sensor de presencia *)
    bPiezaAlta  : BOOL;   (* Indica que la pieza detectada es alta *)
    bContado    : BOOL;   (* Evita contar la misma pieza más de una vez *)
END_VAR

(* ------------------------------------------------------------------ *)
(* 1. La banda funciona siempre                                        *)
(* ------------------------------------------------------------------ *)
banda := TRUE;

(* ------------------------------------------------------------------ *)
(* 2. Detectar flanco ascendente del sensor de presencia              *)
(* ------------------------------------------------------------------ *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    (* Capturar si la pieza es alta en el momento de la detección *)
    bPiezaAlta := sensorAltura;
    bContado   := FALSE;

    IF bPiezaAlta THEN
        (* Arrancar el retardo de 2 s antes de activar el pistón *)
        tRetardo.IN := FALSE; (* Reset previo para reiniciar el temporizador *)
    END_IF;
END_IF;

(* ------------------------------------------------------------------ *)
(* 3. Gestión del retardo (2 s) y del pistón (1 s) para piezas altas *)
(* ------------------------------------------------------------------ *)
(* Activar el temporizador de retardo mientras haya pieza alta pendiente
   y el pistón aún no haya terminado su ciclo                         *)
tRetardo(IN := bPiezaAlta AND NOT tRetardo.Q,
         PT := T#2S);

(* Cuando el retardo termina, activar el temporizador del pistón *)
tPiston(IN := tRetardo.Q AND NOT tPiston.Q,
        PT := T#1S);

(* Salida del pistón activa durante el segundo de accionamiento *)
piston := tRetardo.Q AND NOT tPiston.Q;

(* ------------------------------------------------------------------ *)
(* 4. Conteo de piezas y limpieza de estado al finalizar el ciclo     *)
(* ------------------------------------------------------------------ *)
IF bPiezaAlta AND tPiston.Q AND NOT bContado THEN
    (* Ciclo completo de pieza alta: retardo + pistón terminados *)
    nAltas   := nAltas + 1;
    bContado := TRUE;

    (* Resetear temporizadores y bandera para el siguiente ciclo *)
    tRetardo.IN := FALSE;
    tPiston.IN  := FALSE;
    bPiezaAlta  := FALSE;
END_IF;

IF NOT bPiezaAlta AND rPresencia.Q THEN
    (* Pieza baja: contar en el mismo ciclo de detección *)
    nBajas := nBajas + 1;
END_IF;

END_FUNCTION_BLOCK