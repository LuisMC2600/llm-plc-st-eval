(*) I4: interlock enclavado y tiempo muerto medido entre caida kY y subida kD. MainTask 4..10 ms. *)
PROGRAM PRG_Test_I4
VAR CONSTANT ULTIMO_PASO:INT:=5;END_VAR
VAR fb:FB_EstrellaTriangulo;btnMarcha,btnParo,pulsoReset,resetMed,finalizado,prevY,prevD,midiendo,interlock,muertoOK:BOOL;paso,i,nPasan:INT;tEspera,duracionMuerto:TIME;tPaso,tMed:TON;resultado:ARRAY[0..5] OF INT;veredicto:INT;END_VAR
IF NOT finalizado THEN CASE paso OF 0:btnMarcha:=FALSE;btnParo:=FALSE;tEspera:=T#200MS;1:btnMarcha:=TRUE;tEspera:=T#7800MS;2:btnMarcha:=TRUE;tEspera:=T#500MS;3:btnMarcha:=TRUE;tEspera:=T#300MS;4:btnMarcha:=FALSE;btnParo:=TRUE;tEspera:=T#200MS;5:btnParo:=FALSE;btnMarcha:=TRUE;tEspera:=T#200MS;END_CASE END_IF
tPaso(IN:=NOT pulsoReset,PT:=tEspera);tMed(IN:=NOT resetMed,PT:=T#10S);pulsoReset:=FALSE;resetMed:=FALSE;fb(btnMarcha:=btnMarcha,btnParo:=btnParo);
IF fb.kY AND fb.kD THEN interlock:=TRUE;END_IF;
IF prevY AND NOT fb.kY THEN midiendo:=TRUE;resetMed:=TRUE;END_IF;
IF midiendo AND fb.kD AND NOT prevD THEN duracionMuerto:=tMed.ET;IF duracionMuerto>=T#100MS THEN muertoOK:=TRUE;END_IF;midiendo:=FALSE;END_IF;prevY:=fb.kY;prevD:=fb.kD;
IF tPaso.Q AND NOT finalizado THEN IF (paso=0 AND NOT fb.kM AND NOT fb.kY AND NOT fb.kD) OR (paso=1 AND fb.kM AND fb.kY AND NOT fb.kD) OR (paso=2 AND fb.kM AND NOT fb.kY AND NOT fb.kD) OR (paso=3 AND fb.kM AND NOT fb.kY AND fb.kD AND muertoOK) OR (paso=4 AND NOT fb.kM AND NOT fb.kY AND NOT fb.kD) OR (paso=5 AND fb.kM AND fb.kY AND NOT fb.kD) THEN resultado[paso]:=1;ELSE resultado[paso]:=2;END_IF;pulsoReset:=TRUE;IF paso<ULTIMO_PASO THEN paso:=paso+1;ELSE finalizado:=TRUE;END_IF END_IF
IF finalizado AND veredicto=0 THEN nPasan:=0;FOR i:=0 TO ULTIMO_PASO DO IF resultado[i]=1 THEN nPasan:=nPasan+1;END_IF END_FOR;IF nPasan=ULTIMO_PASO+1 AND NOT interlock THEN veredicto:=1;ELSE veredicto:=2;END_IF END_IF
