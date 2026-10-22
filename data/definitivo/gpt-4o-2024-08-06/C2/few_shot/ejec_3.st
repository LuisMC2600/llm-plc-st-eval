1. Tabla de entradas y salidas:

| Nombre       | Tipo de dato | Descripción                                                  |
|--------------|--------------|--------------------------------------------------------------|
| tanqueVacio  | BOOL         | Indica si el tanque de arriba está vacío                     |
| pozoSinAgua  | BOOL         | Indica si el pozo está sin agua                              |
| btnApagar    | BOOL         | Botón para apagar manualmente la bomba                       |
| bombaPozo    | BOOL         | Salida para controlar el estado de la bomba del pozo         |
| luzAlarma    | BOOL         | Luz indicadora de que algo está mal (pozo sin agua)          |

2. Tipo de POU recomendado: FUNCTION_BLOCK

Justificación: Un FUNCTION_BLOCK es adecuado porque encapsula el comportamiento de control de la bomba del pozo, permitiendo gestionar múltiples estados y condiciones (como el estado del tanque, el pozo y el botón de apagado). Además, facilita la reutilización del bloque en diferentes partes del programa o en otros proyectos.

3. Lista de ambigüedades o información faltante:

- ¿Qué debe suceder si el tanque está vacío y el pozo tiene agua, pero el botón de apagado está activado? ¿Debe la bomba permanecer apagada?
- ¿Qué condiciones específicas deben activar la luz de alarma? ¿Solo cuando el pozo está sin agua o también en otras situaciones?
- ¿Debe haber algún tipo de retardo o temporización en el encendido o apagado de la bomba para evitar ciclos rápidos de encendido/apagado?
- ¿Existen otras condiciones de seguridad o fallos que deban ser considerados para el control de la bomba?
- ¿Cómo se debe manejar la situación cuando el tanque se llena? ¿Debe la bomba apagarse automáticamente?