(*
    BANCO DE PRUEBA AUTOVERIFICABLE - Tarea B8 (FB_Puerta: aperturas por flanco)
    ---------------------------------------------------------------------------
    Validado por simulacion en codesys/validar_harness_B8.py (traduccion fiel):
    9 implementaciones (1 correcta, 8 defectuosas), ciclos de 4, 10 y 20 ms.

    Pasos (cuentas acumuladas):
      0 reset, puerta cerrada ............................ n=0  aviso=F
      1 se suelta reset y se abre la puerta (1 flanco) ... n=1  aviso=F
      2 puerta sostenida abierta 500 ms .................. n=1  aviso=F
      3 puerta cerrada ................................... n=1  aviso=F
      4 3 flancos generados .............................. n=4  aviso=F  (umbral 4)
      5 1 flanco ......................................... n=5  aviso=T  (umbral '>5')
      6 1 flanco ......................................... n=6  aviso=T  ('=5', saturacion)
      7 reset, puerta cerrada ............................ n=0  aviso=F  (reset incompleto)
      8 se suelta reset, 1 flanco ........................ n=1  aviso=F  (bloqueo tras reset)
    Las transiciones de reset se hacen con la puerta cerrada: el enunciado no
    define que pasa con un flanco durante el reset, asi que no se prueba.

    Generador determinista de flancos (patron de B3): el numero de flancos no
    depende del ciclo de la MainTask; el asentamiento del paso queda retenido
    mientras se generan.
*)
PROGRAM PRG_Test_B8
VAR CONSTANT
    ULTIMO_PASO : INT  := 8;
    T_PULSO     : TIME := T#20MS;
END_VAR
VAR
    fb : FB_Puerta;                 (* bloque bajo prueba *)

    puertaAbierta : BOOL;
    reset         : BOOL;

    paso        : INT := 0;
    esperadoN   : INT;
    esperadoAv  : BOOL;
    tEspera     : TIME;
    tPaso       : TON;
    pulsoReset  : BOOL;
    finalizado  : BOOL;

    flancosPendientes : INT;
    pasoCargado       : INT := -1;
    tPulso            : TON;
    resetPulso        : BOOL;
    generando         : BOOL;

    resultado : ARRAY[0..8] OF INT;
    nPasan    : INT;
    veredicto : INT := 0;
    i         : INT;
END_VAR

(* 1. Definicion del paso. En los pasos 4, 5, 6 y 8 la puerta la gobierna el generador. *)
IF NOT finalizado THEN
    CASE paso OF
        0: reset := TRUE;  puertaAbierta := FALSE; tEspera := T#200MS; esperadoN := 0; esperadoAv := FALSE;
        1: reset := FALSE; puertaAbierta := TRUE;  tEspera := T#200MS; esperadoN := 1; esperadoAv := FALSE;
        2: puertaAbierta := TRUE;                  tEspera := T#500MS; esperadoN := 1; esperadoAv := FALSE;
        3: puertaAbierta := FALSE;                 tEspera := T#200MS; esperadoN := 1; esperadoAv := FALSE;
        4:                                         tEspera := T#200MS; esperadoN := 4; esperadoAv := FALSE;
        5:                                         tEspera := T#200MS; esperadoN := 5; esperadoAv := TRUE;
        6:                                         tEspera := T#200MS; esperadoN := 6; esperadoAv := TRUE;
        7: reset := TRUE;  puertaAbierta := FALSE; tEspera := T#200MS; esperadoN := 0; esperadoAv := FALSE;
        8: reset := FALSE;                         tEspera := T#200MS; esperadoN := 1; esperadoAv := FALSE;
    END_CASE
END_IF

(* 2. Carga del numero de flancos al entrar en cada paso *)
IF paso <> pasoCargado THEN
    CASE paso OF
        4: flancosPendientes := 3;
        5, 6, 8: flancosPendientes := 1;
    ELSE
        flancosPendientes := 0;
    END_CASE
    pasoCargado := paso;
END_IF

(* 3. Generador determinista de flancos *)
generando := flancosPendientes > 0;
IF generando THEN
    tPulso(IN := NOT resetPulso, PT := T_PULSO);
    resetPulso := FALSE;
    IF tPulso.Q THEN
        puertaAbierta := NOT puertaAbierta;
        IF puertaAbierta THEN
            flancosPendientes := flancosPendientes - 1;   (* solo flancos ascendentes *)
        END_IF
        resetPulso := TRUE;
    END_IF
ELSE
    tPulso(IN := FALSE, PT := T_PULSO);
END_IF

(* 4. Asentamiento, retenido mientras se generan flancos *)
tPaso(IN := NOT pulsoReset AND NOT generando, PT := tEspera);
pulsoReset := FALSE;

(* 5. Bloque bajo prueba *)
fb(puertaAbierta := puertaAbierta, reset := reset);

(* 6. Evaluacion *)
IF tPaso.Q AND NOT finalizado THEN
    IF (fb.nAperturas = esperadoN) AND (fb.aviso = esperadoAv) THEN
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
