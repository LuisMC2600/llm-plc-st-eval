"""
Validacion del harness PRG_Test_I6 por simulacion del ciclo de scan.

I6 (escalado analogico con histeresis): rawTemp 0..27648 -> tempC 0.0..100.0;
el enfriador se activa en >= 80.0 y se desactiva en <= 75.0, conservando su
estado entre ambos umbrales; fuera del rango 0..27648 se activa almSensor Y SE
DESACTIVA EL ENFRIADOR.

Uso:  python validar_harness_I6.py
"""

from dataclasses import dataclass

RAW_MAX = 27648


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


@dataclass
class FBCorrecto:
    tempC: float = 0.0
    enfriador: bool = False
    almSensor: bool = False

    def __call__(self, rawTemp, dt):
        if rawTemp < 0 or rawTemp > RAW_MAX:
            self.almSensor = True
            self.enfriador = False
            return
        self.almSensor = False
        self.tempC = rawTemp / RAW_MAX * 100.0
        if self.tempC >= 80.0:
            self.enfriador = True
        elif self.tempC <= 75.0:
            self.enfriador = False


@dataclass
class FBAlarmaNoApagaEnfriador(FBCorrecto):
    """DEFECTO: fuera de rango activa la alarma pero NO desactiva el enfriador,
    incumpliendo la ultima frase del enunciado."""

    def __call__(self, rawTemp, dt):
        if rawTemp < 0 or rawTemp > RAW_MAX:
            self.almSensor = True
            return                          # deja el enfriador como estaba
        FBCorrecto.__call__(self, rawTemp, dt)


@dataclass
class FBSinHisteresis(FBCorrecto):
    """DEFECTO: umbral unico en 80; no conserva el estado en la banda."""

    def __call__(self, rawTemp, dt):
        if rawTemp < 0 or rawTemp > RAW_MAX:
            self.almSensor = True
            self.enfriador = False
            return
        self.almSensor = False
        self.tempC = rawTemp / RAW_MAX * 100.0
        self.enfriador = self.tempC >= 80.0


@dataclass
class FBDivisionEntera(FBCorrecto):
    """DEFECTO: escalado en aritmetica entera; tempC vale 0 en todo el rango."""

    def __call__(self, rawTemp, dt):
        if rawTemp < 0 or rawTemp > RAW_MAX:
            self.almSensor = True
            self.enfriador = False
            return
        self.almSensor = False
        self.tempC = float(rawTemp // RAW_MAX * 100)
        if self.tempC >= 80.0:
            self.enfriador = True
        elif self.tempC <= 75.0:
            self.enfriador = False


@dataclass
class FBRangoSoloSuperior(FBCorrecto):
    """DEFECTO: solo comprueba el limite superior; un valor negativo no alarma."""

    def __call__(self, rawTemp, dt):
        if rawTemp > RAW_MAX:
            self.almSensor = True
            self.enfriador = False
            return
        self.almSensor = False
        self.tempC = rawTemp / RAW_MAX * 100.0
        if self.tempC >= 80.0:
            self.enfriador = True
        elif self.tempC <= 75.0:
            self.enfriador = False


@dataclass
class FBAlarmaEnclavada(FBCorrecto):
    """DEFECTO: la alarma no se desactiva al volver el valor al rango."""

    def __call__(self, rawTemp, dt):
        alm = self.almSensor
        FBCorrecto.__call__(self, rawTemp, dt)
        self.almSensor = self.almSensor or alm


# --------------------------------------------------------------------------
# Harness PRG_Test_I6 corregido (traduccion fiel del .st, enmienda 13)
# --------------------------------------------------------------------------
T_ASENT = 0.100
# (rawTemp, espTemp, espFrio, espAlarma, comprobar_temp)
PASOS = [
    (13824,  50.0, False, False, True),
    (22119,  80.0, True,  False, True),
    (21289,  77.0, True,  False, True),   # banda bajando: conserva ON
    (27649,   0.0, False, True,  False),  # fuera de rango CON EL ENFRIADOR ON
    (20736,  75.0, False, False, True),   # vuelve al rango
    (21289,  77.0, False, False, True),   # banda subiendo: conserva OFF
    (-1,      0.0, False, True,  False),  # fuera de rango por abajo
    (0,       0.0, False, False, True),   # vuelve al rango: alarma se limpia
]


def correr_harness(fb, dt: float, pasos=None, limite_scans: int = 500_000,
                   traza=False):
    pasos = pasos or PASOS
    ultimo = len(pasos) - 1
    paso = 0
    tPaso = TON()
    pulsoReset = False
    finalizado = False
    resultado = [0] * (ultimo + 1)
    veredicto = 0
    raw, espTemp, espFrio, espAlarma, compT = pasos[0]

    for _ in range(limite_scans):
        tPaso(not pulsoReset, T_ASENT, dt)
        pulsoReset = False

        if not finalizado:
            raw, espTemp, espFrio, espAlarma, compT = pasos[paso]

        fb(raw, dt)

        if tPaso.q and not finalizado:
            ok = (fb.enfriador == espFrio) and (fb.almSensor == espAlarma)
            if compT:
                ok = ok and (espTemp - 0.1 < fb.tempC < espTemp + 0.1)
            resultado[paso] = 1 if ok else 2
            if traza:
                print(f"    paso {paso}: raw={raw} tempC={fb.tempC:.1f} "
                      f"frio={int(fb.enfriador)} alm={int(fb.almSensor)} "
                      f"(esperado {int(espFrio)} {int(espAlarma)}) -> {resultado[paso]}")
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
        ("Defecto: la alarma no apaga el enfriador", FBAlarmaNoApagaEnfriador, 2, 3),
        ("Defecto: sin histeresis (umbral unico)", FBSinHisteresis, 2, 2),
        ("Defecto: division entera en el escalado", FBDivisionEntera, 2, 0),
        ("Defecto: no comprueba el limite inferior", FBRangoSoloSuperior, 2, 6),
        ("Defecto: alarma enclavada", FBAlarmaEnclavada, 2, 4),
    ]
    ciclos = [0.004, 0.010, 0.020]

    print("VALIDACION DEL HARNESS PRG_Test_I6")
    print(f"Duracion nominal de la secuencia: {len(PASOS)*T_ASENT:.1f} s")
    print("=" * 92)
    print(f"{'implementacion':44}{'ciclo':8}{'ver.':6}{'pasos':26}{'ok'}")
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
            print(f"{nombre:44}{int(dt*1000):>3} ms  {v:^6}{str(r):26}{'si' if ok else 'NO'}")
        print("-" * 92)

    if fallos:
        print("\nCasos que NO discriminan:")
        for nombre, cls, dt in fallos[:1]:
            print(f"  {nombre} @ {int(dt*1000)} ms")
            correr_harness(cls(), dt, traza=True)
    print(f"\nDiscrimina correctamente en los 3 ciclos de tarea: {'SI' if todo_ok else 'NO'}")
    raise SystemExit(0 if todo_ok else 1)


if __name__ == "__main__":
    main()
