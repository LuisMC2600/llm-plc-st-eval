(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea I4 (arranque estrella-triangulo)
    ---------------------------------------------------------------------------
    Aplica la enmienda 2 de ENMIENDAS_HARNESSES.md: DOS verificaciones
    independientes, porque una transicion con 0 ms de tiempo muerto no produce
    ningun scan con kY AND kD y por tanto la bandera de interlock por si sola
    no la detecta.
      1. Seguridad (continua y enclavada): si en cualquier scan kY AND kD, la
         bandera 'interlock' queda en TRUE hasta el final del banco.
      2. Tiempo muerto (medido): se cronometra el intervalo entre la caida de
         kY y la subida de kD y se exige que alcance el minimo.

    Ciclo de MainTask: 4 a 10 ms (enmienda 3). El umbral del tiempo muerto
    absorbe un ciclo de cuantizacion del scan.

    USO: crear este PROGRAM junto al FUNCTION_BLOCK de la respuesta a evaluar y
    ejecutar en modo Simulacion. Al terminar, leer 'veredicto': 1 = supera,
    2 = falla. 'resultado' indica el paso; 'interlock' y 'duracionMuerto' se
    registran aparte porque una violacion de seguridad es cualitativamente
    distinta de un fallo funcional (enmienda 4).

    ---------------------------------------------------------------------------
    CORRECCION DEL 2026-09-09 (enmienda 5). La version anterior tenia tres
    fallos, verificados por simulacion con validar_harness_I4.py:

      1. El paso 2 exigia NOT kD a los 8,3 s, cuando una implementacion
         correcta ya tiene el triangulo dentro desde los 8,1 s. Reprobaba al
         100 % de las implementaciones validas. Era un residuo del enfoque de
         muestreo que la enmienda 2 habia descartado.
      2. La medida reiniciaba su temporizador con un ciclo de retraso, de modo
         que contaba de menos alrededor de un scan: un tiempo muerto correcto
         de 100 ms se media como 96 ms con ciclo de 4 ms y 80 ms con 20 ms, y
         se comparaba contra un umbral estricto de 100 ms.
      3. Si kY caia y kD subia en el MISMO scan, ambas condiciones se cumplian
         en el mismo ciclo, la medida leia un valor viejo del cronometro y
         registraba 8 208 ms: daba por bueno el defecto de 0 ms de tiempo
         muerto, que es exactamente el que la enmienda 2 persigue.

    La medida pasa a hacerse por DIFERENCIA de dos lecturas de un cronometro
    libre que nunca se reinicia. Eso elimina el retraso de un ciclo y hace que
    el caso simultaneo mida 0 ms por construccion, sin necesidad de un caso
    especial. El paso 2 pasa a comprobar que la transicion se completo, y el
    instante exacto queda a cargo de la medida en el paso 3.
*)

PROGRAM PRG_Test_I4
VAR CONSTANT
    ULTIMO_PASO   : INT  := 5;
    T_MUERTO_MIN  : TIME := T#90MS;   (* 100 ms del enunciado menos un ciclo de
                                         MainTask: la cuantizacion del scan es
                                         inevitable y se declara en la metodologia *)
    T_CRONO       : TIME := T#100S;   (* cronometro libre: nunca se reinicia *)
