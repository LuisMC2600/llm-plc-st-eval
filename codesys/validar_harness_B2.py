"""
Validacion del harness PRG_Test_B2 por simulacion del ciclo de scan.

Reconstruye como archivo la validacion que en su momento se hizo de forma
interactiva y no quedo guardada (INVENTARIO.md, seccion 8, punto 5).

PRG_Test_B2 es la plantilla para tareas CON temporizadores: cada paso lleva su
propio tiempo de asentamiento, porque el bloque bajo prueba necesita tiempo
real para que su TON venza. Se ejecuta contra varias implementaciones
sinteticas de FB_Valvula (nivelAlto -> valvula, retardo de 5 s a la conexion).

Un harness valido debe:
  - dar veredicto = 1 ante una implementacion correcta
  - dar veredicto = 2 ante cada implementacion defectuosa, senalando el paso

Se comprueba ademas la independencia del ciclo de MainTask (4, 10 y 20 ms),
segun la enmienda 3 de ENMIENDAS_HARNESSES.md.

Uso:  python validar_harness_B2.py
"""

from dataclasses import dataclass


# --------------------------------------------------------------------------
# Emulacion de bloques estandar IEC
# --------------------------------------------------------------------------
@dataclass
class TON:
    """Temporizador a la conexion."""
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


@dataclass
class TOF:
    """Temporizador a la desconexion."""
    et: float = 0.0
    q: bool = False

    def __call__(self, IN: bool, PT: float, dt: float) -> bool:
        if IN:
            self.et = 0.0
            self.q = True
        elif self.q:
            self.et += dt
            if self.et >= PT:
                self.q = False
        return self.q


# --------------------------------------------------------------------------
# Implementaciones sinteticas del bloque bajo prueba (FB_Valvula)
# --------------------------------------------------------------------------
PT_ESPECIFICADO = 5.0


@dataclass
class FBCorrecto:
    """TON de 5 s: abre tras nivel alto sostenido, cierra sin retardo."""
    valvula: bool = False
    _ton: TON = None

    def __post_init__(self):
        self._ton = TON()

    def __call__(self, nivelAlto, dt):
        self.valvula = self._ton(nivelAlto, PT_ESPECIFICADO, dt)


@dataclass
class FBTofEnVezDeTon:
    """DEFECTO: usa un retardo a la desconexion. Abre de inmediato y cierra
    5 s tarde: invierte por completo el comportamiento pedido."""
    valvula: bool = False
    _tof: TOF = None

    def __post_init__(self):
        self._tof = TOF()

    def __call__(self, nivelAlto, dt):
        self.valvula = self._tof(nivelAlto, PT_ESPECIFICADO, dt)


@dataclass
class FBPresetCorto:
    """DEFECTO: preset de 2 s en lugar de los 5 s del enunciado."""
    valvula: bool = False
    _ton: TON = None

    def __post_init__(self):
        self._ton = TON()

    def __call__(self, nivelAlto, dt):
        self.valvula = self._ton(nivelAlto, 2.0, dt)


@dataclass
class FBSinCierreInmediato:
    """DEFECTO: una vez abierta, la valvula queda enclavada; no cierra al
    caer el nivel, que es justo lo que el enunciado exige sin retardo."""
    valvula: bool = False
    _ton: TON = None

    def __post_init__(self):
        self._ton = TON()

    def __call__(self, nivelAlto, dt):
        if self._ton(nivelAlto, PT_ESPECIFICADO, dt):
            self.valvula = True


@dataclass
class FBUnSoloDisparo:
    """DEFECTO: el temporizador no se rearma. Abre y cierra bien la primera
    vez, pero nunca vuelve a abrir en un segundo ciclo."""
    valvula: bool = False
    _ton: TON = None
    _yaAbrio: bool = False

    def __post_init__(self):
        self._ton = TON()

    def __call__(self, nivelAlto, dt):
        q = self._ton(nivelAlto, PT_ESPECIFICADO, dt)
        if q and not self._yaAbrio:
            self.valvula = True
            self._yaAbrio = True
        if not nivelAlto:
            self.valvula = False


