# Comparación de evaluadores LLM: Claude vs DeepSeek

Fecha: 2026-10-09 (hora de Panamá). Soporta la decisión pendiente del INC-35: qué evaluación queda como oficial.

## Evaluadores

| | Evaluador 1 | Evaluador 2 |
|---|---|---|
| Modelo | Claude (Anthropic), con 13 subagentes | `deepseek-v4-pro`, razonamiento activado (esfuerzo high) |
| Fecha | 2026-10-08 | 2026-10-09, de 02:20 a 07:36 |
| Material | 29 entradas a ciegas | las mismas 29 entradas y las mismas instrucciones |
| Relación con los modelos evaluados | misma familia que `claude-sonnet-4-6` | ninguna |
| Costo | — | ≈ USD 1,93 (30 llamadas; 1 reintento de formato en A1) |

Las dos salidas pasan la misma validación: 24 objetos por tarea, códigos correctos, rangos correctos y valores fijados por CODESYS copiados.

## Concordancia: rúbrica (600 respuestas)

| Criterio | n | Acuerdo exacto | κ | κ ponderado | Acuerdo ±1 | Media DS − Claude |
|---|---|---|---|---|---|---|
| Funcional (solo no fijadas) | 167 | 76,6 % | 0,54 | 0,71 | 100 % | −0,15 |
| IEC (solo no fijadas) | 518 | 83,8 % | 0,71 | 0,68 | 97,7 % | −0,04 |
| Coherencia | 600 | 65,0 % | 0,48 | 0,85 | 97,7 % | +0,29 |
| Claridad | 600 | 64,2 % | 0,31 | 0,46 | 99,3 % | +0,21 |
| Mantenibilidad | 600 | 67,3 % | 0,38 | 0,48 | 100 % | −0,04 |

- Las diferencias de 2 o más puntos son 30 de 3 000 puntuaciones, un 1 % (14 en coherencia, 12 en IEC y 4 en claridad). La lista está en `rubrica_claude_vs_deepseek_desacuerdos.csv`.
- El κ es bajo en claridad y mantenibilidad aunque el acuerdo ±1 sea casi del 100 %. Esto ocurre porque las puntuaciones se concentran en 1–2 niveles y los dos evaluadores difieren por un nivel en la frontera. En coherencia, DeepSeek es sistemáticamente más benévolo.

## Concordancia: diagnóstico (C1, C5, C6) y C2

- Detección de los errores de la clave: acuerdo del 92 al 100 % por ítem.
- Las mayores discrepancias están en los conteos de hallazgos adicionales y errores inventados de C1. DeepSeek cuenta como "inventado" lo que Claude cuenta como "adicional".
- En C2, las E/S, los tipos y el POU coinciden en un 88–100 %. Las ambigüedades A3 y A4 coinciden en un 75 y 83 %. DeepSeek reporta más ambigüedades adicionales.

## ¿Cambian las conclusiones según el evaluador? No.

Total de la rúbrica (0–15), media por modelo evaluado:

| Modelo | Claude evalúa | DeepSeek evalúa |
|---|---|---|
| Gemini 3.1 Pro | 12,56 | 12,71 |
| Claude Sonnet 4.6 | 11,27 | 11,84 |
| GPT-4o | 7,73 | 7,99 |
| Qwen2.5-Coder 14B | 6,38 | 6,94 |

- El ranking es idéntico con los dos evaluadores.
- **No se observa autopreferencia.** Claude como evaluador puntúa a Claude Sonnet 4.6 *más bajo* que DeepSeek: +0,27 en coherencia y +0,24 en claridad a favor de DeepSeek. Esa diferencia es similar a la que muestra con los demás modelos.
- En el diagnóstico, la detección media por modelo es prácticamente igual con los dos evaluadores.

## Opciones de decisión

1. **DeepSeek como oficial y Claude como segundo evaluador (recomendada).** El evaluador oficial no pertenece a la familia de ningún modelo evaluado, lo que elimina la objeción de autopreferencia. La concordancia con Claude se reporta como confiabilidad entre evaluadores.
2. **Promedio de ambos (panel de dos jueces).** Reduce el sesgo propio de cada evaluador, pero produce medias puntuaciones y se aleja del formato de la ficha.
3. **Claude como oficial.** Es válido porque los datos no muestran autopreferencia, pero es más fácil de objetar en la defensa.

Con cualquiera de las tres hay que reportar el κ ponderado por criterio y declarar que claridad y mantenibilidad tienen una confiabilidad moderada (κw ≈ 0,46–0,48).
