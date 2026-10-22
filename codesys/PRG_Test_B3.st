(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea B3 (contador de piezas por flanco)
    ---------------------------------------------------------------------------
    CORRIGE la version anterior, que tenia dos defectos fatales:

    1. El CASE asignaba sensorPieza := TRUE y una linea posterior lo invertia
       antes de llamar al bloque, de modo que el FB recibia siempre FALSE.
       No se generaba ningun flanco y el paso 4 reprobaba SIEMPRE, incluso a
       implementaciones correctas (falso negativo del 100%).

    2. La alternancia ocurria una vez por scan, por lo que el numero de flancos
       dependia del ciclo de la MainTask (2 flancos con 20 ms, 12 con 4 ms).
       El resultado era un accidente del entorno, no una medicion.

    SOLUCION: generador determinista de flancos con temporizador propio y
    contador explicito. Genera exactamente FLANCOS_EXTRA flancos ascendentes
    con independencia del ciclo de tarea. El temporizador de asentamiento del
    paso queda retenido mientras la generacion esta en curso, de modo que la
    evaluacion solo ocurre cuando ya se emitieron todos los flancos.

    3. (detectado por la validacion) Comprobar solo el estado final (cuenta=12,
       loteListo=TRUE) NO distingue un preset incorrecto: una implementacion que
       active el lote a las 10 piezas tambien llega a 12 con el lote activo. El
       umbral se verifica ahora en DOS LOTES: primero 10 flancos (cuenta=11, el
       lote debe seguir APAGADO) y despues 1 flanco mas (cuenta=12, lote ENCENDIDO).

    Cuentas esperadas: 1 (paso 1) + 10 (paso 4) + 1 (paso 5) = 12.
*)

PROGRAM PRG_Test_B3
VAR CONSTANT
    ULTIMO_PASO    : INT  := 6;
    FLANCOS_LOTE_A : INT  := 10;     (* 1 + 10 = 11 cuentas: el lote NO debe activarse *)
    FLANCOS_LOTE_B : INT  := 1;      (* 11 + 1 = 12 cuentas: el lote SI debe activarse *)
    T_PULSO        : TIME := T#20MS; (* semiperiodo del generador de flancos *)
END_VAR
VAR
    (* --- Bloque bajo prueba --- *)
    fb : FB_Contador;

    (* --- Entradas manipuladas por el banco --- *)
    sensorPieza : BOOL;
    btnReset    : BOOL;

    (* --- Control de la secuencia --- *)
    paso           : INT := 0;
    esperadoCuenta : INT;
    esperadoLote   : BOOL;
    tEspera        : TIME;
    tPaso          : TON;
    pulsoReset     : BOOL;
    finalizado     : BOOL;

    (* --- Generador determinista de flancos --- *)
    flancosPendientes : INT;
    pasoCargado       : INT := -1;   (* para cargar los flancos al entrar al paso *)
    tPulso            : TON;
    resetPulso        : BOOL;
    generando         : BOOL;

    (* --- Resultados --- *)
    resultado : ARRAY[0..6] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Definicion del paso en curso.
      En el paso 4 el CASE NO toca sensorPieza: lo gobierna el generador. *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Reset inicial *)
            btnReset := TRUE;  sensorPieza := FALSE;
            tEspera := T#200MS; esperadoCuenta := 0; esperadoLote := FALSE;
        1:  (* Primer flanco ascendente *)
            btnReset := FALSE; sensorPieza := TRUE;
            tEspera := T#200MS; esperadoCuenta := 1; esperadoLote := FALSE;
        2:  (* Sensor sostenido en alto: NO debe seguir contando *)
            sensorPieza := TRUE;
            tEspera := T#500MS; esperadoCuenta := 1; esperadoLote := FALSE;
        3:  (* Vuelta a bajo para preparar la generacion *)
            sensorPieza := FALSE;
            tEspera := T#200MS; esperadoCuenta := 1; esperadoLote := FALSE;
        4:  (* 10 flancos -> 11 cuentas: el lote AUN NO debe activarse.
               Este paso es el que detecta un preset menor que 12. *)
            tEspera := T#200MS; esperadoCuenta := 11; esperadoLote := FALSE;
        5:  (* 1 flanco mas -> 12 cuentas: el lote SI debe activarse.
               Este paso detecta un preset mayor que 12. *)
            tEspera := T#200MS; esperadoCuenta := 12; esperadoLote := TRUE;
        6:  (* Reset final *)
            btnReset := TRUE;  sensorPieza := FALSE;
            tEspera := T#200MS; esperadoCuenta := 0; esperadoLote := FALSE;
    END_CASE
END_IF

(* 2. Carga del numero de flancos al entrar en cada paso generador *)
IF paso <> pasoCargado THEN
    CASE paso OF
        4: flancosPendientes := FLANCOS_LOTE_A;
        5: flancosPendientes := FLANCOS_LOTE_B;
    ELSE
        flancosPendientes := 0;
    END_CASE
    pasoCargado := paso;
END_IF

(* 3. Generador determinista de flancos (pasos 4 y 5) *)
generando := ((paso = 4) OR (paso = 5)) AND (flancosPendientes > 0);

IF generando THEN
    tPulso(IN := NOT resetPulso, PT := T_PULSO);
    resetPulso := FALSE;
    IF tPulso.Q THEN
        sensorPieza := NOT sensorPieza;
        IF sensorPieza THEN
            flancosPendientes := flancosPendientes - 1;   (* solo flancos ascendentes *)
        END_IF
        resetPulso := TRUE;
    END_IF
ELSE
    tPulso(IN := FALSE, PT := T_PULSO);
END_IF

(* 4. Asentamiento del paso, retenido mientras se generan flancos *)
tPaso(IN := NOT pulsoReset AND NOT generando, PT := tEspera);
pulsoReset := FALSE;

(* 5. Llamada al bloque bajo prueba *)
fb(sensorPieza := sensorPieza, btnReset := btnReset);

(* 6. Evaluacion al vencer el asentamiento *)
IF tPaso.Q AND NOT finalizado THEN
    IF (fb.cuenta = esperadoCuenta) AND (fb.loteListo = esperadoLote) THEN
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

(* 7. Veredicto global *)
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
