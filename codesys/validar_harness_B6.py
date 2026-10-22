"""
Validacion del harness PRG_Test_B6 por simulacion del ciclo de scan.

B6 (baliza intermitente) es el harness que motivo la enmienda 1: muestrear la
lampara cada 1,1 s NO discrimina, porque una implementacion con 1,5 s / 1,5 s
produce el mismo patron de alternancia que la correcta. El harness debe medir
la DURACION de cada intervalo ON y OFF completo, descartando el primero por
parcial, y exigir 1 s +/- 150 ms.

Se prueba contra dos lecturas igualmente defendibles del enunciado (el
oscilador que arranca encendido y el que arranca apagado) y contra cinco
implementaciones defectuosas, incluida la de 1,5 s que la enmienda 1 senala
como el falso negativo del enfoque anterior.

Uso:  python validar_harness_B6.py
"""

from dataclasses import dataclass, field


@dataclass
class TON:
    et: float = 0.0
    q: bool = False

    def __call__(self, IN: bool, PT: float, dt: float) -> bool:
        if IN:
            self.et = min(self.et + dt, PT)   # IEC: ET se satura en PT
            self.q = self.et >= PT
        else:
            self.et = 0.0
            self.q = False
        return self.q


# --------------------------------------------------------------------------
# Implementaciones sinteticas del bloque bajo prueba (FB_Baliza)
# --------------------------------------------------------------------------
@dataclass
class _Oscilador:
    """Base: oscilador de dos TON con semiperiodos configurables."""
    t_on: float = 1.0
    t_off: float = 1.0
    arranca_encendida: bool = False
    lampara: bool = False
    _t1: TON = field(default_factory=TON)
    _t2: TON = field(default_factory=TON)
    _prevAlarma: bool = False

    def __call__(self, alarma, dt):
        if not alarma:
            self.lampara = False
            self._t1(False, self.t_off, dt)
            self._t2(False, self.t_on, dt)
            self._prevAlarma = False
            return
        if self.arranca_encendida and not self._prevAlarma:
            self.lampara = True                 # enciende en el flanco de alarma
        self._prevAlarma = True
        if self.lampara:
            self._t1(False, self.t_off, dt)
            if self._t2(True, self.t_on, dt):
                self.lampara = False
        else:
            self._t2(False, self.t_on, dt)
            if self._t1(True, self.t_off, dt):
                self.lampara = True


def FBCorrectoInicioOFF():
    return _Oscilador(1.0, 1.0, arranca_encendida=False)


def FBCorrectoInicioON():
    return _Oscilador(1.0, 1.0, arranca_encendida=True)


def FBPeriodo1500():
    """DEFECTO: 1,5 s / 1,5 s. Es el falso negativo que motivo la enmienda 1:
    muestreado cada 1,1 s alterna igual que la correcta."""
    return _Oscilador(1.5, 1.5, arranca_encendida=True)


def FBPeriodo500():
    """DEFECTO: 0,5 s / 0,5 s."""
    return _Oscilador(0.5, 0.5, arranca_encendida=True)


def FBAsimetrico():
    """DEFECTO: 1 s encendida pero 2 s apagada."""
    return _Oscilador(1.0, 2.0, arranca_encendida=True)


@dataclass
class FBSiempreEncendida:
    """DEFECTO: la lampara sigue a la alarma sin parpadear."""
    lampara: bool = False

    def __call__(self, alarma, dt):
        self.lampara = alarma


@dataclass
class FBNoApagaSinAlarma:
    """DEFECTO: sigue parpadeando aunque la alarma se retire."""
    lampara: bool = False
    _osc: _Oscilador = None
    _visto: bool = False

    def __post_init__(self):
        self._osc = _Oscilador(1.0, 1.0, arranca_encendida=True)

    def __call__(self, alarma, dt):
        if alarma:
            self._visto = True
        self._osc(True if self._visto else alarma, dt)
        self.lampara = self._osc.lampara


# --------------------------------------------------------------------------
# Harness PRG_Test_B6 corregido (traduccion fiel del .st, enmienda 6)
# --------------------------------------------------------------------------
ULTIMO_PASO = 2
TOL_MIN, TOL_MAX = 0.850, 1.150        # 1 s +/- 150 ms (enmienda 1)
T_REPOSO = 2.500                       # > 2 periodos nominales (enmienda 6)
T_CRONO = 100.0
PASOS = [(False, 0.200), (True, 7.000), (False, T_REPOSO)]


