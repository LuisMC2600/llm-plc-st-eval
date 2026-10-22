"""
Validacion del harness PRG_Test_A1 (FB_PID con anti-windup por clamping) por
simulacion del ciclo de scan.

Enunciado (tasks.json v1, A1): CV = Kp*(e + (1/Ti)*int(e dt) + Td*de/dt),
e = SP - PV; derivada sobre el error; Ti <= 0 desactiva la integral; CV limitada
a 0.0..100.0; anti-windup por clamping (saturada en 100 no integra error
positivo; saturada en 0 no integra error negativo); 'ciclo' = periodo de muestreo.

TOLERANCIAS (aprobadas por Luis y su asesora, 30-09-2026):
  solo P: +-0.01 | integral: +-2 pasos de muestreo | derivada: +-5 %% del termino
  derivativo | saturacion exacta (+-0.001) | anti-windup: sale de la saturacion en
  menos de 1 s tras invertir el error | sentido: PV < SP -> CV sube.

TIEMPO VIRTUAL: ciclo := T#100MS fijo; pasos por NUMERO DE LLAMADAS. Cada
escenario usa su PROPIA instancia del FB (fbP, fbI, fbD, fbW), para que el estado
interno de un escenario (p. ej. una integral acumulada) no contamine otro.

Paso  instancia  (Kp, Ti, Td, SP, PV) llamadas -> comprobacion
  0   fbP  (2, 0, 0, 50, 40)     5 -> CV = 20.0 +-0.01     solo P, sentido
  1   fbP  (2, 0, 0, 50, 60)     5 -> CV = 0.0 +-0.001     saturacion baja
  2   fbP  (2, 0, 0, 50,-20)     5 -> CV = 100.0 +-0.001   saturacion alta
  3   fbP  (2,-1, 0, 50, 45)     5 -> CV = 10.0 +-0.01     Ti < 0: sin integral
  4   fbI  (1,10, 0, 50, 45)   100 -> CV = 10.0 +-0.10     5 + 0.5*10 s
  5   fbI  (1,10, 0, 50, 45)   100 -> CV = 15.0 +-0.10     5 + 0.5*20 s
  6   fbD  (1, 0, 2, 50+0.1k, 40) 50 -> CV = 17.0 +-0.10   e = 15, Td*de/dt = 2 (SP en rampa:
                                                           la derivada sobre PV daria 0)
  7   fbW  (1, 5, 0,100,  0)   300 -> CV = 100.0 +-0.001   30 s saturado en alto
  8   fbW  (1, 5, 0,100,110)    10 -> CV <= 99.5            sale de 100 en < 1 s
  9   fbW  (1, 5, 0,  0,200)   300 -> CV = 0.0 +-0.001     30 s saturado en bajo
 10   fbW  (1, 5, 0,  0,-10)    10 -> CV >= 0.5             sale de 0 en < 1 s
Uso:  python validar_harness_A1.py
"""
CICLO = 0.1


class FBCorrecta:
    SIGNO, DERIV_PV, ANTIWINDUP, AW_BAJO, USA_DT, DT_ESCALA, SATURA, TI_CERO_INTEGRA, USA_TD = \
        1, False, True, True, True, 1.0, True, False, True

    def __init__(self):
        self.CV, self.I, self.ePrev, self.pvPrev, self.primero = 0.0, 0.0, 0.0, 0.0, True

    def __call__(self, SP, PV, Kp, Ti, Td, ciclo):
        dt = ciclo * self.DT_ESCALA
        e = (SP - PV) * self.SIGNO
        if self.primero:
            self.ePrev, self.pvPrev, self.primero = e, PV, False
        d = (-(PV - self.pvPrev) if self.DERIV_PV else (e - self.ePrev)) / dt if self.USA_TD else 0.0
        self.ePrev, self.pvPrev = e, PV
        tiEf = Ti if Ti > 0 else (1.0 if self.TI_CERO_INTEGRA else 0.0)
        integra = tiEf > 0
        if integra:
            sat_alto = self.CV >= 100.0 and e > 0
            sat_bajo = self.CV <= 0.0 and e < 0 and self.AW_BAJO
            if not (self.ANTIWINDUP and (sat_alto or sat_bajo)):
                self.I += e * (dt if self.USA_DT else 1.0)
        cv = Kp * (e + (self.I / tiEf if integra else 0.0) + Td * d)
        self.CV = min(100.0, max(0.0, cv)) if self.SATURA else cv


def defecto(nombre, **kw):
    return type(nombre, (FBCorrecta,), kw)


FBSignoInvertido = defecto("FBSignoInvertido", SIGNO=-1)
FBSinSaturacion = defecto("FBSinSaturacion", SATURA=False)
FBTiCeroIntegra = defecto("FBTiCeroIntegra", TI_CERO_INTEGRA=True)
FBIntegralSinDt = defecto("FBIntegralSinDt", USA_DT=False)
FBCicloEnMs = defecto("FBCicloEnMs", DT_ESCALA=1000.0)
FBSinDerivada = defecto("FBSinDerivada", USA_TD=False)
FBDerivadaSobrePV = defecto("FBDerivadaSobrePV", DERIV_PV=True)
FBSinAntiWindup = defecto("FBSinAntiWindup", ANTIWINDUP=False)
FBAntiWindupSoloAlto = defecto("FBAntiWindupSoloAlto", AW_BAJO=False)


