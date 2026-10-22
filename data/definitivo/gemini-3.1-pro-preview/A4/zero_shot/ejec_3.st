```iecst
FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL;       (* Consigna de velocidad objetivo *)
    paroRapido : BOOL;  (* Comando de paro rápido *)
    ciclo : TIME;       (* Período de ejecución del bloque *)
END_VAR
VAR_OUTPUT
    CVvel : REAL;       (* Consigna de velocidad actual (salida con rampa) *)
END_VAR
VAR
    ciclo_s : REAL;     (* Tiempo de ciclo convertido a segundos *)
    target : REAL;      (* Objetivo de velocidad a alcanzar *)
    stepUp : REAL;      (* Paso máximo de incremento por ciclo *)
    stepDown : REAL;    (* Paso máximo de decremento por ciclo *)
END_VAR

(* Convertir el tiempo de ciclo a segundos (asumiendo que TIME internamente está en milisegundos) *)
ciclo_s := DINT_TO_REAL(TIME_TO_DINT(ciclo)) / 1000.0;

(* Configurar el objetivo y las pendientes según el estado de paro rápido *)
IF paroRapido THEN
    target := 0.0;
    (* En paro rápido, la pendiente es 40.0 pts/s tanto si desciende desde positivo como si asciende desde negativo *)
    stepUp := 40.0 * ciclo_s;   
    stepDown := 40.0 * ciclo_s; 
ELSE
    target := SPvel;
    stepUp := 10.0 * ciclo_s;   (* Pendiente de subida: 10.0 pts/s *)
    stepDown := 20.0 * ciclo_s; (* Pendiente de bajada: 20.0 pts/s *)
END_IF;

(* Aplicar la rampa hacia el objetivo asegurando que no haya sobrepaso *)
IF CVvel < target THEN
    CVvel := CVvel + stepUp;
    IF CVvel > target THEN
        CVvel := target; (* Evitar sobrepaso al subir *)
    END_IF;
ELSIF CVvel > target THEN
    CVvel := CVvel - stepDown;
    IF CVvel < target THEN
        CVvel := target; (* Evitar sobrepaso al bajar *)
    END_IF;
END_IF;

END_FUNCTION_BLOCK
```