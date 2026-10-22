FUNCTION_BLOCK FB_Rampa
VAR_INPUT
    SPvel : REAL; (* Consigna de velocidad *)
    paroRapido : BOOL; (* Paro rápido activo *)
    ciclo : TIME; (* Ciclo de ejecución *)
END_VAR
VAR_OUTPUT
    CVvel : REAL; (* Condicional de velocidad *)
END_VAR
VAR
    error : REAL; (* Error entre SPvel y CVvel *)
    dt : TIME; (* Tiempo transcurrido desde la última ejecución *)
    dtSec : REAL; (* Tiempo transcurrido en segundos *)
    rampaSubida : REAL; (* Pendiente de subida *)
    rampaBajada : REAL; (* Pendiente de bajada *)
    rampaParoRapido : REAL; (* Pendiente de paro rápido *)
END_VAR

(* Inicialización de las rampas *)
rampaSubida := 10.0;
rampaBajada := 20.0;
rampaParoRapido := 40.0;

(* Cálculo del tiempo transcurrido en segundos *)
dt := ciclo;
dtSec := dt / T#1S;

(* Lógica de paro rápido *)
IF paroRapido THEN
    CVvel := MAX(0.0, CVvel - rampaParoRapido * dtSec);
ELSE
    (* Cálculo del error *)
    error := SPvel - CVvel;

    (* Ajuste de CVvel con rampa *)
    IF error > 0 THEN
        CVvel := MIN(CVvel + rampaSubida * dtSec, SPvel);
    ELSE
        CVvel := MAX(CVvel - rampaBajada * dtSec, SPvel);
    END_IF;
END_IF;

(* Evitar sobrepaso *)
IF CVvel > SPvel THEN
    CVvel := SPvel;
ELSIF CVvel < 0.0 THEN
    CVvel := 0.0;
END_IF;

END_FUNCTION_BLOCK