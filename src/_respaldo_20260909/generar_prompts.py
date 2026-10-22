"""
Generador de prompts experimentales — tareas 2.2 y 2.4 del plan de trabajo.
Fuente única de verdad: los enunciados viven aquí; el script produce
  (1) ../Prompts_Banco_v0.md   — documento para revisión con la asesora
  (2) tasks.json               — entrada directa del pipeline (runner.py)
Así, lo aprobado en el piloto es EXACTAMENTE lo que se ejecuta.
"""

import json

ROL = "Eres un asistente de programación de PLC. Trabajas conforme al estándar IEC 61131-3."

SALIDA_CODIGO = ("Entrega únicamente el código, con la declaración completa de "
                 "variables y comentarios breves.")

# ------------------------- Ejemplos few-shot (fijos) -------------------------
# Nivel básico, NO pertenecen al banco evaluado. Enseñan el formato, no la solución.
EJ1 = """Ejemplo 1.
Tarea: programa el control de la iluminación de un pasillo con dos interruptores conmutados: la luz debe encender cuando exactamente uno de los dos interruptores esté activado. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Pasillo con variables de entrada sw1, sw2 (BOOL) y salida luz (BOOL). Entrega únicamente el código, con la declaración completa de variables y comentarios breves.

Respuesta:
FUNCTION_BLOCK FB_Pasillo
VAR_INPUT
    sw1 : BOOL; (* Interruptor 1 *)
    sw2 : BOOL; (* Interruptor 2 *)
END_VAR
VAR_OUTPUT
    luz : BOOL; (* Luz del pasillo *)
END_VAR

(* La luz enciende cuando exactamente un interruptor esta activado *)
luz := sw1 XOR sw2;
END_FUNCTION_BLOCK"""

EJ2 = """Ejemplo 2.
Tarea: programa un pulso de lubricación: al pulsar el botón, la bomba de lubricación debe activarse exactamente 3 segundos y luego apagarse, aunque el botón siga pulsado. Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Lubricacion con variable de entrada btnLub (BOOL) y salida bombaLub (BOOL). Usa el tiempo T#3S. Entrega únicamente el código, con la declaración completa de variables y comentarios breves.

Respuesta:
FUNCTION_BLOCK FB_Lubricacion
VAR_INPUT
    btnLub : BOOL; (* Boton de lubricacion *)
END_VAR
VAR_OUTPUT
    bombaLub : BOOL; (* Bomba de lubricacion *)
END_VAR
VAR
    tPulso : TP; (* Temporizador de pulso *)
END_VAR

(* Pulso fijo de 3 s independiente de la duracion del boton *)
tPulso(IN := btnLub, PT := T#3S);
bombaLub := tPulso.Q;
END_FUNCTION_BLOCK"""

PREAMBULO_FS = ("A continuación se muestran dos ejemplos resueltos del formato de trabajo esperado.\n\n"
                + EJ1 + "\n\n" + EJ2 + "\n\n")

# ------------------------- Código para tareas C1 y C4 -------------------------
CODIGO_C1 = """FUNCTION_BLOCK FB_Semaforo
VAR_INPUT
    habilitado : BOOL;
END_VAR
VAR_OUTPUT
    luzV : BOOL;
    luzA : BOOL;
    luzR : BOOL;
END_VAR
VAR
    estado : INT;
    t1 : TON;
    parp : BOOL;
END_VAR

IF NOT habilitado THEN
    CASE estado OF
        0:
            luzV := TRUE; luzA := FALSE; luzR := FALSE;
            t1(IN := TRUE, PT := T#20S);
            IF t1.Q THEN estado := 1; END_IF
        1:
            luzV := FALSE; luzA := TRUE;
            t1(IN := TRUE, PT := T#4S);
            IF t1.Q THEN estado := 2; END_IF
        2:
            luzA := FALSE; luzR := TRUE;
            t1(IN := TRUE, PT := T#15S);
            IF t1.Q THEN estado := 0; END_IF
        3:
            luzA := parp;
    END_CASE
ELSE
    luzV := FALSE; luzA := FALSE; luzR := FALSE;
END_IF
END_FUNCTION_BLOCK"""

