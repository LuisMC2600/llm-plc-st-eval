(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea I5 (banda clasificadora)
    ---------------------------------------------------------------------------
    La banda funciona siempre. Cada flanco de sensorPresencia cuenta una pieza;
    si sensorAltura esta activo en ese instante la pieza es alta y debe
    desviarse: el piston se activa durante 1 s, comenzando 2 s despues de la
    deteccion. Se cuentan altas y bajas por separado.

    USO: crear este PROGRAM junto al FUNCTION_BLOCK de la respuesta a evaluar y
    ejecutar en modo Simulacion. Al terminar, leer 'veredicto': 1 = supera,
    2 = falla.

    ---------------------------------------------------------------------------
    CORRECCION DEL 2026-09-09 (enmienda 11). Validado con validar_harness_I5.py.
    La version anterior REPROBABA a la implementacion correcta en los tres
    ciclos de tarea.

    Causa: el paso que decia comprobar "antes de 2 s" esperaba 1800 ms contando
    desde su propio inicio, pero la deteccion de la pieza alta ocurre 200 ms
    antes, en el paso anterior. El tiempo efectivo desde la deteccion era por
    tanto de 2000 ms exactos, es decir justo el instante en que el piston se
    activa, y la evaluacion lo encontraba ya activado.

    Es el tercer caso del mismo error, tras I4 (enmienda 5) e I2 (enmienda 10):
    una ventana calculada como si la fase empezara en el limite del paso,
    cuando en realidad empieza antes. Conviene enunciarlo como regla: el
    tiempo de una ventana se cuenta desde el evento que la origina, no desde
    el paso en que se escribe.

    Correccion: las tres ventanas del desvio se recalculan con margen explicito
    de 0,3 s a 0,5 s respecto a los flancos del pulso, tomando como origen la
    deteccion real. Con la secuencia corregida se discriminan un retardo de
    1,5 s, la ausencia de retardo, un pulso de 2 s y el desvio indebido de las
    piezas bajas.

    Cronologia (t = 0 en el arranque del banco; deteccion de la pieza alta en
    t = 0,7 s; pulso correcto de 2,7 s a 3,7 s):
        paso 4 evalua en t = 2,4 s  -> 0,3 s ANTES de que el piston se active
        paso 5 evalua en t = 3,2 s  -> dentro del pulso, a 0,5 s de cada flanco
        paso 6 evalua en t = 4,0 s  -> 0,3 s DESPUES de que el piston se apague
*)

PROGRAM PRG_Test_I5
VAR CONSTANT
    ULTIMO_PASO : INT := 6;
END_VAR
VAR
    (* --- Bloque bajo prueba: sustituir por la respuesta a evaluar --- *)
    fb : FB_Clasificadora;

    (* --- Entradas manipuladas por el banco --- *)
    sensorPresencia : BOOL;
    sensorAltura    : BOOL;

    (* --- Control de la secuencia --- *)
    espBanda, espPiston : BOOL;
    espAltas, espBajas  : INT;
    paso       : INT := 0;
    tEspera    : TIME;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    (* --- Resultados: 0 = pendiente, 1 = pasa, 2 = falla --- *)
    resultado : ARRAY[0..6] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Definicion del paso en curso *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Reposo: la banda debe estar en marcha desde el principio *)
            sensorPresencia := FALSE; sensorAltura := FALSE;
            tEspera := T#200MS;
            espBanda := TRUE; espPiston := FALSE; espAltas := 0; espBajas := 0;
        1:  (* Pieza baja con presencia SOSTENIDA: debe contar una sola vez *)
            sensorPresencia := TRUE; sensorAltura := FALSE;
            tEspera := T#300MS;
            espBanda := TRUE; espPiston := FALSE; espAltas := 0; espBajas := 1;
        2:  (* Se retira la pieza baja *)
            sensorPresencia := FALSE;
            tEspera := T#200MS;
            espBanda := TRUE; espPiston := FALSE; espAltas := 0; espBajas := 1;
        3:  (* Pieza ALTA: aqui empieza a contar el retardo de 2 s del desvio *)
            sensorPresencia := TRUE; sensorAltura := TRUE;
            tEspera := T#200MS;
            espBanda := TRUE; espPiston := FALSE; espAltas := 1; espBajas := 1;

        (* --- Ventanas del desvio, con origen en la deteccion (enmienda 11) --- *)
        4:  (* t = 2,4 s: 0,3 s antes de que el piston deba activarse *)
            sensorPresencia := FALSE; sensorAltura := FALSE;
            tEspera := T#1500MS;
            espBanda := TRUE; espPiston := FALSE; espAltas := 1; espBajas := 1;
        5:  (* t = 3,2 s: dentro del pulso, a 0,5 s de cada flanco *)
            tEspera := T#800MS;
            espBanda := TRUE; espPiston := TRUE;  espAltas := 1; espBajas := 1;
        6:  (* t = 4,0 s: 0,3 s despues de que el piston deba apagarse *)
            tEspera := T#800MS;
            espBanda := TRUE; espPiston := FALSE; espAltas := 1; espBajas := 1;
    END_CASE
END_IF

(* 2. Temporizador de asentamiento del paso *)
tPaso(IN := NOT pulsoReset, PT := tEspera);
pulsoReset := FALSE;

(* 3. Llamada al bloque bajo prueba *)
fb(sensorPresencia := sensorPresencia, sensorAltura := sensorAltura);

(* 4. Evaluacion al vencer el asentamiento *)
IF tPaso.Q AND NOT finalizado THEN
    IF     fb.banda   = espBanda
       AND fb.piston  = espPiston
       AND fb.nAltas  = espAltas
       AND fb.nBajas  = espBajas
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
