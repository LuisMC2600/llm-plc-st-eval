"""
Validacion del harness PRG_Test_B8 (FB_Puerta: conteo de aperturas por flanco)
por simulacion del ciclo de scan. Mismo metodo que validar_harness_B3.py.

Enunciado (tasks.json v1, B8): cada flanco FALSE->TRUE de puertaAbierta suma 1
a nAperturas; mantener la puerta abierta no cuenta; con 5 o mas aperturas se
activa aviso; reset pone el registro en cero y desactiva el aviso.

Pasos del banco (cuentas acumuladas):
  0 reset, puerta cerrada ............................ n=0  aviso=F
  1 se suelta reset y se abre la puerta (1 flanco) ... n=1  aviso=F
  2 puerta sostenida abierta 500 ms .................. n=1  aviso=F   (cuenta por nivel)
  3 puerta cerrada ................................... n=1  aviso=F   (cuenta en flanco de bajada)
  4 3 flancos generados .............................. n=4  aviso=F   (umbral 4)
  5 1 flanco ......................................... n=5  aviso=T   (umbral 6 / '>5')
  6 1 flanco ......................................... n=6  aviso=T   (aviso solo en '=5', saturacion)
  7 reset, puerta cerrada ............................ n=0  aviso=F   (reset incompleto)
  8 se suelta reset, 1 flanco ........................ n=1  aviso=F   (bloqueo tras reset)
Las transiciones de reset se hacen siempre con la puerta cerrada: el enunciado
no dice que pasa con un flanco durante el reset, asi que no se prueba.

Uso:  python validar_harness_B8.py
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


# ------------------------------------------------------------ implementaciones
@dataclass
class _Base:
    nAperturas: int = 0
    aviso: bool = False
    _prev: bool = False


class FBCorrecta(_Base):
    def __call__(self, puertaAbierta, reset, dt):
        if reset:
            self.nAperturas, self.aviso = 0, False
        elif puertaAbierta and not self._prev:
            self.nAperturas += 1
        self._prev = puertaAbierta
        self.aviso = self.nAperturas >= 5


class FBCuentaPorNivel(_Base):
    """DEFECTO: suma 1 en cada scan con la puerta abierta."""
    def __call__(self, puertaAbierta, reset, dt):
        if reset:
            self.nAperturas = 0
        elif puertaAbierta:
            self.nAperturas += 1
        self.aviso = self.nAperturas >= 5


class FBCuentaFlancoBajada(_Base):
    """DEFECTO: cuenta el cierre (TRUE->FALSE) en lugar de la apertura."""
    def __call__(self, puertaAbierta, reset, dt):
        if reset:
            self.nAperturas = 0
        elif self._prev and not puertaAbierta:
            self.nAperturas += 1
        self._prev = puertaAbierta
        self.aviso = self.nAperturas >= 5


def _umbral(cmp):
    class _U(_Base):
        def __call__(self, puertaAbierta, reset, dt):
            if reset:
                self.nAperturas = 0
            elif puertaAbierta and not self._prev:
                self.nAperturas += 1
            self._prev = puertaAbierta
            self.aviso = cmp(self.nAperturas)
    return _U


FBUmbralCuatro = _umbral(lambda n: n >= 4)      # DEFECTO: aviso con 4
FBUmbralSeis = _umbral(lambda n: n > 5)         # DEFECTO: '>5' en vez de '>=5'
FBAvisoSoloEnCinco = _umbral(lambda n: n == 5)  # DEFECTO: '=5'


class FBSaturaEnCinco(_Base):
    """DEFECTO: deja de contar al llegar a 5."""
    def __call__(self, puertaAbierta, reset, dt):
        if reset:
            self.nAperturas = 0
        elif puertaAbierta and not self._prev and self.nAperturas < 5:
            self.nAperturas += 1
        self._prev = puertaAbierta
        self.aviso = self.nAperturas >= 5


class FBResetNoApagaAviso(_Base):
    """DEFECTO: aviso enclavado que el reset no borra."""
    def __call__(self, puertaAbierta, reset, dt):
        if reset:
            self.nAperturas = 0
        elif puertaAbierta and not self._prev:
            self.nAperturas += 1
        self._prev = puertaAbierta
        self.aviso = self.aviso or self.nAperturas >= 5


class FBResetSoloAviso(_Base):
    """DEFECTO: el reset apaga el aviso pero no pone la cuenta en cero."""
    def __call__(self, puertaAbierta, reset, dt):
        if reset:
            self.aviso = False
        elif puertaAbierta and not self._prev:
            self.nAperturas += 1
        self._prev = puertaAbierta
        if not reset:
            self.aviso = self.nAperturas >= 5


# ------------------------------------------------------------ harness (traduccion fiel del .st)
ULTIMO_PASO = 8
T_PULSO = 0.020
#        reset  puerta  tEspera  n   aviso  flancos
PASOS = [(True, False, 0.200, 0, False, 0),
         (False, True, 0.200, 1, False, 0),
         (None, True, 0.500, 1, False, 0),
         (None, False, 0.200, 1, False, 0),
         (None, None, 0.200, 4, False, 3),
         (None, None, 0.200, 5, True, 1),
         (None, None, 0.200, 6, True, 1),
         (True, False, 0.200, 0, False, 0),
         (False, None, 0.200, 1, False, 1)]


def correr_harness(fb, dt, limite_scans=500_000):
    puerta = reset = False
    paso, tEspera, espN, espA = 0, 0.0, 0, False
    tPaso, tPulso = TON(), TON()
    pulsoReset = resetPulso = finalizado = False
    pendientes, cargado = 0, -1
    resultado = [0] * (ULTIMO_PASO + 1)
    for _ in range(limite_scans):
        if not finalizado:
            r, p, t, n, a, _f = PASOS[paso]
            if r is not None:
                reset = r
            if p is not None:
                puerta = p
            tEspera, espN, espA = t, n, a
        if paso != cargado:
            pendientes = PASOS[paso][5]
            cargado = paso
        generando = pendientes > 0
        if generando:
            q = tPulso(not resetPulso, T_PULSO, dt)
            resetPulso = False
            if q:
                puerta = not puerta
                if puerta:
                    pendientes -= 1
                resetPulso = True
        else:
            tPulso(False, T_PULSO, dt)
        qPaso = tPaso((not pulsoReset) and (not generando), tEspera, dt)
        pulsoReset = False
        fb(puerta, reset, dt)
        if qPaso and not finalizado:
            resultado[paso] = 1 if (fb.nAperturas == espN and fb.aviso == espA) else 2
            pulsoReset = True
            if paso < ULTIMO_PASO:
                paso += 1
            else:
                finalizado = True
        if finalizado:
            return (1 if all(x == 1 for x in resultado) else 2), resultado
    return 0, resultado


CASOS = [("Correcta", FBCorrecta, 1, None),
         ("CuentaPorNivel", FBCuentaPorNivel, 2, 1),
         ("CuentaFlancoBajada", FBCuentaFlancoBajada, 2, 1),
         ("UmbralCuatro", FBUmbralCuatro, 2, 4),
         ("UmbralSeis", FBUmbralSeis, 2, 5),
         ("AvisoSoloEnCinco", FBAvisoSoloEnCinco, 2, 6),
         ("SaturaEnCinco", FBSaturaEnCinco, 2, 6),
         ("ResetNoApagaAviso", FBResetNoApagaAviso, 2, 7),
         ("ResetSoloAviso", FBResetSoloAviso, 2, 7)]


def main():
    todo_ok = True
    print("VALIDACION DEL HARNESS PRG_Test_B8")
    for nombre, cls, esp, paso in CASOS:
        vec = set()
        for dt in (0.004, 0.010, 0.020):
            v, r = correr_harness(cls(), dt)
            ok = v == esp and (paso is None or r[paso] == 2) and (paso is None or 2 not in r[:paso])
            todo_ok &= ok
            vec.add(tuple(r))
            print("%-20s %2d ms  v=%d  %s  %s" % (nombre, int(dt * 1000), v, r, "ok" if ok else "NO"))
        todo_ok &= len(vec) == 1
    print("Discrimina y es independiente del ciclo:", "SI" if todo_ok else "NO")
    return todo_ok


if __name__ == "__main__":
    main()
