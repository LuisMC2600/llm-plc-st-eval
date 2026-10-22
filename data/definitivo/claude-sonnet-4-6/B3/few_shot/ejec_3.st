```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; (* Sensor fotoelectrico de pieza *)
    btnReset    : BOOL; (* Boton de reset de cuenta *)
END_VAR
VAR_OUTPUT
    loteListo : BOOL; (* Lote de 12 piezas completo *)
    cuenta    : INT;  (* Contador de piezas *)
END_VAR
VAR
    rTrigPieza : R_TRIG; (* Detector de flanco ascendente del sensor *)
END_VAR

(* Detectar flanco ascendente del sensor fotoelectrico *)
rTrigPieza(CLK := sensorPieza);

(* Incrementar cuenta en cada pieza detectada *)
IF rTrigPieza.Q THEN
    cuenta := cuenta + 1;
END_IF;

(* Reset: pone la cuenta en cero y desactiva el lote *)
IF btnReset THEN
    cuenta    := 0;
    loteListo := FALSE;
END_IF;

(* Activar salida de lote al alcanzar 12 piezas *)
IF cuenta >= 12 THEN
    loteListo := TRUE;
END_IF;

END_FUNCTION_BLOCK
```