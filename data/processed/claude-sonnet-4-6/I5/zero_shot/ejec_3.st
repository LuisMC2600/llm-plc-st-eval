FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura    : BOOL; (* TRUE = pieza alta *)
END_VAR

VAR_OUTPUT
    banda   : BOOL; (* Banda transportadora activa *)
    piston  : BOOL; (* Desviador activo *)
    nAltas  : INT;  (* Contador de piezas altas *)
    nBajas  : INT;  (* Contador de piezas bajas *)
END_VAR

VAR
    tRetardo    : TON; (* Temporizador retardo 2 s hasta el desviador *)
    tPiston     : TON; (* Temporizador duración del pistón 1 s *)
    rPresencia  : R_TRIG; (* Flanco ascendente del sensor de presencia *)
    piezaAlta   : BOOL;   (* Indica que la pieza detectada es alta *)
END_VAR

(* ── Banda siempre activa ─────────────────────────────────────── *)
banda := TRUE;

(* ── Detección de flanco en sensorPresencia ───────────────────── *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    (* Nueva pieza detectada: registrar su tipo y arrancar retardo *)
    piezaAlta := sensorAltura;

    IF piezaAlta THEN
        nAltas := nAltas + 1; (* Contar pieza alta *)
    ELSE
        nBajas := nBajas + 1; (* Contar pieza baja *)
    END_IF;

    (* Reiniciar temporizadores para esta pieza *)
    tRetardo(IN := FALSE, PT := T#2S);
    tPiston (IN := FALSE, PT := T#1S);
END_IF;

(* ── Retardo de 2 s: tiempo de tránsito hasta el desviador ───── *)
IF piezaAlta THEN
    tRetardo(IN := TRUE, PT := T#2S);
ELSE
    tRetardo(IN := FALSE, PT := T#2S);
END_IF;

(* ── Activar pistón durante 1 s al cumplirse el retardo ─────── *)
IF tRetardo.Q THEN
    tPiston(IN := TRUE, PT := T#1S); (* Arrancar temporizador pistón *)
END_IF;

IF tPiston.Q THEN
    (* Tiempo de pistón cumplido: desactivar todo *)
    tPiston (IN := FALSE, PT := T#1S);
    tRetardo(IN := FALSE, PT := T#2S);
    piezaAlta := FALSE;
END_IF;

(* ── Salida pistón activa mientras tPiston está contando ─────── *)
piston := tPiston.IN AND NOT tPiston.Q;

END_FUNCTION_BLOCK