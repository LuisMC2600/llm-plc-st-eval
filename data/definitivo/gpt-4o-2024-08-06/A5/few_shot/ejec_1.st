```pascal
TYPE
    ST_Evento : STRUCT
        codigo : INT;  (* Código del evento *)
        marca : TIME;  (* Marca de tiempo del evento *)
    END_STRUCT;
END_TYPE

FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento : INT;      (* Código del evento actual *)
    nuevoEvento : BOOL; (* Señal de nuevo evento *)
    ciclo : TIME;      (* Período de ejecución del bloque *)
END_VAR
VAR_OUTPUT
    buffer : ARRAY[0..19] OF ST_Evento; (* Buffer circular de eventos *)
    indice : INT := -1;  (* Índice del último evento registrado *)
    nEventos : INT := 0; (* Número de eventos registrados *)
END_VAR
VAR
    tiempoAcumulado : TIME := T#0S; (* Tiempo acumulado desde el arranque *)
    nuevoEventoPrev : BOOL := FALSE; (* Estado anterior de nuevoEvento *)
END_VAR

(* Acumula el tiempo de ejecución *)
tiempoAcumulado := tiempoAcumulado + ciclo;

(* Detecta transición de FALSE a TRUE en nuevoEvento *)
IF (nuevoEvento AND NOT nuevoEventoPrev) THEN
    (* Incrementa el índice circular *)
    indice := (indice + 1) MOD 20;
    
    (* Registra el evento en el buffer *)
    buffer[indice].codigo := evento;
    buffer[indice].marca := tiempoAcumulado;
    
    (* Actualiza el número de eventos registrados *)
    IF nEventos < 20 THEN
        nEventos := nEventos + 1;
    END_IF
END_IF

(* Actualiza el estado anterior de nuevoEvento *)
nuevoEventoPrev := nuevoEvento;
END_FUNCTION_BLOCK
```