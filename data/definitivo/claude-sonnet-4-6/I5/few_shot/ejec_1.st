```pascal
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura    : BOOL; (* Sensor de pieza alta *)
END_VAR
VAR_OUTPUT
    banda   : BOOL; (* Banda transportadora activa *)
    piston  : BOOL; (* Piston desviador *)
    nAltas  : INT;  (* Contador de piezas altas *)
    nBajas  : INT;  (* Contador de piezas bajas *)
END_VAR
VAR
    tRetardo : TON; (* Temporizador de retardo 2 s hasta el desviador *)
    tPulso   : TP;  (* Temporizador de pulso 1 s del piston *)
    rPresencia : R_TRIG; (* Flanco ascendente del sensor de presencia *)
    piezaAlta  : BOOL;   (* Indica que la pieza detectada es alta *)
END_VAR

(* La banda funciona continuamente *)
banda := TRUE;

(* Detectar flanco ascendente del sensor de presencia *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    IF sensorAltura THEN
        (* Pieza alta: registrar y armar retardo *)
        nAltas    := nAltas + 1;
        piezaAlta := TRUE;
    ELSE
        (* Pieza baja: solo registrar *)
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* Retardo de 2 s: la pieza tarda ese tiempo en llegar al desviador *)
tRetardo(IN := piezaAlta, PT := T#2S);

(* Al cumplirse el retardo, lanzar pulso de 1 s en el piston *)
tPulso(IN := tRetardo.Q, PT := T#1S);

(* Cuando el pulso termina, desactivar la bandera de pieza alta *)
IF tPulso.Q = FALSE AND tRetardo.Q THEN
    (* El pulso TP.Q cae al terminar; limpiar cuando TP ya no este activo *)
    (* Se limpia piezaAlta cuando el temporizador de pulso finaliza *)
    piezaAlta := FALSE;
END_IF;

(* Activar piston durante el pulso de 1 s *)
piston := tPulso.Q;

END_FUNCTION_BLOCK
```

> **Nota sobre la lógica de limpieza de `piezaAlta`:**
> El bloque `TP` mantiene `Q = TRUE` durante exactamente 1 s desde que su entrada `IN` sube. Cuando `tPulso.Q` vuelve a `FALSE` (pulso terminado) y `tRetardo.Q` sigue en `TRUE` (el TON aún tiene su salida alta porque `piezaAlta` todavía es `TRUE`), se ejecuta la limpieza. Al poner `piezaAlta := FALSE`, en el siguiente ciclo `tRetardo.IN` baja, el TON se reinicia y el sistema queda listo para la siguiente pieza alta.