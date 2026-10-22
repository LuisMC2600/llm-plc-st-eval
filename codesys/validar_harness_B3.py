"""
Validación del harness PRG_Test_B3 por simulación del ciclo de scan.

Reproduce en Python la lógica del banco de prueba y la ejecuta contra varias
implementaciones sintéticas del bloque FB_Contador. Un harness válido debe:
  - dar veredicto = 1 ante una implementación correcta
  - dar veredicto = 2 ante cada implementación defectuosa, señalando el paso

Además comprueba la independencia del ciclo de tarea: el resultado debe ser
idéntico con 4, 10 y 20 ms de MainTask. Esa independencia es justamente lo que
fallaba en la versión anterior del harness.

Uso:  python validar_harness_B3.py
"""

from dataclasses import dataclass, field


# --------------------------------------------------------------------------
# Emulación de bloques estándar IEC
# --------------------------------------------------------------------------
@dataclass
class TON:
    """Temporizador a la conexión."""
    et: float = 0.0
    q: bool = False

    def __call__(self, IN: bool, PT: float, dt: float) -> bool:
        if IN:
            self.et += dt
            self.q = self.et >= PT
        else:
            self.et = 0.0
            self.q = False
        return self.q


# --------------------------------------------------------------------------
# Implementaciones sintéticas del bloque bajo prueba
# --------------------------------------------------------------------------
@dataclass
class FBCorrecto:
    """Cuenta flancos ascendentes; preset 12; reset pone a cero."""
    cuenta: int = 0
    loteListo: bool = False
    _prev: bool = False

    def __call__(self, sensorPieza: bool, btnReset: bool, dt: float):
        if btnReset:
            self.cuenta = 0
            self.loteListo = False
        elif sensorPieza and not self._prev:
            self.cuenta += 1
        if self.cuenta >= 12:
            self.loteListo = True
        self._prev = sensorPieza


@dataclass
class FBCuentaPorNivel:
    """DEFECTO: incrementa mientras la entrada esté alta, no por flanco."""
    cuenta: int = 0
    loteListo: bool = False

    def __call__(self, sensorPieza, btnReset, dt):
        if btnReset:
            self.cuenta = 0
            self.loteListo = False
        elif sensorPieza:
            self.cuenta += 1
        if self.cuenta >= 12:
            self.loteListo = True


@dataclass
class FBPresetIncorrecto:
    """DEFECTO: activa el lote a las 10 piezas en lugar de 12."""
    cuenta: int = 0
    loteListo: bool = False
    _prev: bool = False

    def __call__(self, sensorPieza, btnReset, dt):
        if btnReset:
            self.cuenta = 0
            self.loteListo = False
        elif sensorPieza and not self._prev:
            self.cuenta += 1
        if self.cuenta >= 10:
            self.loteListo = True
        self._prev = sensorPieza


@dataclass
class FBResetIncompleto:
    """DEFECTO: el reset pone la cuenta a cero pero no apaga loteListo."""
    cuenta: int = 0
    loteListo: bool = False
    _prev: bool = False

    def __call__(self, sensorPieza, btnReset, dt):
        if btnReset:
            self.cuenta = 0
        elif sensorPieza and not self._prev:
            self.cuenta += 1
        if self.cuenta >= 12:
            self.loteListo = True
        self._prev = sensorPieza


# --------------------------------------------------------------------------
# Harness PRG_Test_B3 (traducción fiel del .st)
# --------------------------------------------------------------------------
ULTIMO_PASO = 6
FLANCOS_LOTE_A = 10      # 1 + 10 = 11 cuentas: el lote NO debe activarse
FLANCOS_LOTE_B = 1       # 11 + 1 = 12 cuentas: el lote SÍ debe activarse
T_PULSO = 0.020