END_VAR
VAR
    (* --- Bloque bajo prueba: sustituir por la respuesta a evaluar --- *)
    fb : FB_EstrellaTriangulo;

    (* --- Entradas manipuladas por el banco --- *)
    btnMarcha : BOOL;
    btnParo   : BOOL;

    (* --- Control de la secuencia --- *)
    paso       : INT := 0;
    tEspera    : TIME;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    (* --- Verificacion 1: seguridad continua y enclavada (enmiendas 2 y 4) --- *)
    interlock : BOOL;

    (* --- Verificacion 2: medida del tiempo muerto (enmienda 2) --- *)
    tCrono         : TON;
    prevY, prevD   : BOOL;
    midiendo       : BOOL;
    etCaidaY       : TIME;
    duracionMuerto : TIME;
    muertoOK       : BOOL;

    (* --- Resultados: 0 = pendiente, 1 = pasa, 2 = falla --- *)
    resultado : ARRAY[0..5] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Definicion del paso en curso. Va antes del temporizador porque tEspera
      lo alimenta. Solo se asigna lo que cada paso cambia. *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Reposo *)
            btnMarcha := FALSE; btnParo := FALSE;
            tEspera   := T#200MS;
        1:  (* Fase estrella: se evalua antes de los 8 s de transicion *)
            btnMarcha := TRUE;
            tEspera   := T#7800MS;
        2:  (* Ya pasada la transicion: debe estar en triangulo *)
            tEspera   := T#500MS;
        3:  (* Confirmacion del veredicto de tiempo muerto *)
            tEspera   := T#300MS;
        4:  (* Paro en cualquier momento: todo a reposo *)
            btnMarcha := FALSE; btnParo := TRUE;
            tEspera   := T#200MS;
        5:  (* Rearranque: debe volver a estrella, no saltar a triangulo *)
            btnParo := FALSE; btnMarcha := TRUE;
            tEspera := T#200MS;
    END_CASE
END_IF

(* 2. Temporizadores del banco *)
tPaso(IN := NOT pulsoReset, PT := tEspera);
tCrono(IN := TRUE, PT := T_CRONO);
pulsoReset := FALSE;

(* 3. Llamada al bloque bajo prueba *)
fb(btnMarcha := btnMarcha, btnParo := btnParo);

(* 4. Verificacion 1 — seguridad: se evalua en CADA scan y queda enclavada *)
IF fb.kY AND fb.kD THEN
    interlock := TRUE;
END_IF

(* 5. Verificacion 2 — tiempo muerto por diferencia de dos lecturas del
      cronometro libre. Si kY cae y kD sube en el mismo scan, ambas ramas se
      ejecutan en ese ciclo y la diferencia vale 0: el defecto queda detectado
      sin necesidad de un caso especial. *)
IF prevY AND NOT fb.kY THEN
    etCaidaY := tCrono.ET;
    midiendo := TRUE;
END_IF

IF midiendo AND fb.kD AND NOT prevD THEN
    duracionMuerto := tCrono.ET - etCaidaY;
    IF duracionMuerto >= T_MUERTO_MIN THEN
        muertoOK := TRUE;
    END_IF
    midiendo := FALSE;
END_IF

prevY := fb.kY;
prevD := fb.kD;

(* 6. Evaluacion al vencer el asentamiento del paso *)
IF tPaso.Q AND NOT finalizado THEN
    IF    (paso = 0 AND NOT fb.kM AND NOT fb.kY AND NOT fb.kD)
       OR (paso = 1 AND fb.kM AND fb.kY AND NOT fb.kD)
       OR (paso = 2 AND fb.kM AND NOT fb.kY AND fb.kD)
       OR (paso = 3 AND fb.kM AND NOT fb.kY AND fb.kD AND muertoOK)
       OR (paso = 4 AND NOT fb.kM AND NOT fb.kY AND NOT fb.kD)
       OR (paso = 5 AND fb.kM AND fb.kY AND NOT fb.kD)
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

(* 7. Veredicto global: exige superar todos los pasos Y no haber violado
      nunca el interlock (enmienda 4) *)
IF finalizado AND veredicto = 0 THEN
    nPasan := 0;
    FOR i := 0 TO ULTIMO_PASO DO
        IF resultado[i] = 1 THEN
            nPasan := nPasan + 1;
        END_IF
    END_FOR

    IF nPasan = (ULTIMO_PASO + 1) AND NOT interlock THEN
        veredicto := 1;
    ELSE
        veredicto := 2;
    END_IF
END_IF
