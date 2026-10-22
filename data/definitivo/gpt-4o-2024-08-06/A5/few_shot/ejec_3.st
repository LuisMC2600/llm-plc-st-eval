```pascal
TYPE ST_Evento :
STRUCT
    codigo : INT;  (* Código del evento *)
    marca : TIME;  (* Marca de tiempo del evento *)
END_STRUCT
END_TYPE

FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento : INT;      (* Código del evento entrante *)
    nuevoEvento : BOOL; (* Señal de nuevo evento *)
    ciclo : TIME;      (* Período de ejecución del bloque *)
END_VAR
VAR_OUTPUT
    buffer : ARRAY[0..19] OF ST_Evento; (* Buffer circular de eventos *)
    indice : INT;       (* Índice del último evento registrado *)
    nEventos : INT;     (* Número de eventos válidos en el buffer *)
END_VAR
VAR
    tiempoAcumulado : TIME := T#0S; (* Tiempo acumulado desde el arranque *)
    nuevoEventoAnt : BOOL := FALSE; (* Estado anterior de nuevoEvento *)
    posActual : INT := 0;           (* Posición actual en el buffer *)
END_VAR

(* Acumula el tiempo de ejecución *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* Detecta transición de FALSE a TRUE en nuevoEvento *)
IF (nuevoEvento AND NOT nuevoEventoAnt) THEN
    (* Registra el evento en la posición actual del buffer *)
    buffer[posActual].codigo := evento;
    buffer[posActual].marca := tiempoAcumulado;
    
    (* Actualiza el índice del último evento registrado *)
    indice := posActual;
    
    (* Incrementa el número de eventos registrados, hasta un máximo de 20 *)
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF;
    
    (* Avanza la posición actual en el buffer, con comportamiento circular *)
    posActual := (posActual + 1) MOD 20;
END_IF;

(* Actualiza el estado anterior de nuevoEvento *)
nuevoEventoAnt := nuevoEvento;
END_FUNCTION_BLOCK
```