def correr_harness(fb, dt: float, limite_scans: int = 2_000_000, traza=False):
    alarma = False
    paso = 0
    tEspera = 0.0
    tPaso, tCrono = TON(), TON()
    pulsoReset = False
    finalizado = False
    prev = primer = error = False
    etFlanco = 0.0
    duracion = 0.0
    nOn = nOff = 0
    lamparaEnPaso0 = lamparaEnPaso2 = False
    medidas = []
    resultado = [0] * (ULTIMO_PASO + 1)
    veredicto = 0

    for _ in range(limite_scans):
        if not finalizado:
            alarma, tEspera = PASOS[paso]

        tPaso(not pulsoReset, tEspera, dt)
        tCrono(True, T_CRONO, dt)
        pulsoReset = False
        fb(alarma, dt)

        # Enmienda 1 + 5: intervalo completo por diferencia de dos lecturas
        # del cronometro libre. El primero se descarta por parcial.
        if paso == 1:
            if (fb.lampara and not prev) or ((not fb.lampara) and prev):
                if primer:
                    duracion = tCrono.et - etFlanco
                    if not fb.lampara:
                        nOn += 1
                    else:
                        nOff += 1
                    medidas.append(("ON" if not fb.lampara else "OFF", duracion))
                    if duracion < TOL_MIN or duracion > TOL_MAX:
                        error = True
                else:
                    primer = True
                etFlanco = tCrono.et

        # Enmienda 6: vigilancia de reposo continua y enclavada
        if paso == 0 and fb.lampara:
            lamparaEnPaso0 = True
        if paso == 2 and fb.lampara:
            lamparaEnPaso2 = True

        prev = fb.lampara

        if tPaso.q and not finalizado:
            ok = ((paso == 0 and not fb.lampara and not lamparaEnPaso0) or
                  (paso == 1 and nOn >= 2 and nOff >= 2 and not error) or
                  (paso == 2 and not fb.lampara and not lamparaEnPaso2))
            resultado[paso] = 1 if ok else 2
            pulsoReset = True
            if paso < ULTIMO_PASO:
                paso += 1
            else:
                finalizado = True

        if finalizado and veredicto == 0:
            veredicto = 1 if all(r == 1 for r in resultado) else 2
            if traza:
                print(f"    intervalos medidos: "
                      f"{[(k, round(v, 3)) for k, v in medidas]}")
            return veredicto, resultado, nOn, nOff, medidas

    return 0, resultado, nOn, nOff, medidas


def main() -> None:
    casos = [
        ("Correcta (arranca apagada)", FBCorrectoInicioOFF, 1, None),
        ("Correcta (arranca encendida)", FBCorrectoInicioON, 1, None),
        ("Defecto: 1,5 s / 1,5 s", FBPeriodo1500, 2, 1),
        ("Defecto: 0,5 s / 0,5 s", FBPeriodo500, 2, 1),
        ("Defecto: asimetrico 1 s / 2 s", FBAsimetrico, 2, 1),
        ("Defecto: no parpadea", FBSiempreEncendida, 2, 1),
        ("Defecto: no apaga sin alarma", FBNoApagaSinAlarma, 2, 2),
    ]
    ciclos = [0.004, 0.010, 0.020]

    dur = sum(p[1] for p in PASOS)
    print("VALIDACION DEL HARNESS PRG_Test_B6 (version corregida, enmienda 6)")
    print(f"Duracion nominal de la secuencia: {dur:.1f} s por respuesta evaluada")
    print("=" * 88)
    print(f"{'implementacion':32}{'ciclo':8}{'ver.':6}{'pasos':14}{'nOn':5}{'nOff':6}{'ok'}")
    print("-" * 88)

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
                fallos.append((nombre, dt))
            print(f"{nombre:32}{int(dt*1000):>3} ms  {v:^6}{str(r):14}"
                  f"{nOn:^5}{nOff:^6}{'si' if ok else 'NO'}")
        print("-" * 88)

    print()
    print("Las dos comprobaciones que exigen medir en vez de muestrear:")
    print("  - 1,5 s / 1,5 s: alternaria igual que la correcta si se muestreara")
    print("    cada 1,1 s (enmienda 1). Solo lo atrapa la medida del intervalo.")
    print("  - no apaga sin alarma: la salida sigue siendo periodica, asi que un")
    print("    unico muestreo la sorprende apagada segun la fase (enmienda 6).")
    print("    Solo lo atrapa la vigilancia continua y enclavada del paso 2.")
    print()
    print("Traza de intervalos de la implementacion correcta a 20 ms:")
    correr_harness(FBCorrectoInicioON(), 0.020, traza=True)
    if fallos:
        print("\nCasos que NO discriminan:")
        for nombre, dt in fallos:
            print(f"  {nombre} @ {int(dt*1000)} ms")
    print(f"\nDiscrimina correctamente en los 3 ciclos de tarea: {'SI' if todo_ok else 'NO'}")
    raise SystemExit(0 if todo_ok else 1)


if __name__ == "__main__":
    main()
