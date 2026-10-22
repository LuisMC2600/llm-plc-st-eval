(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea B1 (arranque/paro con enclavamiento)
    ---------------------------------------------------------------------------
    Implementa el protocolo de 7 pasos de la ficha de evaluacion de B1 como
    codigo ST. El programa aplica las entradas paso a paso, compara la salida
    del bloque bajo prueba contra el valor esperado y emite un veredicto.

    Ventaja para la investigacion: la verificacion funcional deja de depender
    de que el investigador manipule variables a mano en linea. El mismo
    protocolo se aplica de forma identica a las 24 respuestas de B1, lo que
    elimina la variabilidad del operador. El veredicto queda en una variable
    que el ScriptEngine puede leer, o que puede volcarse a archivo.

    LO QUE NO HACE: no juzga claridad estructural ni mantenibilidad. Esos
    criterios de la rubrica siguen requiriendo lectura humana del codigo.

    USO: crear este PROGRAM en el proyecto, junto al FUNCTION_BLOCK de la
    respuesta a evaluar. Ejecutar en modo Simulacion. Al terminar la secuencia,
    leer 'veredicto': 1 = supera todos los pasos, 2 = falla al menos uno.
    El arreglo 'resultado' indica que paso concreto fallo.
*)

PROGRAM PRG_Test_B1
VAR CONSTANT
    ULTIMO_PASO : INT := 6;          (* 7 pasos: indices 0..6 *)
    T_ASENTAMIENTO : TIME := T#200MS; (* margen por paso; subir si hay temporizadores *)
END_VAR
VAR
    (* --- Bloque bajo prueba: sustituir por la respuesta a evaluar --- *)
    fb : FB_Motor;

    (* --- Entradas manipuladas por el banco --- *)
    btnMarcha : BOOL;
    btnParo   : BOOL;
    btnEmerg  : BOOL;

    (* --- Control de la secuencia --- *)
    paso       : INT := 0;
    esperado   : BOOL;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    (* --- Resultados: 0 = pendiente, 1 = pasa, 2 = falla --- *)
    resultado : ARRAY[0..6] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;            (* 0 = en curso, 1 = PASA, 2 = FALLA *)
    i         : INT;
END_VAR

(* 1. Temporizador de asentamiento entre pasos *)
tPaso(IN := NOT pulsoReset, PT := T_ASENTAMIENTO);
pulsoReset := FALSE;

(* 2. Aplicacion de entradas y valor esperado segun el paso *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Reposo: ninguna entrada activa *)
            btnMarcha := FALSE; btnParo := FALSE; btnEmerg := FALSE;
            esperado  := FALSE;
        1:  (* Arranque con pulso de marcha *)
            btnMarcha := TRUE;
            esperado  := TRUE;
        2:  (* Se suelta la marcha: debe mantenerse (enclavamiento) *)
            btnMarcha := FALSE;
            esperado  := TRUE;
        3:  (* Paro normal *)
            btnParo   := TRUE;
            esperado  := FALSE;
        4:  (* Rearranque tras paro normal *)
            btnParo   := FALSE; btnMarcha := TRUE;
            esperado  := TRUE;
        5:  (* Paro de emergencia *)
            btnEmerg  := TRUE;
            esperado  := FALSE;
        6:  (* Se libera la emergencia con la marcha aun pulsada:
               NO debe rearrancar solo *)
            btnEmerg  := FALSE;
            esperado  := FALSE;
    END_CASE
END_IF

(* 3. Llamada al bloque bajo prueba *)
fb(btnMarcha := btnMarcha, btnParo := btnParo, btnEmerg := btnEmerg);

(* 4. Evaluacion al vencer el tiempo de asentamiento *)
IF tPaso.Q AND NOT finalizado THEN
    IF fb.motorOn = esperado THEN
        resultado[paso] := 1;
    ELSE
        resultado[paso] := 2;
    END_IF

    pulsoReset := TRUE;              (* reinicia el temporizador un ciclo *)

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
        veredicto := 1;              (* supera el protocolo completo *)
    ELSE
        veredicto := 2;              (* falla al menos un paso *)
    END_IF
END_IF
