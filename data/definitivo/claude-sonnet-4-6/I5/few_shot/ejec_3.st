```pascal
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura    : BOOL; (* Sensor de altura: TRUE = pieza alta *)
END_VAR
VAR_OUTPUT
    banda   : BOOL; (* Banda transportadora activa *)
    piston  : BOOL; (* Pistón desviador *)
    nAltas  : INT;  (* Contador de piezas altas *)
    nBajas  : INT;  (* Contador de piezas bajas *)
END_VAR
VAR
    tRetardo : TON; (* Retardo de 2 s hasta llegar al desviador *)
    tPulso   : TP;  (* Pulso de 1 s para activar el pistón *)
    rPresencia : R_TRIG; (* Flanco ascendente del sensor de presencia *)
    bPiezaAlta : BOOL;   (* Indica que la pieza detectada es alta *)
END_VAR

(* La banda funciona siempre *)
banda := TRUE;

(* Detectar flanco ascendente del sensor de presencia *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    IF sensorAltura THEN
        (* Pieza alta: registrar y armar retardo *)
        nAltas     := nAltas + 1;
        bPiezaAlta := TRUE;
    ELSE
        (* Pieza baja: solo contar *)
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* Retardo de 2 s: la pieza tarda ese tiempo en llegar al desviador *)
tRetardo(IN := bPiezaAlta, PT := T#2S);

(* Al cumplirse el retardo, lanzar pulso de 1 s en el pistón *)
tPulso(IN := tRetardo.Q, PT := T#1S);

(* Cuando el pulso termina, limpiar la bandera de pieza alta *)
IF NOT tPulso.Q AND NOT tRetardo.Q AND bPiezaAlta THEN
    (* El temporizador de retardo aún no ha arrancado o ya terminó el pulso *)
    (* Limpiar solo cuando el ciclo completo haya concluido *)
    IF tRetardo.ET = T#0S AND NOT tRetardo.IN THEN
        bPiezaAlta := FALSE;
    END_IF;
END_IF;

(* Limpiar bandera al finalizar el pulso del pistón *)
IF tPulso.Q = FALSE AND tRetardo.Q = FALSE AND tRetardo.ET >= T#2S THEN
    bPiezaAlta := FALSE;
END_IF;

(* Activar pistón durante el pulso de 1 s *)
piston := tPulso.Q;

END_FUNCTION_BLOCK
```

> **Nota sobre la lógica de limpieza de `bPiezaAlta`:** el bloque `TP` mantiene `Q = TRUE` durante 1 s a partir del flanco ascendente de `tRetardo.Q`. Una vez que `tPulso.Q` vuelve a `FALSE` y `tRetardo.Q` también es `FALSE` (el retardo ya completó su ciclo, `ET = T#2S`), se baja la bandera `bPiezaAlta`, lo que reinicia `tRetardo.IN` y deja el sistema listo para la siguiente pieza alta. Las piezas bajas no activan ningún temporizador y solo incrementan `nBajas`.