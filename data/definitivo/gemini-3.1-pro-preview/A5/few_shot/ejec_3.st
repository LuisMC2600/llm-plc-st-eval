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
    buffer : ARRAY[0..19] OF ST_Evento; (* Buffer circular *)
    indice : INT := -1; (* Posicion del ultimo evento *)
    nEventos : INT := 0; (* Cantidad de eventos validos *)
END_VAR
VAR
    detectorFlanco : R_TRIG; (* Detector de flanco de subida *)
    tiempoAcumulado : TIME := T#0S; (* Tiempo desde el arranque *)
END_VAR

(* Acumular el tiempo de ciclo *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* Detectar transicion de FALSE a TRUE en nuevoEvento *)
detectorFlanco(CLK := nuevoEvento);

IF detectorFlanco.Q THEN
    (* Calcular siguiente posicion en el buffer circular *)
    indice := (indice + 1) MOD 20;
    
    (* Registrar datos en el buffer *)
    buffer[indice].codigo := evento;
    buffer[indice].marca := tiempoAcumulado;
    
    (* Incrementar contador de eventos hasta un maximo de 20 *)
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF;
END_IF;
END_FUNCTION_BLOCK