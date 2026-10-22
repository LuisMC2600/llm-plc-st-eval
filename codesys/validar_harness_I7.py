"""
Validacion del harness PRG_Test_I7 (FB_Duplex: bombas duplex con alternancia)
por simulacion del ciclo de scan.

Enunciado (tasks.json v1, I7, alineado con C4 por la decision D5): con demanda
arranca SOLO la principal; sin demanda ambas paradas; cada flanco de demanda
alterna la principal (la primera tras el arranque es bomba1); si la principal
tiene falla funciona la otra (si no tiene falla) y se activa almFalla; si la
falla desaparece con demanda, vuelve la principal; almFalla solo por falla de la
principal CON demanda; ambas con falla -> ninguna funciona y almFalla.

Paso (demanda, falla1, falla2) -> (bomba1, bomba2, almFalla)   principal
  0  (F,F,F) -> (F,F,F)                                          -
  1  (T,F,F) -> (T,F,F)   primera demanda                        b1
  2  (F,F,F) -> (F,F,F)
  3  (T,F,F) -> (F,T,F)   alterna                                b2
  4  (F,F,F) -> (F,F,F)
  5  (T,F,F) -> (T,F,F)   alterna de nuevo                       b1
  6  (T,T,F) -> (F,T,T)   falla de la principal: respaldo        b1
  7  (T,F,F) -> (T,F,F)   vuelve la principal                    b1
  8  (T,F,T) -> (T,F,F)   falla SOLO del respaldo: sin alarma    b1
  9  (T,T,T) -> (F,F,T)   ambas con falla                        b1
 10  (F,T,T) -> (F,F,F)   sin demanda: sin alarma aunque haya fallas
 11  (T,F,F) -> (F,T,F)   cuarta demanda                         b2
 12  (T,F,T) -> (T,F,T)   falla de la principal b2: respaldo b1  b2
 13  (F,F,F) -> (F,F,F)
Uso:  python validar_harness_I7.py
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


class _Base:
    def __init__(self):
        self.bomba1 = self.bomba2 = self.almFalla = False
        self.turno = False     # FALSE hasta la primera demanda
        self.prev = False

    def _flanco(self, demanda):
        f = demanda and not self.prev
        self.prev = demanda
        return f

    def _salidas(self, demanda, f1, f2, p1):
        """Logica correcta dada la principal (p1=True -> bomba1)."""
        if not demanda:
            return False, False, False
        if p1:
            return (not f1), (f1 and not f2), f1
        return (f2 and not f1), (not f2), f2


class FBCorrecta(_Base):
    def __call__(self, demanda, falla1, falla2):
        if self._flanco(demanda):
            self.turno = not self.turno
        self.bomba1, self.bomba2, self.almFalla = self._salidas(demanda, falla1, falla2, self.turno)


FBReferenciaC4 = FBCorrecta   # el FB del prompt de C4 implementa exactamente esta logica


class FBSinAlternancia(FBCorrecta):
    """DEFECTO: la principal es siempre bomba1."""
    def __call__(self, demanda, falla1, falla2):
        self._flanco(demanda)
        self.bomba1, self.bomba2, self.almFalla = self._salidas(demanda, falla1, falla2, True)


class FBPrimeraEsB2(FBCorrecta):
    """DEFECTO: la primera demanda asigna bomba2."""
    def __init__(self):
        super().__init__()
        self.turno = True


class FBAmbasArrancan(FBCorrecta):
    """DEFECTO: con demanda y sin fallas arrancan las dos."""
    def __call__(self, demanda, falla1, falla2):
        super().__call__(demanda, falla1, falla2)
        if demanda:
            self.bomba1, self.bomba2 = not falla1, not falla2


class FBSinRespaldo(FBCorrecta):
    """DEFECTO: con falla de la principal no arranca la otra."""
    def __call__(self, demanda, falla1, falla2):
        super().__call__(demanda, falla1, falla2)
        if self.turno:
            self.bomba2 = False
        else:
            self.bomba1 = False


class FBRespaldoEnclavado(FBCorrecta):
    """DEFECTO: una vez en respaldo, sigue en respaldo hasta que cae la demanda."""
    def __init__(self):
        super().__init__()
        self.enResp = False

    def __call__(self, demanda, falla1, falla2):
        if self._flanco(demanda):
            self.turno = not self.turno
        if not demanda:
            self.enResp = False
        falla_p = falla1 if self.turno else falla2
        self.enResp = self.enResp or (demanda and falla_p)
        p1 = self.turno if not self.enResp else not self.turno
        fp, fr = (falla1, falla2) if p1 else (falla2, falla1)
        if not demanda:
            s = (False, False, False)
        elif self.enResp:
            corre = not (falla1 if p1 else falla2)
            s = (corre, False, True) if p1 else (False, corre, True)
            if falla_p is False:
                s = (s[0], s[1], False)
        else:
            s = self._salidas(demanda, falla1, falla2, p1)
        self.bomba1, self.bomba2, self.almFalla = s


class FBAlarmaPorRespaldo(FBCorrecta):
    """DEFECTO: almFalla con cualquier falla (tambien la del respaldo)."""
    def __call__(self, demanda, falla1, falla2):
        super().__call__(demanda, falla1, falla2)
        self.almFalla = demanda and (falla1 or falla2)


class FBRespaldoConFalla(FBCorrecta):
    """DEFECTO: el respaldo arranca aunque tambien tenga falla."""
    def __call__(self, demanda, falla1, falla2):
        super().__call__(demanda, falla1, falla2)
        if demanda:
            if self.turno:
                self.bomba2 = falla1
            else:
                self.bomba1 = falla2


class FBAlarmaSinDemanda(FBCorrecta):
    """DEFECTO: almFalla por falla de la principal aunque no haya demanda."""
    def __call__(self, demanda, falla1, falla2):
        super().__call__(demanda, falla1, falla2)
        self.almFalla = falla1 if self.turno else falla2


# ------------------------------------------------------------ harness (traduccion fiel del .st)
T_PASO = 0.100
PASOS = [((False, False, False), (False, False, False)),
         ((True, False, False), (True, False, False)),
         ((False, False, False), (False, False, False)),
         ((True, False, False), (False, True, False)),
         ((False, False, False), (False, False, False)),
         ((True, False, False), (True, False, False)),
         ((True, True, False), (False, True, True)),
         ((True, False, False), (True, False, False)),
         ((True, False, True), (True, False, False)),
         ((True, True, True), (False, False, True)),
         ((False, True, True), (False, False, False)),
         ((True, False, False), (False, True, False)),
         ((True, False, True), (True, False, True)),
         ((False, False, False), (False, False, False))]
ULTIMO_PASO = len(PASOS) - 1


def correr_harness(fb, dt, limite_scans=100_000):
    paso, tPaso, pulsoReset, finalizado = 0, TON(), False, False
    resultado = [0] * (ULTIMO_PASO + 1)
    ent, esp = PASOS[0]
    for _ in range(limite_scans):
        if not finalizado:
            ent, esp = PASOS[paso]
        qPaso = tPaso(not pulsoReset, T_PASO, dt)
        pulsoReset = False
        fb(*ent)
        if qPaso and not finalizado:
            resultado[paso] = 1 if (fb.bomba1, fb.bomba2, fb.almFalla) == esp else 2
            pulsoReset = True
            if paso < ULTIMO_PASO:
                paso += 1
            else:
                finalizado = True
        if finalizado:
            return (1 if all(x == 1 for x in resultado) else 2), resultado
    return 0, resultado


CASOS = [("Correcta", FBCorrecta, 1, None),
         ("ReferenciaC4", FBReferenciaC4, 1, None),
         ("SinAlternancia", FBSinAlternancia, 2, 3),
         ("PrimeraEsB2", FBPrimeraEsB2, 2, 1),
         ("AmbasArrancan", FBAmbasArrancan, 2, 1),
         ("SinRespaldo", FBSinRespaldo, 2, 6),
         ("RespaldoEnclavado", FBRespaldoEnclavado, 2, 7),
         ("AlarmaPorRespaldo", FBAlarmaPorRespaldo, 2, 8),
         ("RespaldoConFalla", FBRespaldoConFalla, 2, 9),
         ("AlarmaSinDemanda", FBAlarmaSinDemanda, 2, 10)]


def main():
    todo_ok = True
    print("VALIDACION DEL HARNESS PRG_Test_I7")
    for nombre, cls, esp, paso in CASOS:
        vec = set()
        for dt in (0.004, 0.010, 0.020):
            v, r = correr_harness(cls(), dt)
            ok = v == esp and (paso is None or (r[paso] == 2 and 2 not in r[:paso]))
            todo_ok &= ok
            vec.add(tuple(r))
            print("%-18s %2d ms  v=%d  %s  %s" % (nombre, int(dt * 1000), v, r, "ok" if ok else "NO"))
        todo_ok &= len(vec) == 1
    print("Discrimina y es independiente del ciclo:", "SI" if todo_ok else "NO")
    return todo_ok


if __name__ == "__main__":
    main()
