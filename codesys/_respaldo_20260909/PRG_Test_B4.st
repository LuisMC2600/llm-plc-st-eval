(*) Banco B4. violacionInterlock se muestrea y enclava en CADA scan. *)
PROGRAM PRG_Test_B4
VAR CONSTANT ULTIMO_PASO : INT := 7; END_VAR
VAR
 fb: FB_Giro; btnFwd,btnRev,btnParo,espFwd,espRev,pulsoReset,finalizado,violacionInterlock: BOOL;
 paso,i,nPasan: INT; tPaso: TON; resultado: ARRAY[0..7] OF INT; veredicto: INT;
END_VAR
tPaso(IN:=NOT pulsoReset,PT:=T#150MS); pulsoReset:=FALSE;
IF NOT finalizado THEN CASE paso OF
 0: btnFwd:=FALSE;btnRev:=FALSE;btnParo:=FALSE;espFwd:=FALSE;espRev:=FALSE; (* reposo *)
 1: btnFwd:=TRUE;espFwd:=TRUE;espRev:=FALSE; (* marcha adelante *)
 2: btnFwd:=FALSE;espFwd:=TRUE;espRev:=FALSE; (* enclavamiento FWD *)
 3: btnRev:=TRUE;espFwd:=TRUE;espRev:=FALSE; (* Rev sin paro: prohibido *)
 4: btnRev:=FALSE;btnParo:=TRUE;espFwd:=FALSE;espRev:=FALSE; (* paro *)
 5: btnParo:=FALSE;btnRev:=TRUE;espFwd:=FALSE;espRev:=TRUE; (* marcha reversa *)
 6: btnFwd:=TRUE;btnRev:=TRUE;espFwd:=FALSE;espRev:=TRUE; (* ambas ordenes: nunca ambas salidas *)
 7: btnFwd:=FALSE;btnRev:=FALSE;btnParo:=TRUE;espFwd:=FALSE;espRev:=FALSE; (* paro final *)
 END_CASE END_IF
fb(btnFwd:=btnFwd,btnRev:=btnRev,btnParo:=btnParo);
IF fb.fwd AND fb.rev THEN violacionInterlock:=TRUE; END_IF;
IF tPaso.Q AND NOT finalizado THEN IF (fb.fwd=espFwd) AND (fb.rev=espRev) THEN resultado[paso]:=1; ELSE resultado[paso]:=2; END_IF; pulsoReset:=TRUE; IF paso<ULTIMO_PASO THEN paso:=paso+1; ELSE finalizado:=TRUE; END_IF END_IF
IF finalizado AND veredicto=0 THEN nPasan:=0;FOR i:=0 TO ULTIMO_PASO DO IF resultado[i]=1 THEN nPasan:=nPasan+1;END_IF END_FOR;IF nPasan=ULTIMO_PASO+1 AND NOT violacionInterlock THEN veredicto:=1;ELSE veredicto:=2;END_IF END_IF
