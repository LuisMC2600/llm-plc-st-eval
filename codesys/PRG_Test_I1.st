(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea I1 (semaforo con secuencia temporizada)
    ---------------------------------------------------------------------------
    Verde 20 s, amarillo 4 s, rojo 15 s, ciclico mientras 'habilitado'. Al
    deshabilitar, amarillo intermitente de 1 s / 1 s con las demas luces
    apagadas. Al rehabilitar, la secuencia REINICIA EN VERDE.

    El modo intermitente se verifica midiendo la duracion de los intervalos
    completos, no muestreando (enmienda 1). La condicion "las demas luces
    apagadas" se vigila en cada scan y queda enclavada (enmienda 6).

    Ciclo de MainTask: 4 a 10 ms (enmienda 3).

    USO: crear este PROGRAM junto al FUNCTION_BLOCK de la respuesta a evaluar y
    ejecutar en modo Simulacion. Al terminar, leer 'veredicto': 1 = supera,
    2 = falla. 'resultado' indica el paso.

    ---------------------------------------------------------------------------
    CORRECCION DEL 2026-09-09 (enmienda 8). Validado con validar_harness_I1.py.
    La version anterior daba veredicto 1 a dos implementaciones defectuosas:

    FALLO 1 — "las demas luces apagadas" se comprobaba en un unico instante al
    final del paso intermitente. Una implementacion que resuelve el
    intermitente alternando AMARILLO y ROJO (error plausible: parpadear entre
    el amarillo y la ultima luz activa) deja el rojo en antifase con el
    amarillo, de modo que en el instante muestreado las demas estan apagadas.
    Verificado: con el parpadeo arrancando en amarillo encendido, el defecto
    obtiene veredicto 1 en los tres ciclos de tarea; con la fase contraria solo
    se detecta de rebote en el paso 0, es decir por suerte de fase y no por
    merito del banco. Es el mismo error de muestreo de la enmienda 6.

    FALLO 2 — el reinicio en verde no se estaba probando. La secuencia
    deshabilitaba el semaforo mientras estaba EN VERDE, asi que al rehabilitar
    una implementacion que reinicia y una que continua donde se quedo muestran
    exactamente lo mismo. Verificado: el defecto "no reinicia" obtenia
    veredicto 1 en los tres ciclos. Para probarlo hay que interrumpir en una
    fase que NO sea verde.

    Correcciones: la vigilancia de V y R en los pasos deshabilitados pasa a ser
    continua y enclavada; y la secuencia recorre un segundo ciclo hasta el ROJO
    antes de deshabilitar, de modo que el reinicio en verde sea observable. La
    medida de intervalos se unifica con el metodo de la enmienda 5 (diferencia
    de dos lecturas de un cronometro libre). La secuencia pasa de 46,6 s a
    70,6 s, dentro de la estimacion de ~90 s de la correccion de tiempos.
*)

PROGRAM PRG_Test_I1
VAR CONSTANT
    ULTIMO_PASO : INT  := 8;          (* 9 pasos: indices 0..8 *)
    TOL_MIN     : TIME := T#850MS;    (* 1 s - 150 ms *)
    TOL_MAX     : TIME := T#1150MS;   (* 1 s + 150 ms *)
    T_CRONO     : TIME := T#100S;
