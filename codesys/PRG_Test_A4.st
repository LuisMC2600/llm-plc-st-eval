(*
    BANCO DE PRUEBA AUTOVERIFICABLE - Tarea A4 (FB_Rampa: consigna con rampa)
    ---------------------------------------------------------------------------
    Validado en codesys/validar_harness_A4.py: 8 implementaciones (1 correcta y
    7 defectuosas). Tabla generada desde el validador.

    TIEMPO VIRTUAL: se pasa siempre ciclo := T#10MS y cada paso dura un NUMERO DE
    LLAMADAS (una por scan), no un tiempo. El resultado no depende del ciclo real.
    Tolerancia 0.01 en el valor final del paso; vigilancia de sobrepaso con 0.001
    (vig = 1: CVvel <= objetivo; vig = 2: CVvel >= objetivo, en cada llamada).

    Paso: (SP, paro) llamadas -> CVvel esperado   [vigilancia]
  0 (0.05,F)  1 ->  0.05   escalon menor que el incremento (0.1): sin sobrepaso [CV <= 0.05]
  1 ( 0,F)    1 ->  0.0    idem al bajar                                        [CV >= 0]
  2 (50,F)  300 -> 30.0    subida 10 %/s
  3 (50,F)  300 -> 50.0    llega y se queda           [CV <= 50]
  4 (20,F)  100 -> 30.0    bajada 20 %/s
  5 (20,F)  100 -> 20.0                               [CV >= 20]
  6 (80,F)  200 -> 40.0
  7 (80,T)   50 -> 20.0    paro rapido 40 %/s
  8 (80,T)  100 ->  0.0                               [CV >= 0]
  9 (80,T)   50 ->  0.0    permanece en 0 con paro    [CV <= 0]
 10 (80,F)  100 -> 10.0    sin paro: vuelve a subir
 11 (10.05,F) 1 -> 10.05                              [CV <= 10.05]
 12 ( 9,F)   10 ->  9.0                               [CV >= 9]
El sobrepaso se prueba PRIMERO (pasos 0 y 1), desde 0.0 y sin acumulacion previa:
asi el paso de fallo de un bloque que no acota no depende del redondeo de REAL
de 32 bits frente al float de 64 bits del validador.
*)
PROGRAM PRG_Test_A4
VAR CONSTANT
    ULTIMO_PASO : INT  := 12;
    TOL         : REAL := 0.01;
    TOL_VIG     : REAL := 0.001;
END_VAR
VAR
    fb : FB_Rampa;                  (* bloque bajo prueba *)
    SPvel      : REAL;
    paroRapido : BOOL;
    nLlamadas  : INT;               (* llamadas del paso *)
    k          : INT;               (* llamadas hechas en el paso *)
    eCV        : REAL;
    vig        : INT;
    violacion  : BOOL;
    paso       : INT := 0;
    finalizado : BOOL;

    resultado : ARRAY[0..12] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

IF NOT finalizado THEN
    (* 1. Definicion del paso *)
    CASE paso OF
        0: SPvel := 0.05; paroRapido := FALSE; nLlamadas := 1; eCV := 0.05; vig := 1;
        1: SPvel := 0.0; paroRapido := FALSE; nLlamadas := 1; eCV := 0.0; vig := 2;
        2: SPvel := 50.0; paroRapido := FALSE; nLlamadas := 300; eCV := 30.0; vig := 0;
        3: SPvel := 50.0; paroRapido := FALSE; nLlamadas := 300; eCV := 50.0; vig := 1;
        4: SPvel := 20.0; paroRapido := FALSE; nLlamadas := 100; eCV := 30.0; vig := 0;
        5: SPvel := 20.0; paroRapido := FALSE; nLlamadas := 100; eCV := 20.0; vig := 2;
        6: SPvel := 80.0; paroRapido := FALSE; nLlamadas := 200; eCV := 40.0; vig := 0;
        7: SPvel := 80.0; paroRapido := TRUE; nLlamadas := 50; eCV := 20.0; vig := 0;
        8: SPvel := 80.0; paroRapido := TRUE; nLlamadas := 100; eCV := 0.0; vig := 2;
        9: SPvel := 80.0; paroRapido := TRUE; nLlamadas := 50; eCV := 0.0; vig := 1;
        10: SPvel := 80.0; paroRapido := FALSE; nLlamadas := 100; eCV := 10.0; vig := 0;
        11: SPvel := 10.05; paroRapido := FALSE; nLlamadas := 1; eCV := 10.05; vig := 1;
        12: SPvel := 9.0; paroRapido := FALSE; nLlamadas := 10; eCV := 9.0; vig := 2;
    END_CASE

    (* 2. Una llamada por scan con ciclo virtual de 10 ms *)
    fb(SPvel := SPvel, paroRapido := paroRapido, ciclo := T#10MS);
    k := k + 1;

    (* 3. Vigilancia de sobrepaso *)
    IF ((vig = 1) AND (fb.CVvel > eCV + TOL_VIG)) OR ((vig = 2) AND (fb.CVvel < eCV - TOL_VIG)) THEN
        violacion := TRUE;
    END_IF

    (* 4. Evaluacion al completar las llamadas del paso *)
    IF k >= nLlamadas THEN
        IF (ABS(fb.CVvel - eCV) <= TOL) AND NOT violacion THEN
            resultado[paso] := 1;
        ELSE
            resultado[paso] := 2;
        END_IF
        k := 0;
        violacion := FALSE;
        IF paso < ULTIMO_PASO THEN
            paso := paso + 1;
        ELSE
            finalizado := TRUE;
        END_IF
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
