 *al arrancar el bloque, el modo vigente es manual.* -> `modoActivo : INT := 1;` and `modoAnterior : INT := 1;`
    *   *Un cambio de modo solo se acepta mientras estadoSeguro esté activo...* -> `IF estadoSeguro THEN ...`
    *   *Valores de selector fuera de 0 a 2 se ignoran.* -> `IF selector >= 0 AND selector <= 