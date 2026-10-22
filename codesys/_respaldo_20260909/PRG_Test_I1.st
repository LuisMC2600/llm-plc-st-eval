(*) I1: secuencia 20/4/15 s y amarillo intermitente medido por flancos. *)
PROGRAM PRG_Test_I1
VAR CONSTANT ULTIMO_PASO:INT:=6;END_VAR
VAR fb:FB_Semaforo;habilitado,pulsoReset,resetIntervalo,finalizado,prevA,primer,error,espV,espA,espR:BOOL;paso,i,nPasan,nOn,nOff:INT;tEspera,duracion:TIME;tPaso,tIntervalo:TON;resultado:ARRAY[0..6] OF INT;veredicto:INT;END_VAR
IF NOT finalizado THEN CASE paso OF
0:habilitado:=FALSE;tEspera:=T#200MS;espV:=FALSE;espR:=FALSE;
1:habilitado:=TRUE;tEspera:=T#200MS;espV:=TRUE;espA:=FALSE;espR:=FALSE;
2:habilitado:=TRUE;tEspera:=T#20S;espV:=FALSE;espA:=TRUE;espR:=FALSE;
3:habilitado:=TRUE;tEspera:=T#4S;espV:=FALSE;espA:=FALSE;espR:=TRUE;
4:habilitado:=TRUE;tEspera:=T#15S;espV:=TRUE;espA:=FALSE;espR:=FALSE;
5:habilitado:=FALSE;tEspera:=T#7S;espV:=FALSE;espR:=FALSE;
6:habilitado:=TRUE;tEspera:=T#200MS;espV:=TRUE;espA:=FALSE;espR:=FALSE;END_CASE END_IF
tPaso(IN:=NOT pulsoReset,PT:=tEspera);tIntervalo(IN:=NOT resetIntervalo,PT:=T#10S);pulsoReset:=FALSE;resetIntervalo:=FALSE;fb(habilitado:=habilitado);
IF paso=5 AND ((fb.luzA AND NOT prevA) OR ((NOT fb.luzA) AND prevA)) THEN IF primer THEN duracion:=tIntervalo.ET;IF NOT fb.luzA THEN nOn:=nOn+1;ELSE nOff:=nOff+1;END_IF;IF duracion<T#850MS OR duracion>T#1150MS THEN error:=TRUE;END_IF;ELSE primer:=TRUE;END_IF;resetIntervalo:=TRUE;END_IF;prevA:=fb.luzA;
IF tPaso.Q AND NOT finalizado THEN IF ((paso=0 AND NOT fb.luzV AND NOT fb.luzR) OR (paso>=1 AND paso<>5 AND fb.luzV=espV AND fb.luzA=espA AND fb.luzR=espR) OR (paso=5 AND NOT fb.luzV AND NOT fb.luzR AND nOn>=2 AND nOff>=2 AND NOT error)) THEN resultado[paso]:=1;ELSE resultado[paso]:=2;END_IF;pulsoReset:=TRUE;IF paso<ULTIMO_PASO THEN paso:=paso+1;ELSE finalizado:=TRUE;END_IF END_IF
IF finalizado AND veredicto=0 THEN nPasan:=0;FOR i:=0 TO ULTIMO_PASO DO IF resultado[i]=1 THEN nPasan:=nPasan+1;END_IF END_FOR;IF nPasan=ULTIMO_PASO+1 THEN veredicto:=1;ELSE veredicto:=2;END_IF END_IF
