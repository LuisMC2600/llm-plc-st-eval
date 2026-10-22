1. **Tabla de Entradas y Salidas**

| Nombre Propuesto | Tipo de Dato | Descripción |
|----------------|--------------|-------------|
| tanqueVacio    | BOOL         | Indica si el tanque de arriba está vacío |
| pozoSeco       | BOOL         | Indica si el pozo está sin agua |
| btnApagar      | BOOL         | Botón para apagar la bomba manualmente |
| bombaArranca   | BOOL         | Salida para controlar el arranque de la bomba |
| luzAlerta      | BOOL         | Luz que avisa cuando algo anda mal |

2. **Tipo de POU Recomendado**

Recomendaría utilizar un **FUNCTION_BLOCK** para este control. La razón es que un FUNCTION_BLOCK permite encapsular el estado interno del sistema (como el temporizador para controlar el arranque de la bomba) y facilita la reutilización y la gestión de las variables de entrada y salida.

3. **Lista de Ambigüedades o Información Faltante**

- **Definición de "algo anda mal":** ¿Qué condiciones específicas deberían activar la luz de alerta? Por ejemplo, ¿si la bomba se enciende cuando el pozo está seco? ¿O si el botón de apagado no funciona?
- **Tiempo de espera antes de arrancar la bomba:** ¿Cuánto tiempo debe esperar la bomba después de que el tanque esté vacío antes de arrancar?
- **Control de sobrecalentamiento:** ¿Hay algún sensor de temperatura que indique si la bomba se está quemando? ¿Qué temperatura considera el cliente como "quemarse"?
- **Comportamiento en caso de apagón:** ¿Qué debería hacer la bomba si el botón de apagón se mantiene pulsado durante un tiempo prolongado? ¿Debería tener un tiempo de espera antes de apagarse?
- **Control de arranque múltiple:** ¿Debería haber alguna lógica para evitar que la bomba arranque múltiples veces en un corto periodo de tiempo?