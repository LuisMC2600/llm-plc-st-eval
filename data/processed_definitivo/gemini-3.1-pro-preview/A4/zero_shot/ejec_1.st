FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL;       (* Consigna de velocidad *)
    paroRapido : BOOL;  (* Comando de paro rápido *)
    ciclo : TIME;       (* Tiempo de ciclo de ejecución del bloque *)
END_VAR

VAR_OUTPUT
    CVvel : REAL;       (* Velocidad actual de salida *)
END_VAR

VAR
    ciclo_s : REAL;     (* Tiempo de ciclo convertido a segundos *)
    target : REAL;      (* Valor objetivo temporal *)
    tasa : REAL;        (* Tasa de cambio activa (%/s) *)
    delta_max : REAL;   (* Cambio máximo permitido en el ciclo actual *)
    diferencia : REAL;  (* Diferencia entre el objetivo y la salida actual *)
END_VAR

(* Convertir el tiempo de ciclo (TIME) a segundos (REAL) *)
(* Se asume que TIME_TO_UDINT devuelve el tiempo en milisegundos, estándar en IEC 61131-3 *)
ciclo_s := UDINT_TO_REAL(TIME_TO_UDINT(ciclo)) / 1000.0;

(* Determinar el objetivo y la tasa de cambio según el estado *)
IF paroRapido THEN
    target := 0.0;
    tasa := 40.0;       (* Pendiente de paro rápido *)
ELSE
    target := SPvel;
    IF target > CVvel THEN
        tasa := 10.0;   (* Pendiente de subida *)
    ELSIF target < CVvel THEN
        tasa := 20.0;   (* Pendiente de bajada *)
    ELSE
        tasa := 0.0;    (* Sin cambio *)
    END_IF;
END_IF;

(* Calcular el incremento máximo y la diferencia *)
delta_max := tasa * ciclo_s;
diferencia := target - CVvel;

(* Actualizar la salida evitando el sobrepaso *)
IF ABS(diferencia) <= delta_max THEN
    CVvel := target;                (* Alcanza el objetivo sin sobrepasarlo *)
ELSIF diferencia > 0.0 THEN
    CVvel := CVvel + delta_max;     (* Incrementa hacia el objetivo *)
ELSE
    CVvel := CVvel - delta_max;     (* Decrementa hacia el objetivo *)
END_IF;

END_FUNCTION_BLOCK