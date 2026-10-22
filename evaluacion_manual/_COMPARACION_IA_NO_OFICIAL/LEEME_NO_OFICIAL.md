# Evaluación IA — NO OFICIAL (solo para comparar)

Fecha: 2026-10-08. A pedido de la asesora, un LLM (el asistente, modelo de Anthropic) hizo la misma evaluación a ciegas que los evaluadores humanos. **Estas calificaciones no son resultados oficiales de la tesis.** No sustituyen a las humanas ni se usan en `analizar_fichas.py`, y no van en `data/results/`.

## Archivos

- `evaluacion_manual/_COMPARACION_IA_NO_OFICIAL/Ficha_IA_NO_OFICIAL_Diagnostico.xlsx`: C1, C5, C6 y C2 (96 respuestas). Tiene el mismo formato que `Ficha_Evaluador1.xlsx`.
- `evaluacion_rubrica/_COMPARACION_IA_NO_OFICIAL/Ficha_IA_NO_OFICIAL_Rubrica.xlsx`: 25 tareas × 24 = 600 respuestas. Tiene el mismo formato que `Ficha_Rubrica_Evaluador1.xlsx`, con las justificaciones incluidas.
- `comparar_humano_vs_ia.py`: compara una ficha humana con la ficha IA, emparejando por código.

## Método

- Material: el mismo que recibieron los humanos (enunciado, clave o rúbrica, protocolo de prueba, resultado de CODESYS, código extraído), identificado solo por código. El LLM no usó las asignaciones selladas y no leyó ninguna calificación humana antes de terminar.
- Reglas: las mismas instrucciones de las fichas. Los valores fijados por CODESYS se respetaron (validado: 0 discrepancias).
- Ejecución: 13 subagentes del mismo modelo, cada uno con un grupo de tareas. Esto puede dar pequeñas diferencias de criterio entre grupos; la principal está abajo.

## Sesgos y advertencias

1. **Autopreferencia.** Uno de los modelos evaluados es `claude-sonnet-4-6`, de la misma familia que el evaluador. El cegado por código lo mitiga, pero no lo elimina, porque el estilo del código puede delatar al modelo.
2. **Interfaz no conforme (28 respuestas).** En B7 y C3 (12 respuestas) se puso IEC = 2. En el resto (16 respuestas, en A3, B2, B5, C8, I1, I2, I4 e I8) se puso IEC = 1. Conviene compararlo con la regla que aplicaron ustedes.
3. **Defectos fuera del harness.** Varios grupos bajaron coherencia por fallos que la simulación no detecta, por ejemplo I3 (ack por nivel), I1-2168, I1-8541, I5-9795 e I5-6738.
4. **B3.** El pin estándar `R` del CTU no compila en CODESYS y el pin `RESET` de CODESYS sí. A las que usan `RESET` se les puso IEC 2, no 3.
5. **Literales del enunciado.** Mantenibilidad quedó baja (1–2) cuando hay valores literales, aunque el enunciado los imponga.

## Medias IA (600 respuestas)

Funcional 1,90 · IEC 2,12 · Coherencia 1,85 · Claridad 1,99 · Mantenibilidad 1,64.

## Cómo comparar

```
python comparar_humano_vs_ia.py diagnostico <Ficha_Evaluador1.xlsx> Ficha_IA_NO_OFICIAL_Diagnostico.xlsx salida.csv
python comparar_humano_vs_ia.py rubrica     <Ficha_Rubrica_Evaluador1.xlsx> Ficha_IA_NO_OFICIAL_Rubrica.xlsx salida.csv
```

El script reporta, por ítem o criterio, el acuerdo, el kappa de Cohen, el kappa ponderado cuadrático, el acuerdo ±1 y la diferencia media (IA − humano). En la rúbrica también reporta funcional e IEC solo sobre las celdas no fijadas, que son las que importan. Además lista en `*_desacuerdos.csv` las celdas con una diferencia de 2 o más.