END_VAR
VAR
    (* --- Bloque bajo prueba: sustituir por la respuesta a evaluar --- *)
    fb : FB_Semaforo;

    (* --- Entrada manipulada por el banco --- *)
    habilitado : BOOL;

    (* --- Control de la secuencia --- *)
    paso       : INT := 0;
    tEspera    : TIME;
    espV, espA, espR : BOOL;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    (* --- Medida del intermitente (enmiendas 1 y 5) --- *)
    tCrono   : TON;
    prevA    : BOOL;
    primer   : BOOL;
    etFlanco : TIME;
    duracion : TIME;
    error    : BOOL;
    nOn, nOff : INT;

    (* --- Vigilancia continua y enclavada de las demas luces (enmienda 6) --- *)
    otraLuzPaso0 : BOOL;
    otraLuzPaso7 : BOOL;

    (* --- Resultados: 0 = pendiente, 1 = pasa, 2 = falla --- *)
    resultado : ARRAY[0..8] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Definicion del paso en curso *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Reposo deshabilitado: V y R deben permanecer apagadas *)
            habilitado := FALSE; tEspera := T#200MS;
        1:  (* Al habilitar arranca en verde *)
            habilitado := TRUE;  tEspera := T#200MS;
            espV := TRUE;  espA := FALSE; espR := FALSE;

        (* --- Primer ciclo completo --- *)
        2:  (* 20 s de verde -> amarillo *)
            tEspera := T#20S;  espV := FALSE; espA := TRUE;  espR := FALSE;
        3:  (* 4 s de amarillo -> rojo *)
            tEspera := T#4S;   espV := FALSE; espA := FALSE; espR := TRUE;
        4:  (* 15 s de rojo -> verde *)
            tEspera := T#15S;  espV := TRUE;  espA := FALSE; espR := FALSE;

        (* --- Segundo ciclo: confirma que es ciclico y deja el semaforo en
               ROJO, que es la fase desde la que hay que interrumpir para que
               el reinicio en verde sea observable (enmienda 8) --- *)
        5:  (* 20 s de verde -> amarillo *)
            tEspera := T#20S;  espV := FALSE; espA := TRUE;  espR := FALSE;
        6:  (* 4 s de amarillo -> rojo *)
            tEspera := T#4S;   espV := FALSE; espA := FALSE; espR := TRUE;

        (* --- Intermitente e inhibicion --- *)
        7:  (* Se deshabilita ESTANDO EN ROJO: amarillo intermitente medido,
               con V y R vigiladas de forma continua *)
            habilitado := FALSE; tEspera := T#7S;
        8:  (* Al rehabilitar debe reiniciar EN VERDE, no continuar en rojo *)
            habilitado := TRUE;  tEspera := T#200MS;
            espV := TRUE;  espA := FALSE; espR := FALSE;
    END_CASE
END_IF

(* 2. Temporizadores del banco *)
tPaso(IN := NOT pulsoReset, PT := tEspera);
tCrono(IN := TRUE, PT := T_CRONO);
pulsoReset := FALSE;

(* 3. Llamada al bloque bajo prueba *)
fb(habilitado := habilitado);

(* 4. Medida de los intervalos del amarillo intermitente (paso 7).
      Duracion por diferencia de dos lecturas del cronometro libre. *)
IF paso = 7 THEN
    IF (fb.luzA AND NOT prevA) OR ((NOT fb.luzA) AND prevA) THEN
        IF primer THEN
            duracion := tCrono.ET - etFlanco;
            IF NOT fb.luzA THEN
                nOn := nOn + 1;
            ELSE
                nOff := nOff + 1;
            END_IF
            IF duracion < TOL_MIN OR duracion > TOL_MAX THEN
                error := TRUE;
            END_IF
        ELSE
            primer := TRUE;
        END_IF
        etFlanco := tCrono.ET;
    END_IF
END_IF
prevA := fb.luzA;

(* 5. Vigilancia continua y enclavada de las demas luces durante los pasos
      deshabilitados (enmienda 6). Un unico muestreo no sirve: si la
      implementacion alterna el amarillo con otra luz, la fase decide si se
      la sorprende encendida. *)
IF paso = 0 AND (fb.luzV OR fb.luzR) THEN
    otraLuzPaso0 := TRUE;
END_IF
IF paso = 7 AND (fb.luzV OR fb.luzR) THEN
    otraLuzPaso7 := TRUE;
END_IF

(* 6. Evaluacion al vencer el asentamiento del paso *)
IF tPaso.Q AND NOT finalizado THEN
    IF    (paso = 0 AND NOT fb.luzV AND NOT fb.luzR AND NOT otraLuzPaso0)
       OR (paso = 7 AND NOT fb.luzV AND NOT fb.luzR AND NOT otraLuzPaso7
                    AND nOn >= 2 AND nOff >= 2 AND NOT error)
       OR (paso <> 0 AND paso <> 7
                    AND fb.luzV = espV AND fb.luzA = espA AND fb.luzR = espR)
    THEN
        resultado[paso] := 1;
    ELSE
        resultado[paso] := 2;
    END_IF

    pulsoReset := TRUE;

    IF paso < ULTIMO_PASO THEN
        paso := paso + 1;
    ELSE
        finalizado := TRUE;
    END_IF
END_IF

(* 7. Veredicto global *)
IF finalizado AND veredicto = 0 THEN
    nPasan := 0;
    FOR i := 0 TO ULTIMO_PASO DO
        IF resultado[i] = 1 THEN
            nPasan := nPasan + 1;
        END_IF
    END_FOR

    IF nPasan = (ULTIMO_PASO + 1) THEN
        veredicto := 1;
    ELSE
        veredicto := 2;
    END_IF
END_IF