CODIGO_C4 = """FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL;
    falla1 : BOOL;
    falla2 : BOOL;
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;
    bomba2 : BOOL;
    almFalla : BOOL;
END_VAR
VAR
    turno : BOOL;
    fDem : R_TRIG;
END_VAR

fDem(CLK := demanda);
IF fDem.Q THEN
    turno := NOT turno;
END_IF
IF demanda THEN
    IF NOT turno THEN
        bomba1 := NOT falla1;
        bomba2 := falla1 AND NOT falla2;
    ELSE
        bomba2 := NOT falla2;
        bomba1 := falla2 AND NOT falla1;
    END_IF
ELSE
    bomba1 := FALSE;
    bomba2 := FALSE;
END_IF
almFalla := (falla1 OR falla2) AND demanda;
END_FUNCTION_BLOCK"""

# ------------------------- Banco de tareas -------------------------
# body = campos 2 a 6 del protocolo (contexto+enunciado+lenguaje+restricciones+salida).
# El campo 1 (rol) se antepone al armar el prompt.
T = []

def tarea(id_, nivel, titulo, body, clave=None):
    T.append({"id": id_, "nivel": nivel, "titulo": titulo, "body": body, "clave": clave})

# ============ NIVEL BÁSICO ============
tarea("B1", "Basico", "Arranque/paro de motor con enclavamiento",
"Tarea: programa el control de arranque y paro de un motor trifásico. El motor debe arrancar al pulsar el botón de marcha y mantenerse encendido al soltarlo. Debe detenerse al pulsar el botón de paro o el paro de emergencia; tras un paro de emergencia el motor no debe rearrancar aunque el botón de marcha siga pulsado. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Motor con variables de entrada btnMarcha, btnParo, btnEmerg (BOOL) y salida motorOn (BOOL). " + SALIDA_CODIGO)

tarea("B2", "Basico", "Válvula con retardo TON",
"Tarea: programa el control de una válvula de drenaje de un tanque. Cuando el sensor de nivel alto se active y permanezca activo durante 5 segundos continuos, la válvula debe abrir. Si el nivel deja de estar alto, la válvula debe cerrar de inmediato, sin retardo. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Valvula con variable de entrada nivelAlto (BOOL) y salida valvula (BOOL). Usa el tiempo T#5S. " + SALIDA_CODIGO)

tarea("B3", "Basico", "Contador de piezas con preset",
"Tarea: programa el conteo de piezas de una línea de producción. Cada vez que el sensor fotoeléctrico detecte una pieza (transición de FALSE a TRUE), la cuenta debe incrementarse en uno. Al llegar a 12 piezas debe activarse la salida de lote completo. Un botón de reset pone la cuenta en cero y desactiva la salida de lote. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Contador con variables de entrada sensorPieza, btnReset (BOOL) y salidas loteListo (BOOL) y cuenta (INT). " + SALIDA_CODIGO)

