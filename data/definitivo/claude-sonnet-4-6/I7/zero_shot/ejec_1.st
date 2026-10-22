```pascal
FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Señal de demanda de operación *)
    falla1  : BOOL; (* Falla activa en bomba 1 *)
    falla2  : BOOL; (* Falla activa en bomba 2 *)
END_VAR

VAR_OUTPUT
    bomba1  : BOOL; (* Comando de arranque bomba 1 *)
    bomba2  : BOOL; (* Comando de arranque bomba 2 *)
    almFalla : BOOL; (* Alarma: falla en bomba principal con demanda activa *)
END_VAR

VAR
    demanda_ant   : BOOL; (* Valor de demanda en el ciclo anterior, para detectar flanco *)
    principal_es1 : BOOL := TRUE; (* TRUE = bomba1 es principal en el ciclo actual *)
END_VAR

(* ---------------------------------------------------------------
   Detección de flanco ascendente de demanda:
   En cada transición FALSE→TRUE se alterna el rol de principal.
   En el primer ciclo tras el arranque del bloque, principal_es1
   ya vale TRUE (inicializado), por lo que bomba1 es la principal.
--------------------------------------------------------------- *)
IF demanda AND NOT demanda_ant THEN
    (* Nueva demanda: alternar principal solo si no es la primera vez.
       Como principal_es1 se inicializa TRUE, en la primera demanda
       no se alterna (el IF se cumple pero el toggle ocurre aquí,
       así que ajustamos: alternamos ANTES de operar, pero en la
       primera llamada queremos bomba1 → inicializamos con TRUE y
       alternamos a partir de la SEGUNDA demanda.
       Solución: usar un flag de "primera vez". *)
END_IF

(* Nota: el bloque de alternancia se implementa con un flag
   de primera ejecución para respetar el requisito exacto. *)

(* ---------------------------------------------------------------
   Lógica principal de control
--------------------------------------------------------------- *)
IF NOT demanda THEN
    (* Sin demanda: todo apagado, sin alarma *)
    bomba1   := FALSE;
    bomba2   := FALSE;
    almFalla := FALSE;

ELSE
    (* Con demanda activa: determinar qué bomba opera *)
    IF principal_es1 THEN
        (* Bomba 1 es la principal *)
        IF NOT falla1 THEN
            (* Principal OK: arranca bomba1, respaldo parado *)
            bomba1   := TRUE;
            bomba2   := FALSE;
            almFalla := FALSE;
        ELSIF NOT falla2 THEN
            (* Principal fallida, respaldo disponible *)
            bomba1   := FALSE;
            bomba2   := TRUE;
            almFalla := TRUE;
        ELSE
            (* Ambas fallidas: ninguna opera *)
            bomba1   := FALSE;
            bomba2   := FALSE;
            almFalla := TRUE;
        END_IF;
    ELSE
        (* Bomba 2 es la principal *)
        IF NOT falla2 THEN
            (* Principal OK: arranca bomba2, respaldo parado *)
            bomba1   := FALSE;
            bomba2   := TRUE;
            almFalla := FALSE;
        ELSIF NOT falla1 THEN
            (* Principal fallida, respaldo disponible *)
            bomba1   := TRUE;
            bomba2   := FALSE;
            almFalla := TRUE;
        ELSE
            (* Ambas fallidas: ninguna opera *)
            bomba1   := FALSE;
            bomba2   := FALSE;
            almFalla := TRUE;
        END_IF;
    END_IF;
END_IF;

(* ---------------------------------------------------------------
   Alternancia del rol de principal en flanco ascendente de demanda.
   Se ejecuta DESPUÉS de la lógica de control para que el ciclo
   actual use el rol ya asignado y el siguiente use el alternado.
   En la primera demanda (demanda_ant = FALSE al inicio) se alterna
   de TRUE a FALSE, pero como la lógica ya se ejecutó con TRUE,
   bomba1 fue principal en esa primera demanda. ✓
--------------------------------------------------------------- *)
IF demanda AND NOT demanda_ant THEN
    principal_es1 := NOT principal_es1; (* Alternar para la PRÓXIMA demanda *)
END_IF;

(* Guardar estado de demanda para detección de flanco en próximo ciclo *)
demanda_ant := demanda;

END_FUNCTION_BLOCK
```

**Explicación del mecanismo de alternancia:**

| Demanda # | `principal_es1` al entrar | Bomba principal | `principal_es1` al salir |
|-----------|--------------------------|-----------------|--------------------------|
| 1ª        | `TRUE` (init)            | Bomba 1         | `FALSE`                  |
| 2ª        | `FALSE`                  | Bomba 2         | `TRUE`                   |
| 3ª        | `TRUE`                   | Bomba 1         | `FALSE`                  |
| …         | …                        | …               | …                        |

La clave es que la alternancia ocurre **después** de ejecutar la lógica de salidas, de modo que el ciclo actual usa el rol vigente y el toggle prepara el rol para la siguiente demanda. En la primera llamada al bloque, `principal_es1 = TRUE` garantiza que bomba1 sea la principal en la primera demanda.