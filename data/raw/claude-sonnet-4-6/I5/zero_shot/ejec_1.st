```pascal
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
    bPiezaAlta  : BOOL;   (* Indica que la pieza detectada es alta *)
    bEsperando  : BOOL;   (* TRUE mientras se espera el retardo *)
END_VAR

(* ── Banda siempre activa ─────────────────────────────────────── *)
banda := TRUE;

(* ── Detección de flanco en sensorPresencia ───────────────────── *)
rPresencia(CLK := sensorPresencia);

IF rPresencia.Q THEN
    (* Nueva pieza detectada *)
    IF sensorAltura THEN
        (* Pieza alta: registrar y armar retardo *)
        nAltas     := nAltas + 1;
        bPiezaAlta := TRUE;
        bEsperando := TRUE;
    ELSE
        (* Pieza baja: solo contar *)
        nBajas := nBajas + 1;
    END_IF;
END_IF;

(* ── Retardo de 2 s (pieza viaja hasta el desviador) ─────────── *)
tRetardo(IN := bEsperando, PT := T#2S);

IF tRetardo.Q THEN
    (* Han pasado 2 s: activar pistón y detener retardo *)
    bEsperando := FALSE;
    tRetardo(IN := FALSE);  (* Reset del temporizador de retardo *)
    bPiezaAlta := TRUE;     (* Señal para arrancar temporizador pistón *)
END_IF;

(* ── Activación del pistón durante 1 s ───────────────────────── *)
tPiston(IN := tRetardo.Q OR tPiston.Q AND NOT tPiston.ET = T#1S, PT := T#1S);
(* Nota: se usa el flanco de salida de tRetardo para arrancar tPiston *)
tPiston(IN := (tRetardo.Q), PT := T#1S);

piston := tPiston.Q OR (tRetardo.Q);

(* ── Salida limpia del pistón ─────────────────────────────────── *)
(* tPiston corre mientras su entrada IN sea TRUE;
   se mantiene TRUE hasta que ET alcance PT (1 s) *)
IF tPiston.ET >= T#1S THEN
    tPiston(IN := FALSE);   (* Reset del temporizador del pistón *)
    piston := FALSE;
END_IF;

END_FUNCTION_BLOCK
```

> **Nota:** La lógica de encadenamiento de los dos `TON` con llamadas múltiples en el mismo ciclo puede generar ambigüedad en algunos compiladores. A continuación se presenta una versión más robusta y limpia usando una máquina de estados explícita, que es la práctica recomendada en IEC 61131-3:

```pascal
FUNCTION_BLOCK FB_Clasificadora
VAR_INPUT
    sensorPresencia : BOOL; (* Sensor de paso de pieza *)
    sensorAltura    : BOOL; (* TRUE = pieza alta *)
END_VAR

VAR_OUTPUT
    banda   : BOOL; (* Banda transportadora siempre activa *)
    piston  : BOOL; (* Salida del desviador *)
    nAltas  : INT;  (* Contador piezas altas *)
    nBajas  : INT;  (* Contador piezas bajas *)
END_VAR

VAR
    rPresencia : R_TRIG; (* Flanco ascendente sensor presencia *)
    tRetardo   : TON;    (* Retardo 2 s: detección → desviador *)
    tPiston    : TON;    (* Duración pistón: 1 s *)

    (* Estados de la máquina:
       0 = reposo
       1 = esperando retardo (pieza alta en camino)
       2 = pistón activo                              *)
    nEstado : INT;
END_VAR

(* ── Banda siempre en marcha ──────────────────────────────────── *)
banda := TRUE;

(* ── Detección de flanco ascendente en sensorPresencia ───────── *)
rPresencia(CLK := sensorPresencia);

(* ── Máquina de estados ───────────────────────────────────────── *)
CASE nEstado OF

    0: (* Reposo: esperando nueva pieza *)
        tRetardo(IN := FALSE, PT := T#2S); (* Mantener reset *)
        tPiston (IN := FALSE, PT := T#1S); (* Mantener reset *)
        piston := FALSE;

        IF rPresencia.Q THEN
            IF sensorAltura THEN
                (* Pieza alta detectada *)
                nAltas  := nAltas + 1;
                nEstado := 1; (* Ir a esperar retardo *)
            ELSE
                (* Pieza baja detectada *)
                nBajas := nBajas + 1;
                (* Permanece en estado 0 *)
            END_IF;
        END_IF;

    1: (* Retardo 2 s: pieza viajando hacia el desviador *)
        tRetardo(IN := TRUE, PT := T#2S);
        piston := FALSE;

        IF tRetardo.Q THEN
            tRetardo(IN := FALSE, PT := T#2S); (* Reset retardo *)
            nEstado := 2; (* Activar pistón *)
        END_IF;

    2: (* Pistón activo durante 1 s *)
        tPiston(IN := TRUE, PT := T#1S);
        piston := TRUE;

        IF tPiston.Q THEN
            tPiston(IN := FALSE, PT := T#1S); (* Reset pistón *)
            piston  := FALSE;
            nEstado := 0; (* Volver a reposo *)
        END_IF;

ELSE
    (* Estado desconocido: recuperación segura *)
    nEstado := 0;

END_CASE;

END_FUNCTION_BLOCK
```

### Explicación de la lógica

| Elemento | Función |
|---|---|
| `rPresencia` (`R_TRIG`) | Genera un pulso de un ciclo en cada pieza que pasa |
| `nEstado = 0` | Reposo; clasifica la pieza (alta/baja) al detectarla |
| `nEstado = 1` | `tRetardo` cuenta **2 s** mientras la pieza viaja al desviador |
| `nEstado = 2` | `tPiston` mantiene la salida `piston` activa **1 s** |
| `banda` | Siempre `TRUE`, independiente del estado |