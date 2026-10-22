"""
Validacion del harness PRG_Test_I2 por simulacion del ciclo de scan.

I2 (FSM de llenado multietapa): reposo -> llenado -> mezcla 60 s -> descarga
-> reposo, con paro seguro en cualquier etapa. Los puntos declarados son el
orden de los estados, la temporizacion de la mezcla y el paro en DOS fases
distintas (llenado y mezcla).

Uso:  python validar_harness_I2.py
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


T_MEZCLA = 60.0


# --------------------------------------------------------------------------
# Implementaciones sinteticas de FB_Llenado
# --------------------------------------------------------------------------
@dataclass
class _Base:
    vLlenado: bool = False
    motorMezcla: bool = False
    vDescarga: bool = False
    estado: int = 0
    t: float = 0.0
    tMezcla: float = T_MEZCLA
    paroEnMezcla: bool = True     # el paro actua tambien durante la mezcla

    def _apaga(self):
        self.vLlenado = self.motorMezcla = self.vDescarga = False

    def __call__(self, nivelAlto, nivelBajo, btnInicio, btnParo, dt):
        if btnParo and (self.paroEnMezcla or self.estado != 2):
            self._apaga()
            self.estado = 0
            self.t = 0.0
            return
        if self.estado == 0:
            self._apaga()
            if btnInicio:
                self.estado = 1
        elif self.estado == 1:
            self.vLlenado, self.motorMezcla, self.vDescarga = True, False, False
            if nivelAlto:
                self.estado, self.t = 2, 0.0
        elif self.estado == 2:
            self.vLlenado, self.motorMezcla, self.vDescarga = False, True, False
            self.t += dt
            if self.t >= self.tMezcla:
                self.estado = 3
        else:
            self.vLlenado, self.motorMezcla, self.vDescarga = False, False, True
            if nivelBajo:
                self.estado = 0


def FBCorrecto():
    return _Base()


def FBMezclaCorta():
    """DEFECTO: la mezcla dura 30 s en vez de 60 s."""
    return _Base(tMezcla=30.0)


def FBParoSoloEnLlenado():
    """DEFECTO: el paro actua en llenado pero NO durante la mezcla."""
    return _Base(paroEnMezcla=False)


@dataclass
class FBParoNoSeguro(_Base):
    """DEFECTO: el paro devuelve el proceso a reposo pero no apaga las salidas."""

    def __call__(self, nivelAlto, nivelBajo, btnInicio, btnParo, dt):
        if btnParo:
            self.estado = 0
            self.t = 0.0
            return                     # deja las salidas como estaban
        _Base.__call__(self, nivelAlto, nivelBajo, btnInicio, btnParo, dt)


@dataclass
class FBSaltaMezcla(_Base):
    """DEFECTO: de llenado pasa directamente a descarga, sin mezclar."""

    def __call__(self, nivelAlto, nivelBajo, btnInicio, btnParo, dt):
        if btnParo:
            self._apaga()
            self.estado = 0
            return
        if self.estado == 0:
            self._apaga()
            if btnInicio:
                self.estado = 1
        elif self.estado == 1:
            self.vLlenado, self.motorMezcla, self.vDescarga = True, False, False
            if nivelAlto:
                self.estado = 3          # se salta la mezcla
        else:
            self.vLlenado, self.motorMezcla, self.vDescarga = False, False, True
            if nivelBajo:
                self.estado = 0


@dataclass
class FBNoRearranca(_Base):
    """DEFECTO: tras un paro el proceso queda bloqueado y no vuelve a arrancar."""
    _bloqueado: bool = False

    def __call__(self, nivelAlto, nivelBajo, btnInicio, btnParo, dt):
        if btnParo:
            self._apaga()
            self.estado = 0
            self._bloqueado = True
            return
        if self._bloqueado:
            self._apaga()
            return
        _Base.__call__(self, nivelAlto, nivelBajo, btnInicio, btnParo, dt)


# --------------------------------------------------------------------------
# Harness PRG_Test_I2 corregido (traduccion fiel del .st, enmienda 10)
# --------------------------------------------------------------------------
# (nivelAlto, nivelBajo, btnInicio, btnParo, tEspera, evL, evM, evD)
# None conserva el valor anterior
PASOS = [
    (False, False, False, False, 0.200, False, False, False),  # 0 reposo
    (None,  None,  True,  None,  0.200, True,  False, False),  # 1 llenado
    (True,  None,  False, None,  1.000, False, True,  False),  # 2 entra en mezcla
    (None,  None,  None,  None,  58.500, None, True,  None),   # 3 ~59,5 s: aun mezcla
    (None,  None,  None,  None,  1.000, False, False, True),   # 4 ~60,5 s: descarga
    (None,  True,  None,  None,  0.200, False, False, False),  # 5 reposo
    (False, False, True,  None,  0.200, True,  False, False),  # 6 nuevo ciclo
    (None,  None,  False, True,  0.200, False, False, False),  # 7 paro en LLENADO
    (None,  None,  True,  False, 0.200, True,  False, False),  # 8 rearranca
    (True,  None,  False, None,  0.500, False, True,  False),  # 9 entra en MEZCLA
    (None,  None,  None,  True,  0.200, False, False, False),  # 10 paro en MEZCLA
    (False, None,  None,  False, 0.200, False, False, False),  # 11 sigue en reposo
]


def correr_harness(fb, dt: float, limite_scans: int = 20_000_000, traza=False):
    ultimo = len(PASOS) - 1
    nivelAlto = nivelBajo = btnInicio = btnParo = False
    evL = evM = evD = False
    tEspera = 0.0
    paso = 0
    tPaso = TON()
    pulsoReset = False
    finalizado = False
    resultado = [0] * (ultimo + 1)
    veredicto = 0

    for _ in range(limite_scans):
        if not finalizado:
            na, nb, bi, bp, t, l, m, d = PASOS[paso]
            if na is not None:
                nivelAlto = na
            if nb is not None:
                nivelBajo = nb
            if bi is not None:
                btnInicio = bi
            if bp is not None:
                btnParo = bp
            tEspera = t
            if l is not None:
                evL = l
            if m is not None:
                evM = m
            if d is not None:
                evD = d

        tPaso(not pulsoReset, tEspera, dt)
        pulsoReset = False
        fb(nivelAlto, nivelBajo, btnInicio, btnParo, dt)

        if tPaso.q and not finalizado:
            ok = (fb.vLlenado == evL and fb.motorMezcla == evM
                  and fb.vDescarga == evD)
            resultado[paso] = 1 if ok else 2
            if traza:
                print(f"    paso {paso}: L={int(fb.vLlenado)} M={int(fb.motorMezcla)} "
                      f"D={int(fb.vDescarga)} (esperado {int(evL)}{int(evM)}{int(evD)}) "
                      f"-> {resultado[paso]}")
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
        ("Defecto: mezcla de 30 s", FBMezclaCorta, 2, 3),
        ("Defecto: se salta la mezcla", FBSaltaMezcla, 2, 2),
        ("Defecto: paro no apaga salidas", FBParoNoSeguro, 2, 7),
        ("Defecto: paro no actua en mezcla", FBParoSoloEnLlenado, 2, 10),
        ("Defecto: no rearranca tras paro", FBNoRearranca, 2, 8),
    ]
    ciclos = [0.004, 0.010, 0.020]

    dur = sum(p[4] for p in PASOS)
    print("VALIDACION DEL HARNESS PRG_Test_I2")
    print(f"Duracion nominal de la secuencia: {dur:.1f} s por respuesta evaluada")
    print("=" * 92)
    print(f"{'implementacion':36}{'ciclo':8}{'ver.':6}{'pasos':32}{'ok'}")
    print("-" * 92)

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
            print(f"{nombre:36}{int(dt*1000):>3} ms  {v:^6}{str(r):32}{'si' if ok else 'NO'}")
        print("-" * 92)

    if fallos:
        print("\nTrazas de los casos que NO discriminan:")
        for nombre, cls, dt in fallos[:3]:
            print(f"  {nombre} @ {int(dt*1000)} ms")
            correr_harness(cls(), dt, traza=True)
    print(f"\nDiscrimina correctamente en los 3 ciclos de tarea: {'SI' if todo_ok else 'NO'}")
    raise SystemExit(0 if todo_ok else 1)


if __name__ == "__main__":
    main()
