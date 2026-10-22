"""
Validacion del harness PRG_Test_A2 (FB_Batch: receta por lotes de 5 fases) por
simulacion del ciclo de scan.

Enunciado (tasks.json v1, A2): fase 1 vA hasta nivelA; fase 2 vB hasta nivelB;
fase 3 calentador hasta temp >= 60.0; fase 4 mezclador 120 s; fase 5 vDescarga
hasta nivelVacio; luego fase 0. btnInicio solo desde reposo (se ignora en curso).
btnAbort en fases 1-5 cierra vA, vB, calentador y mezclador; con producto
(nivelVacio inactivo) pasa a fase 5 y descarga; sin producto, a reposo; un abort
en fase 5 continua la descarga; en reposo no tiene efecto. 'fase' reporta la fase
activa en todo momento.

Se evalua al final de cada paso: fase y las 5 salidas (exactamente la de la fase).
No hay vigilancia continua: el enunciado no prohibe que las salidas sigan a 'fase'
con un scan de retraso, que es el estilo habitual CASE-salidas/transiciones.

Paso: (nA,nB,nVac,ini,abo,temp) duracion -> fase esperada
  0 (F,F,F,F,F,20)   0.2 s -> 0   reposo CON producto
  1 (F,F,F,F,T,20)   0.2 s -> 0   abort en reposo: sin efecto
  2 (F,F,F,T,F,20)   0.2 s -> 1   inicio
  3 (F,F,F,F,F,20)   0.2 s -> 1   espera nivelA
  4 (T,F,F,F,F,20)   0.2 s -> 2
  5 (T,F,F,T,F,20)   0.2 s -> 2   inicio durante la receta: se ignora
  6 (T,T,F,F,F,20)   0.2 s -> 3
  7 (T,T,F,F,F,59.9) 0.2 s -> 3   59.9 no basta
  8 (T,T,F,F,F,60.0) 0.2 s -> 4   60.0 o mas
  9 (T,T,F,F,F,60.0) 118  s -> 4   mezcla: aun no cumple 120 s
 10 (T,T,F,F,F,60.0) 3.0 s -> 5   ya cumplio
 11 (T,T,T,F,F,60.0) 0.2 s -> 0   vacio: reposo
 12 (F,F,F,T,F,20)   0.2 s -> 1   nueva receta (con producto)
 13 (F,F,F,F,T,20)   0.2 s -> 5   abort con producto: descarga
 14 (F,F,F,F,F,20)   0.2 s -> 5   sigue descargando
 15 (F,F,T,F,F,20)   0.2 s -> 0
 16 (F,F,T,T,F,20)   0.2 s -> 1   receta con reactor vacio
 17 (F,F,T,F,T,20)   0.2 s -> 0   abort sin producto: directo a reposo
 18 (F,F,F,T,F,20)   0.2 s -> 1
 19 (T,F,F,F,F,20)   0.2 s -> 2
 20 (T,T,F,F,F,20)   0.2 s -> 3   calentando
 21 (T,T,F,F,T,20)   0.2 s -> 5   abort en fase 3: calentador cerrado, descarga
 22 (T,T,F,F,F,20)   0.2 s -> 5
 23 (T,T,F,F,T,20)   0.2 s -> 5   abort durante la descarga: continua
 24 (T,T,T,F,F,20)   0.2 s -> 0
Uso:  python validar_harness_A2.py
"""
from dataclasses import dataclass


@dataclass
class TON:
    et: float = 0.0
    q: bool = False

    def __call__(self, IN, PT, dt):
        if IN:
            self.et += dt
            self.q = self.et >= PT
        else:
            self.et, self.q = 0.0, False
        return self.q


SALIDA = {0: (0, 0, 0, 0, 0), 1: (1, 0, 0, 0, 0), 2: (0, 1, 0, 0, 0), 3: (0, 0, 1, 0, 0),
          4: (0, 0, 0, 1, 0), 5: (0, 0, 0, 0, 1)}