def correr_harness(fb, dt: float, limite_scans: int = 500_000):
    sensorPieza = False
    btnReset = False
    paso = 0
    esperadoCuenta = 0
    esperadoLote = False
    tEspera = 0.0
    tPaso = TON()
    pulsoReset = False
    finalizado = False

    flancosPendientes = 0
    pasoCargado = -1
    tPulso = TON()
    resetPulso = False

    resultado = [0] * (ULTIMO_PASO + 1)
    veredicto = 0

    for _ in range(limite_scans):
        # 1. Definición del paso
        if not finalizado:
            if paso == 0:
                btnReset, sensorPieza = True, False
                tEspera, esperadoCuenta, esperadoLote = 0.200, 0, False
            elif paso == 1:
                btnReset, sensorPieza = False, True
                tEspera, esperadoCuenta, esperadoLote = 0.200, 1, False
            elif paso == 2:
                sensorPieza = True
                tEspera, esperadoCuenta, esperadoLote = 0.500, 1, False
            elif paso == 3:
                sensorPieza = False
                tEspera, esperadoCuenta, esperadoLote = 0.200, 1, False
            elif paso == 4:
                # 10 flancos -> 11 cuentas: detecta un preset MENOR que 12
                tEspera, esperadoCuenta, esperadoLote = 0.200, 11, False
            elif paso == 5:
                # 1 flanco más -> 12 cuentas: detecta un preset MAYOR que 12
                tEspera, esperadoCuenta, esperadoLote = 0.200, 12, True
            elif paso == 6:
                btnReset, sensorPieza = True, False
                tEspera, esperadoCuenta, esperadoLote = 0.200, 0, False

        # 2. Carga de flancos al entrar al paso
        if paso != pasoCargado:
            flancosPendientes = (FLANCOS_LOTE_A if paso == 4
                                 else FLANCOS_LOTE_B if paso == 5 else 0)
            pasoCargado = paso

        # 3. Generador determinista de flancos
        generando = paso in (4, 5) and flancosPendientes > 0
        if generando:
            q = tPulso(not resetPulso, T_PULSO, dt)
            resetPulso = False
            if q:
                sensorPieza = not sensorPieza
                if sensorPieza:
                    flancosPendientes -= 1
                resetPulso = True
        else:
            tPulso(False, T_PULSO, dt)

        # 3. Asentamiento, retenido durante la generación
        qPaso = tPaso((not pulsoReset) and (not generando), tEspera, dt)
        pulsoReset = False

        # 4. Bloque bajo prueba
        fb(sensorPieza, btnReset, dt)

        # 5. Evaluación
        if qPaso and not finalizado:
            ok = (fb.cuenta == esperadoCuenta) and (fb.loteListo == esperadoLote)
            resultado[paso] = 1 if ok else 2
            pulsoReset = True
            if paso < ULTIMO_PASO:
                paso += 1
            else:
                finalizado = True

        # 6. Veredicto
        if finalizado and veredicto == 0:
            veredicto = 1 if all(r == 1 for r in resultado) else 2
            return veredicto, resultado

    return 0, resultado  # no terminó


# --------------------------------------------------------------------------
def main() -> None:
    casos = [
        ("Correcta", FBCorrecto, 1, None),
        ("Defecto: cuenta por nivel", FBCuentaPorNivel, 2, 2),
        ("Defecto: preset 10 en vez de 12", FBPresetIncorrecto, 2, 4),
        ("Defecto: reset no apaga loteListo", FBResetIncompleto, 2, 6),
    ]
    ciclos = [0.004, 0.010, 0.020]

    print("VALIDACIÓN DEL HARNESS PRG_Test_B3")
    print("=" * 78)
    print(f"{'implementación':36}{'ciclo':8}{'veredicto':11}{'pasos':22}{'ok'}")
    print("-" * 78)

    todo_ok = True
    for nombre, cls, esperado, paso_esperado in casos:
        for dt in ciclos:
            v, r = correr_harness(cls(), dt)
            ok = (v == esperado)
            if paso_esperado is not None:
                ok = ok and r[paso_esperado] == 2
            todo_ok &= ok
            print(f"{nombre:36}{int(dt*1000):>3} ms  {v:^11}{str(r):22}{'sí' if ok else 'NO'}")
        print("-" * 78)

    print()
    print(f"Discrimina correctamente en los 3 ciclos de tarea: {'SÍ' if todo_ok else 'NO'}")
    print("La independencia del ciclo de tarea era el defecto de la versión anterior:")
    print("generaba 2 flancos con 20 ms y 12 con 4 ms.")


if __name__ == "__main__":
    main()
