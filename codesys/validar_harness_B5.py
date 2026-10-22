"""
Validacion del harness PRG_Test_B5 por simulacion del ciclo de scan.

B5 (ventilador con retardo a la desconexion, TOF de 30 s). El punto delicado
declarado en ENMIENDAS_HARNESSES.md es "reactivar el quemador durante el
post-enfriamiento": la reactivacion debe REARMAR el temporizador, de modo que
el siguiente post-enfriamiento vuelva a durar 30 s completos.

Uso:  python validar_harness_B5.py
"""

from dataclasses import dataclass


@dataclass
class TOF:
    et: float = 0.0
    q: bool = False

    def __call__(self, IN: bool, PT: float, dt: float) -> bool:
        if IN:
            self.et = 0.0
            self.q = True
        elif self.q:
            self.et = min(self.et + dt, PT)
            if self.et >= PT:
                self.q = False
        return self.q


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


PT_ESPECIFICADO = 30.0


# --------------------------------------------------------------------------
# Implementaciones sinteticas de FB_Ventilador
# --------------------------------------------------------------------------
@dataclass
class FBCorrecto:
    """TOF de 30 s: el ventilador acompana al quemador y sigue 30 s tras el paro."""
    ventilador: bool = False
    _tof: TOF = None

    def __post_init__(self):
        self._tof = TOF()

    def __call__(self, quemadorOn, dt):
        self.ventilador = self._tof(quemadorOn, PT_ESPECIFICADO, dt)


@dataclass
class FBSinRetardo:
    """DEFECTO: el ventilador sigue al quemador sin post-enfriamiento."""
    ventilador: bool = False

    def __call__(self, quemadorOn, dt):
        self.ventilador = quemadorOn


@dataclass
class FBTiempoCorto:
    """DEFECTO: post-enfriamiento de 10 s en lugar de 30 s."""
    ventilador: bool = False
    _tof: TOF = None

    def __post_init__(self):
        self._tof = TOF()

    def __call__(self, quemadorOn, dt):
        self.ventilador = self._tof(quemadorOn, 10.0, dt)


@dataclass
class FBTiempoLargo:
    """DEFECTO: post-enfriamiento de 60 s; nunca llega a apagarse a tiempo."""
    ventilador: bool = False
    _tof: TOF = None

    def __post_init__(self):
        self._tof = TOF()

    def __call__(self, quemadorOn, dt):
        self.ventilador = self._tof(quemadorOn, 60.0, dt)


@dataclass
class FBTonEnVezDeTof:
    """DEFECTO: retardo a la CONEXION; el ventilador arranca 30 s tarde."""
    ventilador: bool = False
    _ton: TON = None

    def __post_init__(self):
        self._ton = TON()

    def __call__(self, quemadorOn, dt):
        self.ventilador = self._ton(quemadorOn, PT_ESPECIFICADO, dt)


@dataclass
class FBSinRearme:
    """DEFECTO: el temporizador no se rearma al reencender el quemador;
    acumula el tiempo apagado de todos los ciclos."""
    ventilador: bool = False
    _acum: float = 0.0

    def __call__(self, quemadorOn, dt):
        if quemadorOn:
            self.ventilador = True          # no reinicia el acumulador
        else:
            self._acum += dt
            if self._acum >= PT_ESPECIFICADO:
                self.ventilador = False


@dataclass
class FBRearmeCorto:
    """DEFECTO SUTIL: el temporizador SI se rearma, pero el segundo
    post-enfriamiento dura solo 15 s en vez de 30 s. El primer ciclo es
    correcto, de modo que solo un segundo ciclo COMPLETO puede detectarlo."""
    ventilador: bool = False
    _acum: float = 0.0
    _ciclos: int = 0
    _prev: bool = False

    def __call__(self, quemadorOn, dt):
        if quemadorOn:
            self.ventilador = True
            self._acum = 0.0
        else:
            if self._prev:
                self._ciclos += 1           # flanco de bajada del quemador
            self._acum += dt
            pt = PT_ESPECIFICADO if self._ciclos <= 1 else 15.0
            if self._acum >= pt:
                self.ventilador = False
        self._prev = quemadorOn