class FBCorrecta:
    T_MEZCLA, UMBRAL_ESTRICTO = 120.0, False

    def __init__(self):
        self.fase, self.tMez = 0, TON()
        self.vA = self.vB = self.calentador = self.mezclador = self.vDescarga = False

    def abort(self, nVac):
        self.fase = 0 if nVac else 5

    def inicio_valido(self):
        return self.fase == 0

    def __call__(self, nA, nB, nVac, ini, abo, temp, dt):
        if ini and self.inicio_valido():
            self.fase = 1
        elif abo and self.fase in (1, 2, 3, 4):
            self.abort(nVac)
        elif self.fase == 1 and nA:
            self.fase = 2
        elif self.fase == 2 and nB:
            self.fase = 3
        elif self.fase == 3 and (temp > 60.0 if self.UMBRAL_ESTRICTO else temp >= 60.0):
            self.fase = 4
        elif self.fase == 4 and self.tMez.q:
            self.fase = 5
        elif self.fase == 5 and nVac:
            self.fase = 0
        self.tMez(self.fase == 4, self.T_MEZCLA, dt)
        self.salidas()

    def salidas(self):
        (self.vA, self.vB, self.calentador, self.mezclador, self.vDescarga) = [bool(x) for x in SALIDA[self.fase]]


class FBInicioNoIgnorado(FBCorrecta):
    """DEFECTO: btnInicio reinicia la receta aunque este en curso."""
    def inicio_valido(self):
        return True


class FBUmbralEstricto(FBCorrecta):
    """DEFECTO: temp > 60.0 en lugar de >= 60.0."""
    UMBRAL_ESTRICTO = True


class FBMezclaCorta(FBCorrecta):
    """DEFECTO: mezcla de 60 s."""
    T_MEZCLA = 60.0


class FBMezclaLarga(FBCorrecta):
    """DEFECTO: mezcla de 180 s."""
    T_MEZCLA = 180.0


class FBAbortSiempreReposo(FBCorrecta):
    """DEFECTO: el abort vuelve a reposo aunque haya producto."""
    def abort(self, nVac):
        self.fase = 0


class FBAbortEnReposo(FBCorrecta):
    """DEFECTO: el abort tambien actua en reposo y manda a descargar."""
    def __call__(self, nA, nB, nVac, ini, abo, temp, dt):
        if abo and self.fase == 0 and not nVac:
            self.fase = 5
            self.tMez(False, self.T_MEZCLA, dt)
            self.salidas()
            return
        super().__call__(nA, nB, nVac, ini, abo, temp, dt)


class FBAbortNoCierraCalentador(FBCorrecta):
    """DEFECTO: tras el abort deja el calentador encendido."""
    def __init__(self):
        super().__init__()
        self.calLat = False

    def abort(self, nVac):
        self.calLat = self.calLat or self.fase == 3
        super().abort(nVac)

    def salidas(self):
        super().salidas()
        if self.fase == 0:
            self.calLat = False
        self.calentador = self.calentador or self.calLat


class FBAbortEnDescargaDetiene(FBCorrecta):
    """DEFECTO: un abort durante la fase 5 vuelve a reposo sin terminar la descarga."""
    def __call__(self, nA, nB, nVac, ini, abo, temp, dt):
        if abo and self.fase == 5:
            self.fase = 0
            self.tMez(False, self.T_MEZCLA, dt)
            self.salidas()
            return
        super().__call__(nA, nB, nVac, ini, abo, temp, dt)


