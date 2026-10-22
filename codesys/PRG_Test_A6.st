(*
    BANCO DE PRUEBA AUTOVERIFICABLE - Tarea A6 (FB_Modos: modos jerarquicos con forzado)
    ---------------------------------------------------------------------------
    Validado en codesys/validar_harness_A6.py: 10 implementaciones (1 correcta y
    9 defectuosas), ciclos de 4, 10 y 20 ms. Tabla generada desde el validador.
    Los patrones de 8 bits se codifican como mascara WORD: bit i = elemento [i].
    cmdManual es siempre M = 11001100 (mascara MASK_MANUAL). confirmarForzado se
    aplica como pulso de UN scan al entrar en el paso.

    Paso: (selector, seguro, cmdAuto, idx, val, pulso) -> (modo, actuadores)
  0 (0,F,A, 0,F,-) -> (1, M)        arranca en manual; sin seguro no cambia
  1 (0,F,A, 0,F,-) -> (1, M)
  2 (0,T,A, 0,F,-) -> (0, A)        el cambio pendiente se aplica al activarse seguro
  3 (5,T,A, 0,F,-) -> (0, A)        fuera de rango: se ignora
  4 (-1,T,A,0,F,-) -> (0, A)
  5 (0,T,A2,0,F,-) -> (0, A2)       sigue a cmdAuto
  6 (2,T,A2,0,F,-) -> (2, 00000000) mantenimiento: todo apagado
  7 (2,T,A2,3,T,P) -> (2, 00010000) fuerza actuador[3]
  8 (2,T,A2,8,T,P) -> (2, 00010000) idx fuera de rango: se ignora
  9 (2,T,A2,5,T,P) -> (2, 00010100)
 10 (2,T,A2,3,F,P) -> (2, 00000100) forzado a FALSE
 11 (2,F,A2,0,F,-) -> (2, 00000000) pierde seguro: anula forzados
 12 (2,T,A2,0,F,-) -> (2, 00000000) vuelve el seguro: siguen anulados
 13 (2,T,A2,0,T,P) -> (2, 10000000)
 14 (1,T,A2,0,F,-) -> (1, M)        sale a manual
 15 (2,T,A2,0,F,-) -> (2, 00000000) los forzados de antes no reaparecen
 16 (0,T,A2,0,F,-) -> (0, A2)
*)
PROGRAM PRG_Test_A6
VAR CONSTANT
    ULTIMO_PASO : INT  := 16;
    T_PASO      : TIME := T#100MS;
    MASK_MANUAL : WORD := 51;
END_VAR
VAR
    fb : FB_Modos;                  (* bloque bajo prueba *)
    selector     : INT;
    estadoSeguro : BOOL;
    cmdAuto      : ARRAY[0..7] OF BOOL;
    cmdManual    : ARRAY[0..7] OF BOOL;
    idxForzado   : INT;
    valorForzado : BOOL;
    confirmarForzado : BOOL;
    mAuto, eMask, mAct : WORD;
    eModo        : INT;
    pulsoStep, pendiente : BOOL;
    pasoCargado  : INT := -1;
    b            : INT;

    paso       : INT := 0;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    resultado : ARRAY[0..16] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Definicion del paso *)
IF NOT finalizado THEN
    CASE paso OF
        0: selector := 0; estadoSeguro := FALSE; mAuto := 85; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 1; eMask := 51;
        1: selector := 0; estadoSeguro := FALSE; mAuto := 85; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 1; eMask := 51;
        2: selector := 0; estadoSeguro := TRUE; mAuto := 85; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 0; eMask := 85;
        3: selector := 5; estadoSeguro := TRUE; mAuto := 85; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 0; eMask := 85;
        4: selector := -1; estadoSeguro := TRUE; mAuto := 85; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 0; eMask := 85;
        5: selector := 0; estadoSeguro := TRUE; mAuto := 102; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 0; eMask := 102;
        6: selector := 2; estadoSeguro := TRUE; mAuto := 102; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 2; eMask := 0;
        7: selector := 2; estadoSeguro := TRUE; mAuto := 102; idxForzado := 3; valorForzado := TRUE; pulsoStep := TRUE; eModo := 2; eMask := 8;
        8: selector := 2; estadoSeguro := TRUE; mAuto := 102; idxForzado := 8; valorForzado := TRUE; pulsoStep := TRUE; eModo := 2; eMask := 8;
        9: selector := 2; estadoSeguro := TRUE; mAuto := 102; idxForzado := 5; valorForzado := TRUE; pulsoStep := TRUE; eModo := 2; eMask := 40;
        10: selector := 2; estadoSeguro := TRUE; mAuto := 102; idxForzado := 3; valorForzado := FALSE; pulsoStep := TRUE; eModo := 2; eMask := 32;
        11: selector := 2; estadoSeguro := FALSE; mAuto := 102; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 2; eMask := 0;
        12: selector := 2; estadoSeguro := TRUE; mAuto := 102; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 2; eMask := 0;
        13: selector := 2; estadoSeguro := TRUE; mAuto := 102; idxForzado := 0; valorForzado := TRUE; pulsoStep := TRUE; eModo := 2; eMask := 1;
        14: selector := 1; estadoSeguro := TRUE; mAuto := 102; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 1; eMask := 51;
        15: selector := 2; estadoSeguro := TRUE; mAuto := 102; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 2; eMask := 0;
        16: selector := 0; estadoSeguro := TRUE; mAuto := 102; idxForzado := 0; valorForzado := FALSE; pulsoStep := FALSE; eModo := 0; eMask := 102;
    END_CASE
END_IF
FOR b := 0 TO 7 DO
    cmdAuto[b] := (SHR(mAuto, b) AND 1) = 1;
    cmdManual[b] := (SHR(MASK_MANUAL, b) AND 1) = 1;
END_FOR

(* 2. Pulso de confirmarForzado de un scan al entrar en el paso *)
IF paso <> pasoCargado THEN
    pendiente := pulsoStep;
    pasoCargado := paso;
END_IF
confirmarForzado := pendiente AND NOT finalizado;
pendiente := FALSE;

(* 3. Asentamiento del paso *)
tPaso(IN := NOT pulsoReset, PT := T_PASO);
pulsoReset := FALSE;

(* 4. Bloque bajo prueba *)
fb(selector := selector, estadoSeguro := estadoSeguro, cmdAuto := cmdAuto, cmdManual := cmdManual,
   idxForzado := idxForzado, valorForzado := valorForzado, confirmarForzado := confirmarForzado);

(* 5. Evaluacion *)
IF tPaso.Q AND NOT finalizado THEN
    mAct := 0;
    FOR b := 0 TO 7 DO
        IF fb.actuador[b] THEN
            mAct := mAct OR SHL(WORD#1, b);
        END_IF
    END_FOR
    IF (fb.modoActivo = eModo) AND (mAct = eMask) THEN
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
