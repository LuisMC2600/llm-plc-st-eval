PROGRAM PRG_Conversion
VAR_INPUT
    btnMarcha : BOOL; (* Contacto NA en paralelo con motor *)
    btnParo : BOOL; (* Contacto NC en serie *)
END_VAR
VAR_OUTPUT
    motor : BOOL; (* Bobina y contacto de retencion *)
    lampara : BOOL; (* Bobina activada por el temporizador *)
END_VAR
VAR
    T1 : TON; (* Temporizador a la conexion *)
END_VAR

(* Rama 1: Circuito de marcha/paro con auto-retencion *)
motor := (btnMarcha OR motor) AND NOT btnParo;

(* Rama 2: Temporizador alimentado por el estado del motor *)
T1(IN := motor, PT := T#10S);

(* Rama 3: Activacion de la lampara con la salida del temporizador *)
lampara := T1.Q;
END_PROGRAM