(*) I2: orden de estados, temporizacion de mezcla y paro seguro en dos fases. *)
PROGRAM PRG_Test_I2
VAR CONSTANT ULTIMO_PASO:INT:=9;END_VAR
VAR fb:FB_Llenado;nivelAlto,nivelBajo,btnInicio,btnParo,evL,evM,evD,pulsoReset,finalizado:BOOL;paso,i,nPasan:INT;tEspera:TIME;tPaso:TON;resultado:ARRAY[0..9] OF INT;veredicto:INT;END_VAR
IF NOT finalizado THEN CASE paso OF
0:nivelAlto:=FALSE;nivelBajo:=FALSE;btnInicio:=FALSE;btnParo:=FALSE;tEspera:=T#200MS;evL:=FALSE;evM:=FALSE;evD:=FALSE;
1:btnInicio:=TRUE;tEspera:=T#200MS;evL:=TRUE;evM:=FALSE;evD:=FALSE;
2:btnInicio:=FALSE;nivelAlto:=TRUE;tEspera:=T#200MS;evL:=FALSE;evM:=TRUE;evD:=FALSE;
3:tEspera:=T#59800MS;evM:=TRUE; (* antes de 60 s *)
4:tEspera:=T#500MS;evL:=FALSE;evM:=FALSE;evD:=TRUE;
5:nivelBajo:=TRUE;tEspera:=T#200MS;evL:=FALSE;evM:=FALSE;evD:=FALSE;
6:nivelAlto:=FALSE;nivelBajo:=FALSE;btnInicio:=TRUE;tEspera:=T#200MS;evL:=TRUE;evM:=FALSE;evD:=FALSE;
7:btnInicio:=FALSE;btnParo:=TRUE;tEspera:=T#200MS;evL:=FALSE;evM:=FALSE;evD:=FALSE; (* paro en llenado *)
8:btnParo:=FALSE;btnInicio:=TRUE;tEspera:=T#200MS;evL:=TRUE;evM:=FALSE;evD:=FALSE;
9:btnInicio:=FALSE;nivelAlto:=TRUE;btnParo:=TRUE;tEspera:=T#200MS;evL:=FALSE;evM:=FALSE;evD:=FALSE; (* paro en mezcla *) END_CASE END_IF
tPaso(IN:=NOT pulsoReset,PT:=tEspera);pulsoReset:=FALSE;fb(nivelAlto:=nivelAlto,nivelBajo:=nivelBajo,btnInicio:=btnInicio,btnParo:=btnParo);
IF tPaso.Q AND NOT finalizado THEN IF fb.vLlenado=evL AND fb.motorMezcla=evM AND fb.vDescarga=evD THEN resultado[paso]:=1;ELSE resultado[paso]:=2;END_IF;pulsoReset:=TRUE;IF paso<ULTIMO_PASO THEN paso:=paso+1;ELSE finalizado:=TRUE;END_IF END_IF
IF finalizado AND veredicto=0 THEN nPasan:=0;FOR i:=0 TO ULTIMO_PASO DO IF resultado[i]=1 THEN nPasan:=nPasan+1;END_IF END_FOR;IF nPasan=ULTIMO_PASO+1 THEN veredicto:=1;ELSE veredicto:=2;END_IF END_IF
