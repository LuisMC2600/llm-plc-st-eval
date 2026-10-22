(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea I2 (FSM de llenado multietapa)
    ---------------------------------------------------------------------------
    Reposo -> llenado -> mezcla 60 s -> descarga -> reposo. El paro debe llevar
    a estado seguro (todas las salidas desactivadas) desde CUALQUIER etapa y
    devolver el proceso a reposo.

    USO: crear este PROGRAM junto al FUNCTION_BLOCK de la respuesta a evaluar y
    ejecutar en modo Simulacion. Al terminar, leer 'veredicto': 1 = supera,
    2 = falla.

    ---------------------------------------------------------------------------
    CORRECCION DEL 2026-09-09 (enmienda 10). Validado con validar_harness_I2.py.
    La version anterior tenia dos fallos:

    FALLO 1 — el paso de "antes de los 60 s" REPROBABA a la implementacion
    correcta en los tres ciclos de tarea. Esperaba 59 800 ms contando desde el
    inicio de ese paso, pero la mezcla no arranca ahi: arranca ~200 ms antes,
    en el paso anterior, en cuanto el bloque ve nivelAlto. El margen resultante
    era nulo y la evaluacion caia justo en el instante en que la mezcla
    termina, de modo que se observaba ya la descarga. Es el mismo error que la
    enmienda 5 corrigio en I4: una ventana calculada como si la fase empezara
    en el limite del paso, cuando empieza antes.

    FALLO 2 — el ultimo paso, etiquetado "paro en mezcla", NUNCA llegaba a la
    mezcla. Aplicaba nivelAlto y btnParo en el MISMO paso, asi que el paro
    alcanzaba al bloque todavia en llenado: era un duplicado del paso anterior.
    Verificado: una implementacion cuyo paro funciona en llenado pero no
    durante la mezcla obtenia el mismo resultado que la correcta. El paro en
    dos fases que este banco dice comprobar solo se comprobaba en una.

    La correccion de tiempos de este documento ya lo insinuaba al estimar I2 en
    ~90 s "porque el paro se prueba en dos fases distintas, cada una exige
    volver a entrar en la fase": la secuencia real duraba 61,9 s porque esa
    segunda entrada nunca se hacia.

    Correcciones: la ventana de la mezcla pasa a tener margen explicito y
    simetrico de 0,5 s a cada lado de los 60 s; y entrar en la mezcla y aplicar
    el paro pasan a ser dos pasos separados, de modo que el paro alcance al
    bloque realmente mezclando. Se anade ademas un paso final que comprueba que
    tras el paro el proceso permanece en reposo y no rearranca solo.
*)

PROGRAM PRG_Test_I2
VAR CONSTANT
    ULTIMO_PASO : INT := 11;          (* 12 pasos: indices 0..11 *)
END_VAR
VAR
    (* --- Bloque bajo prueba: sustituir por la respuesta a evaluar --- *)
    fb : FB_Llenado;

    (* --- Entradas manipuladas por el banco --- *)
    nivelAlto : BOOL;
    nivelBajo : BOOL;
    btnInicio : BOOL;
    btnParo   : BOOL;

    (* --- Control de la secuencia --- *)
    evL, evM, evD : BOOL;
    paso       : INT := 0;
    tEspera    : TIME;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    (* --- Resultados: 0 = pendiente, 1 = pasa, 2 = falla --- *)
    resultado : ARRAY[0..11] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Definicion del paso en curso *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Reposo *)
            nivelAlto := FALSE; nivelBajo := FALSE;
            btnInicio := FALSE; btnParo := FALSE;
            tEspera := T#200MS; evL := FALSE; evM := FALSE; evD := FALSE;
        1:  (* Arranque: abre la valvula de llenado *)
            btnInicio := TRUE;
            tEspera := T#200MS; evL := TRUE;  evM := FALSE; evD := FALSE;
        2:  (* Nivel alto: entra en mezcla. La mezcla arranca AQUI, no en el
               paso siguiente; de ahi el margen explicito del paso 3. *)
            btnInicio := FALSE; nivelAlto := TRUE;
            tEspera := T#1S;    evL := FALSE; evM := TRUE;  evD := FALSE;
        3:  (* ~59,5 s de mezcla acumulados: aun NO debe haber terminado *)
            tEspera := T#58500MS; evM := TRUE;
        4:  (* ~60,5 s acumulados: ya debe estar descargando *)
            tEspera := T#1S;    evL := FALSE; evM := FALSE; evD := TRUE;
        5:  (* Nivel bajo: vuelve a reposo *)
            nivelBajo := TRUE;
            tEspera := T#200MS; evL := FALSE; evM := FALSE; evD := FALSE;

        (* --- Paro en la fase de LLENADO --- *)
        6:  (* Nuevo ciclo *)
            nivelAlto := FALSE; nivelBajo := FALSE; btnInicio := TRUE;
            tEspera := T#200MS; evL := TRUE;  evM := FALSE; evD := FALSE;
        7:  (* Paro estando en llenado: estado seguro *)
            btnInicio := FALSE; btnParo := TRUE;
            tEspera := T#200MS; evL := FALSE; evM := FALSE; evD := FALSE;

        (* --- Paro en la fase de MEZCLA (enmienda 10): entrar en la mezcla y
               aplicar el paro son DOS pasos distintos, para que el paro
               alcance al bloque realmente mezclando --- *)
        8:  (* Rearranca tras el paro *)
            btnParo := FALSE; btnInicio := TRUE;
            tEspera := T#200MS; evL := TRUE;  evM := FALSE; evD := FALSE;
        9:  (* Entra en mezcla y se deja mezclando *)
            btnInicio := FALSE; nivelAlto := TRUE;
            tEspera := T#500MS; evL := FALSE; evM := TRUE;  evD := FALSE;
        10: (* Paro ESTANDO EN MEZCLA: estado seguro *)
            btnParo := TRUE;
            tEspera := T#200MS; evL := FALSE; evM := FALSE; evD := FALSE;
        11: (* Tras el paro debe permanecer en reposo, sin rearrancar solo *)
            btnParo := FALSE; nivelAlto := FALSE;
            tEspera := T#200MS; evL := FALSE; evM := FALSE; evD := FALSE;
    END_CASE
END_IF

(* 2. Temporizador de asentamiento del paso *)
tPaso(IN := NOT pulsoReset, PT := tEspera);
pulsoReset := FALSE;

(* 3. Llamada al bloque bajo prueba *)
fb(nivelAlto := nivelAlto, nivelBajo := nivelBajo,
   btnInicio := btnInicio, btnParo := btnParo);

(* 4. Evaluacion al vencer el asentamiento *)
IF tPaso.Q AND NOT finalizado THEN
    IF fb.vLlenado = evL AND fb.motorMezcla = evM AND fb.vDescarga = evD THEN
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

(* 5. Veredicto global *)
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
