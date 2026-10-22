(*) Banco I3: retencion individual, ACK condicionado y prioridad. *)
PROGRAM PRG_Test_I3
VAR CONSTANT ULTIMO_PASO:INT:=8;END_VAR
VAR fb:FB_Alarmas;alm1,alm2,alm3,ack1,ack2,ack3,espSirena,pulsoReset,finalizado:BOOL;espCodigo,paso,i,nPasan:INT;tPaso:TON;resultado:ARRAY[0..8] OF INT;veredicto:INT;END_VAR
tPaso(IN:=NOT pulsoReset,PT:=T#150MS);pulsoReset:=FALSE;
IF NOT finalizado THEN CASE paso OF
0:alm1:=FALSE;alm2:=FALSE;alm3:=FALSE;ack1:=TRUE;ack2:=TRUE;ack3:=TRUE;espSirena:=FALSE;espCodigo:=0;
1:ack1:=FALSE;ack2:=FALSE;ack3:=FALSE;alm3:=TRUE;espSirena:=TRUE;espCodigo:=3;
2:alm3:=FALSE;espSirena:=TRUE;espCodigo:=3; (* retencion *)
3:ack3:=TRUE;espSirena:=FALSE;espCodigo:=0; (* ACK al retirar causa *)
4:ack3:=FALSE;alm2:=TRUE;alm3:=TRUE;espSirena:=TRUE;espCodigo:=2;
5:alm1:=TRUE;espSirena:=TRUE;espCodigo:=1; (* prioridad alta *)
6:alm1:=FALSE;ack1:=TRUE;espSirena:=TRUE;espCodigo:=2;
7:alm2:=FALSE;ack2:=TRUE;espSirena:=TRUE;espCodigo:=3;
8:alm3:=FALSE;ack3:=TRUE;espSirena:=FALSE;espCodigo:=0;
END_CASE END_IF
fb(alm1:=alm1,alm2:=alm2,alm3:=alm3,ack1:=ack1,ack2:=ack2,ack3:=ack3);
IF tPaso.Q AND NOT finalizado THEN IF fb.sirena=espSirena AND fb.codigoAlm=espCodigo THEN resultado[paso]:=1;ELSE resultado[paso]:=2;END_IF;pulsoReset:=TRUE;IF paso<ULTIMO_PASO THEN paso:=paso+1;ELSE finalizado:=TRUE;END_IF END_IF
IF finalizado AND veredicto=0 THEN nPasan:=0;FOR i:=0 TO ULTIMO_PASO DO IF resultado[i]=1 THEN nPasan:=nPasan+1;END_IF END_FOR;IF nPasan=ULTIMO_PASO+1 THEN veredicto:=1;ELSE veredicto:=2;END_IF END_IF
