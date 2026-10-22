"""
Validacion del harness PRG_Test_I4 por simulacion del ciclo de scan.

I4 (arranque estrella-triangulo) es, junto con B6, el harness que mas depende
de las enmiendas: la enmienda 2 exige DOS verificaciones independientes -- la
bandera de interlock enclavada y la MEDIDA del tiempo muerto -- porque una
transicion con 0 ms de tiempo muerto no produce ningun scan con kY AND kD y
por tanto la bandera sola no la detecta.

Se ejecuta el harness contra una implementacion correcta y contra las cuatro
implementaciones defectuosas tipicas. Un harness valido debe:
  - dar veredicto = 1 ante la implementacion correcta
  - dar veredicto = 2 ante cada defectuosa, senalando el paso

Uso:  python validar_harness_I4.py
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


T_ESTRELLA = 8.0
T_MUERTO = 0.100


@dataclass
class FBCorrecto:
    """kM+kY, a los 8 s cae kY, 100 ms de tiempo muerto, entra kD.
    El paro devuelve todo a reposo y rearma los temporizadores."""
    kM: bool = False
    kY: bool = False
    kD: bool = False
    estado: int = 0
    _t1: TON = field(default_factory=TON)
    _t2: TON = field(default_factory=TON)

    def __call__(self, btnMarcha, btnParo, dt):
        if btnParo:
            self.kM = self.kY = self.kD = False
            self.estado = 0
            self._t1(False, T_ESTRELLA, dt)
            self._t2(False, T_MUERTO, dt)
            return
        if self.estado == 0:
            self._t1(False, T_ESTRELLA, dt)
            self._t2(False, T_MUERTO, dt)
            if btnMarcha:
                self.kM = True
                self.kY = True
                self.estado = 1
        elif self.estado == 1:
            if self._t1(True, T_ESTRELLA, dt):
                self.kY = False
                self.estado = 2
        elif self.estado == 2:
            if self._t2(True, T_MUERTO, dt):
                self.kD = True
                self.estado = 3


@dataclass
class FBSolapamiento:
    """DEFECTO: kD entra antes de que kY caiga -> ambos activos a la vez."""
    kM: bool = False
    kY: bool = False
    kD: bool = False
    estado: int = 0
    _t1: TON = field(default_factory=TON)
    _t2: TON = field(default_factory=TON)

    def __call__(self, btnMarcha, btnParo, dt):
        if btnParo:
            self.kM = self.kY = self.kD = False
            self.estado = 0
            self._t1(False, T_ESTRELLA, dt); self._t2(False, T_MUERTO, dt)
            return
        if self.estado == 0:
            self._t1(False, T_ESTRELLA, dt); self._t2(False, T_MUERTO, dt)
            if btnMarcha:
                self.kM = True; self.kY = True; self.estado = 1
        elif self.estado == 1:
            if self._t1(True, T_ESTRELLA, dt):
                self.kD = True              # entra kD con kY aun activo
                self.estado = 2
        elif self.estado == 2:
            if self._t2(True, 0.040, dt):   # 40 ms de solapamiento
                self.kY = False
                self.estado = 3


@dataclass
class FBSinTiempoMuerto:
    """DEFECTO: kY cae y kD sube en el MISMO scan. No hay solapamiento, asi
    que la bandera de interlock no lo ve; solo la medida lo detecta."""
    kM: bool = False
    kY: bool = False
    kD: bool = False
    estado: int = 0
    _t1: TON = field(default_factory=TON)

    def __call__(self, btnMarcha, btnParo, dt):
        if btnParo:
            self.kM = self.kY = self.kD = False
            self.estado = 0
            self._t1(False, T_ESTRELLA, dt)
            return
        if self.estado == 0:
            self._t1(False, T_ESTRELLA, dt)
            if btnMarcha:
                self.kM = True; self.kY = True; self.estado = 1
        elif self.estado == 1:
            if self._t1(True, T_ESTRELLA, dt):
                self.kY = False
                self.kD = True              # mismo scan: tiempo muerto = 0
                self.estado = 2


@dataclass
class FBTemporizadorSinRearme:
    """DEFECTO: t1 no se reinicia en el paro; tras rearrancar, la transicion
    a triangulo es inmediata en vez de esperar los 8 s."""
    kM: bool = False
    kY: bool = False
    kD: bool = False
    estado: int = 0
    _t1: TON = field(default_factory=TON)
    _t2: TON = field(default_factory=TON)

    def __call__(self, btnMarcha, btnParo, dt):
        if btnParo:
            self.kM = self.kY = self.kD = False
            self.estado = 0
            return                          # no rearma los temporizadores
        if self.estado == 0:
            if btnMarcha:
                self.kM = True; self.kY = True; self.estado = 1
        elif self.estado == 1:
            if self._t1(True, T_ESTRELLA, dt):
                self.kY = False; self.estado = 2
        elif self.estado == 2:
            if self._t2(True, T_MUERTO, dt):
                self.kD = True; self.estado = 3


@dataclass
class FBParoNoApagaKM:
    """DEFECTO: el paro apaga kY y kD pero deja el contactor principal."""
    kM: bool = False
    kY: bool = False
    kD: bool = False
    estado: int = 0
    _t1: TON = field(default_factory=TON)
    _t2: TON = field(default_factory=TON)

    def __call__(self, btnMarcha, btnParo, dt):
        if btnParo:
            self.kY = self.kD = False       # kM se queda activo
            self.estado = 0
            self._t1(False, T_ESTRELLA, dt); self._t2(False, T_MUERTO, dt)
            return
        if self.estado == 0:
            self._t1(False, T_ESTRELLA, dt); self._t2(False, T_MUERTO, dt)
            if btnMarcha:
                self.kM = True; self.kY = True; self.estado = 1
        elif self.estado == 1:
            if self._t1(True, T_ESTRELLA, dt):
                self.kY = False; self.estado = 2
        elif self.estado == 2:
            if self._t2(True, T_MUERTO, dt):
                self.kD = True; self.estado = 3


# --------------------------------------------------------------------------
# Harness PRG_Test_I4 corregido (traduccion fiel del .st, enmienda 5)
# --------------------------------------------------------------------------
ULTIMO_PASO = 5
T_MUERTO_MIN = 0.090      # 100 ms menos un ciclo de MainTask (cuantizacion)
T_CRONO = 100.0
# (btnMarcha, btnParo, tEspera) -- None conserva el valor anterior
PASOS = [
    (False, False, 0.200),
    (True,  None,  7.800),
    (None,  None,  0.500),
    (None,  None,  0.300),
    (False, True,  0.200),
    (True,  False, 0.200),
]


def correr_harness(fb, dt: float, limite_scans: int = 2_000_000, traza=False):
    btnMarcha = btnParo = False
    paso = 0
    tEspera = 0.0
    tPaso, tCrono = TON(), TON()
    pulsoReset = False
    finalizado = False
    prevY = prevD = midiendo = interlock = muertoOK = False
    etCaidaY = 0.0
    duracionMuerto = 0.0
    resultado = [0] * (ULTIMO_PASO + 1)
    veredicto = 0

    for _ in range(limite_scans):
        # 1. Definicion del paso
        if not finalizado:
            m, p, t = PASOS[paso]
            if m is not None:
                btnMarcha = m
            if p is not None:
                btnParo = p
            tEspera = t

        # 2. Temporizadores del banco
        tPaso(not pulsoReset, tEspera, dt)
        tCrono(True, T_CRONO, dt)
        pulsoReset = False

        # 3. Bloque bajo prueba
        fb(btnMarcha, btnParo, dt)

        # 4. Verificacion 1: seguridad continua y enclavada
        if fb.kY and fb.kD:
            interlock = True

        # 5. Verificacion 2: tiempo muerto por DIFERENCIA de dos lecturas del
        #    cronometro libre. Si kY cae y kD sube en el mismo scan, ambas
        #    ramas corren en ese ciclo y la diferencia vale 0.
        if prevY and not fb.kY:
            etCaidaY = tCrono.et
            midiendo = True
        if midiendo and fb.kD and not prevD:
            duracionMuerto = tCrono.et - etCaidaY
            if duracionMuerto >= T_MUERTO_MIN:
                muertoOK = True
            midiendo = False
        prevY, prevD = fb.kY, fb.kD

        # 6. Evaluacion del paso
        if tPaso.q and not finalizado:
            ok = ((paso == 0 and not fb.kM and not fb.kY and not fb.kD) or
                  (paso == 1 and fb.kM and fb.kY and not fb.kD) or
                  (paso == 2 and fb.kM and not fb.kY and fb.kD) or
                  (paso == 3 and fb.kM and not fb.kY and fb.kD and muertoOK) or
                  (paso == 4 and not fb.kM and not fb.kY and not fb.kD) or
                  (paso == 5 and fb.kM and fb.kY and not fb.kD))
            resultado[paso] = 1 if ok else 2
            if traza:
                print(f"    paso {paso}: kM={int(fb.kM)} kY={int(fb.kY)} "
                      f"kD={int(fb.kD)} muertoOK={int(muertoOK)} -> {resultado[paso]}")
            pulsoReset = True
            if paso < ULTIMO_PASO:
                paso += 1
            else:
                finalizado = True

        # 7. Veredicto: todos los pasos Y sin violacion de interlock
        if finalizado and veredicto == 0:
            veredicto = 1 if (all(r == 1 for r in resultado) and not interlock) else 2
            return veredicto, resultado, interlock, duracionMuerto

    return 0, resultado, interlock, duracionMuerto


def main() -> None:
    # (nombre, clase, veredicto esperado, paso que debe fallar, interlock esperado)
    casos = [
        ("Correcta", FBCorrecto, 1, None, False),
        ("Defecto: solapamiento kY/kD", FBSolapamiento, 2, 3, True),
        ("Defecto: tiempo muerto de 0 ms", FBSinTiempoMuerto, 2, 3, False),
        ("Defecto: temporizador sin rearme", FBTemporizadorSinRearme, 2, 5, False),
        ("Defecto: el paro no apaga kM", FBParoNoApagaKM, 2, 4, False),
    ]
    ciclos = [0.004, 0.010, 0.020]

    print("VALIDACION DEL HARNESS PRG_Test_I4 (version corregida, enmienda 5)")
    print("=" * 92)
    print(f"{'implementacion':36}{'ciclo':8}{'ver.':6}{'pasos':22}{'interlock':11}{'t_muerto':10}{'ok'}")
    print("-" * 92)

    todo_ok = True
    for nombre, cls, esperado, paso_esperado, il_esperado in casos:
        for dt in ciclos:
            v, r, il, tm = correr_harness(cls(), dt)
            ok = (v == esperado) and (il == il_esperado)
            if paso_esperado is not None:
                ok = ok and r[paso_esperado] == 2
            todo_ok &= ok
            print(f"{nombre:36}{int(dt*1000):>3} ms  {v:^6}{str(r):22}"
                  f"{('SI' if il else 'no'):11}{tm*1000:7.0f} ms {'si' if ok else 'NO'}")
        print("-" * 92)

    print()
    print("Las dos verificaciones de la enmienda 2 son independientes y ambas hacen falta:")
    print("  - 'solapamiento' lo atrapa la bandera de interlock (columna interlock = SI)")
    print("  - 'tiempo muerto de 0 ms' NO produce solapamiento y solo lo atrapa la medida")
    if not todo_ok:
        print("\nTraza de la implementacion CORRECTA a 4 ms:")
        correr_harness(FBCorrecto(), 0.004, traza=True)
    print(f"\nDiscrimina correctamente en los 3 ciclos de tarea: {'SI' if todo_ok else 'NO'}")
    raise SystemExit(0 if todo_ok else 1)


if __name__ == "__main__":
    main()
