```pascal
FUNCTION_BLOCK FB_Giro
VAR_INPUT
    btnFwd  : BOOL; (* Botón marcha horaria *)
    btnRev  : BOOL; (* Botón marcha antihoraria *)
    btnParo : BOOL; (* Botón paro *)
END_VAR

VAR_OUTPUT
    fwd : BOOL; (* Salida giro horario *)
    rev : BOOL; (* Salida giro antihorario *)
END_VAR

VAR
    (* Estados internos del bloque *)
    stateFwd : BOOL; (* Estado interno: motor en marcha horaria *)
    stateRev : BOOL; (* Estado interno: motor en marcha antihoraria *)
END_VAR

(*
    Lógica de control:
    - btnParo detiene cualquier giro (prioridad máxima).
    - btnFwd activa marcha horaria SOLO si el motor está parado.
    - btnRev activa marcha antihoraria SOLO si el motor está parado.
    - El interbloqueo impide que fwd y rev sean TRUE simultáneamente.
*)

(* 1. Paro: tiene prioridad sobre todo *)
IF btnParo THEN
    stateFwd := FALSE;
    stateRev := FALSE;

(* 2. Marcha horaria: solo si el motor está completamente parado *)
ELSIF btnFwd AND NOT stateRev THEN
    stateFwd := TRUE;

(* 3. Marcha antihoraria: solo si el motor está completamente parado *)
ELSIF btnRev AND NOT stateFwd THEN
    stateRev := TRUE;

END_IF;

(* 4. Asignación de salidas con interbloqueo hardware por software *)
fwd := stateFwd AND NOT stateRev; (* Interbloqueo explícito *)
rev := stateRev AND NOT stateFwd; (* Interbloqueo explícito *)

END_FUNCTION_BLOCK
```

---

### Explicación de la lógica

| Condición | Resultado |
|---|---|
| `btnParo = TRUE` | Ambos estados internos se ponen a `FALSE` (paro inmediato) |
| `btnFwd = TRUE` y motor parado (`stateRev = FALSE`) | Se activa `stateFwd` |
| `btnRev = TRUE` y motor parado (`stateFwd = FALSE`) | Se activa `stateRev` |
| `btnFwd` mientras gira en reversa | **Ignorado** — debe pasar por paro primero |
| `btnRev` mientras gira en directa | **Ignorado** — debe pasar por paro primero |

**Doble interbloqueo**: la protección se aplica en dos capas:
1. **Lógica de estados**: `ELSIF` impide cambiar de sentido sin pasar por paro.
2. **Asignación de salidas**: `fwd := stateFwd AND NOT stateRev` garantiza que, ante cualquier inconsistencia, las salidas físicas **nunca** sean `TRUE` simultáneamente.