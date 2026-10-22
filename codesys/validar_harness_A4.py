"""
Validacion del harness PRG_Test_A4 (FB_Rampa: generador de consigna con rampa)
por simulacion del ciclo de scan.

Enunciado (tasks.json v1, A4): CVvel sigue a SPvel con pendiente maxima de
10 %/s al subir y 20 %/s al bajar; con paroRapido, desciende a 0.0 a 40 %/s
ignorando SPvel y permanece en 0.0; 'ciclo' es el periodo de ejecucion; sin
sobrepaso.

TIEMPO VIRTUAL: el banco pasa SIEMPRE ciclo := T#10MS y define cada paso por
NUMERO DE LLAMADAS, no por tiempo real. El resultado es determinista e
independiente del ciclo de la MainTask (las respuestas se evaluan con MainTask a
10 ms, donde ademas el ciclo virtual coincide con el real).
Comparaciones con tolerancia 0.01 (REAL de 32 bits). Vigilancia continua de
sobrepaso: CVvel nunca puede cruzar el objetivo en mas de 0.001.

Paso: (SP, paro) llamadas -> CVvel esperado   [vigilancia]
  0 (0.05,F)  1 ->  0.05   escalon menor que el incremento (0.1): sin sobrepaso [CV <= 0.05]
  1 ( 0,F)    1 ->  0.0    idem al bajar                                        [CV >= 0]
  2 (50,F)  300 -> 30.0    subida 10 %/s
  3 (50,F)  300 -> 50.0    llega y se queda           [CV <= 50]
  4 (20,F)  100 -> 30.0    bajada 20 %/s
  5 (20,F)  100 -> 20.0                               [CV >= 20]
  6 (80,F)  200 -> 40.0
  7 (80,T)   50 -> 20.0    paro rapido 40 %/s
  8 (80,T)  100 ->  0.0                               [CV >= 0]
  9 (80,T)   50 ->  0.0    permanece en 0 con paro    [CV <= 0]
 10 (80,F)  100 -> 10.0    sin paro: vuelve a subir
 11 (10.05,F) 1 -> 10.05                              [CV <= 10.05]
 12 ( 9,F)   10 ->  9.0                               [CV >= 9]
El sobrepaso se prueba PRIMERO (pasos 0 y 1), desde 0.0 y sin acumulacion previa:
asi el paso de fallo de un bloque que no acota no depende del redondeo de REAL
de 32 bits frente al float de 64 bits del validador.
Uso:  python validar_harness_A4.py
"""
CICLO = 0.010
TOL, TOL_VIG = 0.01, 0.001


class FBCorrecta:
    SUB, BAJ, PARO = 10.0, 20.0, 40.0

    def __init__(self):
        self.CVvel = 0.0

    def dt(self, ciclo):
        return ciclo

    def __call__(self, SPvel, paroRapido, ciclo):
        d = self.dt(ciclo)
        obj = 0.0 if paroRapido else SPvel
        if self.CVvel < obj:
            self.CVvel = min(obj, self.CVvel + self.SUB * d)
        elif self.CVvel > obj:
            self.CVvel = max(obj, self.CVvel - (self.PARO if paroRapido else self.BAJ) * d)


class FBSubidaRapida(FBCorrecta):
    """DEFECTO: sube a 20 %/s."""
    SUB = 20.0


class FBBajadaLenta(FBCorrecta):
    """DEFECTO: baja a 10 %/s (misma pendiente que al subir)."""
    BAJ = 10.0


class FBParoLento(FBCorrecta):
    """DEFECTO: el paro rapido usa la pendiente normal de bajada."""
    PARO = 20.0


class FBParoInstantaneo(FBCorrecta):
    """DEFECTO: el paro rapido pone CVvel a 0 de golpe."""
    def __call__(self, SPvel, paroRapido, ciclo):
        if paroRapido:
            self.CVvel = 0.0
        else:
            super().__call__(SPvel, paroRapido, ciclo)


