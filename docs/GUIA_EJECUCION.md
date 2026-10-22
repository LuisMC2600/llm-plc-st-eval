# Guía de ejecución — de los prompts a los datos experimentales

Ruta operativa desde hoy hasta tener el dataset primario completo (Fases 2–4 del plan).
Marca cada casilla al completarla; anota fechas en la bitácora (sirven para la Metodología del informe).

---

## Etapa 0 — Validar antes de gastar un token (Hito H1)

- [ ] **0.1** Revisar `Prompts_Banco_v0.md` con la asesora en el piloto. Atención especial a A2, A3, A5 y A6 (yo concreté sus E/S; deben validarse).
- [ ] **0.2** Resolver tú mismo 2–3 tareas (una por nivel) en CODESYS partiendo solo del prompt, como lo haría el modelo. Si un enunciado te resulta ambiguo a ti, lo será para el modelo: corregirlo.
- [ ] **0.3** Todo cambio se hace **editando `generar_prompts.py` y regenerando** (`python generar_prompts.py`). Nunca editar `tasks.json` ni el `.md` a mano — son productos derivados.
- [ ] **0.4** Con el visto bueno: congelar banco, prompts y rúbrica. **Hito H1 cumplido.** Desde aquí, ningún prompt cambia.

## Etapa 1 — Preparar el entorno (una sola vez)

- [ ] **1.1** Python 3.10+ instalado. En la carpeta `pipeline_tesis`: `pip install -r requirements.txt`.
- [ ] **1.2** Crear cuentas de desarrollador y generar claves API: OpenAI (platform.openai.com), Anthropic (console.anthropic.com), Google (aistudio.google.com). Cargar saldo mínimo (USD 5 por proveedor sobra: el presupuesto aprobado estima ~$21 en total).
- [ ] **1.3** Guardar las claves como **variables de entorno**, jamás en el código. En Windows (PowerShell):
  ```powershell
  setx OPENAI_API_KEY "sk-..."
  setx ANTHROPIC_API_KEY "sk-ant-..."
  setx GOOGLE_API_KEY "AI..."
  ```
  (cerrar y reabrir la terminal después de `setx`).
- [ ] **1.4** Instalar Ollama (ollama.com) y descargar el modelo local: `ollama pull qwen2.5-coder:14b` (~9 GB; requiere GPU o buena RAM). Si tu equipo no lo mueve con fluidez, usar `qwen2.5-coder:7b` y **documentar el cambio** en config y bitácora.
- [ ] **1.5** Instalar CODESYS (versión gratuita) y hacer la familiarización: crear un proyecto, compilar un FB de prueba, correr una simulación. Esto adelanta la mitigación del riesgo R3.
- [ ] **1.6** Crear un repositorio **git privado** (GitHub) con `pipeline_tesis/`. Añadir `.gitignore` con `repositorio/` si prefieres respaldar los datos por otra vía, y nunca subir claves. Mitiga el riesgo R7 (pérdida de datos).

## Etapa 2 — Congelar configuración y calibrar (tareas 3.1 y 3.4, Hito H2)

- [ ] **2.1** Verificar en la documentación de cada proveedor las **versiones vigentes** de los modelos ese mes y actualizar los `id` en `config.yaml` con el identificador exacto (p. ej. el string completo con fecha). Anotar fecha de congelamiento — riesgo R1.
- [ ] **2.2** `python runner.py --dry-run` → debe reportar **624 pendientes** (26 × 4 × 2 × 3). Si no, revisar config.
- [ ] **2.3** **Calibración con una sola tarea:** copiar `tasks.json` a `tasks_calibracion.json` dejando solo B1, apuntar `rutas.tareas` del config a ese archivo y correr `python runner.py`. Revisar:
  - que los `.st` lleguen completos (si aparecen cortados → subir `max_tokens`),
  - que el `log.jsonl` registre metadatos correctos,
  - el costo real por tarea (extrapolar × 26 y comparar con presupuesto).
- [ ] **2.4** Compilar en CODESYS las respuestas de la calibración para ensayar el flujo completo de la Fase 5 en miniatura.
- [ ] **2.5** Fijar parámetros definitivos (temperature, max_tokens) en `config.yaml`, devolver `rutas.tareas` a `tasks.json`, borrar la carpeta `repositorio/` de calibración (o archivarla aparte como "calibración"). **Hito H2 cumplido.**

## Etapa 3 — Ejecución experimental (Fase 4)

- [ ] **3.1** Correr `python runner.py`. Puede hacerse por lotes (comenta modelos en `config.yaml` para correr un proveedor a la vez); el runner es idempotente: se puede interrumpir y relanzar sin duplicar nada.
- [ ] **3.2** Los modelos locales (Ollama) son lentos: conviene dejarlos corriendo de noche. Los comerciales completan en horas; si aparecen errores de rate limit, el backoff los maneja solo.
- [ ] **3.3** Al terminar: `python runner.py --dry-run` debe reportar **0 pendientes**, y `python analisis_ejemplo.py` debe mostrar 624 registros y el chequeo `[OK] prompts idénticos entre modelos`.
- [ ] **3.4** **Respaldo inmediato del dato primario:** zip de `repositorio/` con fecha + push a git + copia en nube (Drive/OneDrive). Tres copias, dos medios.

## Etapa 4 — Entrada a la verificación (Fase 5)

- [ ] **4.1** Importar cada `.st` a CODESYS: registrar compila (1/0) en la hoja *Seguimiento Experimental* del banco.
- [ ] **4.2** Para los que compilan: simular contra el **criterio de éxito funcional** definido en el banco para esa tarea; puntuar con la rúbrica 5×4 en las fichas.
- [ ] **4.3** Para C1, C2 y C4: evaluar contra las **claves de evaluación** del documento de prompts.
- [ ] **4.4** Sesiones de validación de puntuaciones con la asesora (tarea 5.4) y clasificación de errores con la taxonomía CWE adaptada (tarea 5.5).

---

**Regla transversal:** todo lo que decidas (versión de modelo, cambio de parámetro, incidencia, fecha) va a la bitácora. La Metodología del informe se escribe sola desde esa bitácora.
