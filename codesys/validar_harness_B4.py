"""
Validacion del harness PRG_Test_B4 por simulacion del ciclo de scan.

B4 (inversion de giro con enclavamiento cruzado). La propiedad critica es la
de la enmienda 4: "nunca fwd AND rev" debe evaluarse en CADA scan y quedar
ENCLAVADA, porque una violacion transitoria entre dos evaluaciones pasaria
inadvertida. El harness ya lo hace; lo que se comprueba aqui es si la
SECUENCIA llega a provocar todas las situaciones en que la violacion puede
producirse.

Uso:  python validar_harness_B4.py
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
# Implementaciones sinteticas de FB_Giro
# --------------------------------------------------------------------------
@dataclass
class FBCorrecto:
    """Enclavamiento con interlock cruzado evaluado sobre el valor ACTUAL de
    la otra salida. Para invertir hay que pasar por el paro."""
    fwd: bool = False
    rev: bool = False

    def __call__(self, btnFwd, btnRev, btnParo, dt):
        if btnParo:
            self.fwd = False
            self.rev = False
        else:
            if btnFwd and not self.rev:
                self.fwd = True
            if btnRev and not self.fwd:
                self.rev = True


@dataclass
class FBSinEnclavamiento:
    """DEFECTO: las salidas siguen a los pulsadores; no hay seal-in."""
    fwd: bool = False
    rev: bool = False

    def __call__(self, btnFwd, btnRev, btnParo, dt):
        self.fwd = btnFwd and not btnParo and not btnRev
        self.rev = btnRev and not btnParo and not btnFwd


@dataclass
class FBInversionDirecta:
    """DEFECTO: permite invertir sin pasar por el paro."""
    fwd: bool = False
    rev: bool = False

    def __call__(self, btnFwd, btnRev, btnParo, dt):
        if btnParo:
            self.fwd = False
            self.rev = False
        elif btnFwd:
            self.fwd = True
            self.rev = False
        elif btnRev:
            self.rev = True
            self.fwd = False


@dataclass
class FBSinInterlock:
    """DEFECTO: sin enclavamiento cruzado; ambas salidas pueden coexistir."""
    fwd: bool = False
    rev: bool = False

    def __call__(self, btnFwd, btnRev, btnParo, dt):
        if btnParo:
            self.fwd = False
            self.rev = False
        else:
            if btnFwd:
                self.fwd = True
            if btnRev:
                self.rev = True


@dataclass
class FBCarreraDeInterlock:
    """DEFECTO SUTIL: el interlock se evalua contra el valor de la otra salida
    en el scan ANTERIOR. Con el motor ya girando se comporta bien, pero si se
    pulsan las dos ordenes ESTANDO EN REPOSO ambas salidas se activan a la vez
    durante un scan. Es el clasico fallo de carrera que la enmienda 4 describe:
    una violacion transitoria."""
    fwd: bool = False
    rev: bool = False
    _fwdPrev: bool = False
    _revPrev: bool = False

    def __call__(self, btnFwd, btnRev, btnParo, dt):
        if btnParo:
            self.fwd = False
            self.rev = False
        else:
            if btnFwd and not self._revPrev:
                self.fwd = True
            if btnRev and not self._fwdPrev:
                self.rev = True
        self._fwdPrev, self._revPrev = self.fwd, self.rev


# --------------------------------------------------------------------------
# Harness PRG_Test_B4 corregido (traduccion fiel del .st, enmienda 9)
# --------------------------------------------------------------------------
T_ASENT = 0.150
# (btnFwd, btnRev, btnParo, espFwd, espRev) -- None conserva el valor anterior
PASOS = [
    (False, False, False, False, False),   # 0 reposo
    (True,  None,  None,  True,  False),   # 1 marcha adelante
    (False, None,  None,  True,  False),   # 2 enclavamiento FWD
    (None,  True,  None,  True,  False),   # 3 Rev sin paro: prohibido
    (None,  False, True,  False, False),   # 4 paro
    (None,  True,  False, False, True),    # 5 marcha reversa
    (True,  None,  None,  False, True),    # 6 ambas ordenes con rev activo
    (False, False, True,  False, False),   # 7 paro
    (True,  True,  False, None,  None),    # 8 ambas ordenes DESDE EL REPOSO (enmienda 9)
    (False, False, True,  False, False),   # 9 paro final
]


def correr_harness(fb, dt: float, pasos=None, limite_scans: int = 1_000_000):
    pasos = pasos or PASOS
    ultimo = len(pasos) - 1
    btnFwd = btnRev = btnParo = False
    espFwd = espRev = False
    paso = 0
    tPaso = TON()
    pulsoReset = False
    finalizado = False
    violacion = False
    resultado = [0] * (ultimo + 1)
    veredicto = 0

    for _ in range(limite_scans):
        tPaso(not pulsoReset, T_ASENT, dt)
        pulsoReset = False

        if not finalizado:
            f, r, p, ef, er = pasos[paso]
            if f is not None:
                btnFwd = f
            if r is not None:
                btnRev = r
            if p is not None:
                btnParo = p
            espFwd, espRev = ef, er

        fb(btnFwd, btnRev, btnParo, dt)

        # Enmienda 4: seguridad continua y enclavada
        if fb.fwd and fb.rev:
            violacion = True

        if tPaso.q and not finalizado:
            if espFwd is None:            # paso cuyo unico criterio es la seguridad
                ok = not (fb.fwd and fb.rev)
            else:
                ok = (fb.fwd == espFwd) and (fb.rev == espRev)
            resultado[paso] = 1 if ok else 2
            pulsoReset = True
            if paso < ultimo:
                paso += 1
            else:
                finalizado = True

        if finalizado and veredicto == 0:
            veredicto = 1 if (all(x == 1 for x in resultado) and not violacion) else 2
            return veredicto, resultado, violacion

    return 0, resultado, violacion


def main() -> None:
    casos = [
        ("Correcta", FBCorrecto, 1, None, False),
        ("Defecto: sin enclavamiento", FBSinEnclavamiento, 2, 2, False),
        ("Defecto: inversion sin pasar por paro", FBInversionDirecta, 2, 3, False),
        ("Defecto: sin interlock cruzado", FBSinInterlock, 2, None, True),
        ("Defecto: carrera de interlock", FBCarreraDeInterlock, 2, None, True),
    ]
    ciclos = [0.004, 0.010, 0.020]

    print("VALIDACION DEL HARNESS PRG_Test_B4")
    print("=" * 90)
    print(f"{'implementacion':40}{'ciclo':8}{'ver.':6}{'pasos':26}{'violacion':11}{'ok'}")
    print("-" * 90)

    todo_ok = True
    for nombre, cls, esperado, paso_esperado, viol_esperada in casos:
        for dt in ciclos:
            v, r, viol = correr_harness(cls(), dt)
            ok = (v == esperado) and (viol == viol_esperada)
            if paso_esperado is not None:
                ok = ok and r[paso_esperado] == 2
            todo_ok &= ok
            print(f"{nombre:40}{int(dt*1000):>3} ms  {v:^6}{str(r):26}"
                  f"{('SI' if viol else 'no'):11}{'si' if ok else 'NO'}")
        print("-" * 90)

    print(f"\nDiscrimina correctamente en los 3 ciclos de tarea: {'SI' if todo_ok else 'NO'}")
    raise SystemExit(0 if todo_ok else 1)


if __name__ == "__main__":
    main()
