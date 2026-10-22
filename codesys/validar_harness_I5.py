"""
Validacion del harness PRG_Test_I5 por simulacion del ciclo de scan.

I5 (banda clasificadora): la banda funciona siempre; cada flanco de
sensorPresencia cuenta una pieza; si sensorAltura esta activo en ese momento la
pieza es alta y debe desviarse con el piston, activo 1 s y comenzando 2 s
despues de la deteccion. Puntos declarados: presencia sostenida no puede contar
mas de una pieza, y el desvio debe estar sincronizado con la pieza correcta.

Uso:  python validar_harness_I5.py
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


T_RETARDO, T_PULSO = 2.0, 1.0


@dataclass
class _Base:
    banda: bool = True
    piston: bool = False
    nAltas: int = 0
    nBajas: int = 0
    _prev: bool = False
    _eventos: list = None
    retardo: float = T_RETARDO
    pulso: float = T_PULSO
    porNivel: bool = False        # cuenta por nivel en vez de por flanco
    desviaTodo: bool = False      # desvia tambien las piezas bajas

    def __post_init__(self):
        self._eventos = []

    def __call__(self, sensorPresencia, sensorAltura, dt):
        self.banda = True
        detecta = sensorPresencia if self.porNivel else (
            sensorPresencia and not self._prev)
        if detecta:
            if sensorAltura:
                self.nAltas += 1
            else:
                self.nBajas += 1
            if sensorAltura or self.desviaTodo:
                self._eventos.append(0.0)
        self._prev = sensorPresencia

        self._eventos = [e + dt for e in self._eventos]
        self.piston = any(self.retardo <= e < self.retardo + self.pulso
                          for e in self._eventos)
        self._eventos = [e for e in self._eventos
                         if e < self.retardo + self.pulso]


def FBCorrecto():
    return _Base()


def FBCuentaPorNivel():
    """DEFECTO: cuenta mientras la presencia este alta, no por flanco."""
    return _Base(porNivel=True)


def FBSinRetardo():
    """DEFECTO: el piston se activa al detectar, sin esperar los 2 s."""
    return _Base(retardo=0.0)


def FBRetardoCorto():
    """DEFECTO: retardo de 1,5 s en vez de 2 s: el piston llega antes que la pieza."""
    return _Base(retardo=1.5)


def FBPulsoLargo():
    """DEFECTO: el pulso del piston dura 2 s en vez de 1 s."""
    return _Base(pulso=2.0)


def FBDesviaTodo():
    """DEFECTO: desvia todas las piezas, tambien las bajas."""
    return _Base(desviaTodo=True)


# --------------------------------------------------------------------------
# Harness PRG_Test_I5 corregido (traduccion fiel del .st, enmienda 11)
# --------------------------------------------------------------------------
# (presencia, altura, tEspera, espBanda, espPiston, espAltas, espBajas)
# None conserva el valor anterior
PASOS = [
    (False, False, 0.200, True, False, 0, 0),
    (True,  False, 0.300, True, False, 0, 1),   # baja sostenida
    (False, None,  0.200, True, False, 0, 1),
    (True,  True,  0.200, True, False, 1, 1),   # pieza alta detectada
    (False, False, 1.500, True, False, 1, 1),   # t=2,4 s: 0,3 s antes del pulso
    (None,  None,  0.800, True, True,  1, 1),   # t=3,2 s: dentro del pulso
    (None,  None,  0.800, True, False, 1, 1),   # t=4,0 s: 0,3 s despues
]


def correr_harness(fb, dt: float, limite_scans: int = 2_000_000, traza=False):
    ultimo = len(PASOS) - 1
    presencia = altura = False
    espBanda = espPiston = False
    espAltas = espBajas = 0
    tEspera = 0.0
    paso = 0
    tPaso = TON()
    pulsoReset = False
    finalizado = False
    resultado = [0] * (ultimo + 1)
    veredicto = 0

    for _ in range(limite_scans):
        if not finalizado:
            p, a, t, eb, ep, ea, ebj = PASOS[paso]
            if p is not None:
                presencia = p
            if a is not None:
                altura = a
            tEspera, espBanda, espPiston, espAltas, espBajas = t, eb, ep, ea, ebj

        tPaso(not pulsoReset, tEspera, dt)
        pulsoReset = False
        fb(presencia, altura, dt)

        if tPaso.q and not finalizado:
            ok = (fb.banda == espBanda and fb.piston == espPiston
                  and fb.nAltas == espAltas and fb.nBajas == espBajas)
            resultado[paso] = 1 if ok else 2
            if traza:
                print(f"    paso {paso}: banda={int(fb.banda)} piston={int(fb.piston)} "
                      f"altas={fb.nAltas} bajas={fb.nBajas} "
                      f"(esperado {int(espBanda)}{int(espPiston)} {espAltas} {espBajas})"
                      f" -> {resultado[paso]}")
            pulsoReset = True
            if paso < ultimo:
                paso += 1
            else:
                finalizado = True

        if finalizado and veredicto == 0:
            veredicto = 1 if all(x == 1 for x in resultado) else 2
            return veredicto, resultado

    return 0, resultado


def main() -> None:
    casos = [
        ("Correcta", FBCorrecto, 1, None),
        ("Defecto: cuenta por nivel", FBCuentaPorNivel, 2, 1),
        ("Defecto: piston sin retardo", FBSinRetardo, 2, 3),
        ("Defecto: retardo de 1,5 s", FBRetardoCorto, 2, 4),
        ("Defecto: pulso de 2 s", FBPulsoLargo, 2, 6),
        ("Defecto: desvia tambien las bajas", FBDesviaTodo, 2, 4),
    ]
    ciclos = [0.004, 0.010, 0.020]

    dur = sum(p[2] for p in PASOS)
    print("VALIDACION DEL HARNESS PRG_Test_I5")
    print(f"Duracion nominal de la secuencia: {dur:.1f} s por respuesta evaluada")
    print("=" * 88)
    print(f"{'implementacion':36}{'ciclo':8}{'ver.':6}{'pasos':24}{'ok'}")
    print("-" * 88)

    todo_ok = True
    fallos = []
    for nombre, cls, esperado, paso_esperado in casos:
        for dt in ciclos:
            v, r = correr_harness(cls(), dt)
            ok = (v == esperado)
            if paso_esperado is not None:
                ok = ok and r[paso_esperado] == 2
            todo_ok &= ok
            if not ok:
                fallos.append((nombre, cls, dt))
            print(f"{nombre:36}{int(dt*1000):>3} ms  {v:^6}{str(r):24}{'si' if ok else 'NO'}")
        print("-" * 88)

    if fallos:
        print("\nTrazas de los casos que NO discriminan:")
        for nombre, cls, dt in fallos[:2]:
            print(f"  {nombre} @ {int(dt*1000)} ms")
            correr_harness(cls(), dt, traza=True)
    print(f"\nDiscrimina correctamente en los 3 ciclos de tarea: {'SI' if todo_ok else 'NO'}")
    raise SystemExit(0 if todo_ok else 1)


if __name__ == "__main__":
    main()
