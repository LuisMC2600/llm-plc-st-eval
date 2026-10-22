```iecst
FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL; (* Habilita la secuencia normal *)
END_VAR
VAR_OUTPUT
    luzV : BOOL; (* Luz verde *)
    luzA : BOOL; (* Luz amarilla *)
    luzR : BOOL; (* Luz roja *)
END_VAR
VAR
    estado : INT := 0; (* 0: Verde, 1: Amarillo, 2: Rojo *)
    tVerde : TON;      (* Temporizador luz verde *)
    tAmarillo : TON;   (* Temporizador luz amarilla *)
    tRojo : TON;       (* Temporizador luz roja *)
    tBlink1 : TON;     (* Temporizador intermitencia ON *)
    tBlink2 : TON;     (* Temporizador intermitencia OFF *)
END_VAR

(* Control de estados y reinicio *)
IF NOT habilitado THEN
    estado := 0; (* Reinicia la secuencia a verde si se deshabilita *)
ELSIF estado = 0 AND tVerde.Q THEN
    estado := 1;
ELSIF estado = 1 AND tAmarillo.Q THEN
    estado := 2;
ELSIF estado = 2 AND tRojo.Q THEN
    estado := 0;
END_IF;

(* Temporizadores de la secuencia normal *)
tVerde(IN := habilitado AND (estado = 0), PT := T#20S);
tAmarillo(IN := habilitado AND (estado = 1), PT := T#4S);
tRojo(IN := habilitado AND (estado = 2), PT := T#15S);

(* Temporizadores del modo intermitente (1s ON / 1s OFF) *)
tBlink1(IN := NOT habilitado AND NOT tBlink2.Q, PT := T#1S);
tBlink2(IN := tBlink1.Q, PT := T#1S);

(* Asignacion de salidas *)
luzV := habilitado AND (estado = 0);
luzR := habilitado AND (estado = 2);
luzA := (habilitado AND (estado = 1)) OR (NOT habilitado AND NOT tBlink1.Q);

END_FUNCTION_BLOCK
```