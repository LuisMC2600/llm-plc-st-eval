IF habilitado THEN   (* eliminar el NOT *)

IF t1.Q THEN
    t1(IN := FALSE, PT := T#20S);  (* reset *)
    estado := 1;
END_IF

luzV := FALSE; luzA := TRUE; luzR := FALSE;

luzV := FALSE; luzA := FALSE; luzR := TRUE;

(* En VAR_INPUT *)
modoIntermitente : BOOL;

(* Antes o fuera del CASE, con prioridad *)
IF modoIntermitente THEN
    estado := 3;
END_IF

(* En VAR: agregar *)
tParp : TON;

(* En estado 3: *)
tParp(IN := NOT tParp.Q, PT := T#500MS);
IF tParp.Q THEN parp := NOT parp; END_IF
luzV := FALSE; luzA := parp; luzR := FALSE;