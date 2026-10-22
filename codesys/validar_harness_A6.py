"""
Validacion del harness PRG_Test_A6 (FB_Modos: modos jerarquicos con forzado
individual) por simulacion del ciclo de scan.

Enunciado (tasks.json v1, A6): modos 0 auto, 1 manual, 2 mantenimiento; al
arrancar, manual; un cambio solo se acepta con estadoSeguro y se aplica en cuanto
se active si el selector sigue indicando otro modo valido; selector fuera de 0..2
se ignora; auto: actuador = cmdAuto; manual: actuador = cmdManual; mantenimiento:
todos apagados y forzado uno a uno por flanco de confirmarForzado si idxForzado
esta en 0..7 (lo conserva); idx fuera de rango se ignora; perder estadoSeguro en
mantenimiento anula los forzados (todo apagado); salir de mantenimiento anula
los forzados.

confirmarForzado se aplica como pulso de UN scan al entrar en el paso (como rxOk
en A3): flanco y nivel se comportan igual.
Patrones: A = 10101010, A2 = 01100110 (cmdAuto), M = 11001100 (cmdManual);
bit i = actuador[i], escrito de 0 a 7.

Paso: (selector, seguro, cmdAuto, idx, val, pulso) -> (modo, actuadores)
  0 (0,F,A, 0,F,-) -> (1, M)        arranca en manual; sin seguro no cambia
  1 (0,F,A, 0,F,-) -> (1, M)
  2 (0,T,A, 0,F,-) -> (0, A)        el cambio pendiente se aplica al activarse seguro
  3 (5,T,A, 0,F,-) -> (0, A)        fuera de rango: se ignora
  4 (-1,T,A,0,F,-) -> (0, A)
  5 (0,T,A2,0,F,-) -> (0, A2)       sigue a cmdAuto
  6 (2,T,A2,0,F,-) -> (2, 00000000) mantenimiento: todo apagado
  7 (2,T,A2,3,T,P) -> (2, 00010000) fuerza actuador[3]
  8 (2,T,A2,8,T,P) -> (2, 00010000) idx fuera de rango: se ignora
  9 (2,T,A2,5,T,P) -> (2, 00010100)
 10 (2,T,A2,3,F,P) -> (2, 00000100) forzado a FALSE
 11 (2,F,A2,0,F,-) -> (2, 00000000) pierde seguro: anula forzados
 12 (2,T,A2,0,F,-) -> (2, 00000000) vuelve el seguro: siguen anulados
 13 (2,T,A2,0,T,P) -> (2, 10000000)
 14 (1,T,A2,0,F,-) -> (1, M)        sale a manual
 15 (2,T,A2,0,F,-) -> (2, 00000000) los forzados de antes no reaparecen
 16 (0,T,A2,0,F,-) -> (0, A2)
Uso:  python validar_harness_A6.py
"""
from dataclasses import dataclass

A = [1, 0, 1, 0, 1, 0, 1, 0]
A2 = [0, 1, 1, 0, 0, 1, 1, 0]
M = [1, 1, 0, 0, 1, 1, 0, 0]
Z = [0] * 8


def bits(s):
    return [int(c) for c in s]


@dataclass
class TON:
    et: float = 0.0
    q: bool = False

    def __call__(self, IN, PT, dt):
        if IN:
            self.et += dt
            self.q = self.et >= PT
        else:
            self.et, self.q = 0.0, False
        return self.q


class FBCorrecta:
    MODO_INICIAL = 1

    def __init__(self):
        self.modoActivo = self.MODO_INICIAL
        self.actuador = [False] * 8
        self.forz = [False] * 8
        self.prev = False

    def cambio(self, selector, seguro):
        if seguro and 0 <= selector <= 2 and selector != self.modoActivo:
            if self.modoActivo == 2:
                self.forz = [False] * 8
            self.modoActivo = selector

    def forzar(self, idx, val):
        if 0 <= idx <= 7:
            self.forz[idx] = val

    def __call__(self, selector, seguro, cmdAuto, cmdManual, idx, val, conf):
        self.cambio(selector, seguro)
        flanco = conf and not self.prev
        self.prev = conf
        if self.modoActivo == 0:
            self.actuador = list(cmdAuto)
        elif self.modoActivo == 1:
            self.actuador = list(cmdManual)
        else:
            if not seguro:
                self.forz = [False] * 8
            elif flanco:
                self.forzar(idx, val)
            self.actuador = list(self.forz)


class FBArrancaEnAuto(FBCorrecta):
    """DEFECTO: modo inicial automatico."""
    MODO_INICIAL = 0


class FBCambioSinSeguro(FBCorrecta):
    """DEFECTO: acepta el cambio de modo sin estadoSeguro."""
    def cambio(self, selector, seguro):
        super().cambio(selector, True)


class FBAceptaFueraDeRango(FBCorrecta):
    """DEFECTO: no valida el rango del selector."""
    def cambio(self, selector, seguro):
        if seguro and selector != self.modoActivo:
            if self.modoActivo == 2:
                self.forz = [False] * 8
            self.modoActivo = selector


class FBCambioSoloPorFlancoDeSelector(FBCorrecta):
    """DEFECTO: el cambio solo se acepta cuando cambia el selector; si en ese
    momento no hay seguro, el cambio se pierde aunque luego se active."""
    def __init__(self):
        super().__init__()
        self.selPrev = self.modoActivo

    def cambio(self, selector, seguro):
        if selector != self.selPrev:
            super().cambio(selector, seguro)
        self.selPrev = selector


