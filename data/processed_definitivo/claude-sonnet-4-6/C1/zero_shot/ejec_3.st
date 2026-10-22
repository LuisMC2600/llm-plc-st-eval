IF t1.Q THEN
      t1(IN := FALSE);   (* reinicio explícito *)
      estado := 1;
  END_IF

luzV := FALSE; luzA := TRUE; luzR := FALSE;

luzV := FALSE; luzA := FALSE; luzR := TRUE;

tParp(IN := NOT tParp.Q, PT := T#500MS);
  parp := tParp.Q;