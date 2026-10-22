"""
Validacion del harness PRG_Test_B7 (SelBomba: selector manual/automatico, POU a
eleccion del modelo) por simulacion del ciclo de scan.

Enunciado (tasks.json v1, B7): modoAuto=TRUE -> bomba = nivelBajo;
modoAuto=FALSE -> bomba = btnManual; sin memoria entre ciclos. El modelo elige
FUNCTION, FUNCTION_BLOCK o PROGRAM y la llama SelBomba.

Como la sintaxis de llamada depende del tipo de POU, el harness tiene TRES
variantes con la misma secuencia y la misma evaluacion, que difieren solo en la
llamada: PRG_Test_B7_FUN.st, PRG_Test_B7_FB.st, PRG_Test_B7_PRG.st. El
simulador elige la variante segun el tipo de POU que declare la respuesta.
La eleccion del tipo de POU NO es parte del criterio 1: se registra aparte.

Secuencia (modoAuto, btnManual, nivelBajo) -> bomba esperada. El orden esta
pensado para que cada paso de TRUE a FALSE delate cualquier memoria:
  0 (F,F,F) F  reposo
  1 (F,T,F) T  manual encendida
  2 (F,F,F) F  manual apagada          -> memoria en manual (telerruptor/enclavamiento)
  3 (F,F,T) F  manual ignora nivel     -> OR de ambas fuentes
  4 (T,F,T) T  auto encendida          -> nivel invertido
  5 (T,F,F) F  auto apagada            -> memoria en auto
  6 (T,T,F) F  auto ignora el boton    -> boton activo tambien en auto
  7 (T,T,T) T
  8 (F,T,T) T
  9 (F,F,T) F  sale de T con nivel activo en manual -> memoria entre modos
Uso:  python validar_harness_B7.py
"""
from dataclasses import dataclass


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


# ------------------------------------------------------------ implementaciones
class _Base:
    def __init__(self):
        self.bomba = False
        self._prev = False


class FBCorrecta(_Base):
    def __call__(self, modoAuto, btnManual, nivelBajo):
        self.bomba = nivelBajo if modoAuto else btnManual


class FBModoInvertido(_Base):
    """DEFECTO: modoAuto=FALSE se interpreta como automatico."""
    def __call__(self, modoAuto, btnManual, nivelBajo):
        self.bomba = btnManual if modoAuto else nivelBajo


class FBOrSimple(_Base):
    """DEFECTO: bomba := btnManual OR nivelBajo, ignora el modo."""
    def __call__(self, modoAuto, btnManual, nivelBajo):
        self.bomba = btnManual or nivelBajo


class FBNivelInvertido(_Base):
    """DEFECTO: en automatico enciende con NOT nivelBajo."""
    def __call__(self, modoAuto, btnManual, nivelBajo):
        self.bomba = (not nivelBajo) if modoAuto else btnManual


class FBBotonTambienEnAuto(_Base):
    """DEFECTO: en automatico el boton manual tambien enciende."""
    def __call__(self, modoAuto, btnManual, nivelBajo):
        self.bomba = (nivelBajo or btnManual) if modoAuto else btnManual


class FBMemoriaEnAuto(_Base):
    """DEFECTO (FB): en auto enclava con nivelBajo y solo suelta al pasar a manual."""
    def __call__(self, modoAuto, btnManual, nivelBajo):
        if modoAuto:
            self.bomba = self.bomba or nivelBajo
        else:
            self.bomba = btnManual


class FBTelerruptorManual(_Base):
    """DEFECTO (PROGRAM): en manual cada pulsacion conmuta la bomba."""
    def __call__(self, modoAuto, btnManual, nivelBajo):
        if modoAuto:
            self.bomba = nivelBajo
        elif btnManual and not self._prev:
            self.bomba = not self.bomba
        self._prev = btnManual


# ------------------------------------------------------------ harness (traduccion fiel del .st)
ULTIMO_PASO = 9
T_PASO = 0.100
PASOS = [(False, False, False, False), (False, True, False, True), (False, False, False, False),
         (False, False, True, False), (True, False, True, True), (True, False, False, False),
         (True, True, False, False), (True, True, True, True), (False, True, True, True),
         (False, False, True, False)]


def correr_harness(fb, dt, limite_scans=100_000):
    paso, tPaso, pulsoReset, finalizado = 0, TON(), False, False
    resultado = [0] * (ULTIMO_PASO + 1)
    modo = boton = nivel = esperado = False
    for _ in range(limite_scans):
        if not finalizado:
            modo, boton, nivel, esperado = PASOS[paso]
        qPaso = tPaso(not pulsoReset, T_PASO, dt)
        pulsoReset = False
        fb(modo, boton, nivel)
        if qPaso and not finalizado:
            resultado[paso] = 1 if fb.bomba == esperado else 2
            pulsoReset = True
            if paso < ULTIMO_PASO:
                paso += 1
            else:
                finalizado = True
        if finalizado:
            return (1 if all(x == 1 for x in resultado) else 2), resultado
    return 0, resultado


#          id                    clase                 esp paso  POU del doble
CASOS = [("Correcta",            FBCorrecta,           1, None, "FUNCTION"),
         ("CorrectaFB",          FBCorrecta,           1, None, "FUNCTION_BLOCK"),
         ("CorrectaPRG",         FBCorrecta,           1, None, "PROGRAM"),
         ("ModoInvertido",       FBModoInvertido,      2, 1,    "FUNCTION"),
         ("OrSimple",            FBOrSimple,           2, 3,    "FUNCTION"),
         ("NivelInvertido",      FBNivelInvertido,     2, 4,    "FUNCTION"),
         ("BotonTambienEnAuto",  FBBotonTambienEnAuto, 2, 6,    "FUNCTION"),
         ("MemoriaEnAuto",       FBMemoriaEnAuto,      2, 5,    "FUNCTION_BLOCK"),
         ("TelerruptorManual",   FBTelerruptorManual,  2, 2,    "PROGRAM")]
FBCorrectaFB = FBCorrectaPRG = FBCorrecta


def main():
    todo_ok = True
    print("VALIDACION DEL HARNESS PRG_Test_B7")
    for nombre, cls, esp, paso, pou in CASOS:
        vec = set()
        for dt in (0.004, 0.010, 0.020):
            v, r = correr_harness(cls(), dt)
            ok = v == esp and (paso is None or (r[paso] == 2 and 2 not in r[:paso]))
            todo_ok &= ok
            vec.add(tuple(r))
            print("%-20s %-15s %2d ms  v=%d  %s  %s" % (nombre, pou, int(dt * 1000), v, r, "ok" if ok else "NO"))
        todo_ok &= len(vec) == 1
    print("Discrimina y es independiente del ciclo:", "SI" if todo_ok else "NO")
    return todo_ok


if __name__ == "__main__":
    main()
