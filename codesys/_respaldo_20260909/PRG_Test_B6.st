(*) B6: mide intervalos completos ON/OFF, T#1S +/- T#150MS. MainTask: 4..10 ms. *)
PROGRAM PRG_Test_B6
VAR CONSTANT ULTIMO_PASO:INT:=2;END_VAR
VAR fb:FB_Baliza;alarma,pulsoReset,resetIntervalo,finalizado,prev,primer,error:BOOL;paso,i,nPasan,nOn,nOff:INT;tEspera:TIME;tPaso,tIntervalo:TON;resultado:ARRAY[0..2] OF INT;veredicto:INT;duracion:TIME;END_VAR
IF NOT finalizado THEN CASE paso OF 0:alarma:=FALSE;tEspera:=T#200MS;1:alarma:=TRUE;tEspera:=T#7S;2:alarma:=FALSE;tEspera:=T#200MS;END_CASE END_IF
tPaso(IN:=NOT pulsoReset,PT:=tEspera);tIntervalo(IN:=NOT resetIntervalo,PT:=T#10S);pulsoReset:=FALSE;resetIntervalo:=FALSE;fb(alarma:=alarma);
IF paso=1 THEN
 IF (fb.lampara AND NOT prev) OR ((NOT fb.lampara) AND prev) THEN
  IF primer THEN duracion:=tIntervalo.ET;IF NOT fb.lampara THEN nOn:=nOn+1;ELSE nOff:=nOff+1;END_IF;IF duracion<T#850MS OR duracion>T#1150MS THEN error:=TRUE;END_IF;ELSE primer:=TRUE;END_IF;
  resetIntervalo:=TRUE;
 END_IF
END_IF;prev:=fb.lampara;
IF tPaso.Q AND NOT finalizado THEN
 IF (paso=0 AND NOT fb.lampara) OR (paso=1 AND nOn>=2 AND nOff>=2 AND NOT error) OR (paso=2 AND NOT fb.lampara) THEN resultado[paso]:=1;ELSE resultado[paso]:=2;END_IF;
 pulsoReset:=TRUE;IF paso<ULTIMO_PASO THEN paso:=paso+1;ELSE finalizado:=TRUE;END_IF
END_IF
IF finalizado AND veredicto=0 THEN nPasan:=0;FOR i:=0 TO ULTIMO_PASO DO IF resultado[i]=1 THEN nPasan:=nPasan+1;END_IF END_FOR;IF nPasan=ULTIMO_PASO+1 THEN veredicto:=1;ELSE veredicto:=2;END_IF END_IF