class FBCorrectaIntegralPrevia(FBCorrecta):
    """Correcta alternativa: calcula CV con la integral del ciclo anterior y
    luego integra; anti-windup con el CV sin saturar; derivada con ePrev inicial 0
    (golpe derivativo en la primera muestra)."""
    def __init__(self):
        super().__init__()
        self.primero = False

    def __call__(self, SP, PV, Kp, Ti, Td, ciclo):
        e = SP - PV
        d = (e - self.ePrev) / ciclo
        self.ePrev = e
        integ = self.I / Ti if Ti > 0 else 0.0
        cv = Kp * (e + integ + Td * d)
        if Ti > 0 and not ((cv >= 100.0 and e > 0) or (cv <= 0.0 and e < 0)):
            self.I += e * ciclo
        self.CV = min(100.0, max(0.0, cv))


class FBCorrectaTrapezoidal(FBCorrecta):
    """Correcta alternativa: integracion trapezoidal."""
    def __call__(self, SP, PV, Kp, Ti, Td, ciclo):
        e = SP - PV
        if self.primero:
            self.ePrev, self.primero = e, False
        d = (e - self.ePrev) / ciclo
        eAnt, self.ePrev = self.ePrev, e
        if Ti > 0 and not ((self.CV >= 100.0 and e > 0) or (self.CV <= 0.0 and e < 0)):
            self.I += 0.5 * (e + eAnt) * ciclo
        cv = Kp * (e + (self.I / Ti if Ti > 0 else 0.0) + Td * d)
        self.CV = min(100.0, max(0.0, cv))

# ------------------------------------------------------------ harness (traduccion fiel del .st)
# (instancia, Kp, Ti, Td, SP, rampaSP, PV, llamadas, tipo, valor, tol)  tipo: 0 '=', 1 '<=', 2 '>='
PASOS = [(0, 2, 0, 0, 50, 0, 40, 5, 0, 20.0, 0.01), (0, 2, 0, 0, 50, 0, 60, 5, 0, 0.0, 0.001),
         (0, 2, 0, 0, 50, 0, -20, 5, 0, 100.0, 0.001), (0, 2, -1, 0, 50, 0, 45, 5, 0, 10.0, 0.01),
         (1, 1, 10, 0, 50, 0, 45, 100, 0, 10.0, 0.10), (1, 1, 10, 0, 50, 0, 45, 100, 0, 15.0, 0.10),
         (2, 1, 0, 2, 50, 1, 40, 50, 0, 17.0, 0.10), (3, 1, 5, 0, 100, 0, 0, 300, 0, 100.0, 0.001),
         (3, 1, 5, 0, 100, 0, 110, 10, 1, 99.5, 0.0), (3, 1, 5, 0, 0, 0, 200, 300, 0, 0.0, 0.001),
         (3, 1, 5, 0, 0, 0, -10, 10, 2, 0.5, 0.0)]
ULTIMO_PASO = len(PASOS) - 1


def correr_harness(cls, dt=None):
    fbs = [cls() for _ in range(4)]
    kRampa = 0
    resultado = [0] * (ULTIMO_PASO + 1)
    for paso, (ins, kp, ti, td, sp, rampa, pv, n, tipo, val, tol) in enumerate(PASOS):
        fb = fbs[ins]
        for _ in range(n):
            if rampa:
                kRampa += 1
            fb(sp + 0.1 * kRampa * rampa, pv, kp, ti, td, CICLO)
        cv = fb.CV
        ok = (abs(cv - val) <= tol) if tipo == 0 else (cv <= val if tipo == 1 else cv >= val)
        resultado[paso] = 1 if ok else 2
    return (1 if all(x == 1 for x in resultado) else 2), resultado


CASOS = [("Correcta", FBCorrecta, 1, None),
         ("CorrectaIntegralPrevia", FBCorrectaIntegralPrevia, 1, None),
         ("CorrectaTrapezoidal", FBCorrectaTrapezoidal, 1, None),
         ("SignoInvertido", FBSignoInvertido, 2, 0),
         ("SinSaturacion", FBSinSaturacion, 2, 1),
         ("TiCeroIntegra", FBTiCeroIntegra, 2, 0),
         ("IntegralSinDt", FBIntegralSinDt, 2, 4),
         ("CicloEnMs", FBCicloEnMs, 2, 4),
         ("SinDerivada", FBSinDerivada, 2, 6),
         ("DerivadaSobrePV", FBDerivadaSobrePV, 2, 6),
         ("SinAntiWindup", FBSinAntiWindup, 2, 8),
         ("AntiWindupSoloAlto", FBAntiWindupSoloAlto, 2, 10)]


def main():
    todo_ok = True
    print("VALIDACION DEL HARNESS PRG_Test_A1 (tiempo virtual)")
    for nombre, cls, esp, paso in CASOS:
        v, r = correr_harness(cls)
        ok = v == esp and (paso is None or (r[paso] == 2 and 2 not in r[:paso]))
        todo_ok &= ok
        print("%-20s v=%d  %s  %s" % (nombre, v, r, "ok" if ok else "NO"))
    print("Discrimina:", "SI" if todo_ok else "NO")
    return todo_ok


if __name__ == "__main__":
    main()
