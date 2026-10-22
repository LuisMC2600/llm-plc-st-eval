PROGRAM PRG_Conversion
VAR_INPUT
    btnMarcha : BOOL; (* Contacto NA, inicio de marcha *)
    btnParo : BOOL; (* Contacto NC, detiene el motor *)
END_VAR
VAR_OUTPUT
    motor : BOOL; (* Bobina del motor y contacto de retencion *)
    lampara : BOOL; (* Bobina indicadora *)
END_VAR
VAR
    T1 : TON; (* Temporizador a la conexion *)
END_VAR

(* Rama 1: Circuito de retencion (arranque/paro) para el motor *)
motor := (btnMarcha OR motor) AND NOT btnParo;

(* Rama 2: El temporizador se activa cuando el motor esta encendido *)
T1(IN := motor, PT := T#10S);

(* Rama 3: La lampara se enciende cuando el temporizador alcanza los 10s *)
lampara := T1.Q;
END_PROGRAM