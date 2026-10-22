```iecst
FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL;       (* Consigna de velocidad objetivo *)
    paroRapido : BOOL;  (* Comando para detención rápida *)
    ciclo : TIME;       (* Período de ejecución del bloque *)
END_VAR

VAR_OUTPUT
    CVvel : REAL;       (* Velocidad de salida con rampa aplicada *)
END_VAR

VAR
    dt : REAL;          (* Tiempo de ciclo convertido a segundos *)
    objetivo : REAL;    (* Valor al que debe tender la salida *)
    deltaMax : REAL;    (* Cambio máximo permitido en el ciclo actual *)
    diferencia : REAL;  (* Diferencia entre el objetivo y la salida actual *)
END_VAR

(* 1. Convertir el tiempo de ciclo (TIME) a segundos (REAL) *)
dt := TIME_TO_REAL(ciclo) / 1000.0;

(* 2. Determinar el valor objetivo y el incremento/decremento máximo (deltaMax) *)
IF paroRapido THEN
    objetivo := 0.0;
    deltaMax := 40.0 * dt; (* Pendiente de paro rápido: 40.0 %/s *)
ELSE
    objetivo := SPvel;
    IF objetivo > CVvel THEN
        deltaMax := 10.0 * dt; (* Pendiente de subida normal: 10.0 %/s *)
    ELSE
        deltaMax := 20.0 * dt; (* Pendiente de bajada normal: 20.0 %/s *)
    END_IF;
END_IF;

(* 3. Calcular la diferencia entre el objetivo y el valor actual *)
diferencia := objetivo - CVvel;

(* 4. Aplicar la rampa asegurando que no haya sobrepaso *)
IF diferencia > 0.0 THEN
    (* Se requiere subir la velocidad *)
    IF diferencia > deltaMax THEN
        CVvel := CVvel + deltaMax;
    ELSE
        CVvel := objetivo; (* Evita el sobrepaso *)
    END_IF;
ELSIF diferencia < 0.0 THEN
    (* Se requiere bajar la velocidad *)
    IF -diferencia > deltaMax THEN
        CVvel := CVvel - deltaMax;
    ELSE
        CVvel := objetivo; (* Evita el sobrepaso *)
    END_IF;
END_IF;

END_FUNCTION_BLOCK
```