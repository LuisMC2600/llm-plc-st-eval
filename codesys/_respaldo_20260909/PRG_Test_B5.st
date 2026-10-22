(*) Banco B5: prueba TOF, tiempo de 30 s y rearme durante post-enfriamiento. *)
PROGRAM PRG_Test_B5
VAR CONSTANT ULTIMO_PASO:INT:=6; END_VAR
VAR fb:FB_Ventilador; quemadorOn,esperado,pulsoReset,finalizado:BOOL;paso,i,nPasan:INT;tEspera:TIME;tPaso:TON;resultado:ARRAY[0..6] OF INT;veredicto:INT;END_VAR
IF NOT finalizado THEN CASE paso OF
0:quemadorOn:=FALSE;tEspera:=T#200MS;esperado:=FALSE;
1:quemadorOn:=TRUE;tEspera:=T#200MS;esperado:=TRUE; (* acompana quemador *)
2:quemadorOn:=FALSE;tEspera:=T#29S;esperado:=TRUE; (* antes de 30 s *)
3:quemadorOn:=FALSE;tEspera:=T#1200MS;esperado:=FALSE; (* 30.2 s acumulados *)
4:quemadorOn:=TRUE;tEspera:=T#200MS;esperado:=TRUE;
5:quemadorOn:=FALSE;tEspera:=T#10S;esperado:=TRUE; (* post-enfriamiento, se reenciende *)
6:quemadorOn:=TRUE;tEspera:=T#200MS;esperado:=TRUE; (* reactivacion reinicia TOF *)
END_CASE END_IF
tPaso(IN:=NOT pulsoReset,PT:=tEspera);pulsoReset:=FALSE;fb(quemadorOn:=quemadorOn);
IF tPaso.Q AND NOT finalizado THEN IF fb.ventilador=esperado THEN resultado[paso]:=1;ELSE resultado[paso]:=2;END_IF;pulsoReset:=TRUE;IF paso<ULTIMO_PASO THEN paso:=paso+1;ELSE finalizado:=TRUE;END_IF END_IF
IF finalizado AND veredicto=0 THEN nPasan:=0;FOR i:=0 TO ULTIMO_PASO DO IF resultado[i]=1 THEN nPasan:=nPasan+1;END_IF END_FOR;IF nPasan=ULTIMO_PASO+1 THEN veredicto:=1;ELSE veredicto:=2;END_IF END_IF
