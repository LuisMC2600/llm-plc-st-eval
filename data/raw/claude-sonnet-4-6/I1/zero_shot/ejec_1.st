```pascal
FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; (* Habilita la secuencia normal del semáforo *)
END_VAR

VAR_OUTPUT
    luzV : BOOL; (* Luz verde *)
    luzA : BOOL; (* Luz amarilla *)
    luzR : BOOL; (* Luz roja *)
END_VAR

VAR
    estado      : INT := 0;   (* Estado de la secuencia: 0=Verde, 1=Amarillo, 2=Rojo *)
    timerSec    : TON;        (* Temporizador para la secuencia normal *)
    timerBlink  : TON;        (* Temporizador para el parpadeo de amarillo *)
    blinkOn     : BOOL;       (* Indica si el amarillo intermitente está encendido *)
END_VAR

(* ─────────────────────────────────────────────────────────────────────────── *)
(*  MODO INHABILITADO: amarillo intermitente, verde y rojo apagados            *)
(* ─────────────────────────────────────────────────────────────────────────── *)
IF NOT habilitado THEN

    (* Detener y resetear el temporizador de secuencia *)
    timerSec(IN := FALSE, PT := T#0S);

    (* Resetear estado para que al habilitar de nuevo arranque en verde *)
    estado := 0;

    (* Temporizador de parpadeo: ciclo de 1 segundo *)
    timerBlink(IN := TRUE, PT := T#1S);

    IF timerBlink.Q THEN
        (* Reiniciar el temporizador y alternar el estado del parpadeo *)
        timerBlink(IN := FALSE, PT := T#1S);
        blinkOn := NOT blinkOn;
    END_IF;

    (* Asignar salidas: solo amarillo parpadea *)
    luzV := FALSE;
    luzA := blinkOn;
    luzR := FALSE;

(* ─────────────────────────────────────────────────────────────────────────── *)
(*  MODO HABILITADO: secuencia Verde → Amarillo → Rojo                        *)
(* ─────────────────────────────────────────────────────────────────────────── *)
ELSE

    (* Detener y resetear el temporizador de parpadeo *)
    timerBlink(IN := FALSE, PT := T#0S);
    blinkOn := FALSE;

    CASE estado OF

        (* ── Estado 0: Verde 20 s ── *)
        0:
            luzV := TRUE;
            luzA := FALSE;
            luzR := FALSE;

            timerSec(IN := TRUE, PT := T#20S);
            IF timerSec.Q THEN
                timerSec(IN := FALSE, PT := T#20S); (* Resetear temporizador *)
                estado := 1;                         (* Pasar a amarillo *)
            END_IF;

        (* ── Estado 1: Amarillo 4 s ── *)
        1:
            luzV := FALSE;
            luzA := TRUE;
            luzR := FALSE;

            timerSec(IN := TRUE, PT := T#4S);
            IF timerSec.Q THEN
                timerSec(IN := FALSE, PT := T#4S);  (* Resetear temporizador *)
                estado := 2;                         (* Pasar a rojo *)
            END_IF;

        (* ── Estado 2: Rojo 15 s ── *)
        2:
            luzV := FALSE;
            luzA := FALSE;
            luzR := TRUE;

            timerSec(IN := TRUE, PT := T#15S);
            IF timerSec.Q THEN
                timerSec(IN := FALSE, PT := T#15S); (* Resetear temporizador *)
                estado := 0;                         (* Volver a verde *)
            END_IF;

        (* ── Estado por defecto: seguridad ── *)
        ELSE
            estado := 0;
            timerSec(IN := FALSE, PT := T#0S);

    END_CASE;

END_IF;
```