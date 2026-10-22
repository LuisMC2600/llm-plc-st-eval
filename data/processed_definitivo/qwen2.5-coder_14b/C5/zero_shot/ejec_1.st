1:
         t1(IN := TRUE, PT := T#8S);
         IF t1.Q THEN
             kY := FALSE;  // Agregar esta línea
             kD := TRUE;
             estado := 2;
         END_IF

2:
         kY := FALSE;
         kD := TRUE;  // Asegurarse de que kD esté activo

IF btnParo THEN
         kM := FALSE;  // Agregar esta línea
         kY := FALSE;
         kD := FALSE;
         estado := 0;
     END_IF

VAR
         t1 : TON;
         t2 : TON;
         t3 : TON;  // Agregar temporizador t3 para el tiempo muerto
     END_VAR

     1:
         t1(IN := TRUE, PT := T#8S);
         IF t1.Q THEN
             t3(IN := TRUE, PT := T#100MS);  // Iniciar temporizador t3
             IF t3.Q THEN
                 kY := FALSE;
                 kD := TRUE;
                 estado := 2;
             END_IF
         END_IF

2:
         kY := FALSE;
         kD := TRUE;  // Asegurarse de que kD esté activo