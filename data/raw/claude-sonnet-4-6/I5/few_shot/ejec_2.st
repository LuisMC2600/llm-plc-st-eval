```pascal
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura    : BOOL; (* TRUE = pieza alta *)
END_VAR
VAR_OUTPUT
    banda   : BOOL; (* Banda transportadora activa *)
    piston  : BOOL; (* Pistón desviador *)
    nAltas  : INT;  (* Contador de piezas altas *)
    nBajas  : INT;  (* Contador de piezas bajas *)
END_VAR
VAR
    tRetardo : TON; (* Retardo 2 s hasta que la pieza llega al desviador *)
    tPulso   : TP;  (* Pulso 1 s de activación del pistón *)
    rPresencia : R_TRIG; (* Flanco ascendente del sensor de presencia *)
    piezaAlta  : BOOL;   (* Indica que la pieza detectada es alta *)
END_VAR

(* La banda funciona siempre *)
banda := TRUE;

(* Detectar flanco ascendente del sensor de presencia *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    IF sensorAltura THEN
        (* Pieza alta: registrar y armar retardo *)
        nAltas    := nAltas + 1;
        piezaAlta := TRUE;
    ELSE
        (* Pieza baja: solo contar *)
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* Retardo de 2 s: empieza cuando se detecta una pieza alta *)
tRetardo(IN := piezaAlta, PT := T#2S);

(* Al cumplirse el retardo, lanzar pulso de 1 s en el pistón *)
tPulso(IN := tRetardo.Q, PT := T#1S);

(* Cuando el pulso termina, limpiar la bandera de pieza alta *)
IF tPulso.Q = FALSE AND tRetardo.Q THEN
    (* El pulso aún no ha terminado; esperar *)
    ;
END_IF;
IF NOT tPulso.Q AND NOT tRetardo.IN THEN
    (* tRetardo.IN vuelve a FALSE solo si piezaAlta = FALSE,
       así que limpiamos piezaAlta cuando el pulso concluye *)
    ;
END_IF;

(* Limpiar piezaAlta una vez que el pulso de 1 s ha finalizado *)
IF tPulso.Q = FALSE AND tRetardo.Q = FALSE AND piezaAlta THEN
    (* El temporizador de retardo ya terminó su ciclo completo *)
    piezaAlta := FALSE;
END_IF;

(* Salida del pistón activa durante el pulso de 1 s *)
piston := tPulso.Q;

END_FUNCTION_BLOCK
```

> **Nota sobre la lógica de reset de `piezaAlta`:**
> `tRetardo` se activa con `piezaAlta = TRUE`. Cuando `tRetardo.Q` sube, `tPulso` arranca. Al finalizar `tPulso` (Q baja), `tRetardo.Q` también baja (porque `TP` ya completó su ciclo). En ese momento `tRetardo.IN` sigue siendo `piezaAlta`, que aún es `TRUE`, por lo que `tRetardo` volvería a contar. Para romper ese ciclo, la condición `NOT tPulso.Q AND NOT tRetardo.Q AND piezaAlta` detecta exactamente el instante en que ambos temporizadores han terminado y pone `piezaAlta := FALSE`, deteniendo `tRetardo` en el siguiente ciclo de scan.