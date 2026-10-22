"""
Validacion del harness PRG_Test_I1 por simulacion del ciclo de scan.

I1 (semaforo): secuencia verde 20 s, amarillo 4 s, rojo 15 s mientras
'habilitado'; al deshabilitar, amarillo intermitente de 1 s / 1 s "con las
demas luces apagadas"; al rehabilitar, la secuencia reinicia en verde.

El modo intermitente cae bajo la enmienda 1 (medir intervalos, no muestrear).
Interesa comprobar tambien si la condicion "las demas luces apagadas" resiste,
ya que en el harness se comprueba en un unico instante.

Uso:  python validar_harness_I1.py
"""

from dataclasses import dataclass


@dataclass
class TON:
    et: float = 0.0
    q: bool = False

    def __call__(self, IN: bool, PT: float, dt: float) -> bool:
        if IN:
            self.et = min(self.et + dt, PT)
            self.q = self.et >= PT
        else:
            self.et = 0.0
            self.q = False
        return self.q


# --------------------------------------------------------------------------
# Implementaciones sinteticas de FB_Semaforo
# --------------------------------------------------------------------------
@dataclass
class _Base:
    luzV: bool = False
    luzA: bool = False
    luzR: bool = False
    estado: int = 0
    t: float = 0.0
    tParp: float = 0.0
    parp: bool = False
    _prevHab: bool = False
    tV: float = 20.0
    tA: float = 4.0
    tR: float = 15.0
    tParpPT: float = 1.0

    def _intermitente(self, dt):
        """Modo por defecto: solo el amarillo parpadea, las demas apagadas."""
        self.luzV = False
        self.luzR = False
        self.tParp += dt
        if self.tParp >= self.tParpPT:
            self.tParp = 0.0
            self.parp = not self.parp
        self.luzA = self.parp

    def _reinicia(self):
        self.estado = 0
        self.t = 0.0
        self.parp = False
        self.tParp = 0.0

    def __call__(self, habilitado, dt):
        if not habilitado:
            self._intermitente(dt)
            self._prevHab = False
            return
        if not self._prevHab:
            self._reinicia()   # solo aqui se decide si la secuencia reinicia
        self._prevHab = True
        self.t += dt
        if self.estado == 0:
            self.luzV, self.luzA, self.luzR = True, False, False
            if self.t >= self.tV:
                self.estado, self.t = 1, 0.0
        elif self.estado == 1:
            self.luzV, self.luzA, self.luzR = False, True, False
            if self.t >= self.tA:
                self.estado, self.t = 2, 0.0
        else:
            self.luzV, self.luzA, self.luzR = False, False, True
            if self.t >= self.tR:
                self.estado, self.t = 0, 0.0


def FBCorrecto():
    return _Base()


def FBTiemposCambiados():
    """DEFECTO: verde 15 s y rojo 20 s (tiempos intercambiados)."""
    return _Base(tV=15.0, tR=20.0)


def FBParpadeoLento():
    """DEFECTO: intermitente de 1,5 s / 1,5 s. Muestreado alternaria igual
    que el correcto (enmienda 1); solo lo atrapa la medida del intervalo."""
    return _Base(tParpPT=1.5)


@dataclass
class FBSinIntermitente(_Base):
    """DEFECTO: al deshabilitar apaga las tres luces, sin modo intermitente."""

    def _intermitente(self, dt):
        self.luzV = self.luzA = self.luzR = False


@dataclass
class FBIntermitenteConRojo(_Base):
    """DEFECTO: implementa el intermitente alternando amarillo y rojo, en vez
    de amarillo contra todo apagado. El rojo queda en ANTIFASE con el amarillo,
    de modo que en el instante en que se muestrea el amarillo encendido las
    demas estan apagadas y el defecto puede pasar inadvertido."""

    def _intermitente(self, dt):
        self.luzV = False
        self.tParp += dt
        if self.tParp >= self.tParpPT:
            self.tParp = 0.0
            self.parp = not self.parp
        self.luzA = self.parp
        self.luzR = not self.parp        # antifase


@dataclass
class FBIntermitenteConRojoFaseInversa(_Base):
    """El MISMO defecto que el anterior pero arrancando el parpadeo con el
    amarillo encendido. Sirve para comprobar si el harness lo detecta por
    merito propio o por la fase en que le toca muestrear."""
    parp: bool = True

    def _intermitente(self, dt):
        self.luzV = False
        self.tParp += dt
        if self.tParp >= self.tParpPT:
            self.tParp = 0.0
            self.parp = not self.parp
        self.luzA = self.parp
        self.luzR = not self.parp


@dataclass
class FBNoReinicia(_Base):
    """DEFECTO: al rehabilitar continua donde se quedo en vez de reiniciar
    en verde."""

    def _reinicia(self):
        pass                              # no reinicia el estado


# --------------------------------------------------------------------------
# Harness PRG_Test_I1 corregido (traduccion fiel del .st, enmienda 8)
# --------------------------------------------------------------------------
TOL_MIN, TOL_MAX = 0.850, 1.150
T_CRONO = 100.0
PASO_INTERM = 7
# (habilitado, tEspera, espV, espA, espR)  -- None conserva el valor anterior
PASOS = [
    (False, 0.200, None, None, None),    # 0 reposo deshabilitado
    (True,  0.200, True,  False, False), # 1 arranca en verde
    (True,  20.000, False, True,  False),# 2 verde 20 s -> amarillo
    (True,  4.000, False, False, True),  # 3 amarillo 4 s -> rojo
    (True,  15.000, True,  False, False),# 4 rojo 15 s -> verde
    (True,  20.000, False, True,  False),# 5 segundo ciclo -> amarillo
    (True,  4.000, False, False, True),  # 6 segundo ciclo -> ROJO
    (False, 7.000, None, None, None),    # 7 intermitente, interrumpido en rojo
    (True,  0.200, True,  False, False), # 8 debe REINICIAR en verde
]


