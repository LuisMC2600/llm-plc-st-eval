(*) I6: escalado 0..27648 a 0..100 y ambos sentidos de la histéresis. *)
PROGRAM PRG_Test_I6
VAR CONSTANT ULTIMO_PASO:INT:=7;END_VAR
VAR fb:FB_Temperatura;rawTemp,espRaw,paso,i,nPasan:INT;espTemp:REAL;espFrio,espAlarma,pulsoReset,finalizado:BOOL;tPaso:TON;resultado:ARRAY[0..7] OF INT;veredicto:INT;END_VAR
tPaso(IN:=NOT pulsoReset,PT:=T#100MS);pulsoReset:=FALSE;
IF NOT finalizado THEN CASE paso OF
0:rawTemp:=13824;espTemp:=50.0;espFrio:=FALSE;espAlarma:=FALSE;
1:rawTemp:=22119;espTemp:=80.0;espFrio:=TRUE;espAlarma:=FALSE;
2:rawTemp:=21289;espTemp:=77.0;espFrio:=TRUE;espAlarma:=FALSE; (* banda: conserva ON *)
3:rawTemp:=20736;espTemp:=75.0;espFrio:=FALSE;espAlarma:=FALSE;
4:rawTemp:=21289;espTemp:=77.0;espFrio:=FALSE;espAlarma:=FALSE; (* banda: conserva OFF *)
5:rawTemp:=27649;espTemp:=0.0;espFrio:=FALSE;espAlarma:=TRUE;
6:rawTemp:=-1;espTemp:=0.0;espFrio:=FALSE;espAlarma:=TRUE;
7:rawTemp:=0;espTemp:=0.0;espFrio:=FALSE;espAlarma:=FALSE;END_CASE END_IF
fb(rawTemp:=rawTemp);
IF tPaso.Q AND NOT finalizado THEN IF ((paso>=5) OR ((fb.tempC>espTemp-0.1) AND (fb.tempC<espTemp+0.1))) AND fb.enfriador=espFrio AND fb.almSensor=espAlarma THEN resultado[paso]:=1;ELSE resultado[paso]:=2;END_IF;pulsoReset:=TRUE;IF paso<ULTIMO_PASO THEN paso:=paso+1;ELSE finalizado:=TRUE;END_IF END_IF
IF finalizado AND veredicto=0 THEN nPasan:=0;FOR i:=0 TO ULTIMO_PASO DO IF resultado[i]=1 THEN nPasan:=nPasan+1;END_IF END_FOR;IF nPasan=ULTIMO_PASO+1 THEN veredicto:=1;ELSE veredicto:=2;END_IF END_IF