# --------------------------------------------------------------------------
# Harness PRG_Test_B2 (traduccion fiel del .st)
# --------------------------------------------------------------------------
ULTIMO_PASO = 5

# (nivelAlto, tEspera, esperado) por paso
PASOS = [
    (False, 0.500, False),   # 0: reposo
    (True,  3.000, False),   # 1: 3 s de nivel alto: aun NO debe abrir
    (True,  3.000, True),    # 2: 6 s acumulados: ya debe abrir
    (False, 0.200, False),   # 3: cae el nivel: cierre inmediato
    (True,  6.000, True),    # 4: ciclo completo nuevo: rearme del temporizador
    (False, 0.200, False),   # 5: cierre final
]


def correr_harness(fb, dt: float, limite_scans: int = 2_000_000):
    paso = 0
    nivelAlto = False
    tEspera = 0.0
    esperado = False
    tPaso = TON()
    pulsoReset = False
    finalizado = False

    resultado = [0] * (ULTIMO_PASO + 1)
    veredicto = 0

    for _ in range(limite_scans):
        # 1. Definicion del paso en curso. Va antes del temporizador porque
        #    tEspera lo alimenta.
        if not finalizado:
            nivelAlto, tEspera, esperado = PASOS[paso]

        # 2. Temporizador de asentamiento, con el tiempo propio del paso
        tPaso(not pulsoReset, tEspera, dt)
        pulsoReset = False

        # 3. Llamada al bloque bajo prueba
        fb(nivelAlto, dt)

        # 4. Evaluacion al vencer el asentamiento del paso
        if tPaso.q and not finalizado:
            resultado[paso] = 1 if fb.valvula == esperado else 2
            pulsoReset = True
            if paso < ULTIMO_PASO:
                paso += 1
            else:
                finalizado = True

        # 5. Veredicto global
        if finalizado and veredicto == 0:
            veredicto = 1 if all(r == 1 for r in resultado) else 2
            return veredicto, resultado

    return 0, resultado  # no termino dentro del limite de scans


# --------------------------------------------------------------------------
def main() -> None:
    casos = [
        ("Correcta", FBCorrecto, 1, None),
        ("Defecto: TOF en vez de TON", FBTofEnVezDeTon, 2, 1),
        ("Defecto: preset de 2 s", FBPresetCorto, 2, 1),
        ("Defecto: no cierra al caer el nivel", FBSinCierreInmediato, 2, 3),
        ("Defecto: no rearma el temporizador", FBUnSoloDisparo, 2, 4),
    ]
    ciclos = [0.004, 0.010, 0.020]

    dur = sum(p[1] for p in PASOS)
    print("VALIDACION DEL HARNESS PRG_Test_B2")
    print(f"Duracion nominal de la secuencia: {dur:.1f} s por respuesta evaluada")
    print("=" * 84)
    print(f"{'implementacion':38}{'ciclo':8}{'veredicto':11}{'pasos':22}{'ok'}")
    print("-" * 84)

    todo_ok = True
    for nombre, cls, esperado, paso_esperado in casos:
        for dt in ciclos:
            v, r = correr_harness(cls(), dt)
            ok = (v == esperado)
            if paso_esperado is not None:
                ok = ok and r[paso_esperado] == 2
            todo_ok &= ok
            print(f"{nombre:38}{int(dt*1000):>3} ms  {v:^11}{str(r):22}{'si' if ok else 'NO'}")
        print("-" * 84)

    pasos_cubiertos = sorted({p for _, _, _, p in casos if p is not None})
    print()
    print(f"Pasos aislados por al menos un defecto: {pasos_cubiertos} de 0..{ULTIMO_PASO}")
    print(f"Discrimina correctamente en los 3 ciclos de tarea: {'SI' if todo_ok else 'NO'}")
    raise SystemExit(0 if todo_ok else 1)


if __name__ == "__main__":
    main()