class FBParoNoMantiene(FBCorrecta):
    """DEFECTO: llegado a 0 con paro, vuelve a seguir a SPvel."""
    def __init__(self):
        super().__init__()
        self.llego = False

    def __call__(self, SPvel, paroRapido, ciclo):
        if not paroRapido:
            self.llego = False
        if paroRapido and self.llego:
            super().__call__(SPvel, False, ciclo)
            return
        super().__call__(SPvel, paroRapido, ciclo)
        if paroRapido and self.CVvel <= 0.0:
            self.llego = True


class FBSobrepaso(FBCorrecta):
    """DEFECTO: suma el incremento completo sin acotar al objetivo."""
    def __call__(self, SPvel, paroRapido, ciclo):
        obj = 0.0 if paroRapido else SPvel
        if self.CVvel < obj:
            self.CVvel += self.SUB * ciclo
        elif self.CVvel > obj:
            self.CVvel -= (self.PARO if paroRapido else self.BAJ) * ciclo


class FBCicloEnMs(FBCorrecta):
    """DEFECTO: toma TIME_TO_REAL(ciclo) (milisegundos) como segundos."""
    def dt(self, ciclo):
        return ciclo * 1000.0


# ------------------------------------------------------------ harness (traduccion fiel del .st)
#        SP     paro llamadas esperado vig ('<=' | '>=' | None)
PASOS = [(0.05, 0, 1, 0.05, '<='), (0.0, 0, 1, 0.0, '>='), (50.0, 0, 300, 30.0, None), (50.0, 0, 300, 50.0, '<='),
         (20.0, 0, 100, 30.0, None), (20.0, 0, 100, 20.0, '>='), (80.0, 0, 200, 40.0, None),
         (80.0, 1, 50, 20.0, None), (80.0, 1, 100, 0.0, '>='), (80.0, 1, 50, 0.0, '<='),
         (80.0, 0, 100, 10.0, None), (10.05, 0, 1, 10.05, '<='), (9.0, 0, 10, 9.0, '>=')]
ULTIMO_PASO = len(PASOS) - 1


def correr_harness(fb, dt=None):
    """dt (ciclo real de la MainTask) no influye: el banco cuenta llamadas."""
    resultado = [0] * (ULTIMO_PASO + 1)
    for paso, (sp, paro, n, esp, vig) in enumerate(PASOS):
        violacion = False
        for _ in range(n):
            fb(sp, bool(paro), CICLO)
            if vig == '<=' and fb.CVvel > esp + TOL_VIG:
                violacion = True
            if vig == '>=' and fb.CVvel < esp - TOL_VIG:
                violacion = True
        resultado[paso] = 1 if (abs(fb.CVvel - esp) <= TOL and not violacion) else 2
    return (1 if all(x == 1 for x in resultado) else 2), resultado


CASOS = [("Correcta", FBCorrecta, 1, None),
         ("SubidaRapida", FBSubidaRapida, 2, 2),
         ("BajadaLenta", FBBajadaLenta, 2, 4),
         ("ParoLento", FBParoLento, 2, 7),
         ("ParoInstantaneo", FBParoInstantaneo, 2, 7),
         ("ParoNoMantiene", FBParoNoMantiene, 2, 8),
         ("Sobrepaso", FBSobrepaso, 2, 0),
         ("CicloEnMs", FBCicloEnMs, 2, 2)]


def main():
    todo_ok = True
    print("VALIDACION DEL HARNESS PRG_Test_A4 (tiempo virtual: no depende del ciclo real)")
    for nombre, cls, esp, paso in CASOS:
        v, r = correr_harness(cls())
        ok = v == esp and (paso is None or (r[paso] == 2 and 2 not in r[:paso]))
        todo_ok &= ok
        print("%-16s v=%d  %s  %s" % (nombre, v, r, "ok" if ok else "NO"))
    print("Discrimina:", "SI" if todo_ok else "NO")
    return todo_ok


if __name__ == "__main__":
    main()
