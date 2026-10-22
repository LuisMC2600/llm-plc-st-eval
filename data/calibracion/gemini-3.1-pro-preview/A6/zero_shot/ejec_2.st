```iecst
FUNCTION_BLOCK FB_Modos
VAR_INPUT
    selector : INT; (* 0: Automático, 1: Manual, 2: Mantenimiento *)
    estadoSeguro : BOOL; (* Condición para permitir cambio de modo *)
    cmdAuto : ARRAY[0..7] OF BOOL; (* Comandos en modo automático *)
    cmdManual : ARRAY[0..7] OF BOOL; (* Comandos en modo