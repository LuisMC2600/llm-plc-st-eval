"""
Validacion del harness PRG_Test_B1 por simulacion del ciclo de scan.

Reconstruye como archivo la validacion que en su momento se hizo de forma
interactiva y no quedo guardada (laguna de reproducibilidad senalada en
INVENTARIO.md, seccion 8, punto 5).

Reproduce en Python la logica del banco PRG_Test_B1.st y la ejecuta contra
varias implementaciones sinteticas de FB_Motor. Un harness valido debe:
  - dar veredicto = 1 ante una implementacion correcta
  - dar veredicto = 2 ante cada implementacion defectuosa, senalando el paso

Se comprueba ademas la independencia del ciclo de MainTask (4, 10 y 20 ms),
segun la enmienda 3 de ENMIENDAS_HARNESSES.md.

Uso:  python validar_harness_B1.py
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


# --------------------------------------------------------------------------
# Implementaciones sinteticas del bloque bajo prueba (FB_Motor)
# --------------------------------------------------------------------------
@dataclass
class FBCorrecto:
    """Enclavamiento correcto; el E-stop domina y queda enclavado hasta que
    se suelta la marcha, por lo que no hay rearranque automatico."""
    motorOn: bool = False
    _bloqueo: bool = False

    def __call__(self, btnMarcha, btnParo, btnEmerg, dt):
        if btnEmerg:
            self.motorOn = False
            self._bloqueo = True
        else:
            if self._bloqueo and not btnMarcha:
                self._bloqueo = False           # rearme al soltar la marcha
            if btnParo:
                self.motorOn = False
            elif btnMarcha and not self._bloqueo:
                self.motorOn = True


@dataclass
class FBSinEnclavamiento:
    """DEFECTO: salida combinacional; el motor cae al soltar la marcha."""
    motorOn: bool = False

    def __call__(self, btnMarcha, btnParo, btnEmerg, dt):
        self.motorOn = btnMarcha and not btnParo and not btnEmerg


@dataclass
class FBRearranqueTrasEmergencia:
    """DEFECTO: enclavamiento sin memoria de la emergencia; al liberar el
    E-stop con la marcha aun pulsada, el motor rearranca solo."""
    motorOn: bool = False

    def __call__(self, btnMarcha, btnParo, btnEmerg, dt):
        if btnParo or btnEmerg:
            self.motorOn = False
        elif btnMarcha:
            self.motorOn = True


@dataclass
class FBEmergenciaNoDomina:
    """DEFECTO: la marcha se evalua antes que los paros, de modo que el
    E-stop no tiene prioridad mientras la marcha siga pulsada."""
    motorOn: bool = False

    def __call__(self, btnMarcha, btnParo, btnEmerg, dt):
        if btnMarcha:
            self.motorOn = True
        elif btnParo or btnEmerg:
            self.motorOn = False


@dataclass
class FBParoInvertido:
    """DEFECTO: interpreta btnParo como senal normalmente cerrada, asi que
    detiene el motor cuando la entrada esta en FALSE."""
    motorOn: bool = False

    def __call__(self, btnMarcha, btnParo, btnEmerg, dt):
        if btnEmerg or not btnParo:
            self.motorOn = False
        elif btnMarcha:
            self.motorOn = True


# --------------------------------------------------------------------------
# Harness PRG_Test_B1 (traduccion fiel del .st)
# --------------------------------------------------------------------------
ULTIMO_PASO = 6
T_ASENTAMIENTO = 0.200


def correr_harness(fb, dt: float, limite_scans: int = 500_000):
    btnMarcha = btnParo = btnEmerg = False
    paso = 0
    esperado = False
    tPaso = TON()
    pulsoReset = False
    finalizado = False

    resultado = [0] * (ULTIMO_PASO + 1)
    veredicto = 0

    for _ in range(limite_scans):
        # 1. Temporizador de asentamiento entre pasos
        tPaso(not pulsoReset, T_ASENTAMIENTO, dt)
        pulsoReset = False

        # 2. Aplicacion de entradas y valor esperado segun el paso.
        #    Solo se asigna lo que asigna el CASE del .st: las demas entradas
        #    conservan su valor, que es justamente lo que prueban los pasos 5 y 6.
        if not finalizado:
            if paso == 0:
                btnMarcha, btnParo, btnEmerg = False, False, False
                esperado = False
            elif paso == 1:
                btnMarcha = True
                esperado = True
            elif paso == 2:
                btnMarcha = False
                esperado = True
            elif paso == 3:
                btnParo = True
                esperado = False
            elif paso == 4:
                btnParo, btnMarcha = False, True
                esperado = True
            elif paso == 5:
                btnEmerg = True
                esperado = False
            elif paso == 6:
                btnEmerg = False          # la marcha sigue pulsada
                esperado = False

        # 3. Llamada al bloque bajo prueba
        fb(btnMarcha, btnParo, btnEmerg, dt)

        # 4. Evaluacion al vencer el tiempo de asentamiento
        if tPaso.q and not finalizado:
            resultado[paso] = 1 if fb.motorOn == esperado else 2
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
        ("Defecto: sin enclavamiento", FBSinEnclavamiento, 2, 2),
        ("Defecto: rearranca tras E-stop", FBRearranqueTrasEmergencia, 2, 6),
        ("Defecto: E-stop no domina", FBEmergenciaNoDomina, 2, 5),
        ("Defecto: paro interpretado como NC", FBParoInvertido, 2, 1),
    ]
    ciclos = [0.004, 0.010, 0.020]

    print("VALIDACION DEL HARNESS PRG_Test_B1")
    print("=" * 82)
    print(f"{'implementacion':36}{'ciclo':8}{'veredicto':11}{'pasos':24}{'ok'}")
    print("-" * 82)

    todo_ok = True
    for nombre, cls, esperado, paso_esperado in casos:
        for dt in ciclos:
            v, r = correr_harness(cls(), dt)
            ok = (v == esperado)
            if paso_esperado is not None:
                ok = ok and r[paso_esperado] == 2
            todo_ok &= ok
            print(f"{nombre:36}{int(dt*1000):>3} ms  {v:^11}{str(r):24}{'si' if ok else 'NO'}")
        print("-" * 82)

    pasos_cubiertos = sorted({p for _, _, _, p in casos if p is not None})
    print()
    print(f"Pasos aislados por al menos un defecto: {pasos_cubiertos} de 0..{ULTIMO_PASO}")
    print(f"Discrimina correctamente en los 3 ciclos de tarea: {'SI' if todo_ok else 'NO'}")
    raise SystemExit(0 if todo_ok else 1)


if __name__ == "__main__":
    main()
