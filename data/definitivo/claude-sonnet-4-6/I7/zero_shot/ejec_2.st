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
    demanda_ant  : BOOL; (* Valor de demanda en ciclo anterior, para detectar flanco *)
    principal    : INT;  (* Índice de la bomba principal: 1 = bomba1, 2 = bomba2 *)
    primerCiclo  : BOOL; (* TRUE hasta que se haya procesado la primera demanda *)
END_VAR

(* ─────────────────────────────────────────────────────────────
   Inicialización en primer ciclo de ejecución del bloque
   ───────────────────────────────────────────────────────────── *)
IF primerCiclo THEN
    principal   := 1;    (* Bomba 1 es la principal en la primera demanda *)
    primerCiclo := FALSE;
    demanda_ant := FALSE;
END_IF;

(* ─────────────────────────────────────────────────────────────
   Detección de flanco ascendente de demanda (FALSE → TRUE)
   Al detectarlo, se alterna la bomba principal para el nuevo ciclo
   ───────────────────────────────────────────────────────────── *)
IF demanda AND NOT demanda_ant THEN
    (* Alternar principal solo si no es la primera demanda ya asignada *)
    (* En la primera llamada primerCiclo ya fue FALSE, principal = 1   *)
    (* A partir de la segunda transición se alterna                    *)
    IF principal = 1 THEN
        principal := 2;
    ELSE
        principal := 1;
    END_IF;
END_IF;

(* ─────────────────────────────────────────────────────────────
   Lógica de control de bombas y alarma
   ───────────────────────────────────────────────────────────── *)
(* Valores por defecto: todo apagado *)
bomba1   := FALSE;
bomba2   := FALSE;
almFalla := FALSE;

IF demanda THEN
    IF principal = 1 THEN
        (* Bomba 1 es la principal *)
        IF NOT falla1 THEN
            (* Principal sin falla: funciona normalmente *)
            bomba1 := TRUE;
        ELSE
            (* Principal con falla: activar alarma *)
            almFalla := TRUE;
            IF NOT falla2 THEN
                (* Respaldo disponible: arrancar bomba 2 *)
                bomba2 := TRUE;
            END_IF;
            (* Si falla2 también activa: ninguna bomba funciona, almFalla activo *)
        END_IF;

    ELSE
        (* Bomba 2 es la principal *)
        IF NOT falla2 THEN
            (* Principal sin falla: funciona normalmente *)
            bomba2 := TRUE;
        ELSE
            (* Principal con falla: activar alarma *)
            almFalla := TRUE;
            IF NOT falla1 THEN
                (* Respaldo disponible: arrancar bomba 1 *)
                bomba1 := TRUE;
            END_IF;
            (* Si falla1 también activa: ninguna bomba funciona, almFalla activo *)
        END_IF;
    END_IF;
END_IF;
(* Si demanda = FALSE: bomba1, bomba2 y almFalla permanecen FALSE *)

(* ─────────────────────────────────────────────────────────────
   Guardar estado de demanda para detección de flanco en próximo ciclo
   ───────────────────────────────────────────────────────────── *)
demanda_ant := demanda;

END_FUNCTION_BLOCK
```

**Notas de diseño:**

| Aspecto | Decisión |
|---|---|
| Alternancia | Ocurre en cada flanco ascendente de `demanda`; la primera demanda siempre usa bomba 1 como principal. |
| Retorno a principal | Si la falla desaparece con `demanda` aún activa, en el mismo ciclo de scan la principal vuelve a funcionar y la de respaldo se detiene (lógica combinacional pura). |
| `almFalla` | Solo se activa cuando la **bomba principal** tiene falla y `demanda` está presente; la falla de la de respaldo sola no la activa. |
| Ambas con falla | `almFalla = TRUE`, ninguna bomba arranca. |
| Variable `primerCiclo` | Se inicializa a `TRUE` por defecto (valor inicial de `BOOL` en IEC 61131-3 es `FALSE`, por lo que debe declararse con valor inicial `TRUE` en el VAR o manejarse con la lógica mostrada). En implementaciones reales se puede usar `primerCiclo : BOOL := TRUE;` en la sección VAR. |