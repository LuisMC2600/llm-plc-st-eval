1. **Tabla de entradas y salidas**

| Nombre          | Tipo de dato | Descripción                                      |
|-----------------|--------------|--------------------------------------------------|
| tanqueVacio     | BOOL         | Indica si el tanque de arriba está vacío          |
| pozoSeco        | BOOL         | Indica si el pozo está sin agua                   |
| btnApagar       | BOOL         | Botón para apagar manualmente la bomba             |
| bombaArrancada  | BOOL         | Indica si la bomba está arrancada                 |
| luzAlerta       | BOOL         | Indica si hay un problema (luz de advertencia)     |

2. **Tipo de POU recomendado**

Recomendaría utilizar un **FUNCTION_BLOCK**. La razón es que un FUNCTION_BLOCK permite encapsular el estado interno de la bomba y sus comportamientos, lo que facilita la gestión de las condiciones de arranque y apagado, así como la lógica de la luz de advertencia. Además, un FUNCTION_BLOCK puede ser reutilizado y es adecuado para controlar dispositivos que tienen un estado persistente.

3. **Lista de ambigüedades o información faltante**

- **Tiempo de arranque automático**: ¿Cuánto tiempo debe esperar la bomba después de que el tanque esté vacío antes de arrancar?
- **Tiempo de encendido máximo**: ¿Existe un límite de tiempo máximo que la bomba debe estar encendida antes de apagarse automáticamente?
- **Condición de alerta específica**: ¿Qué condiciones específicas deben cumplirse para encender la luz de advertencia? Por ejemplo, ¿solo cuando la bomba se quema o también en otras situaciones?
- **Prioridad de comandos**: ¿Cuál tiene prioridad, el botón de apagado manual o las condiciones de arranque automático?
- **Estado inicial de la bomba**: ¿Debería la bomba estar apagada o encendida al inicio del sistema?
- **Control de temperatura**: ¿Existe algún sensor de temperatura que pueda detectar si la bomba se está quemando? ¿Cómo se manejaría esa información?