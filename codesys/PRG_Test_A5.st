(*
    BANCO DE PRUEBA AUTOVERIFICABLE - Tarea A5 (FB_Registro: buffer circular de eventos)
    ---------------------------------------------------------------------------
    Validado en codesys/validar_harness_A5.py: 9 implementaciones (2 correctas,
    que acumulan el tiempo antes y despues de registrar, y 7 defectuosas).
    Tabla generada desde el validador.
    TIEMPO VIRTUAL: ciclo := T#10MS fijo; pasos por numero de llamadas (una por
    scan). Para el ultimo evento se acepta marca = g*10 ms o (g-1)*10 ms.
    pM/p2 = -1: no se comprueba contenido en ese paso.

    Paso: llamadas/eventos -> (indice, nEventos, comprobacion de contenido)
  0 5 llamadas sin evento ..................... (-1, 0)
  1 evento 11 con nuevoEvento sostenido 3 llamadas (0, 1)  buffer[0]=11 + marca
  2 2 llamadas sin flanco ..................... (0, 1)
  3 19 eventos (12..30) ....................... (19, 20) buffer[19]=30 + marca; buffer[0]=11
  4 1 evento (31): sobrescribe el mas antiguo . (0, 20)  buffer[0]=31 + marca; buffer[1]=12
  5 2 eventos (32, 33) ........................ (2, 20)  buffer[2]=33 + marca; buffer[3]=14
*)
PROGRAM PRG_Test_A5
VAR CONSTANT
    ULTIMO_PASO : INT := 5;
END_VAR
VAR
    fb : FB_Registro;               (* bloque bajo prueba *)
    evento      : INT;
    nuevoEvento : BOOL;
    prevNuevo   : BOOL;
    nEv, libres, sost, cod0 : INT;  (* definicion del paso *)
    eIdx, eN, pM, cM, p2, c2 : INT; (* comprobaciones del paso *)
    L, k        : INT;              (* llamadas del paso / hechas *)
    g, gUlt     : DINT;             (* llamadas totales / del ultimo flanco *)
    bien        : BOOL;
    paso        : INT := 0;
    finalizado  : BOOL;

    resultado : ARRAY[0..5] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

IF NOT finalizado THEN
    (* 1. Definicion del paso *)
    CASE paso OF
        0: nEv := 0; libres := 5; sost := 0; cod0 := 0; eIdx := -1; eN := 0; pM := -1; cM := 0; p2 := -1; c2 := 0;
        1: nEv := 1; libres := 0; sost := 3; cod0 := 11; eIdx := 0; eN := 1; pM := 0; cM := 11; p2 := -1; c2 := 0;
        2: nEv := 0; libres := 2; sost := 0; cod0 := 0; eIdx := 0; eN := 1; pM := -1; cM := 0; p2 := -1; c2 := 0;
        3: nEv := 19; libres := 0; sost := 0; cod0 := 12; eIdx := 19; eN := 20; pM := 19; cM := 30; p2 := 0; c2 := 11;
        4: nEv := 1; libres := 0; sost := 0; cod0 := 31; eIdx := 0; eN := 20; pM := 0; cM := 31; p2 := 1; c2 := 12;
        5: nEv := 2; libres := 0; sost := 0; cod0 := 32; eIdx := 2; eN := 20; pM := 2; cM := 33; p2 := 3; c2 := 14;
    END_CASE
    IF sost > 0 THEN
        L := sost + libres;
    ELSE
        L := 2 * nEv + libres;
    END_IF

    (* 2. Entradas de esta llamada *)
    IF sost > 0 THEN
        IF k < sost THEN
            evento := cod0; nuevoEvento := TRUE;
        ELSE
            evento := 0; nuevoEvento := FALSE;
        END_IF
    ELSIF k < 2 * nEv THEN
        evento := cod0 + k / 2;
        nuevoEvento := (k MOD 2) = 0;
    ELSE
        evento := 0; nuevoEvento := FALSE;
    END_IF

    (* 3. Llamada con ciclo virtual de 10 ms *)
    g := g + 1;
    fb(evento := evento, nuevoEvento := nuevoEvento, ciclo := T#10MS);
    IF nuevoEvento AND NOT prevNuevo THEN
        gUlt := g;
    END_IF
    prevNuevo := nuevoEvento;
    k := k + 1;

    (* 4. Evaluacion al completar el paso *)
    IF k >= L THEN
        bien := (fb.indice = eIdx) AND (fb.nEventos = eN);
        IF pM >= 0 THEN
            bien := bien AND (fb.buffer[pM].codigo = cM)
                    AND ((fb.buffer[pM].marca = DINT_TO_TIME(gUlt * 10)) OR (fb.buffer[pM].marca = DINT_TO_TIME((gUlt - 1) * 10)));
        END_IF
        IF p2 >= 0 THEN
            bien := bien AND (fb.buffer[p2].codigo = c2);
        END_IF
        IF bien THEN
            resultado[paso] := 1;
        ELSE
            resultado[paso] := 2;
        END_IF
        k := 0;
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