tarea("B4", "Basico", "Inversión de giro con enclavamiento cruzado",
"Tarea: programa la inversión de giro de un motor. Con el botón btnFwd el motor gira en sentido horario (salida fwd); con btnRev, en sentido antihorario (salida rev). Ambas salidas jamás deben estar activas simultáneamente y, para invertir el sentido de giro, es obligatorio pasar primero por el paro (btnParo). "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Giro con variables de entrada btnFwd, btnRev, btnParo (BOOL) y salidas fwd, rev (BOOL). " + SALIDA_CODIGO)

tarea("B5", "Basico", "Ventilador con retardo a la desconexión",
"Tarea: programa el ventilador de enfriamiento de un horno. Mientras el quemador esté encendido, el ventilador debe funcionar. Al apagarse el quemador, el ventilador debe continuar funcionando 30 segundos adicionales y luego detenerse. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Ventilador con variable de entrada quemadorOn (BOOL) y salida ventilador (BOOL). Usa el tiempo T#30S. " + SALIDA_CODIGO)

tarea("B6", "Basico", "Baliza intermitente",
"Tarea: programa una baliza de alarma. Mientras la condición de alarma esté activa, la lámpara debe parpadear con un ciclo de 1 segundo encendida y 1 segundo apagada. Sin alarma, la lámpara permanece apagada. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Baliza con variable de entrada alarma (BOOL) y salida lampara (BOOL). Usa tiempos T#1S. " + SALIDA_CODIGO)

tarea("B7", "Basico", "Selector manual/automático",
"Tarea: programa la selección de modo de operación de una bomba. La entrada modoAuto selecciona el modo: cuando está activa (modo automático), la bomba se enciende cuando nivelBajo esté activo; cuando está inactiva (modo manual), la bomba obedece directamente al botón btnManual. La conmutación entre modos no debe producir activaciones espurias de la bomba. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un PROGRAM llamado PRG_Bomba con variables de entrada modoAuto, btnManual, nivelBajo (BOOL) y salida bomba (BOOL). " + SALIDA_CODIGO)

tarea("B8", "Basico", "Conteo de eventos por flanco",
"Tarea: programa el registro de aperturas de una puerta de seguridad. Cada apertura (transición de FALSE a TRUE de la señal puertaAbierta) debe incrementar el número de aperturas en uno; mantener la puerta abierta no debe seguir contando. Al acumular 5 o más aperturas debe activarse la salida de aviso. La entrada reset pone el registro en cero y desactiva el aviso. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Puerta con variables de entrada puertaAbierta, reset (BOOL) y salidas aviso (BOOL) y nAperturas (INT). " + SALIDA_CODIGO)

# ============ NIVEL INTERMEDIO ============
tarea("I1", "Intermedio", "Semáforo con secuencia temporizada",
"Tarea: programa un semáforo vehicular cíclico: verde 20 segundos, amarillo 4 segundos, rojo 15 segundos, repitiendo la secuencia indefinidamente mientras la entrada habilitado esté activa. Si habilitado se desactiva, el semáforo debe pasar a amarillo intermitente (1 segundo encendido, 1 segundo apagado) con las demás luces apagadas; al habilitarse de nuevo, la secuencia reinicia en verde. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Semaforo con variable de entrada habilitado (BOOL) y salidas luzV, luzA, luzR (BOOL). Usa los tiempos T#20S, T#4S, T#15S y T#1S. " + SALIDA_CODIGO)

tarea("I2", "Intermedio", "FSM de llenado multietapa",
"Tarea: programa un proceso de llenado por etapas. En reposo, al pulsar btnInicio se abre la válvula de llenado (vLlenado) hasta que se active nivelAlto; después funciona el motor de mezcla (motorMezcla) durante 60 segundos; después se abre la válvula de descarga (vDescarga) hasta que se active nivelBajo; finalmente el proceso vuelve a reposo. El botón btnParo detiene el proceso en cualquier etapa, lleva todas las salidas a estado seguro (desactivadas) y regresa el proceso a reposo. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Llenado con variables de entrada nivelAlto, nivelBajo, btnInicio, btnParo (BOOL) y salidas vLlenado, motorMezcla, vDescarga (BOOL). Usa el tiempo T#60S. " + SALIDA_CODIGO)

tarea("I3", "Intermedio", "Gestión de alarmas con prioridad",
"Tarea: programa la gestión de tres alarmas con prioridad: alm1 es de prioridad alta, alm2 media y alm3 baja. Cualquier alarma activa enciende la sirena. La salida codigoAlm debe reportar el número de la alarma de mayor prioridad presente (1, 2 o 3; 0 si no hay alarmas). Cada alarma debe quedar retenida (aunque su causa desaparezca) hasta que se reconozca individualmente con ack1, ack2 o ack3, respectivamente; el reconocimiento solo tiene efecto si la causa ya desapareció. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Alarmas con variables de entrada alm1, alm2, alm3, ack1, ack2, ack3 (BOOL) y salidas sirena (BOOL) y codigoAlm (INT). " + SALIDA_CODIGO)

tarea("I4", "Intermedio", "Arranque estrella-triángulo",
"Tarea: programa un arranque estrella-triángulo. Al pulsar btnMarcha se activan el contactor principal kM y el contactor de estrella kY. Después de 8 segundos se desactiva kY, se espera un tiempo muerto de 100 milisegundos y se activa el contactor de triángulo kD. Las salidas kY y kD jamás deben estar activas simultáneamente. El botón btnParo desactiva todos los contactores en cualquier momento. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_EstrellaTriangulo con variables de entrada btnMarcha, btnParo (BOOL) y salidas kM, kY, kD (BOOL). Usa los tiempos T#8S y T#100MS. " + SALIDA_CODIGO)

tarea("I5", "Intermedio", "Banda con clasificación por sensores",
"Tarea: programa una banda transportadora clasificadora. La banda funciona continuamente (salida banda activa). El sensor sensorPresencia detecta el paso de cada pieza; si en ese momento sensorAltura está activo, la pieza es alta y debe desviarse: el pistón (salida piston) debe activarse durante 1 segundo, comenzando 2 segundos después de la detección (tiempo que tarda la pieza en llegar al desviador). Contar las piezas altas en nAltas y las bajas en nBajas. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Clasificadora con variables de entrada sensorPresencia, sensorAltura (BOOL) y salidas banda, piston (BOOL) y nAltas, nBajas (INT). Usa los tiempos T#2S y T#1S. " + SALIDA_CODIGO)

tarea("I6", "Intermedio", "Escalado analógico con histéresis",
"Tarea: programa el acondicionamiento y control de una señal de temperatura. La entrada rawTemp entrega un valor entero de 0 a 27648 proporcional a 0.0–100.0 grados Celsius; calcula la temperatura en la salida tempC. El enfriador debe activarse cuando tempC sea mayor o igual a 80.0 y desactivarse cuando sea menor o igual a 75.0 (histéresis: entre ambos umbrales conserva su estado, sin oscilar). Si rawTemp es menor que 0 o mayor que 27648, debe activarse almSensor y desactivarse el enfriador. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Temperatura con variable de entrada rawTemp (INT) y salidas tempC (REAL), enfriador (BOOL) y almSensor (BOOL). " + SALIDA_CODIGO)

tarea("I7", "Intermedio", "Bombas dúplex con alternancia",
"Tarea: programa un grupo de dos bombas en configuración dúplex. Cuando la entrada demanda se activa, debe arrancar una sola bomba (la principal de ese ciclo); al desactivarse la demanda, ambas se detienen. En cada nueva demanda, el rol de bomba principal debe alternarse entre bomba1 y bomba2 para igualar el desgaste. Si la bomba principal en servicio tiene su falla activa (falla1 o falla2), debe entrar automáticamente la otra bomba y activarse almFalla. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Duplex con variables de entrada demanda, falla1, falla2 (BOOL) y salidas bomba1, bomba2, almFalla (BOOL). " + SALIDA_CODIGO)

tarea("I8", "Intermedio", "Permisivos de arranque de compresor",
"Tarea: programa los permisivos de arranque de un compresor. El compresor (salida comp) puede arrancar con btnMarcha únicamente si: la presión de aceite es correcta (pOilOk activa durante 3 segundos continuos), la temperatura es correcta (tempOk activa) y no hay alarmas (sinAlm activa). Si algún permisivo falta, el compresor no arranca y la salida causaBloqueo indica cuál: 1 presión de aceite, 2 temperatura, 3 alarma activa, 0 ninguno (si faltan varios, reporta el de número menor). Con el compresor en marcha, la pérdida de cualquier permisivo debe detenerlo. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Compresor con variables de entrada pOilOk, tempOk, sinAlm, btnMarcha (BOOL) y salidas comp (BOOL) y causaBloqueo (INT). Usa el tiempo T#3S. " + SALIDA_CODIGO)

# ============ NIVEL AVANZADO ============
tarea("A1", "Avanzado", "Controlador PID con anti-windup",
"Tarea: programa un controlador PID discreto de temperatura. Entradas: consigna SP, variable de proceso PV, ganancia proporcional Kp, tiempo integral Ti (segundos), tiempo derivativo Td (segundos), todas REAL, y ciclo (TIME) con el período de muestreo. La salida CV es el porcentaje de mando, limitada al rango 0.0 a 100.0. Implementa las tres acciones y anti-windup por clamping: la acción integral no debe seguir acumulando cuando la salida está saturada en su límite. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_PID con variables de entrada SP, PV, Kp, Ti, Td (REAL) y ciclo (TIME), y salida CV (REAL). " + SALIDA_CODIGO)

tarea("A2", "Avanzado", "Control por lotes multifase",
"Tarea: programa el control por lotes de un reactor con la siguiente receta secuencial: (fase 1) dosificar el componente A abriendo vA hasta que se active nivelA; (fase 2) dosificar el componente B abriendo vB hasta que se active nivelB; (fase 3) calentar activando calentador hasta que temp alcance 60.0 grados o más; (fase 4) mezclar activando mezclador durante 120 segundos; (fase 5) descargar abriendo vDescarga hasta que se active nivelVacio; después, reposo (fase 0). btnInicio arranca la receta desde reposo. btnAbort aborta en cualquier fase: cierra vA, vB, calentador y mezclador de inmediato y, si hay producto en el reactor, ejecuta la descarga antes de volver a reposo. La salida fase reporta la fase activa (0 a 5). "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Batch con variables de entrada nivelA, nivelB, nivelVacio, btnInicio, btnAbort (BOOL) y temp (REAL), y salidas vA, vB, calentador, mezclador, vDescarga (BOOL) y fase (INT). Usa el tiempo T#120S. " + SALIDA_CODIGO)

tarea("A3", "Avanzado", "Protocolo de comunicación con reintentos",
"Tarea: programa un intercambio de petición/respuesta con un dispositivo externo. Al activarse txReq (flanco), transmite el valor de prueba 100 en la salida txData y espera la confirmación: rxOk activa con rxData igual al valor transmitido (eco), dentro de un plazo de 500 milisegundos. Si el plazo vence sin confirmación, o el eco no coincide, reintenta la transmisión; se permiten como máximo 3 intentos en total. Al agotarlos, activa la salida error, que permanece activa hasta un nuevo txReq. La variable interna nIntentos debe llevar el intento en curso. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Com con variables de entrada txReq, rxOk (BOOL) y rxData (INT), y salidas txData (INT) y error (BOOL). Usa el tiempo T#500MS. " + SALIDA_CODIGO)

tarea("A4", "Avanzado", "Rampa de velocidad limitada",
"Tarea: programa un generador de consigna de velocidad con rampa. La salida CVvel debe seguir a la consigna SPvel con una pendiente máxima de 10.0 puntos porcentuales por segundo al subir y de 20.0 al bajar. Con paroRapido activo, CVvel debe descender hacia 0.0 con una pendiente de 40.0 puntos porcentuales por segundo, ignorando SPvel, y permanecer en 0.0 mientras paroRapido siga activo. La entrada ciclo (TIME) es el período de ejecución del bloque. No debe haber sobrepaso: CVvel nunca cruza el valor objetivo. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Rampa con variables de entrada SPvel (REAL), paroRapido (BOOL) y ciclo (TIME), y salida CVvel (REAL). " + SALIDA_CODIGO)

tarea("A5", "Avanzado", "Registro de eventos en buffer circular",
"Tarea: programa un registro de eventos en buffer circular. Define una estructura ST_Evento con los campos codigo (INT) y marca (TIME). Al activarse nuevoEvento (transición de FALSE a TRUE), registra el valor de la entrada evento junto con la marca de tiempo relativa (tiempo transcurrido desde el arranque del bloque) en el arreglo buffer, de tipo ARRAY[0..19] OF ST_Evento. Cuando el arreglo se llena, se sobrescribe el registro más antiguo. La salida indice apunta a la posición del último evento registrado. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Registro con variables de entrada evento (INT) y nuevoEvento (BOOL), y salidas buffer (ARRAY[0..19] OF ST_Evento) e indice (INT). Incluye la declaración TYPE de ST_Evento. " + SALIDA_CODIGO)

tarea("A6", "Avanzado", "Modos de operación jerárquicos",
"Tarea: programa la gestión de modos de operación de una máquina: automático (0), manual (1) y mantenimiento (2), seleccionados con la entrada selector (INT). Un cambio de modo solo se acepta si estadoSeguro está activo; si no lo está, se mantiene el modo vigente aunque el selector cambie. La salida modoActivo reporta el modo vigente. En modo mantenimiento, la salida habForzado (habilitación de forzado de actuadores) se activa únicamente mientras confirmarForzado esté presionado. Al salir del modo mantenimiento, habForzado debe quedar desactivada. Valores de selector fuera de 0 a 2 se ignoran. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un FUNCTION_BLOCK llamado FB_Modos con variables de entrada selector (INT), estadoSeguro, confirmarForzado (BOOL) y salidas modoActivo (INT), habForzado (BOOL). " + SALIDA_CODIGO)

# ============ COMPLEMENTARIAS ============
tarea("C1", "Complementaria", "Diagnóstico de código con errores",
"Tarea: el siguiente FUNCTION_BLOCK en Structured Text (IEC 61131-3) debería implementar un semáforo cíclico (verde 20 s, amarillo 4 s, rojo 15 s) mientras habilitado esté activo, con un modo de amarillo intermitente. El código contiene errores lógicos. Analízalo, identifica todos los errores, y para cada uno explica: en qué línea o sección está, por qué es un error y cuál sería la corrección. No reescribas el programa completo.\n\n" + CODIGO_C1 + "\n\n"
"Entrega únicamente la lista numerada de errores con su explicación y corrección propuesta.",
clave="Errores sembrados (clave de evaluación, NO enviar al modelo): (1) condición invertida: IF NOT habilitado ejecuta la secuencia cuando debería ser IF habilitado; (2) el TON t1 se llama con IN:=TRUE permanente y nunca se reinicia entre estados, por lo que las transiciones tras la primera son inmediatas; (3) estado 3 (amarillo intermitente) es inalcanzable: ninguna transición asigna estado:=3; (4) parp nunca se inicializa ni se conmuta, así que el intermitente jamás parpadearía; adicionalmente luzV/luzR no se apagan en el estado 3 (aceptable como hallazgo extra).")

tarea("C2", "Complementaria", "De requisito ambiguo a especificación",
"Tarea: un cliente describe así lo que necesita para el control de la bomba de un pozo: \"Necesito que la bomba del pozo no se queme. Cuando el tanque de arriba esté vacío, que arranque sola; pero si el pozo está sin agua, que no arranque porque se quema. Y un botón para apagarla cuando queramos, y que una luz avise cuando algo ande mal.\" A partir de ese requisito, produce: (1) una tabla de entradas y salidas con nombre propuesto, tipo de dato IEC 61131-3 y descripción; (2) el tipo de POU que recomendarías (FUNCTION, FUNCTION_BLOCK o PROGRAM) con una justificación breve; (3) la lista de ambigüedades o información faltante que habría que aclarar con el cliente antes de programar. Entrega únicamente los tres apartados numerados, sin escribir código.",
clave="Ambigüedades esperadas (clave, NO enviar): niveles como señales digitales (flotadores) o analógicas; qué significa exactamente 'tanque vacío' (histéresis entre niveles de arranque/paro); tiempo de protección por marcha en seco y si el rearme es manual o automático; el 'botón para apagarla' ¿es paro momentáneo o inhibición retenida?; qué condiciones agrupa la luz de falla; comportamiento al recuperarse el agua del pozo.")

tarea("C3", "Complementaria", "Conversión Ladder a ST",
"Tarea: convierte a Structured Text el siguiente segmento de un programa en Ladder Diagram (IEC 61131-3), preservando exactamente su comportamiento. Descripción del segmento: Rama 1: el contacto normalmente abierto btnMarcha en paralelo con el contacto normalmente abierto motor, ambos en serie con el contacto normalmente cerrado btnParo, alimentan la bobina motor. Rama 2: el contacto normalmente abierto motor alimenta un temporizador TON llamado T1 con tiempo preestablecido de 10 segundos. Rama 3: el contacto normalmente abierto de T1.Q alimenta la bobina lampara. "
"Programa en Structured Text (ST) conforme a IEC 61131-3, en un PROGRAM llamado PRG_Conversion con variables btnMarcha, btnParo (BOOL de entrada), motor, lampara (BOOL de salida) y T1 (TON). Usa el tiempo T#10S. " + SALIDA_CODIGO)

tarea("C4", "Complementaria", "Documentar un FB ajeno",
"Tarea: el siguiente FUNCTION_BLOCK en Structured Text (IEC 61131-3) funciona correctamente pero carece por completo de documentación. Primero, redacta un párrafo que describa qué hace el bloque y para qué aplicación serviría. Después, entrega el mismo código con comentarios técnicos por bloque o por línea, sin modificar en absoluto la lógica ni los identificadores.\n\n" + CODIGO_C4 + "\n\n"
"Entrega el párrafo de descripción seguido del código comentado.",
clave="Comportamiento real (clave, NO enviar): grupo dúplex de dos bombas con alternancia del rol principal en cada flanco de demanda y respaldo automático ante falla de la principal; almFalla se activa si hay falla con demanda presente.")

# ------------------------- Armado de prompts -------------------------
def zero_shot(t):
    return ROL + "\n\n" + t["body"]

def few_shot(t):
    cierre = ("Ahora resuelve la siguiente tarea con el mismo formato.\n\n"
              if t["nivel"] in ("Basico", "Intermedio", "Avanzado")
              else "Ahora resuelve la siguiente tarea.\n\n")
    return ROL + " " + PREAMBULO_FS + cierre + t["body"]

# ------------------------- Salida 1: documento Markdown -------------------------
NIVEL_TITULO = {"Basico": "Nivel Básico", "Intermedio": "Nivel Intermedio",
                "Avanzado": "Nivel Avanzado", "Complementaria": "Tareas Complementarias"}
TIPO = {"B": "T1_generacion", "I": "T1_generacion",
        "A": "T1_generacion", "C": None}
TIPO_C = {"C1": "T2_analisis", "C2": "T3_interpretacion", "C3": "T4_conversion", "C4": "T5_documentacion"}

md = []
md.append("# PROMPTS EXPERIMENTALES — BANCO DE PRUEBAS v0\n")
md.append("Tesis: LLMs como Asistentes de Programación PLC en la Academia (FIE-UTP) · Tareas 2.2 y 2.4 del plan de trabajo.\n")
md.append("Generado por `pipeline_tesis/generar_prompts.py` — fuente única de verdad: este documento y el `tasks.json` del pipeline salen del mismo script, por lo que lo aprobado en el piloto es exactamente lo que se ejecuta.\n")
md.append("Estructura de cada prompt zero-shot: (1) rol, (2) contexto normativo, (3) enunciado, (4) lenguaje requerido, (5) restricciones técnicas (POU, variables, tipos, tiempos), (6) formato de salida. El prompt few-shot antepone dos ejemplos resueltos de nivel básico que **no** pertenecen al banco (iluminación XOR y pulso TP) y conserva el enunciado idéntico.\n")
md.append("> **Nota metodológica:** los bloques marcados como *clave de evaluación* al final de C1, C2 y C4 son para la ficha del evaluador y **nunca** se envían al modelo.\n")

nivel_actual = None
for t in T:
    if t["nivel"] != nivel_actual:
        nivel_actual = t["nivel"]
        md.append("\n---\n\n## " + NIVEL_TITULO[nivel_actual] + "\n")
    md.append("\n### " + t["id"] + " – " + t["titulo"] + "\n")
    md.append("**Prompt Zero-shot**\n")
    md.append("```text\n" + zero_shot(t) + "\n```\n")
    md.append("**Prompt Few-shot**\n")
    md.append("```text\n" + few_shot(t) + "\n```\n")
    if t.get("clave"):
        md.append("> **Clave de evaluación (no enviar al modelo):** " + t["clave"] + "\n")

with open("../Prompts_Banco_v0.md", "w", encoding="utf-8") as f:
    f.write("\n".join(md))

# ------------------------- Salida 2: tasks.json del pipeline -------------------------
tareas_json = []
for t in T:
    tipo = TIPO_C.get(t["id"], "T1_generacion")
    tareas_json.append({
        "id": t["id"],
        "nivel": t["nivel"],
        "tipo": tipo,
        "titulo": t["titulo"],
        "prompts": {"zero_shot": zero_shot(t), "few_shot": few_shot(t)},
    })

with open("tasks.json", "w", encoding="utf-8") as f:
    json.dump({
        "_comentario": "Generado por generar_prompts.py — NO editar a mano; editar el generador y regenerar.",
        "tareas": tareas_json,
    }, f, ensure_ascii=False, indent=2)

print(f"Generadas {len(T)} tareas -> ../Prompts_Banco_v0.md y tasks.json")
print("Distribución:", {n: sum(1 for t in T if t['nivel'] == n) for n in NIVEL_TITULO})
