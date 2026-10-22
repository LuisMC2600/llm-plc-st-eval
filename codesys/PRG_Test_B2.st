(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea B2 (valvula con retardo TON de 5 s)
    ---------------------------------------------------------------------------
    PLANTILLA PARA TAREAS CON TEMPORIZADORES.

    Diferencia clave respecto a PRG_Test_B1: el tiempo de asentamiento es
    DISTINTO EN CADA PASO. Un valor fijo corto (200 ms) haria fallar a bloques
    correctos, porque evaluaria la salida antes de que venza el temporizador
    interno del bloque bajo prueba. Con un TON de 5 s, el paso que espera la
    apertura necesita mas de 5 s de asentamiento.

    Usa esta plantilla (y no la de B1) en las tareas B2, B5, B6, I1, I2, I4,
    I5 e I8, que incluyen temporizacion. La de B1 solo sirve para logica
    puramente combinacional o de enclavamiento sin retardos.

    ATENCION AL TIEMPO REAL: la simulacion corre en tiempo real, de modo que
    un banco con esperas de 6 s por paso tarda unos 20 s por respuesta. Para
    24 respuestas de una tarea son unos 8 minutos; asumible. En tareas con
    retardos largos (B5 usa TOF de 30 s; I1 encadena 20+4+15 s) conviene
    estimar el tiempo total antes de lanzar el lote.
*)

PROGRAM PRG_Test_B2
VAR CONSTANT
    ULTIMO_PASO : INT := 5;          (* 6 pasos: indices 0..5 *)
END_VAR
VAR
    (* --- Bloque bajo prueba --- *)
    fb : FB_Valvula;

    (* --- Entrada manipulada por el banco --- *)
    nivelAlto : BOOL;

    (* --- Control de la secuencia --- *)
    paso       : INT := 0;
    esperado   : BOOL;
    tEspera    : TIME;               (* asentamiento del paso en curso *)
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    (* --- Resultados: 0 = pendiente, 1 = pasa, 2 = falla --- *)
    resultado : ARRAY[0..5] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;            (* 0 = en curso, 1 = PASA, 2 = FALLA *)
    i         : INT;
END_VAR

(* 1. Definicion del paso en curso: entrada, espera y valor esperado.
      Se evalua antes del temporizador porque tEspera lo alimenta. *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Reposo *)
            nivelAlto := FALSE;
            tEspera   := T#500MS;
            esperado  := FALSE;
        1:  (* Nivel alto durante 3 s: aun NO debe abrir (el TON pide 5 s) *)
            nivelAlto := TRUE;
            tEspera   := T#3S;
            esperado  := FALSE;
        2:  (* Se mantiene 3 s mas (6 s acumulados): ya debe abrir *)
            nivelAlto := TRUE;
            tEspera   := T#3S;
            esperado  := TRUE;
        3:  (* Cae el nivel: debe cerrar de inmediato, sin retardo *)
            nivelAlto := FALSE;
            tEspera   := T#200MS;
            esperado  := FALSE;
        4:  (* Nuevo ciclo completo: comprueba el rearme del temporizador *)
            nivelAlto := TRUE;
            tEspera   := T#6S;
            esperado  := TRUE;
        5:  (* Cierre final *)
            nivelAlto := FALSE;
            tEspera   := T#200MS;
            esperado  := FALSE;
    END_CASE
END_IF

(* 2. Temporizador de asentamiento, con el tiempo propio del paso *)
tPaso(IN := NOT pulsoReset, PT := tEspera);
pulsoReset := FALSE;

(* 3. Llamada al bloque bajo prueba *)
fb(nivelAlto := nivelAlto);

(* 4. Evaluacion al vencer el asentamiento del paso *)
IF tPaso.Q AND NOT finalizado THEN
    IF fb.valvula = esperado THEN
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
