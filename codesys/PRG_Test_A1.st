(*
    BANCO DE PRUEBA AUTOVERIFICABLE - Tarea A1 (FB_PID con anti-windup por clamping)
    ---------------------------------------------------------------------------
    Validado en codesys/validar_harness_A1.py: 12 implementaciones (3 correctas,
    con integracion rectangular, integral previa y trapezoidal, y 9 defectuosas).
    Tabla generada desde el validador. tipo: 0 = valor +-tol, 1 = CV <= eVal,
    2 = CV >= eVal.

    TOLERANCIAS (aprobadas por Luis y su asesora, 30-09-2026):
  solo P: +-0.01 | integral: +-2 pasos de muestreo | derivada: +-5 % del termino
  derivativo | saturacion exacta (+-0.001) | anti-windup: sale de la saturacion en
  menos de 1 s tras invertir el error | sentido: PV < SP -> CV sube.

TIEMPO VIRTUAL: ciclo := T#100MS fijo; pasos por NUMERO DE LLAMADAS. Cada
escenario usa su PROPIA instancia del FB (fbP, fbI, fbD, fbW), para que el estado
interno de un escenario (p. ej. una integral acumulada) no contamine otro.

Paso  instancia  (Kp, Ti, Td, SP, PV) llamadas -> comprobacion
  0   fbP  (2, 0, 0, 50, 40)     5 -> CV = 20.0 +-0.01     solo P, sentido
  1   fbP  (2, 0, 0, 50, 60)     5 -> CV = 0.0 +-0.001     saturacion baja
  2   fbP  (2, 0, 0, 50,-20)     5 -> CV = 100.0 +-0.001   saturacion alta
  3   fbP  (2,-1, 0, 50, 45)     5 -> CV = 10.0 +-0.01     Ti < 0: sin integral
  4   fbI  (1,10, 0, 50, 45)   100 -> CV = 10.0 +-0.10     5 + 0.5*10 s
  5   fbI  (1,10, 0, 50, 45)   100 -> CV = 15.0 +-0.10     5 + 0.5*20 s
  6   fbD  (1, 0, 2, 50+0.1k, 40) 50 -> CV = 17.0 +-0.10   e = 15, Td*de/dt = 2 (SP en rampa:
                                                           la derivada sobre PV daria 0)
  7   fbW  (1, 5, 0,100,  0)   300 -> CV = 100.0 +-0.001   30 s saturado en alto
  8   fbW  (1, 5, 0,100,110)    10 -> CV <= 99.5            sale de 100 en < 1 s
  9   fbW  (1, 5, 0,  0,200)   300 -> CV = 0.0 +-0.001     30 s saturado en bajo
 10   fbW  (1, 5, 0,  0,-10)    10 -> CV >= 0.5             sale de 0 en < 1 s
*)
PROGRAM PRG_Test_A1
VAR CONSTANT
    ULTIMO_PASO : INT := 10;
END_VAR
VAR
    fbP, fbI, fbD, fbW : FB_PID;    (* una instancia por escenario *)
    ins        : INT;
    Kp, Ti, Td : REAL;
    SPbase, PV : REAL;
    rampa      : BOOL;
    kRampa     : INT;
    SP, CV     : REAL;
    nLlamadas, k, tipo : INT;
    eVal, tol  : REAL;
    bien       : BOOL;
    paso       : INT := 0;
    finalizado : BOOL;

    resultado : ARRAY[0..10] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

IF NOT finalizado THEN
    (* 1. Definicion del paso *)
    CASE paso OF
        0: ins := 0; Kp := 2.0; Ti := 0.0; Td := 0.0; SPbase := 50.0; rampa := FALSE; PV := 40.0; nLlamadas := 5; tipo := 0; eVal := 20.0; tol := 0.01;
        1: ins := 0; Kp := 2.0; Ti := 0.0; Td := 0.0; SPbase := 50.0; rampa := FALSE; PV := 60.0; nLlamadas := 5; tipo := 0; eVal := 0.0; tol := 0.001;
        2: ins := 0; Kp := 2.0; Ti := 0.0; Td := 0.0; SPbase := 50.0; rampa := FALSE; PV := -20.0; nLlamadas := 5; tipo := 0; eVal := 100.0; tol := 0.001;
        3: ins := 0; Kp := 2.0; Ti := -1.0; Td := 0.0; SPbase := 50.0; rampa := FALSE; PV := 45.0; nLlamadas := 5; tipo := 0; eVal := 10.0; tol := 0.01;
        4: ins := 1; Kp := 1.0; Ti := 10.0; Td := 0.0; SPbase := 50.0; rampa := FALSE; PV := 45.0; nLlamadas := 100; tipo := 0; eVal := 10.0; tol := 0.1;
        5: ins := 1; Kp := 1.0; Ti := 10.0; Td := 0.0; SPbase := 50.0; rampa := FALSE; PV := 45.0; nLlamadas := 100; tipo := 0; eVal := 15.0; tol := 0.1;
        6: ins := 2; Kp := 1.0; Ti := 0.0; Td := 2.0; SPbase := 50.0; rampa := TRUE; PV := 40.0; nLlamadas := 50; tipo := 0; eVal := 17.0; tol := 0.1;
        7: ins := 3; Kp := 1.0; Ti := 5.0; Td := 0.0; SPbase := 100.0; rampa := FALSE; PV := 0.0; nLlamadas := 300; tipo := 0; eVal := 100.0; tol := 0.001;
        8: ins := 3; Kp := 1.0; Ti := 5.0; Td := 0.0; SPbase := 100.0; rampa := FALSE; PV := 110.0; nLlamadas := 10; tipo := 1; eVal := 99.5; tol := 0.0;
        9: ins := 3; Kp := 1.0; Ti := 5.0; Td := 0.0; SPbase := 0.0; rampa := FALSE; PV := 200.0; nLlamadas := 300; tipo := 0; eVal := 0.0; tol := 0.001;
        10: ins := 3; Kp := 1.0; Ti := 5.0; Td := 0.0; SPbase := 0.0; rampa := FALSE; PV := -10.0; nLlamadas := 10; tipo := 2; eVal := 0.5; tol := 0.0;
    END_CASE

    (* 2. Consigna (en rampa en el escenario derivativo) *)
    IF rampa THEN
        kRampa := kRampa + 1;
        SP := SPbase + 0.1 * INT_TO_REAL(kRampa);
    ELSE
        SP := SPbase;
    END_IF

    (* 3. Una llamada por scan a la instancia del escenario, ciclo virtual 100 ms *)
    CASE ins OF
        0: fbP(SP := SP, PV := PV, Kp := Kp, Ti := Ti, Td := Td, ciclo := T#100MS); CV := fbP.CV;
        1: fbI(SP := SP, PV := PV, Kp := Kp, Ti := Ti, Td := Td, ciclo := T#100MS); CV := fbI.CV;
        2: fbD(SP := SP, PV := PV, Kp := Kp, Ti := Ti, Td := Td, ciclo := T#100MS); CV := fbD.CV;
        3: fbW(SP := SP, PV := PV, Kp := Kp, Ti := Ti, Td := Td, ciclo := T#100MS); CV := fbW.CV;
    END_CASE
    k := k + 1;

    (* 4. Evaluacion al completar las llamadas del paso *)
    IF k >= nLlamadas THEN
        CASE tipo OF
            0: bien := ABS(CV - eVal) <= tol;
            1: bien := CV <= eVal;
            2: bien := CV >= eVal;
        END_CASE
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
