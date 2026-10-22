(*
    BANCO DE PRUEBA AUTOVERIFICABLE - Tarea A2 (FB_Batch: receta por lotes de 5 fases)
    ---------------------------------------------------------------------------
    Validado en codesys/validar_harness_A2.py: 9 implementaciones (1 correcta y
    8 defectuosas), ciclos de 4, 10 y 20 ms. Tabla generada desde el validador.
    Al final de cada paso se exige la fase esperada y que este activa exactamente
    la salida de esa fase (fase 0: ninguna).

    Paso: (nA,nB,nVac,ini,abo,temp) duracion -> fase esperada
  0 (F,F,F,F,F,20)   0.2 s -> 0   reposo CON producto
  1 (F,F,F,F,T,20)   0.2 s -> 0   abort en reposo: sin efecto
  2 (F,F,F,T,F,20)   0.2 s -> 1   inicio
  3 (F,F,F,F,F,20)   0.2 s -> 1   espera nivelA
  4 (T,F,F,F,F,20)   0.2 s -> 2
  5 (T,F,F,T,F,20)   0.2 s -> 2   inicio durante la receta: se ignora
  6 (T,T,F,F,F,20)   0.2 s -> 3
  7 (T,T,F,F,F,59.9) 0.2 s -> 3   59.9 no basta
  8 (T,T,F,F,F,60.0) 0.2 s -> 4   60.0 o mas
  9 (T,T,F,F,F,60.0) 118  s -> 4   mezcla: aun no cumple 120 s
 10 (T,T,F,F,F,60.0) 3.0 s -> 5   ya cumplio
 11 (T,T,T,F,F,60.0) 0.2 s -> 0   vacio: reposo
 12 (F,F,F,T,F,20)   0.2 s -> 1   nueva receta (con producto)
 13 (F,F,F,F,T,20)   0.2 s -> 5   abort con producto: descarga
 14 (F,F,F,F,F,20)   0.2 s -> 5   sigue descargando
 15 (F,F,T,F,F,20)   0.2 s -> 0
 16 (F,F,T,T,F,20)   0.2 s -> 1   receta con reactor vacio
 17 (F,F,T,F,T,20)   0.2 s -> 0   abort sin producto: directo a reposo
 18 (F,F,F,T,F,20)   0.2 s -> 1
 19 (T,F,F,F,F,20)   0.2 s -> 2
 20 (T,T,F,F,F,20)   0.2 s -> 3   calentando
 21 (T,T,F,F,T,20)   0.2 s -> 5   abort en fase 3: calentador cerrado, descarga
 22 (T,T,F,F,F,20)   0.2 s -> 5
 23 (T,T,F,F,T,20)   0.2 s -> 5   abort durante la descarga: continua
 24 (T,T,T,F,F,20)   0.2 s -> 0
*)
PROGRAM PRG_Test_A2
VAR CONSTANT
    ULTIMO_PASO : INT := 24;
END_VAR
VAR
    fb : FB_Batch;                  (* bloque bajo prueba *)
    nivelA, nivelB, nivelVacio, btnInicio, btnAbort : BOOL;
    temp  : REAL;
    eFase : INT;
    salidasOk : BOOL;

    paso       : INT := 0;
    tEspera    : TIME;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    resultado : ARRAY[0..24] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Entradas, duracion y fase esperada del paso *)
IF NOT finalizado THEN
    CASE paso OF
        0: nivelA := FALSE; nivelB := FALSE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 0;
        1: nivelA := FALSE; nivelB := FALSE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := TRUE;
            temp := 20.0; tEspera := T#200MS; eFase := 0;
        2: nivelA := FALSE; nivelB := FALSE; nivelVacio := FALSE; btnInicio := TRUE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 1;
        3: nivelA := FALSE; nivelB := FALSE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 1;
        4: nivelA := TRUE; nivelB := FALSE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 2;
        5: nivelA := TRUE; nivelB := FALSE; nivelVacio := FALSE; btnInicio := TRUE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 2;
        6: nivelA := TRUE; nivelB := TRUE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 3;
        7: nivelA := TRUE; nivelB := TRUE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 59.9; tEspera := T#200MS; eFase := 3;
        8: nivelA := TRUE; nivelB := TRUE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 60.0; tEspera := T#200MS; eFase := 4;
        9: nivelA := TRUE; nivelB := TRUE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 60.0; tEspera := T#118000MS; eFase := 4;
        10: nivelA := TRUE; nivelB := TRUE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 60.0; tEspera := T#3000MS; eFase := 5;
        11: nivelA := TRUE; nivelB := TRUE; nivelVacio := TRUE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 60.0; tEspera := T#200MS; eFase := 0;
        12: nivelA := FALSE; nivelB := FALSE; nivelVacio := FALSE; btnInicio := TRUE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 1;
        13: nivelA := FALSE; nivelB := FALSE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := TRUE;
            temp := 20.0; tEspera := T#200MS; eFase := 5;
        14: nivelA := FALSE; nivelB := FALSE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 5;
        15: nivelA := FALSE; nivelB := FALSE; nivelVacio := TRUE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 0;
        16: nivelA := FALSE; nivelB := FALSE; nivelVacio := TRUE; btnInicio := TRUE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 1;
        17: nivelA := FALSE; nivelB := FALSE; nivelVacio := TRUE; btnInicio := FALSE; btnAbort := TRUE;
            temp := 20.0; tEspera := T#200MS; eFase := 0;
        18: nivelA := FALSE; nivelB := FALSE; nivelVacio := FALSE; btnInicio := TRUE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 1;
        19: nivelA := TRUE; nivelB := FALSE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 2;
        20: nivelA := TRUE; nivelB := TRUE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 3;
        21: nivelA := TRUE; nivelB := TRUE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := TRUE;
            temp := 20.0; tEspera := T#200MS; eFase := 5;
        22: nivelA := TRUE; nivelB := TRUE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 5;
        23: nivelA := TRUE; nivelB := TRUE; nivelVacio := FALSE; btnInicio := FALSE; btnAbort := TRUE;
            temp := 20.0; tEspera := T#200MS; eFase := 5;
        24: nivelA := TRUE; nivelB := TRUE; nivelVacio := TRUE; btnInicio := FALSE; btnAbort := FALSE;
            temp := 20.0; tEspera := T#200MS; eFase := 0;
    END_CASE
END_IF

(* 2. Asentamiento del paso *)
tPaso(IN := NOT pulsoReset, PT := tEspera);
pulsoReset := FALSE;

(* 3. Bloque bajo prueba *)
fb(nivelA := nivelA, nivelB := nivelB, nivelVacio := nivelVacio, btnInicio := btnInicio,
   btnAbort := btnAbort, temp := temp);

(* 4. Evaluacion: fase y exactamente la salida de esa fase *)
IF tPaso.Q AND NOT finalizado THEN
    salidasOk := (fb.vA = (eFase = 1)) AND (fb.vB = (eFase = 2)) AND (fb.calentador = (eFase = 3))
                 AND (fb.mezclador = (eFase = 4)) AND (fb.vDescarga = (eFase = 5));
    IF (fb.fase = eFase) AND salidasOk THEN
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
