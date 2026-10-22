import pandas as pd
J = [
 ("SECUENCIA","Al entrar en mantenimiento no apaga los actuadores; solo los apaga al salir del modo 2 (accion en el momento equivocado)"),
 ("INICIALIZACION","principal1 arranca en TRUE y se conmuta en el primer flanco de demanda: la primera demanda la atiende bomba2"),
 ("SEGURIDAD","Abort en reposo con producto pasa a descarga (fase 5) en lugar de no tener efecto: respuesta al aborto de receta incorrecta"),
 ("SEGURIDAD","Liberada la emergencia con la marcha pulsada, el latch se activa de nuevo: rearranque automatico"),
 ("TEMPORIZACION","Retardo a la desconexion emulado con TON sobre NOT quemadorOn: el ventilador se apaga al apagar el quemador y se enciende 30 s despues"),
 ("TEMPORIZACION","Intermitencia mal construida: el TON se invoca dos veces por ciclo con entradas distintas; los intervalos no son de 1 s"),
 ("TEMPORIZACION","tMezcla solo se invoca en el ciclo de la transicion a mezcla: nunca vence y no pasa a descarga"),
 ("TEMPORIZACION","tEstrella solo se invoca en el ciclo de la marcha: nunca vence y no pasa a triangulo"),
 ("INICIALIZACION","principal se fija en TRUE en reposo y se conmuta en el flanco de demanda: la primera demanda la atiende bomba2"),
 ("SEGURIDAD","causaBloqueo usa la senal cruda pOilOk y no el permisivo temporizado: reporta 0 con aceite aun sin 3 s (frontera con temporizacion)"),
 ("INICIALIZACION","indice queda en el valor por defecto 0 sin eventos (el -1 solo existe en la variable interna)"),
 ("TEMPORIZACION","TP usado como retardo a la conexion: la valvula abre al instante durante 5 s"),
 ("SEGURIDAD","Permite pasar de adelante a reversa sin pasar por paro"),
 ("TEMPORIZACION","El ventilador sigue a timer.Q, que es FALSE al apagar el quemador: no hay post-enfriamiento de 30 s"),
 ("TEMPORIZACION","estado se invierte en cada ciclo: la lampara parpadea al periodo del ciclo, no a 1 s"),
 ("TEMPORIZACION","T1 se invoca con IN := FALSE en cada ciclo antes de IN := TRUE: se reinicia siempre y la lampara nunca enciende"),
 ("TEMPORIZACION","TP usado como plazo de cada luz: la salida se activa al instante y la transicion ocurre de inmediato"),
 ("TEMPORIZACION","timerMezcla solo se invoca en el ciclo de la transicion: nunca vence"),
 ("SECUENCIA","Sin retencion: retAlm sigue a la causa y el ACK la borra aunque la causa siga presente"),
 ("TEMPORIZACION","Los temporizadores se invocan con IN := FALSE al inicio de cada ciclo: se reinician siempre y no pasa a triangulo"),
 ("SEGURIDAD","Con ambas bombas en falla almFalla queda en FALSE (NOT falla2): no se senaliza la falla de equipo"),
 ("SEGURIDAD","causaBloqueo usa la senal cruda pOilOk y no el permisivo temporizado (frontera con temporizacion)"),
]
m=pd.read_csv('muestra2_mapa_v2_seleccion.csv')
assert len(m)==len(J)
m['categoria_codigo']=[j[0] for j in J]; m['observacion']=[j[1] for j in J]
c=pd.read_csv('clasificacion_fallos_cwe.csv')
k=['modelo','tarea','estrategia','ejec']
m=m.merge(c[k+['categoria_plc']].rename(columns={'categoria_plc':'categoria_mapa_v2'}),on=k)
m['coincide']=(m.categoria_mapa_v2==m.categoria_codigo).astype(int)
m=m[k+['paso_primario','categoria_mapa_v2','categoria_codigo','coincide','observacion']]
m.to_csv('verificacion_mapa_pasos_v2.csv',index=False)
print(m[k+['paso_primario','categoria_mapa_v2','categoria_codigo','coincide']].to_string())
print('coinciden', m.coincide.sum(),'de',len(m))