# ------------------------------------------------------------ harness (traduccion fiel del .st)
#        nA nB nV in ab temp   dur    fase
PASOS = [(0, 0, 0, 0, 0, 20.0, 0.2, 0), (0, 0, 0, 0, 1, 20.0, 0.2, 0), (0, 0, 0, 1, 0, 20.0, 0.2, 1),
         (0, 0, 0, 0, 0, 20.0, 0.2, 1), (1, 0, 0, 0, 0, 20.0, 0.2, 2), (1, 0, 0, 1, 0, 20.0, 0.2, 2),
         (1, 1, 0, 0, 0, 20.0, 0.2, 3), (1, 1, 0, 0, 0, 59.9, 0.2, 3), (1, 1, 0, 0, 0, 60.0, 0.2, 4),
         (1, 1, 0, 0, 0, 60.0, 118.0, 4), (1, 1, 0, 0, 0, 60.0, 3.0, 5), (1, 1, 1, 0, 0, 60.0, 0.2, 0),
         (0, 0, 0, 1, 0, 20.0, 0.2, 1), (0, 0, 0, 0, 1, 20.0, 0.2, 5), (0, 0, 0, 0, 0, 20.0, 0.2, 5),
         (0, 0, 1, 0, 0, 20.0, 0.2, 0), (0, 0, 1, 1, 0, 20.0, 0.2, 1), (0, 0, 1, 0, 1, 20.0, 0.2, 0),
         (0, 0, 0, 1, 0, 20.0, 0.2, 1), (1, 0, 0, 0, 0, 20.0, 0.2, 2), (1, 1, 0, 0, 0, 20.0, 0.2, 3),
         (1, 1, 0, 0, 1, 20.0, 0.2, 5), (1, 1, 0, 0, 0, 20.0, 0.2, 5), (1, 1, 0, 0, 1, 20.0, 0.2, 5),
         (1, 1, 1, 0, 0, 20.0, 0.2, 0)]
ULTIMO_PASO = len(PASOS) - 1


def correr_harness(fb, dt, limite_scans=5_000_000):
    paso, tPaso, pulsoReset, finalizado = 0, TON(), False, False
    resultado = [0] * (ULTIMO_PASO + 1)
    for _ in range(limite_scans):
        if not finalizado:
            nA, nB, nV, ini, abo, temp, t, fase = PASOS[paso]
        qPaso = tPaso(not pulsoReset, t, dt)
        pulsoReset = False
        fb(bool(nA), bool(nB), bool(nV), bool(ini), bool(abo), temp, dt)
        if qPaso and not finalizado:
            sal = (fb.vA, fb.vB, fb.calentador, fb.mezclador, fb.vDescarga)
            bien = fb.fase == fase and tuple(int(x) for x in sal) == SALIDA[fase]
            resultado[paso] = 1 if bien else 2
            pulsoReset = True
            if paso < ULTIMO_PASO:
                paso += 1
            else:
                finalizado = True
        if finalizado:
            return (1 if all(x == 1 for x in resultado) else 2), resultado
    return 0, resultado


CASOS = [("Correcta", FBCorrecta, 1, None),
         ("AbortEnReposo", FBAbortEnReposo, 2, 1),
         ("InicioNoIgnorado", FBInicioNoIgnorado, 2, 5),
         ("UmbralEstricto", FBUmbralEstricto, 2, 8),
         ("MezclaCorta", FBMezclaCorta, 2, 9),
         ("MezclaLarga", FBMezclaLarga, 2, 10),
         ("AbortSiempreReposo", FBAbortSiempreReposo, 2, 13),
         ("AbortNoCierraCalentador", FBAbortNoCierraCalentador, 2, 21),
         ("AbortEnDescargaDetiene", FBAbortEnDescargaDetiene, 2, 13)]


def main():
    todo_ok = True
    print("VALIDACION DEL HARNESS PRG_Test_A2")
    for nombre, cls, esp, paso in CASOS:
        vec = set()
        for dt in (0.004, 0.010, 0.020):
            v, r = correr_harness(cls(), dt)
            ok = v == esp and (paso is None or (r[paso] == 2 and 2 not in r[:paso]))
            todo_ok &= ok
            vec.add(tuple(r))
            print("%-24s %2d ms  v=%d  %s  %s" % (nombre, int(dt * 1000), v, "".join(map(str, r)), "ok" if ok else "NO"))
        todo_ok &= len(vec) == 1
    print("Discrimina y es independiente del ciclo:", "SI" if todo_ok else "NO")
    return todo_ok


if __name__ == "__main__":
    main()
