(*
    BANCO DE PRUEBA AUTOVERIFICABLE — Tarea I3 (gestion de alarmas con prioridad)
    ---------------------------------------------------------------------------
    Tres alarmas con prioridad (alm1 alta, alm2 media, alm3 baja). Cualquiera
    activa enciende la sirena. codigoAlm reporta la de mayor prioridad presente
    (0 si no hay). Cada alarma queda RETENIDA aunque su causa desaparezca hasta
    que se reconozca individualmente, y el reconocimiento SOLO tiene efecto si
    la causa ya desaparecio.

    USO: crear este PROGRAM junto al FUNCTION_BLOCK de la respuesta a evaluar y
    ejecutar en modo Simulacion. Al terminar, leer 'veredicto': 1 = supera,
    2 = falla.

    ---------------------------------------------------------------------------
    CORRECCION DEL 2026-09-09 (enmienda 12). Validado con validar_harness_I3.py.
    La version anterior daba veredicto 1 a una implementacion cuyo ACK borraba
    la alarma AUNQUE la causa siguiera presente, que es la violacion directa de
    la regla central del enunciado. Los nueve pasos daban exactamente el mismo
    resultado que con la implementacion correcta.

    Causa: en toda la secuencia no habia un solo instante en que una entrada
    ackN estuviera activa a la vez que su almN. Los reconocimientos se
    aplicaban siempre con la causa ya retirada, de modo que la mitad de la
    regla ("no debe borrar con la causa presente") no se ejercitaba nunca.

    Es notable porque ENMIENDAS_HARNESSES.md ya aprobaba explicitamente ese
    paso en su lista: "I3: ACK con la causa todavia presente (no debe borrar) y
    ACK tras retirarla (si debe)". El paso estaba aprobado en el documento pero
    no implementado en el banco.

    Correccion: se anade el paso 2, que aplica ack3 con alm3 todavia activa y
    exige que la alarma NO se borre. La secuencia pasa de 9 a 10 pasos.
*)

PROGRAM PRG_Test_I3
VAR CONSTANT
    ULTIMO_PASO    : INT  := 9;       (* 10 pasos: indices 0..9 *)
    T_ASENTAMIENTO : TIME := T#150MS;
END_VAR
VAR
    (* --- Bloque bajo prueba: sustituir por la respuesta a evaluar --- *)
    fb : FB_Alarmas;

    (* --- Entradas manipuladas por el banco --- *)
    alm1, alm2, alm3 : BOOL;
    ack1, ack2, ack3 : BOOL;

    (* --- Control de la secuencia --- *)
    espSirena  : BOOL;
    espCodigo  : INT;
    paso       : INT := 0;
    tPaso      : TON;
    pulsoReset : BOOL;
    finalizado : BOOL;

    (* --- Resultados: 0 = pendiente, 1 = pasa, 2 = falla --- *)
    resultado : ARRAY[0..9] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Temporizador de asentamiento entre pasos *)
tPaso(IN := NOT pulsoReset, PT := T_ASENTAMIENTO);
pulsoReset := FALSE;

(* 2. Aplicacion de entradas y valores esperados. Solo se asigna lo que cada
      paso cambia: las demas entradas conservan su valor. *)
IF NOT finalizado THEN
    CASE paso OF
        0:  (* Reposo: sin alarmas, con los ACK activos (no deben hacer nada) *)
            alm1 := FALSE; alm2 := FALSE; alm3 := FALSE;
            ack1 := TRUE;  ack2 := TRUE;  ack3 := TRUE;
            espSirena := FALSE; espCodigo := 0;
        1:  (* Alarma baja activa *)
            ack1 := FALSE; ack2 := FALSE; ack3 := FALSE;
            alm3 := TRUE;
            espSirena := TRUE;  espCodigo := 3;
        2:  (* ACK CON LA CAUSA TODAVIA PRESENTE: no debe borrar (enmienda 12) *)
            ack3 := TRUE;
            espSirena := TRUE;  espCodigo := 3;
        3:  (* Se retira la causa y se suelta el ACK: sigue retenida *)
            alm3 := FALSE; ack3 := FALSE;
            espSirena := TRUE;  espCodigo := 3;
        4:  (* ACK con la causa ya retirada: ahora si debe borrar *)
            ack3 := TRUE;
            espSirena := FALSE; espCodigo := 0;
        5:  (* Dos alarmas: domina la de mayor prioridad de las presentes *)
            ack3 := FALSE; alm2 := TRUE; alm3 := TRUE;
            espSirena := TRUE;  espCodigo := 2;
        6:  (* Entra la de prioridad alta *)
            alm1 := TRUE;
            espSirena := TRUE;  espCodigo := 1;
        7:  (* Se retira y reconoce la alta: queda la media *)
            alm1 := FALSE; ack1 := TRUE;
            espSirena := TRUE;  espCodigo := 2;
        8:  (* Se retira y reconoce la media: queda la baja *)
            alm2 := FALSE; ack2 := TRUE;
            espSirena := TRUE;  espCodigo := 3;
        9:  (* Se retira y reconoce la baja: todo en reposo *)
            alm3 := FALSE; ack3 := TRUE;
            espSirena := FALSE; espCodigo := 0;
    END_CASE
END_IF

(* 3. Llamada al bloque bajo prueba *)
fb(alm1 := alm1, alm2 := alm2, alm3 := alm3,
   ack1 := ack1, ack2 := ack2, ack3 := ack3);

(* 4. Evaluacion al vencer el asentamiento *)
IF tPaso.Q AND NOT finalizado THEN
    IF fb.sirena = espSirena AND fb.codigoAlm = espCodigo THEN
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
