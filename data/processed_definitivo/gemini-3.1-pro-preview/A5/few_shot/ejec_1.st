TYPE ST_Evento :
STRUCT
    codigo : INT; (* Codigo del evento *)
    marca : TIME; (* Marca de tiempo *)
END_STRUCT
END_TYPE

FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento : INT; (* Codigo del evento a registrar *)
    nuevoEvento : BOOL; (* Disparador para registrar evento *)
    ciclo : TIME; (* Periodo de ejecucion del bloque *)
END_VAR
VAR_OUTPUT
    buffer : ARRAY[0..19] OF ST_Evento; (* Buffer circular de eventos *)
    indice : INT := -1; (* Posicion del ultimo evento registrado *)
    nEventos : INT := 0; (* Numero de eventos validos en el buffer *)
END_VAR
VAR
    tiempoAcumulado : TIME := T#0S; (* Tiempo acumulado desde el arranque *)
    trigEvento : R_TRIG; (* Detector de flanco ascendente *)
END_VAR

(* Acumular el tiempo de ciclo en cada ejecucion *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* Detectar transicion de FALSE a TRUE en nuevoEvento *)
trigEvento(CLK := nuevoEvento);

IF trigEvento.Q THEN
    (* Actualizar el indice de forma circular *)
    IF indice < 19 THEN
        indice := indice + 1;
    ELSE
        indice := 0;
    END_IF;
    
    (* Registrar el evento y la marca de tiempo en el buffer *)
    buffer[indice].codigo := evento;
    buffer[indice].marca := tiempoAcumulado;
    
    (* Incrementar el numero de eventos validos hasta un maximo de 20 *)
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF;
END_IF;
END_FUNCTION_BLOCK