class FBForzadoNoRetiene(FBCorrecta):
    """DEFECTO: el actuador forzado solo dura mientras hay flanco."""
    def __call__(self, selector, seguro, cmdAuto, cmdManual, idx, val, conf):
        super().__call__(selector, seguro, cmdAuto, cmdManual, idx, val, conf)
        if self.modoActivo == 2:
            self.forz = [False] * 8 if not (conf and 0 <= idx <= 7) else self.forz


class FBIdxSinValidar(FBCorrecta):
    """DEFECTO: un idx fuera de rango se recorta a 0..7 en lugar de ignorarse."""
    def forzar(self, idx, val):
        self.forz[max(0, min(7, idx))] = val


class FBSeguroNoAnula(FBCorrecta):
    """DEFECTO: perder estadoSeguro en mantenimiento no anula los forzados."""
    def __call__(self, selector, seguro, cmdAuto, cmdManual, idx, val, conf):
        super().__call__(selector, True if self.modoActivo == 2 else seguro, cmdAuto, cmdManual, idx, val, conf)


class FBSalirNoAnula(FBCorrecta):
    """DEFECTO: al salir de mantenimiento los forzados se conservan."""
    def cambio(self, selector, seguro):
        if seguro and 0 <= selector <= 2 and selector != self.modoActivo:
            self.modoActivo = selector


class FBMantenimientoSigueManual(FBCorrecta):
    """DEFECTO: en mantenimiento los no forzados siguen a cmdManual."""
    def __call__(self, selector, seguro, cmdAuto, cmdManual, idx, val, conf):
        super().__call__(selector, seguro, cmdAuto, cmdManual, idx, val, conf)
        if self.modoActivo == 2:
            self.actuador = [bool(f) or bool(m) for f, m in zip(self.forz, cmdManual)]


# ------------------------------------------------------------ harness (traduccion fiel del .st)
PASOS = [(0, 0, A, 0, 0, 0, 1, M), (0, 0, A, 0, 0, 0, 1, M), (0, 1, A, 0, 0, 0, 0, A),
         (5, 1, A, 0, 0, 0, 0, A), (-1, 1, A, 0, 0, 0, 0, A), (0, 1, A2, 0, 0, 0, 0, A2),
         (2, 1, A2, 0, 0, 0, 2, Z), (2, 1, A2, 3, 1, 1, 2, bits("00010000")),
         (2, 1, A2, 8, 1, 1, 2, bits("00010000")), (2, 1, A2, 5, 1, 1, 2, bits("00010100")),
         (2, 1, A2, 3, 0, 1, 2, bits("00000100")), (2, 0, A2, 0, 0, 0, 2, Z), (2, 1, A2, 0, 0, 0, 2, Z),
         (2, 1, A2, 0, 1, 1, 2, bits("10000000")), (1, 1, A2, 0, 0, 0, 1, M), (2, 1, A2, 0, 0, 0, 2, Z),
         (0, 1, A2, 0, 0, 0, 0, A2)]
ULTIMO_PASO = len(PASOS) - 1
T_PASO = 0.100


def correr_harness(fb, dt, limite_scans=200_000):
    paso, tPaso, pulsoReset, finalizado = 0, TON(), False, False
    cargado, pendiente = -1, False
    resultado = [0] * (ULTIMO_PASO + 1)
    for _ in range(limite_scans):
        if not finalizado:
            sel, seg, ca, idx, val, pul, emodo, eact = PASOS[paso]
        if paso != cargado:
            pendiente = bool(pul)
            cargado = paso
        conf = pendiente and not finalizado
        pendiente = False
        qPaso = tPaso(not pulsoReset, T_PASO, dt)
        pulsoReset = False
        fb(sel, bool(seg), [bool(x) for x in ca], [bool(x) for x in M], idx, bool(val), conf)
        if qPaso and not finalizado:
            ok = fb.modoActivo == emodo and [int(x) for x in fb.actuador] == list(eact)
            resultado[paso] = 1 if ok else 2
            pulsoReset = True
            if paso < ULTIMO_PASO:
                paso += 1
            else:
                finalizado = True
        if finalizado:
            return (1 if all(x == 1 for x in resultado) else 2), resultado
    return 0, resultado


CASOS = [("Correcta", FBCorrecta, 1, None),
         ("ArrancaEnAuto", FBArrancaEnAuto, 2, 0),
         ("CambioSinSeguro", FBCambioSinSeguro, 2, 0),
         ("CambioSoloPorFlancoDeSelector", FBCambioSoloPorFlancoDeSelector, 2, 2),
         ("AceptaFueraDeRango", FBAceptaFueraDeRango, 2, 3),
         ("MantenimientoSigueManual", FBMantenimientoSigueManual, 2, 6),
         ("ForzadoNoRetiene", FBForzadoNoRetiene, 2, 7),
         ("IdxSinValidar", FBIdxSinValidar, 2, 8),
         ("SeguroNoAnula", FBSeguroNoAnula, 2, 11),
         ("SalirNoAnula", FBSalirNoAnula, 2, 15)]


def main():
    todo_ok = True
    print("VALIDACION DEL HARNESS PRG_Test_A6")
    for nombre, cls, esp, paso in CASOS:
        vec = set()
        for dt in (0.004, 0.010, 0.020):
            v, r = correr_harness(cls(), dt)
            ok = v == esp and (paso is None or (r[paso] == 2 and 2 not in r[:paso]))
            todo_ok &= ok
            vec.add(tuple(r))
            print("%-30s %2d ms v=%d %s %s" % (nombre, int(dt * 1000), v, "".join(map(str, r)), "ok" if ok else "NO"))
        todo_ok &= len(vec) == 1
    print("Discrimina y es independiente del ciclo:", "SI" if todo_ok else "NO")
    return todo_ok


if __name__ == "__main__":
    main()
