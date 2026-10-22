(* DOBLE DE PRUEBA A5/PrimeroEnPosicion1 - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 0 *)
TYPE ST_Evento :
STRUCT
    codigo : INT;
    marca : TIME;
END_STRUCT
END_TYPE

FUNCTION_BLOCK FB_Registro
VAR_INPUT
    evento : INT;
    nuevoEvento : BOOL;
    ciclo : TIME;
END_VAR
VAR_OUTPUT
    buffer : ARRAY[0..19] OF ST_Evento;
    indice : INT;
    nEventos : INT;
END_VAR
VAR
    tAcum : TIME;
    prev : BOOL;
    nTotal : INT;
END_VAR
tAcum := tAcum + ciclo;
IF (nuevoEvento AND NOT prev) AND (TRUE) THEN
    indice := (indice + 1) MOD 20;
    buffer[indice].codigo := evento;
    buffer[indice].marca := tAcum;
    nEventos := MIN(20, nEventos + 1);
END_IF
prev := nuevoEvento;
END_FUNCTION_BLOCK
