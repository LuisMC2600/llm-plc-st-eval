(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea B4 (inversion de giro)
    ---------------------------------------------------------------------------
    Propiedad critica (enmienda 4): "nunca fwd AND rev" se evalua en CADA scan
    y queda ENCLAVADA en 'violacionInterlock' hasta el final del banco, porque
    una violacion transitoria entre dos evaluaciones pasaria inadvertida. El
    veredicto final exige superar todos los pasos Y que la bandera este en
    FALSE. Se registra aparte porque una violacion de seguridad es
    cualitativamente distinta de un fallo funcional.

    USO: crear este PROGRAM junto al FUNCTION_BLOCK de la respuesta a evaluar y
    ejecutar en modo Simulacion. Al terminar, leer 'veredicto': 1 = supera,
    2 = falla.

    ---------------------------------------------------------------------------
    CORRECCION DEL 2026-09-09 (enmienda 9). Validado con validar_harness_B4.py.
    La version anterior daba veredicto 1, y sin levantar la bandera, a una
    implementacion con una CARRERA DE INTERLOCK: el enclavamiento cruzado se
    evaluaba contra el valor de la otra salida en el scan ANTERIOR. Con el
    motor ya girando se comporta bien, pero al pulsar las dos ordenes ESTANDO
    EN REPOSO ambas salidas se activan a la vez durante un scan.

    Causa: la secuencia solo pulsaba las dos ordenes con el motor ya girando en
    reversa (paso 6), situacion en la que la salida activa bloquea a la otra
    incluso con la comparacion retrasada. Nunca las pulsaba desde el reposo,
    que es justamente el caso en que la carrera se manifiesta.

    Es un fallo de COBERTURA, no del mecanismo: la enmienda 4 dejo el
    instrumento capaz de detectar la violacion transitoria, pero la secuencia
    no llegaba a provocarla. Una bandera enclavada solo puede atrapar lo que la
    secuencia produce.

    Correccion: se anaden dos pasos que pulsan ambas ordenes desde el reposo.
    El paso 8 no exige un sentido concreto —el enunciado no dice cual debe
    ganar si se piden los dos a la vez— sino unicamente que no coexistan.
*)

PROGRAM PRG_Test_B4
VAR CONSTANT
    ULTIMO_PASO    : INT  := 9;       (* 10 pasos: indices 0..9 *)
    T_ASENTAMIENTO : TIME := T#150MS;
END_VAR
VAR
    (* --- Bloque bajo prueba: sustituir por la respuesta a evaluar --- *)
    fb : FB_Giro;

    (* --- Entradas manipuladas por el banco --- *)
    btnFwd  : BOOL;
    btnRev  : BOOL;
    btnParo : BOOL;

    (* --- Control de la secuencia --- *)
    espFwd, espRev : BOOL;
    paso       : INT := 0;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    (* --- Seguridad continua y enclavada (enmienda 4) --- *)
    violacionInterlock : BOOL;

    (* --- Resultados: 0 = pendiente, 1 = pasa, 2 = falla --- *)
    resultado : ARRAY[0..9] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Temporizador de asentamiento entre pasos *)
tPaso(IN := NOT pulsoReset, PT := T_ASENTAMIENTO);
pulsoReset := FALSE;

(* 2. Aplicacion de entradas y valores esperados. Solo se asigna lo que cada
      paso cambia: las demas entradas conservan su valor. *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Reposo *)
            btnFwd := FALSE; btnRev := FALSE; btnParo := FALSE;
            espFwd := FALSE; espRev := FALSE;
        1:  (* Marcha adelante *)
            btnFwd := TRUE;
            espFwd := TRUE;  espRev := FALSE;
        2:  (* Se suelta la orden: debe mantenerse (enclavamiento) *)
            btnFwd := FALSE;
            espFwd := TRUE;  espRev := FALSE;
        3:  (* Reversa sin pasar por paro: prohibida *)
            btnRev := TRUE;
            espFwd := TRUE;  espRev := FALSE;
        4:  (* Paro *)
            btnRev := FALSE; btnParo := TRUE;
            espFwd := FALSE; espRev := FALSE;
        5:  (* Ahora si, marcha en reversa *)
            btnParo := FALSE; btnRev := TRUE;
            espFwd := FALSE; espRev := TRUE;
        6:  (* Ambas ordenes con el motor ya girando: la activa debe bloquear *)
            btnFwd := TRUE;
            espFwd := FALSE; espRev := TRUE;
        7:  (* Paro *)
            btnFwd := FALSE; btnRev := FALSE; btnParo := TRUE;
            espFwd := FALSE; espRev := FALSE;

        (* --- Ambas ordenes DESDE EL REPOSO (enmienda 9): es el unico caso en
               que una carrera de interlock se manifiesta --- *)
        8:  (* No se exige un sentido concreto, solo que no coexistan *)
            btnParo := FALSE; btnFwd := TRUE; btnRev := TRUE;
        9:  (* Paro final *)
            btnFwd := FALSE; btnRev := FALSE; btnParo := TRUE;
            espFwd := FALSE; espRev := FALSE;
    END_CASE
END_IF

(* 3. Llamada al bloque bajo prueba *)
fb(btnFwd := btnFwd, btnRev := btnRev, btnParo := btnParo);

(* 4. Seguridad: se evalua en CADA scan y queda enclavada (enmienda 4) *)
IF fb.fwd AND fb.rev THEN
    violacionInterlock := TRUE;
END_IF

(* 5. Evaluacion al vencer el asentamiento *)
IF tPaso.Q AND NOT finalizado THEN
    IF paso = 8 THEN
        (* El enunciado no fija cual de los dos sentidos debe ganar si se
           piden ambos a la vez, asi que el unico criterio es que no coexistan. *)
        IF NOT (fb.fwd AND fb.rev) THEN
            resultado[paso] := 1;
        ELSE
            resultado[paso] := 2;
        END_IF
    ELSE
        IF (fb.fwd = espFwd) AND (fb.rev = espRev) THEN
            resultado[paso] := 1;
        ELSE
            resultado[paso] := 2;
        END_IF
    END_IF

    pulsoReset := TRUE;

    IF paso < ULTIMO_PASO THEN
        paso := paso + 1;
    ELSE
        finalizado := TRUE;
    END_IF
END_IF

(* 6. Veredicto global: todos los pasos Y sin violacion de interlock *)
IF finalizado AND veredicto = 0 THEN
    nPasan := 0;
    FOR i := 0 TO ULTIMO_PASO DO
        IF resultado[i] = 1 THEN
            nPasan := nPasan + 1;
        END_IF
    END_FOR

    IF nPasan = (ULTIMO_PASO + 1) AND NOT violacionInterlock THEN
        veredicto := 1;
    ELSE
        veredicto := 2;
    END_IF
END_IF
