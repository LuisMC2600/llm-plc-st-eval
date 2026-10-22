t1(IN := FALSE); // resetear
  estado := <siguiente>;

t1(IN := TRUE, PT := T#500MS);
  IF t1.Q THEN
      parp := NOT parp;
      t1(IN := FALSE);
  END_IF
  luzV := FALSE; luzA := parp; luzR := FALSE;