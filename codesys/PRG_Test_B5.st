(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea B5 (ventilador con retardo TOF)
    ---------------------------------------------------------------------------
    El ventilador acompana al quemador y sigue funcionando 30 s tras el paro.
    El punto delicado, declarado en ENMIENDAS_HARNESSES.md, es reactivar el
    quemador DURANTE el post-enfriamiento: la reactivacion debe REARMAR el
    temporizador, de modo que el siguiente post-enfriamiento vuelva a durar
    30 s completos.

    USO: crear este PROGRAM junto al FUNCTION_BLOCK de la respuesta a evaluar y
    ejecutar en modo Simulacion. Al terminar, leer 'veredicto': 1 = supera,
    2 = falla. 'resultado' indica el paso.

    ---------------------------------------------------------------------------
    CORRECCION DEL 2026-09-09 (enmienda 7). Validado con validar_harness_B5.py.
    La version anterior daba veredicto 1 a una implementacion que rearmaba el
    temporizador pero con un tiempo MENOR: el segundo post-enfriamiento duraba
    15 s en lugar de 30 s y pasaba como correcta en los tres ciclos de tarea.

    Causa: la secuencia reactivaba el quemador en el ultimo paso y terminaba
    ahi. Comprobaba que el temporizador se rearmaba, pero nunca que se rearmara
    a los 30 s completos, porque el segundo post-enfriamiento no se llegaba a
    recorrer. El paso final, ademas, no discriminaba nada: cualquier
    implementacion que superara el paso 1 lo superaba tambien.

    La propia enmienda de correccion de tiempos ya anticipaba esto al estimar
    B5 en ~70 s "porque la reactivacion durante el post-enfriamiento exige un
    segundo ciclo". La secuencia anterior duraba 41 s: el segundo ciclo que esa
    estimacion daba por hecho nunca se habia implementado.

    Correccion: tras la reactivacion se anaden dos pasos que recorren el
    segundo post-enfriamiento completo, con la misma pareja de comprobaciones
    que el primero (antes de los 30 s debe seguir encendido; pasados los 30 s
    debe estar apagado). La secuencia pasa a durar 71,2 s, acorde con la
    estimacion de la enmienda.
*)

PROGRAM PRG_Test_B5
VAR CONSTANT
    ULTIMO_PASO : INT := 8;          (* 9 pasos: indices 0..8 *)
END_VAR
VAR
    (* --- Bloque bajo prueba: sustituir por la respuesta a evaluar --- *)
    fb : FB_Ventilador;

    (* --- Entrada manipulada por el banco --- *)
    quemadorOn : BOOL;

    (* --- Control de la secuencia --- *)
    paso       : INT := 0;
    esperado   : BOOL;
    tEspera    : TIME;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    (* --- Resultados: 0 = pendiente, 1 = pasa, 2 = falla --- *)
    resultado : ARRAY[0..8] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Definicion del paso en curso. Va antes del temporizador porque tEspera
      lo alimenta. *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Reposo *)
            quemadorOn := FALSE; tEspera := T#200MS;  esperado := FALSE;
        1:  (* El ventilador acompana al quemador *)
            quemadorOn := TRUE;  tEspera := T#200MS;  esperado := TRUE;

        (* --- Primer post-enfriamiento --- *)
        2:  (* A los 29 s aun debe estar encendido *)
            quemadorOn := FALSE; tEspera := T#29S;    esperado := TRUE;
        3:  (* A los 30,2 s acumulados ya debe estar apagado *)
            quemadorOn := FALSE; tEspera := T#1200MS; esperado := FALSE;

        (* --- Reactivacion durante el post-enfriamiento --- *)
        4:  (* Se reenciende el quemador *)
            quemadorOn := TRUE;  tEspera := T#200MS;  esperado := TRUE;
        5:  (* Se apaga: arranca un post-enfriamiento que aun no vence *)
            quemadorOn := FALSE; tEspera := T#10S;    esperado := TRUE;
        6:  (* Se reenciende EN PLENO post-enfriamiento: debe rearmar *)
            quemadorOn := TRUE;  tEspera := T#200MS;  esperado := TRUE;

        (* --- Segundo post-enfriamiento COMPLETO (enmienda 7):
               no basta con que el temporizador se rearme, tiene que rearmarse
               a los 30 s completos --- *)
        7:  (* A los 29 s del nuevo paro aun debe estar encendido *)
            quemadorOn := FALSE; tEspera := T#29S;    esperado := TRUE;
        8:  (* A los 30,2 s del nuevo paro ya debe estar apagado *)
            quemadorOn := FALSE; tEspera := T#1200MS; esperado := FALSE;
    END_CASE
END_IF

(* 2. Temporizador de asentamiento del paso *)
tPaso(IN := NOT pulsoReset, PT := tEspera);
pulsoReset := FALSE;

(* 3. Llamada al bloque bajo prueba *)
fb(quemadorOn := quemadorOn);

(* 4. Evaluacion al vencer el asentamiento *)
IF tPaso.Q AND NOT finalizado THEN
    IF fb.ventilador = esperado THEN
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
