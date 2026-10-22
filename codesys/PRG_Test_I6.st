(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea I6 (escalado analogico con histeresis)
    ---------------------------------------------------------------------------
    rawTemp de 0 a 27648 se escala a tempC de 0.0 a 100.0 grados. El enfriador
    se activa cuando tempC alcanza 80.0 y se desactiva cuando desciende a 75.0,
    conservando su estado entre ambos umbrales. Si rawTemp queda fuera del
    rango se activa almSensor Y SE DESACTIVA EL ENFRIADOR.

    Se comprueba la histeresis en LOS DOS SENTIDOS: conserva el estado ON al
    bajar dentro de la banda y conserva el estado OFF al subir dentro de ella.

    USO: crear este PROGRAM junto al FUNCTION_BLOCK de la respuesta a evaluar y
    ejecutar en modo Simulacion. Al terminar, leer 'veredicto': 1 = supera,
    2 = falla.

    ---------------------------------------------------------------------------
    CORRECCION DEL 2026-09-09 (enmienda 13). Validado con validar_harness_I6.py.
    La version anterior daba veredicto 1 a una implementacion que activaba la
    alarma pero NO desactivaba el enfriador, incumpliendo la ultima frase del
    enunciado.

    Causa: los dos pasos de fuera de rango estaban al final de la secuencia,
    cuando el enfriador ya llevaba tres pasos apagado. La condicion "y se
    desactiva el enfriador" se evaluaba sobre una salida que ya estaba en el
    valor esperado, de modo que la implementacion defectuosa y la correcta
    daban el mismo resultado. Para observar que la alarma APAGA el enfriador
    hay que provocarla con el enfriador ENCENDIDO.

    Es el mismo patron de cobertura de las enmiendas 7, 9, 10 y 12: el banco no
    llegaba al estado en el que el defecto se manifiesta.

    Correccion: el primer paso de fuera de rango se adelanta y pasa a aplicarse
    justo despues de la banda de histeresis con el enfriador encendido. La
    secuencia conserva los ocho pasos y sigue cubriendo los dos sentidos de la
    histeresis y los dos limites del rango.
*)

PROGRAM PRG_Test_I6
VAR CONSTANT
    ULTIMO_PASO    : INT  := 7;
    T_ASENTAMIENTO : TIME := T#100MS;
    RAW_MAX        : INT  := 27648;
END_VAR
VAR
    (* --- Bloque bajo prueba: sustituir por la respuesta a evaluar --- *)
    fb : FB_Temperatura;

    (* --- Entrada manipulada por el banco --- *)
    rawTemp : INT;

    (* --- Control de la secuencia --- *)
    espTemp    : REAL;
    espFrio    : BOOL;
    espAlarma  : BOOL;
    compTemp   : BOOL;                (* FALSE fuera de rango: tempC indefinida *)
    paso       : INT := 0;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    (* --- Resultados: 0 = pendiente, 1 = pasa, 2 = falla --- *)
    resultado : ARRAY[0..7] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Temporizador de asentamiento entre pasos *)
tPaso(IN := NOT pulsoReset, PT := T_ASENTAMIENTO);
pulsoReset := FALSE;

(* 2. Definicion del paso en curso *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Punto medio del rango *)
            rawTemp := 13824; espTemp := 50.0;
            espFrio := FALSE; espAlarma := FALSE; compTemp := TRUE;
        1:  (* Umbral superior: el enfriador debe activarse *)
            rawTemp := 22119; espTemp := 80.0;
            espFrio := TRUE;  espAlarma := FALSE; compTemp := TRUE;
        2:  (* Dentro de la banda bajando: debe CONSERVAR el estado ON *)
            rawTemp := 21289; espTemp := 77.0;
            espFrio := TRUE;  espAlarma := FALSE; compTemp := TRUE;
        3:  (* Fuera de rango CON EL ENFRIADOR ENCENDIDO (enmienda 13):
               la alarma debe activarse y el enfriador debe apagarse *)
            rawTemp := 27649; espTemp := 0.0;
            espFrio := FALSE; espAlarma := TRUE;  compTemp := FALSE;
        4:  (* Vuelve al rango en el umbral inferior: enfriador apagado *)
            rawTemp := 20736; espTemp := 75.0;
            espFrio := FALSE; espAlarma := FALSE; compTemp := TRUE;
        5:  (* Dentro de la banda subiendo: debe CONSERVAR el estado OFF *)
            rawTemp := 21289; espTemp := 77.0;
            espFrio := FALSE; espAlarma := FALSE; compTemp := TRUE;
        6:  (* Fuera de rango por el limite inferior *)
            rawTemp := -1;    espTemp := 0.0;
            espFrio := FALSE; espAlarma := TRUE;  compTemp := FALSE;
        7:  (* Vuelve al rango: la alarma debe desactivarse *)
            rawTemp := 0;     espTemp := 0.0;
            espFrio := FALSE; espAlarma := FALSE; compTemp := TRUE;
    END_CASE
END_IF

(* 3. Llamada al bloque bajo prueba *)
fb(rawTemp := rawTemp);

(* 4. Evaluacion al vencer el asentamiento. tempC solo se comprueba dentro
      del rango: fuera de el su valor no esta definido por el enunciado. *)
IF tPaso.Q AND NOT finalizado THEN
    IF     fb.enfriador = espFrio
       AND fb.almSensor = espAlarma
       AND ((NOT compTemp)
            OR ((fb.tempC > espTemp - 0.1) AND (fb.tempC < espTemp + 0.1)))
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