def correr_harness(fb, dt: float, limite_scans: int = 20_000_000, traza=False):
    ultimo = len(PASOS) - 1
    habilitado = False
    paso = 0
    tEspera = 0.0
    espV = espA = espR = False
    tPaso, tCrono = TON(), TON()
    pulsoReset = False
    finalizado = False
    prevA = primer = error = False
    etFlanco = 0.0
    nOn = nOff = 0
    otraLuzPaso0 = otraLuzPaso7 = False
    medidas = []
    resultado = [0] * (ultimo + 1)
    veredicto = 0

    for _ in range(limite_scans):
        if not finalizado:
            h, t, v, a, r = PASOS[paso]
            habilitado, tEspera = h, t
            if v is not None:
                espV, espA, espR = v, a, r

        tPaso(not pulsoReset, tEspera, dt)
        tCrono(True, T_CRONO, dt)
        pulsoReset = False
        fb(habilitado, dt)

        # Medida de intervalos del intermitente (enmiendas 1 y 5)
        if paso == PASO_INTERM:
            if (fb.luzA and not prevA) or ((not fb.luzA) and prevA):
                if primer:
                    duracion = tCrono.et - etFlanco
                    if not fb.luzA:
                        nOn += 1
                    else:
                        nOff += 1
                    medidas.append(("ON" if not fb.luzA else "OFF", duracion))
                    if duracion < TOL_MIN or duracion > TOL_MAX:
                        error = True
                else:
                    primer = True
                etFlanco = tCrono.et
        prevA = fb.luzA

        # Vigilancia continua y enclavada de las demas luces (enmienda 6)
        if paso == 0 and (fb.luzV or fb.luzR):
            otraLuzPaso0 = True
        if paso == PASO_INTERM and (fb.luzV or fb.luzR):
            otraLuzPaso7 = True

        if tPaso.q and not finalizado:
            if paso == 0:
                ok = not fb.luzV and not fb.luzR and not otraLuzPaso0
            elif paso == PASO_INTERM:
                ok = (not fb.luzV and not fb.luzR and not otraLuzPaso7
                      and nOn >= 2 and nOff >= 2 and not error)
            else:
                ok = (fb.luzV == espV and fb.luzA == espA and fb.luzR == espR)
            resultado[paso] = 1 if ok else 2
            if traza:
                print(f"    paso {paso}: V={int(fb.luzV)} A={int(fb.luzA)} "
                      f"R={int(fb.luzR)} -> {resultado[paso]}")
            pulsoReset = True
            if paso < ultimo:
                paso += 1
            else:
                finalizado = True

        if finalizado and veredicto == 0:
            veredicto = 1 if all(r == 1 for r in resultado) else 2
            return veredicto, resultado, nOn, nOff, medidas

    return 0, resultado, nOn, nOff, medidas


def main() -> None:
    casos = [
        ("Correcta", FBCorrecto, 1, None),
        ("Defecto: verde 15 s / rojo 20 s", FBTiemposCambiados, 2, 2),
        ("Defecto: intermitente 1,5 s", FBParpadeoLento, 2, 7),
        ("Defecto: sin modo intermitente", FBSinIntermitente, 2, 7),
        ("Defecto: intermitente con rojo", FBIntermitenteConRojo, 2, 7),
        ("Defecto: idem, fase opuesta", FBIntermitenteConRojoFaseInversa, 2, 7),
        ("Defecto: no reinicia en verde", FBNoReinicia, 2, 8),
    ]
    ciclos = [0.004, 0.010, 0.020]

    dur = sum(p[1] for p in PASOS)
    print("VALIDACION DEL HARNESS PRG_Test_I1 (version corregida, enmienda 8)")
    print(f"Duracion nominal de la secuencia: {dur:.1f} s por respuesta evaluada")
    print("=" * 92)
    print(f"{'implementacion':34}{'ciclo':8}{'ver.':6}{'pasos':30}{'ok'}")
    print("-" * 92)

    todo_ok = True
    fallos = []
    for nombre, cls, esperado, paso_esperado in casos:
        for dt in ciclos:
            v, r, nOn, nOff, med = correr_harness(cls(), dt)
            ok = (v == esperado)
            if paso_esperado is not None:
                ok = ok and r[paso_esperado] == 2
            todo_ok &= ok
            if not ok:
                fallos.append((nombre, cls, dt))
            print(f"{nombre:34}{int(dt*1000):>3} ms  {v:^6}{str(r):30}{'si' if ok else 'NO'}")
        print("-" * 92)

    print()
    print("Los dos defectos que la version anterior dejaba pasar:")
    print("  - intermitente con rojo (ambas fases): lo atrapa la vigilancia continua")
    print("    y enclavada de V y R, no el muestreo del instante final.")
    print("  - no reinicia en verde: solo es observable porque ahora se interrumpe")
    print("    estando en ROJO; interrumpiendo en verde los dos casos se ven iguales.")
    if fallos:
        print("\nCasos que NO discriminan:")
        for nombre, cls, dt in fallos:
            print(f"  {nombre} @ {int(dt*1000)} ms")
            correr_harness(cls(), dt, traza=True)
    print(f"\nDiscrimina correctamente en los 3 ciclos de tarea: {'SI' if todo_ok else 'NO'}")
    raise SystemExit(0 if todo_ok else 1)


if __name__ == "__main__":
    main()
