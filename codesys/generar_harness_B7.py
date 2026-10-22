# -*- coding: utf-8 -*-
"""Genera las tres variantes del harness B7 (FUNCTION / FUNCTION_BLOCK / PROGRAM).
Son identicas salvo la declaracion de la instancia y la linea de llamada, para
que la secuencia y la evaluacion sean las mismas sea cual sea el POU elegido."""
import os
AQUI = os.path.dirname(os.path.abspath(__file__))
PLANTILLA = r"""(*
    BANCO DE PRUEBA AUTOVERIFICABLE - Tarea B7 (SelBomba, POU a eleccion)
    VARIANTE: %(variante)s  (generada por generar_harness_B7.py; no editar a mano)
    ---------------------------------------------------------------------------
    Validado en codesys/validar_harness_B7.py: 9 implementaciones (3 correctas,
    una por tipo de POU, y 6 defectuosas), ciclos de 4, 10 y 20 ms.
    Las tres variantes comparten secuencia y evaluacion; solo cambia la llamada.

    Paso (modoAuto, btnManual, nivelBajo) -> bomba
      0 (F,F,F) F   1 (F,T,F) T   2 (F,F,F) F   3 (F,F,T) F   4 (T,F,T) T
      5 (T,F,F) F   6 (T,T,F) F   7 (T,T,T) T   8 (F,T,T) T   9 (F,F,T) F
    Cada paso de TRUE a FALSE delata memoria entre ciclos (el enunciado la prohibe).
*)
PROGRAM PRG_Test_B7
VAR CONSTANT
    ULTIMO_PASO : INT  := 9;
    T_PASO      : TIME := T#100MS;
END_VAR
VAR
%(instancia)s
    modoAuto   : BOOL;
    btnManual  : BOOL;
    nivelBajo  : BOOL;
    bomba      : BOOL;       (* salida leida del POU bajo prueba *)
    esperado   : BOOL;

    paso       : INT := 0;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    resultado : ARRAY[0..9] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Entradas y valor esperado del paso *)
IF NOT finalizado THEN
    CASE paso OF
        0: modoAuto := FALSE; btnManual := FALSE; nivelBajo := FALSE; esperado := FALSE;
        1: modoAuto := FALSE; btnManual := TRUE;  nivelBajo := FALSE; esperado := TRUE;
        2: modoAuto := FALSE; btnManual := FALSE; nivelBajo := FALSE; esperado := FALSE;
        3: modoAuto := FALSE; btnManual := FALSE; nivelBajo := TRUE;  esperado := FALSE;
        4: modoAuto := TRUE;  btnManual := FALSE; nivelBajo := TRUE;  esperado := TRUE;
        5: modoAuto := TRUE;  btnManual := FALSE; nivelBajo := FALSE; esperado := FALSE;
        6: modoAuto := TRUE;  btnManual := TRUE;  nivelBajo := FALSE; esperado := FALSE;
        7: modoAuto := TRUE;  btnManual := TRUE;  nivelBajo := TRUE;  esperado := TRUE;
        8: modoAuto := FALSE; btnManual := TRUE;  nivelBajo := TRUE;  esperado := TRUE;
        9: modoAuto := FALSE; btnManual := FALSE; nivelBajo := TRUE;  esperado := FALSE;
    END_CASE
END_IF

(* 2. Asentamiento del paso *)
tPaso(IN := NOT pulsoReset, PT := T_PASO);
pulsoReset := FALSE;

(* 3. Llamada al POU bajo prueba (%(variante)s) *)
%(llamada)s

(* 4. Evaluacion *)
IF tPaso.Q AND NOT finalizado THEN
    IF bomba = esperado THEN
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
"""
ARGS = "modoAuto := modoAuto, btnManual := btnManual, nivelBajo := nivelBajo"
VARIANTES = {
    "FUN": ("FUNCTION", "    (* sin instancia: SelBomba es una FUNCTION *)",
            "bomba := SelBomba(%s);" % ARGS),
    "FB": ("FUNCTION_BLOCK", "    fb : SelBomba;           (* instancia del FB bajo prueba *)",
           "fb(%s);\nbomba := fb.bomba;" % ARGS),
    "PRG": ("PROGRAM", "    (* sin instancia: SelBomba es un PROGRAM, se llama por su nombre *)",
            "SelBomba(%s);\nbomba := SelBomba.bomba;" % ARGS),
}
for suf, (variante, inst, llamada) in VARIANTES.items():
    with open(os.path.join(AQUI, "PRG_Test_B7_%s.st" % suf), "w") as fh:
        fh.write(PLANTILLA % {"variante": variante, "instancia": inst, "llamada": llamada})
print("3 variantes escritas")
