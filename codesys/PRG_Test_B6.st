(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea B6 (baliza intermitente)
    ---------------------------------------------------------------------------
    Aplica la enmienda 1 de ENMIENDAS_HARNESSES.md: NO se muestrea la lampara,
    se MIDE la duracion de cada intervalo ON y OFF completo. Muestrear cada
    1,1 s no discrimina, porque una implementacion de 1,5 s / 1,5 s produce el
    mismo patron de alternancia que la correcta.

    El primer intervalo se descarta por parcial: depende de en que momento se
    activo la alarma. Se exige 1 s +/- 150 ms en al menos dos intervalos ON y
    dos OFF completos.

    Ciclo de MainTask: 4 a 10 ms (enmienda 3).

    USO: crear este PROGRAM junto al FUNCTION_BLOCK de la respuesta a evaluar y
    ejecutar en modo Simulacion. Al terminar, leer 'veredicto': 1 = supera,
    2 = falla. 'resultado' indica el paso.

    ---------------------------------------------------------------------------
    CORRECCION DEL 2026-09-09 (enmienda 6). Validado con validar_harness_B6.py.
    La version anterior daba veredicto 1 a una implementacion que SEGUIA
    PARPADEANDO despues de retirarse la alarma.

    Causa: el paso 2 esperaba 200 ms y comprobaba la lampara en un unico
    instante. Como la salida defectuosa es periodica, que se la sorprenda
    encendida o apagada depende de la fase en ese instante; en la simulacion
    caia sistematicamente en un tramo apagado y el defecto pasaba como bueno.
    Es exactamente el fallo de muestreo que la enmienda 1 corrigio para el
    paso 1, sin corregirse tambien en los pasos de reposo.

    Correccion, con la misma logica de la enmienda 4: la condicion se evalua en
    CADA scan y queda ENCLAVADA, y la ventana del paso 2 pasa de 200 ms a
    2,5 s, mas de dos periodos nominales completos. Asi cualquier parpadeo
    indebido con semiperiodo por debajo de ~2,5 s queda registrado.

    Se unifica ademas la medida de intervalos con el metodo adoptado en la
    enmienda 5 para I4: diferencia de dos lecturas de un cronometro libre, en
    lugar de reiniciar un temporizador con un ciclo de retraso. Con la
    tolerancia de +/- 150 ms el sesgo anterior no llegaba a ser un defecto
    (medía ~980 ms en vez de 1000 ms con ciclo de 20 ms), pero no hay razon
    para conservar un sesgo conocido.
*)

PROGRAM PRG_Test_B6
VAR CONSTANT
    ULTIMO_PASO : INT  := 2;
    T_NOMINAL   : TIME := T#1S;
    TOL_MIN     : TIME := T#850MS;    (* 1 s - 150 ms *)
    TOL_MAX     : TIME := T#1150MS;   (* 1 s + 150 ms *)
    T_REPOSO    : TIME := T#2500MS;   (* > 2 periodos nominales (enmienda 6) *)
    T_CRONO     : TIME := T#100S;     (* cronometro libre: nunca se reinicia *)
END_VAR
VAR
    (* --- Bloque bajo prueba: sustituir por la respuesta a evaluar --- *)
    fb : FB_Baliza;

    (* --- Entrada manipulada por el banco --- *)
    alarma : BOOL;

    (* --- Control de la secuencia --- *)
    paso       : INT := 0;
    tEspera    : TIME;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    (* --- Medida de intervalos (enmienda 1) --- *)
    tCrono       : TON;
    prev         : BOOL;
    primer       : BOOL;              (* el primer intervalo es parcial *)
    etFlanco     : TIME;
    duracion     : TIME;
    error        : BOOL;              (* algun intervalo fuera de tolerancia *)
    nOn, nOff    : INT;

    (* --- Vigilancia de reposo, continua y enclavada (enmienda 6) --- *)
    lamparaEnPaso0 : BOOL;
    lamparaEnPaso2 : BOOL;

    (* --- Resultados: 0 = pendiente, 1 = pasa, 2 = falla --- *)
    resultado : ARRAY[0..2] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Definicion del paso en curso *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Reposo inicial: sin alarma, la lampara debe estar apagada *)
            alarma  := FALSE;
            tEspera := T#200MS;
        1:  (* Alarma activa: ventana de observacion del parpadeo *)
            alarma  := TRUE;
            tEspera := T#7S;
        2:  (* Alarma retirada: debe apagarse y PERMANECER apagada *)
            alarma  := FALSE;
            tEspera := T_REPOSO;
    END_CASE
END_IF

(* 2. Temporizadores del banco *)
tPaso(IN := NOT pulsoReset, PT := tEspera);
tCrono(IN := TRUE, PT := T_CRONO);
pulsoReset := FALSE;

(* 3. Llamada al bloque bajo prueba *)
fb(alarma := alarma);

(* 4. Medida de intervalos completos durante el paso 1 (enmienda 1).
      La duracion se obtiene por diferencia de dos lecturas del cronometro
      libre, no reiniciando un temporizador (enmienda 5). *)
IF paso = 1 THEN
    IF (fb.lampara AND NOT prev) OR ((NOT fb.lampara) AND prev) THEN
        IF primer THEN
            duracion := tCrono.ET - etFlanco;
            IF NOT fb.lampara THEN
                nOn := nOn + 1;        (* se acaba de cerrar un intervalo ON *)
            ELSE
                nOff := nOff + 1;      (* se acaba de cerrar un intervalo OFF *)
            END_IF
            IF duracion < TOL_MIN OR duracion > TOL_MAX THEN
                error := TRUE;
            END_IF
        ELSE
            primer := TRUE;            (* se descarta el intervalo parcial *)
        END_IF
        etFlanco := tCrono.ET;
    END_IF
END_IF

(* 5. Vigilancia de reposo: se evalua en CADA scan y queda enclavada
      (enmienda 6). Un unico muestreo al final del paso no sirve porque la
      salida defectuosa es periodica. *)
IF paso = 0 AND fb.lampara THEN
    lamparaEnPaso0 := TRUE;
END_IF
IF paso = 2 AND fb.lampara THEN
    lamparaEnPaso2 := TRUE;
END_IF

prev := fb.lampara;

(* 6. Evaluacion al vencer el asentamiento del paso *)
IF tPaso.Q AND NOT finalizado THEN
    IF    (paso = 0 AND NOT fb.lampara AND NOT lamparaEnPaso0)
       OR (paso = 1 AND nOn >= 2 AND nOff >= 2 AND NOT error)
       OR (paso = 2 AND NOT fb.lampara AND NOT lamparaEnPaso2)
    THEN
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
