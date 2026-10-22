(*) I5: presencia sostenida no puede contar mas de una pieza; desvio 2 s + 1 s. *)
PROGRAM PRG_Test_I5
VAR CONSTANT ULTIMO_PASO:INT:=6;END_VAR
VAR fb:FB_Clasificadora;sensorPresencia,sensorAltura,pulsoReset,finalizado,espBanda,espPiston:BOOL;espAltas,espBajas,paso,i,nPasan:INT;tEspera:TIME;tPaso:TON;resultado:ARRAY[0..6] OF INT;veredicto:INT;END_VAR
IF NOT finalizado THEN CASE paso OF
0:sensorPresencia:=FALSE;sensorAltura:=FALSE;tEspera:=T#200MS;espBanda:=TRUE;espPiston:=FALSE;espAltas:=0;espBajas:=0;
1:sensorPresencia:=TRUE;sensorAltura:=FALSE;tEspera:=T#300MS;espBanda:=TRUE;espPiston:=FALSE;espAltas:=0;espBajas:=1; (* baja sostenida *)
2:sensorPresencia:=FALSE;tEspera:=T#200MS;espBanda:=TRUE;espPiston:=FALSE;espAltas:=0;espBajas:=1;
3:sensorPresencia:=TRUE;sensorAltura:=TRUE;tEspera:=T#200MS;espBanda:=TRUE;espPiston:=FALSE;espAltas:=1;espBajas:=1;
4:sensorPresencia:=FALSE;sensorAltura:=FALSE;tEspera:=T#1800MS;espBanda:=TRUE;espPiston:=FALSE;espAltas:=1;espBajas:=1; (* antes de 2 s *)
5:tEspera:=T#400MS;espBanda:=TRUE;espPiston:=TRUE;espAltas:=1;espBajas:=1; (* dentro del pulso *)
6:tEspera:=T#1200MS;espBanda:=TRUE;espPiston:=FALSE;espAltas:=1;espBajas:=1;END_CASE END_IF
tPaso(IN:=NOT pulsoReset,PT:=tEspera);pulsoReset:=FALSE;fb(sensorPresencia:=sensorPresencia,sensorAltura:=sensorAltura);
IF tPaso.Q AND NOT finalizado THEN IF fb.banda=espBanda AND fb.piston=espPiston AND fb.nAltas=espAltas AND fb.nBajas=espBajas THEN resultado[paso]:=1;ELSE resultado[paso]:=2;END_IF;pulsoReset:=TRUE;IF paso<ULTIMO_PASO THEN paso:=paso+1;ELSE finalizado:=TRUE;END_IF END_IF
IF finalizado AND veredicto=0 THEN nPasan:=0;FOR i:=0 TO ULTIMO_PASO DO IF resultado[i]=1 THEN nPasan:=nPasan+1;END_IF END_FOR;IF nPasan=ULTIMO_PASO+1 THEN veredicto:=1;ELSE veredicto:=2;END_IF END_IF
