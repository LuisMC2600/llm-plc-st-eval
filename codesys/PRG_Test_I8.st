(*
    BANCO DE PRUEBA AUTOVERIFICABLE - Tarea I8 (FB_Compresor: permisivos de arranque)
    ---------------------------------------------------------------------------
    Validado en codesys/validar_harness_I8.py: 8 implementaciones (1 correcta y
    7 defectuosas), ciclos de 4, 10 y 20 ms. La tabla de pasos se genera desde
    el validador para que ambos coincidan.

    Paso: entradas (pOil,temp,sinAlm,marcha,paro), duracion -> (comp, causa)
  0 (F,F,F,F,F) 0.2 s -> (F,1)   reposo, faltan todos: reporta el menor
  1 (T,T,T,F,F) 1.0 s -> (F,1)   aceite aun sin 3 s continuos
  2 (T,T,T,F,F) 2.5 s -> (F,0)   permisivos completos: NO arranca solo
  3 (T,T,T,T,F) 0.2 s -> (T,0)   flanco de marcha
  4 (T,T,T,F,F) 0.2 s -> (T,0)   enclavado
  5 (T,F,T,F,F) 0.2 s -> (F,2)   pierde temperatura
  6 (T,T,T,F,F) 0.5 s -> (F,0)   se recupera: sin rearranque automatico
  7 (T,T,T,T,T) 0.2 s -> (F,0)   marcha y paro a la vez: prioridad del paro
  8 (T,T,T,T,F) 0.2 s -> (F,0)   se suelta el paro con marcha sostenida: sin flanco no arranca
  9 (T,T,T,F,F) 0.2 s -> (F,0)
 10 (T,T,T,T,F) 0.2 s -> (T,0)
 11 (T,T,F,F,F) 0.2 s -> (F,3)   alarma
 12 (F,F,F,F,F) 0.2 s -> (F,1)   faltan todos
 13 (T,T,T,T,F) 0.5 s -> (F,1)   pulsa con el aceite aun temporizando (reiniciado)
 14 (T,T,T,T,F) 3.0 s -> (F,0)   llegan los permisivos con marcha sostenida: no arranca
 15 (T,T,T,F,F) 0.2 s -> (F,0)
 16 (T,T,T,T,F) 0.2 s -> (T,0)
 17 (F,T,T,T,F) 0.2 s -> (F,1)   perdida momentanea de aceite: se detiene
 18 (T,T,T,F,F) 0.2 s -> (F,1)   el aceite vuelve pero no lleva 3 s

VIGILANCIA CONTINUA (patron de la enmienda 4, banderas enclavadas): en los pasos
en que comp llega en FALSE y debe seguir en FALSE todo el paso (0,1,2,6,7,8,9,
12,13,14,15,18), un solo scan con comp=TRUE reprueba el paso. Sin ella, la
validacion mostro que "marcha gana al paro" pasaba inadvertido: el compresor
arrancaba UN scan en el paso 7 y se apagaba antes del muestreo.
*)
PROGRAM PRG_Test_I8
VAR CONSTANT
    ULTIMO_PASO : INT := 18;
END_VAR
VAR
    fb : FB_Compresor;              (* bloque bajo prueba *)
    pOilOk, tempOk, sinAlm, btnMarcha, btnParo : BOOL;
    eComp  : BOOL;                  (* esperado *)
    eCausa : INT;

    paso       : INT := 0;
    tEspera    : TIME;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;
    vigilado   : BOOL;
    violacion  : BOOL;              (* bandera enclavada del paso *)

    resultado : ARRAY[0..18] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Entradas, duracion y salidas esperadas del paso *)
IF NOT finalizado THEN
    CASE paso OF
        0: pOilOk := FALSE; tempOk := FALSE; sinAlm := FALSE; btnMarcha := FALSE; btnParo := FALSE;
            tEspera := T#200MS; eComp := FALSE; eCausa := 1;
        1: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := FALSE; btnParo := FALSE;
            tEspera := T#1000MS; eComp := FALSE; eCausa := 1;
        2: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := FALSE; btnParo := FALSE;
            tEspera := T#2500MS; eComp := FALSE; eCausa := 0;
        3: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := TRUE; btnParo := FALSE;
            tEspera := T#200MS; eComp := TRUE; eCausa := 0;
        4: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := FALSE; btnParo := FALSE;
            tEspera := T#200MS; eComp := TRUE; eCausa := 0;
        5: pOilOk := TRUE; tempOk := FALSE; sinAlm := TRUE; btnMarcha := FALSE; btnParo := FALSE;
            tEspera := T#200MS; eComp := FALSE; eCausa := 2;
        6: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := FALSE; btnParo := FALSE;
            tEspera := T#500MS; eComp := FALSE; eCausa := 0;
        7: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := TRUE; btnParo := TRUE;
            tEspera := T#200MS; eComp := FALSE; eCausa := 0;
        8: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := TRUE; btnParo := FALSE;
            tEspera := T#200MS; eComp := FALSE; eCausa := 0;
        9: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := FALSE; btnParo := FALSE;
            tEspera := T#200MS; eComp := FALSE; eCausa := 0;
        10: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := TRUE; btnParo := FALSE;
            tEspera := T#200MS; eComp := TRUE; eCausa := 0;
        11: pOilOk := TRUE; tempOk := TRUE; sinAlm := FALSE; btnMarcha := FALSE; btnParo := FALSE;
            tEspera := T#200MS; eComp := FALSE; eCausa := 3;
        12: pOilOk := FALSE; tempOk := FALSE; sinAlm := FALSE; btnMarcha := FALSE; btnParo := FALSE;
            tEspera := T#200MS; eComp := FALSE; eCausa := 1;
        13: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := TRUE; btnParo := FALSE;
            tEspera := T#500MS; eComp := FALSE; eCausa := 1;
        14: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := TRUE; btnParo := FALSE;
            tEspera := T#3000MS; eComp := FALSE; eCausa := 0;
        15: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := FALSE; btnParo := FALSE;
            tEspera := T#200MS; eComp := FALSE; eCausa := 0;
        16: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := TRUE; btnParo := FALSE;
            tEspera := T#200MS; eComp := TRUE; eCausa := 0;
        17: pOilOk := FALSE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := TRUE; btnParo := FALSE;
            tEspera := T#200MS; eComp := FALSE; eCausa := 1;
        18: pOilOk := TRUE; tempOk := TRUE; sinAlm := TRUE; btnMarcha := FALSE; btnParo := FALSE;
            tEspera := T#200MS; eComp := FALSE; eCausa := 1;
    END_CASE
END_IF

(* 2. Asentamiento del paso *)
tPaso(IN := NOT pulsoReset, PT := tEspera);
pulsoReset := FALSE;

(* 3. Bloque bajo prueba *)
fb(pOilOk := pOilOk, tempOk := tempOk, sinAlm := sinAlm, btnMarcha := btnMarcha, btnParo := btnParo);

(* 4. Vigilancia continua: comp no puede valer TRUE ni un scan en estos pasos *)
CASE paso OF
    0, 1, 2, 6, 7, 8, 9, 12, 13, 14, 15, 18: vigilado := TRUE;
ELSE
    vigilado := FALSE;
END_CASE
IF vigilado AND fb.comp AND NOT finalizado THEN
    violacion := TRUE;
END_IF

(* 5. Evaluacion *)
IF tPaso.Q AND NOT finalizado THEN
    IF (fb.comp = eComp) AND (fb.causaBloqueo = eCausa) AND NOT violacion THEN
        resultado[paso] := 1;
    ELSE
        resultado[paso] := 2;
    END_IF
    violacion := FALSE;
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
