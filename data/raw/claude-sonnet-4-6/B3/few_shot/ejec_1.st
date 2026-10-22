```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor fotoelectrico de pieza *)
    btnReset    : BOOL; (* Boton de reset de cuenta *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Lote de 12 piezas completo *)
    cuenta    : INT;  (* Cantidad de piezas contadas *)
END_VAR
VAR
    rTrigPieza : R_TRIG; (* Detector de flanco ascendente del sensor *)
END_VAR

(* Detectar flanco ascendente del sensor fotoelectrico *)
rTrigPieza(CLK := sensorPieza);

(* Reset prioritario: pone la cuenta en cero *)
IF btnReset THEN
    cuenta := 0;

(* Incrementar cuenta en cada pieza detectada, solo si el lote no esta completo *)
ELSIF rTrigPieza.Q AND NOT loteListo THEN
    cuenta := cuenta + 1;
END_IF;

(* Activar salida de lote al alcanzar 12 piezas *)
loteListo := (cuenta >= 12);

END_FUNCTION_BLOCK
```