# --------------------------------------------------------------------------
# Harness PRG_Test_B5 corregido (traduccion fiel del .st, enmienda 7)
# --------------------------------------------------------------------------
# (quemadorOn, tEspera, esperado)
PASOS = [
    (False, 0.200, False),
    (True,  0.200, True),
    (False, 29.000, True),     # primer post-enfriamiento: antes de los 30 s
    (False, 1.200, False),     # 30,2 s acumulados: ya apagado
    (True,  0.200, True),      # se reenciende
    (False, 10.000, True),     # post-enfriamiento en curso
    (True,  0.200, True),      # reactivacion EN PLENO post-enfriamiento
    (False, 29.000, True),     # 2.o post-enfriamiento COMPLETO: sigue encendido
    (False, 1.200, False),     # y a los 30,2 s se apaga  (enmienda 7)
]


def correr_harness(fb, dt: float, pasos=None, limite_scans: int = 5_000_000):
    pasos = pasos or PASOS
    ultimo = len(pasos) - 1
    paso = 0
    quemadorOn = False
    tEspera = 0.0
    esperado = False
    tPaso = TON()
    pulsoReset = False
    finalizado = False
    resultado = [0] * (ultimo + 1)
    veredicto = 0

    for _ in range(limite_scans):
        if not finalizado:
            quemadorOn, tEspera, esperado = pasos[paso]

        tPaso(not pulsoReset, tEspera, dt)
        pulsoReset = False
        fb(quemadorOn, dt)

        if tPaso.q and not finalizado:
            resultado[paso] = 1 if fb.ventilador == esperado else 2
            pulsoReset = True
            if paso < ultimo:
                paso += 1
            else:
                finalizado = True

        if finalizado and veredicto == 0:
            veredicto = 1 if all(r == 1 for r in resultado) else 2
            return veredicto, resultado

    return 0, resultado


def main() -> None:
    casos = [
        ("Correcta", FBCorrecto, 1, None),
        ("Defecto: sin post-enfriamiento", FBSinRetardo, 2, 2),
        ("Defecto: 10 s en vez de 30 s", FBTiempoCorto, 2, 2),
        ("Defecto: 60 s en vez de 30 s", FBTiempoLargo, 2, 3),
        ("Defecto: TON en vez de TOF", FBTonEnVezDeTof, 2, 1),
        ("Defecto: no rearma el temporizador", FBSinRearme, 2, 5),
        ("Defecto: rearma pero solo a 15 s", FBRearmeCorto, 2, 7),
    ]
    ciclos = [0.004, 0.010, 0.020]

    dur = sum(p[1] for p in PASOS)
    print("VALIDACION DEL HARNESS PRG_Test_B5")
    print(f"Duracion nominal de la secuencia: {dur:.1f} s por respuesta evaluada")
    print("=" * 86)
    print(f"{'implementacion':38}{'ciclo':8}{'ver.':6}{'pasos':24}{'ok'}")
    print("-" * 86)

    todo_ok = True
    for nombre, cls, esperado, paso_esperado in casos:
        for dt in ciclos:
            v, r = correr_harness(cls(), dt)
            ok = (v == esperado)
            if paso_esperado is not None:
                ok = ok and r[paso_esperado] == 2
            todo_ok &= ok
            print(f"{nombre:38}{int(dt*1000):>3} ms  {v:^6}{str(r):24}{'si' if ok else 'NO'}")
        print("-" * 86)

    print(f"\nDiscrimina correctamente en los 3 ciclos de tarea: {'SI' if todo_ok else 'NO'}")
    raise SystemExit(0 if todo_ok else 1)


if __name__ == "__main__":
    main()
