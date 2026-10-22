(*
    BANCO DE PRUEBA AUTOVERIFICABLE - Tarea C3 (conversion Ladder -> ST, PRG_Conversion)
    ---------------------------------------------------------------------------
    Validado en codesys/validar_harness_C3.py: 7 implementaciones (1 correcta y
    6 defectuosas), ciclos de 4, 10 y 20 ms. Tabla de pasos generada desde el
    validador. Una respuesta con las E/S en VAR local no compila con este banco
    (CODESYS no admite escribir desde fuera una VAR local de un PROGRAM): se
    clasifica como INTERFAZ NO CONFORME, igual que los FB con E/S en VAR.
    El POU bajo prueba es un PROGRAM: se escriben sus entradas y se leen sus
    salidas por nombre, y se llama una vez por scan desde este banco.

    Paso (btnMarcha, btnParo) duracion -> (motor, lampara)
  0 (F,F) 0.2 s -> (F,F)
  1 (T,F) 0.2 s -> (T,F)   arranque; la lampara aun no
  2 (F,F) 5.0 s -> (T,F)   enclavamiento; lampara vigilada en FALSE todo el paso
  3 (F,F) 5.5 s -> (T,T)   ~10.7 s con motor: lampara encendida
  4 (F,T) 0.2 s -> (F,F)   paro: motor y lampara (T1 se reinicia)
  5 (F,F) 0.2 s -> (F,F)
  6 (T,T) 0.2 s -> (F,F)   marcha y paro a la vez: gana el NC en serie; vigilado
  7 (T,F) 0.2 s -> (T,F)
  8 (F,F) 9.0 s -> (T,F)   T1 empezo de cero en el paso 7: lampara vigilada en FALSE
  9 (F,F) 1.5 s -> (T,T)
 10 (F,T) 0.2 s -> (F,F)
VIGILANCIA CONTINUA (enmienda 4): en los pasos 0, 2, 5, 6 y 8 la lampara no puede
valer TRUE ni un scan; en los pasos 0, 5 y 6 tampoco el motor.
*)
PROGRAM PRG_Test_C3
VAR CONSTANT
    ULTIMO_PASO : INT := 10;
END_VAR
VAR
    bM, bP             : BOOL;     (* btnMarcha, btnParo aplicados *)
    eMotor, eLampara   : BOOL;     (* esperados *)

    paso       : INT := 0;
    tEspera    : TIME;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;
    vigLampara : BOOL;
    vigMotor   : BOOL;
    violacion  : BOOL;

    resultado : ARRAY[0..10] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Entradas, duracion y salidas esperadas del paso *)
IF NOT finalizado THEN
    CASE paso OF
        0: bM := FALSE; bP := FALSE; tEspera := T#200MS; eMotor := FALSE; eLampara := FALSE;
        1: bM := TRUE; bP := FALSE; tEspera := T#200MS; eMotor := TRUE; eLampara := FALSE;
        2: bM := FALSE; bP := FALSE; tEspera := T#5000MS; eMotor := TRUE; eLampara := FALSE;
        3: bM := FALSE; bP := FALSE; tEspera := T#5500MS; eMotor := TRUE; eLampara := TRUE;
        4: bM := FALSE; bP := TRUE; tEspera := T#200MS; eMotor := FALSE; eLampara := FALSE;
        5: bM := FALSE; bP := FALSE; tEspera := T#200MS; eMotor := FALSE; eLampara := FALSE;
        6: bM := TRUE; bP := TRUE; tEspera := T#200MS; eMotor := FALSE; eLampara := FALSE;
        7: bM := TRUE; bP := FALSE; tEspera := T#200MS; eMotor := TRUE; eLampara := FALSE;
        8: bM := FALSE; bP := FALSE; tEspera := T#9000MS; eMotor := TRUE; eLampara := FALSE;
        9: bM := FALSE; bP := FALSE; tEspera := T#1500MS; eMotor := TRUE; eLampara := TRUE;
        10: bM := FALSE; bP := TRUE; tEspera := T#200MS; eMotor := FALSE; eLampara := FALSE;
    END_CASE
END_IF

(* 2. Asentamiento del paso *)
tPaso(IN := NOT pulsoReset, PT := tEspera);
pulsoReset := FALSE;

(* 3. PROGRAM bajo prueba *)
PRG_Conversion.btnMarcha := bM;
PRG_Conversion.btnParo := bP;
PRG_Conversion();

(* 4. Vigilancia continua *)
CASE paso OF
    0, 2, 5, 6, 8: vigLampara := TRUE;
ELSE
    vigLampara := FALSE;
END_CASE
CASE paso OF
    0, 5, 6: vigMotor := TRUE;
ELSE
    vigMotor := FALSE;
END_CASE
IF NOT finalizado AND ((vigLampara AND PRG_Conversion.lampara) OR (vigMotor AND PRG_Conversion.motor)) THEN
    violacion := TRUE;
END_IF

(* 5. Evaluacion *)
IF tPaso.Q AND NOT finalizado THEN
    IF (PRG_Conversion.motor = eMotor) AND (PRG_Conversion.lampara = eLampara) AND NOT violacion THEN
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
