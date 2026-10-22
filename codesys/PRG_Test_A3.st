(*
    BANCO DE PRUEBA AUTOVERIFICABLE - Tarea A3 (FB_Com: peticion/respuesta con reintentos)
    ---------------------------------------------------------------------------
    Validado en codesys/validar_harness_A3.py: 9 implementaciones (1 correcta y
    8 defectuosas), ciclos de 4, 10 y 20 ms. Tabla generada desde el validador.
    rxOk se aplica como pulso de UN scan al entrar en el paso (ver validador).
    eN = -1 o eTx = -1: ese valor no se evalua en el paso.

    Paso: (txReq, pulso rxOk, rxData) duracion -> (ocupado, ok, error, nIntentos, txData)   [- = no se evalua]
  0 (F,-,0)   0.20 s -> (F,F,F,-,-)  reposo
  1 (T,-,0)   0.20 s -> (T,F,F,1,100) flanco: intento 1
  2 (F,-,0)   0.20 s -> (T,F,F,1,-)   0.40 s: aun intento 1   (plazo corto)
  3 (F,-,0)   0.25 s -> (T,F,F,2,-)   0.65 s: intento 2        (plazo largo / sin reintento)
  4 (F,P,100) 0.20 s -> (F,T,F,2,-)   eco correcto: ok, conserva nIntentos=2
  5 (F,-,0)   0.30 s -> (F,T,F,2,-)   ok permanece
  6 (T,-,0)   0.10 s -> (T,F,F,1,100) nuevo intercambio: ok se borra
  7 (F,P,55)  0.10 s -> (T,F,F,2,-)   eco erroneo: falla el intento 1
  8 (T,-,0)   0.10 s -> (T,F,F,2,-)   flanco de txReq durante el intercambio: se ignora
  9 (T,-,0)   0.50 s -> (T,F,F,3,-)   vence el intento 2
 10 (T,-,0)   0.40 s -> (F,F,T,3,-)   vence el intento 3: error
 11 (F,-,0)   0.30 s -> (F,F,T,3,-)   error permanece, nIntentos se conserva
 12 (T,-,0)   0.20 s -> (T,F,F,1,100) nuevo intercambio: error se borra
 13 (T,-,0)   0.20 s -> (T,F,F,1,-)   ~0.41-0.46 s del intento 1 (segun el ciclo)
 14 (T,P,100) 0.20 s -> (F,T,F,1,-)   eco al inicio del paso: dentro del plazo (plazo demasiado corto)
NOTA: la primera version usaba 0.25 s en el paso 13 y REPROBABA a la correcta con
ciclo de 20 ms (el eco llegaba a ~0.51 s): cada cambio de paso consume un scan.
*)
PROGRAM PRG_Test_A3
VAR CONSTANT
    ULTIMO_PASO : INT := 14;
END_VAR
VAR
    fb : FB_Com;                    (* bloque bajo prueba *)
    txReq, rxOk : BOOL;
    rxData      : INT;
    pulsoStep   : BOOL;             (* el paso aplica un pulso de rxOk *)
    pendiente   : BOOL;
    pasoCargado : INT := -1;
    eOcup, eOk, eErr : BOOL;
    eN, eTx     : INT;

    paso       : INT := 0;
    tEspera    : TIME;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    resultado : ARRAY[0..14] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Entradas, duracion y valores esperados del paso *)
IF NOT finalizado THEN
    CASE paso OF
        0: txReq := FALSE; pulsoStep := FALSE; rxData := 0; tEspera := T#200MS;
            eOcup := FALSE; eOk := FALSE; eErr := FALSE; eN := -1; eTx := -1;
        1: txReq := TRUE; pulsoStep := FALSE; rxData := 0; tEspera := T#200MS;
            eOcup := TRUE; eOk := FALSE; eErr := FALSE; eN := 1; eTx := 100;
        2: txReq := FALSE; pulsoStep := FALSE; rxData := 0; tEspera := T#200MS;
            eOcup := TRUE; eOk := FALSE; eErr := FALSE; eN := 1; eTx := -1;
        3: txReq := FALSE; pulsoStep := FALSE; rxData := 0; tEspera := T#250MS;
            eOcup := TRUE; eOk := FALSE; eErr := FALSE; eN := 2; eTx := -1;
        4: txReq := FALSE; pulsoStep := TRUE; rxData := 100; tEspera := T#200MS;
            eOcup := FALSE; eOk := TRUE; eErr := FALSE; eN := 2; eTx := -1;
        5: txReq := FALSE; pulsoStep := FALSE; rxData := 0; tEspera := T#300MS;
            eOcup := FALSE; eOk := TRUE; eErr := FALSE; eN := 2; eTx := -1;
        6: txReq := TRUE; pulsoStep := FALSE; rxData := 0; tEspera := T#100MS;
            eOcup := TRUE; eOk := FALSE; eErr := FALSE; eN := 1; eTx := 100;
        7: txReq := FALSE; pulsoStep := TRUE; rxData := 55; tEspera := T#100MS;
            eOcup := TRUE; eOk := FALSE; eErr := FALSE; eN := 2; eTx := -1;
        8: txReq := TRUE; pulsoStep := FALSE; rxData := 0; tEspera := T#100MS;
            eOcup := TRUE; eOk := FALSE; eErr := FALSE; eN := 2; eTx := -1;
        9: txReq := TRUE; pulsoStep := FALSE; rxData := 0; tEspera := T#500MS;
            eOcup := TRUE; eOk := FALSE; eErr := FALSE; eN := 3; eTx := -1;
        10: txReq := TRUE; pulsoStep := FALSE; rxData := 0; tEspera := T#400MS;
            eOcup := FALSE; eOk := FALSE; eErr := TRUE; eN := 3; eTx := -1;
        11: txReq := FALSE; pulsoStep := FALSE; rxData := 0; tEspera := T#300MS;
            eOcup := FALSE; eOk := FALSE; eErr := TRUE; eN := 3; eTx := -1;
        12: txReq := TRUE; pulsoStep := FALSE; rxData := 0; tEspera := T#200MS;
            eOcup := TRUE; eOk := FALSE; eErr := FALSE; eN := 1; eTx := 100;
        13: txReq := TRUE; pulsoStep := FALSE; rxData := 0; tEspera := T#200MS;
            eOcup := TRUE; eOk := FALSE; eErr := FALSE; eN := 1; eTx := -1;
        14: txReq := TRUE; pulsoStep := TRUE; rxData := 100; tEspera := T#200MS;
            eOcup := FALSE; eOk := TRUE; eErr := FALSE; eN := 1; eTx := -1;
    END_CASE
END_IF

(* 2. Pulso de rxOk de un solo scan al entrar en el paso *)
IF paso <> pasoCargado THEN
    pendiente := pulsoStep;
    pasoCargado := paso;
END_IF
rxOk := pendiente AND NOT finalizado;
pendiente := FALSE;

(* 3. Asentamiento del paso *)
tPaso(IN := NOT pulsoReset, PT := tEspera);
pulsoReset := FALSE;

(* 4. Bloque bajo prueba *)
fb(txReq := txReq, rxOk := rxOk, rxData := rxData);

(* 5. Evaluacion *)
IF tPaso.Q AND NOT finalizado THEN
    IF (fb.ocupado = eOcup) AND (fb.ok = eOk) AND (fb.error = eErr)
       AND ((eN < 0) OR (fb.nIntentos = eN)) AND ((eTx < 0) OR (fb.txData = eTx)) THEN
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

(* 6. Veredicto global *)
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
