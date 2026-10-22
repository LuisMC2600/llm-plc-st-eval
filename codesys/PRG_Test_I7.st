(*
    BANCO DE PRUEBA AUTOVERIFICABLE - Tarea I7 (FB_Duplex: bombas duplex con alternancia)
    ---------------------------------------------------------------------------
    Validado en codesys/validar_harness_I7.py: 10 implementaciones (la correcta,
    el FB de referencia del prompt de C4 y 8 defectuosas), ciclos de 4, 10 y 20 ms.
    La tabla de pasos se genera desde el validador para que ambos coincidan.

    Paso (demanda, falla1, falla2) -> (bomba1, bomba2, almFalla)   principal
  0  (F,F,F) -> (F,F,F)                                          -
  1  (T,F,F) -> (T,F,F)   primera demanda                        b1
  2  (F,F,F) -> (F,F,F)
  3  (T,F,F) -> (F,T,F)   alterna                                b2
  4  (F,F,F) -> (F,F,F)
  5  (T,F,F) -> (T,F,F)   alterna de nuevo                       b1
  6  (T,T,F) -> (F,T,T)   falla de la principal: respaldo        b1
  7  (T,F,F) -> (T,F,F)   vuelve la principal                    b1
  8  (T,F,T) -> (T,F,F)   falla SOLO del respaldo: sin alarma    b1
  9  (T,T,T) -> (F,F,T)   ambas con falla                        b1
 10  (F,T,T) -> (F,F,F)   sin demanda: sin alarma aunque haya fallas
 11  (T,F,F) -> (F,T,F)   cuarta demanda                         b2
 12  (T,F,T) -> (T,F,T)   falla de la principal b2: respaldo b1  b2
 13  (F,F,F) -> (F,F,F)
*)
PROGRAM PRG_Test_I7
VAR CONSTANT
    ULTIMO_PASO : INT  := 13;
    T_PASO      : TIME := T#100MS;
END_VAR
VAR
    fb : FB_Duplex;                 (* bloque bajo prueba *)
    demanda, falla1, falla2 : BOOL;
    e1, e2, eAlm : BOOL;            (* esperados: bomba1, bomba2, almFalla *)

    paso       : INT := 0;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    resultado : ARRAY[0..13] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Entradas y salidas esperadas del paso *)
IF NOT finalizado THEN
    CASE paso OF
        0: demanda := FALSE; falla1 := FALSE; falla2 := FALSE;
            e1 := FALSE; e2 := FALSE; eAlm := FALSE;
        1: demanda := TRUE; falla1 := FALSE; falla2 := FALSE;
            e1 := TRUE; e2 := FALSE; eAlm := FALSE;
        2: demanda := FALSE; falla1 := FALSE; falla2 := FALSE;
            e1 := FALSE; e2 := FALSE; eAlm := FALSE;
        3: demanda := TRUE; falla1 := FALSE; falla2 := FALSE;
            e1 := FALSE; e2 := TRUE; eAlm := FALSE;
        4: demanda := FALSE; falla1 := FALSE; falla2 := FALSE;
            e1 := FALSE; e2 := FALSE; eAlm := FALSE;
        5: demanda := TRUE; falla1 := FALSE; falla2 := FALSE;
            e1 := TRUE; e2 := FALSE; eAlm := FALSE;
        6: demanda := TRUE; falla1 := TRUE; falla2 := FALSE;
            e1 := FALSE; e2 := TRUE; eAlm := TRUE;
        7: demanda := TRUE; falla1 := FALSE; falla2 := FALSE;
            e1 := TRUE; e2 := FALSE; eAlm := FALSE;
        8: demanda := TRUE; falla1 := FALSE; falla2 := TRUE;
            e1 := TRUE; e2 := FALSE; eAlm := FALSE;
        9: demanda := TRUE; falla1 := TRUE; falla2 := TRUE;
            e1 := FALSE; e2 := FALSE; eAlm := TRUE;
        10: demanda := FALSE; falla1 := TRUE; falla2 := TRUE;
            e1 := FALSE; e2 := FALSE; eAlm := FALSE;
        11: demanda := TRUE; falla1 := FALSE; falla2 := FALSE;
            e1 := FALSE; e2 := TRUE; eAlm := FALSE;
        12: demanda := TRUE; falla1 := FALSE; falla2 := TRUE;
            e1 := TRUE; e2 := FALSE; eAlm := TRUE;
        13: demanda := FALSE; falla1 := FALSE; falla2 := FALSE;
            e1 := FALSE; e2 := FALSE; eAlm := FALSE;
    END_CASE
END_IF

(* 2. Asentamiento del paso *)
tPaso(IN := NOT pulsoReset, PT := T_PASO);
pulsoReset := FALSE;

(* 3. Bloque bajo prueba *)
fb(demanda := demanda, falla1 := falla1, falla2 := falla2);

(* 4. Evaluacion *)
IF tPaso.Q AND NOT finalizado THEN
    IF (fb.bomba1 = e1) AND (fb.bomba2 = e2) AND (fb.almFalla = eAlm) THEN
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
