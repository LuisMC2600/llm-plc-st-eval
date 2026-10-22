"""
Validacion del harness PRG_Test_C3 (conversion Ladder -> ST, PROGRAM PRG_Conversion)
por simulacion del ciclo de scan.

Comportamiento del Ladder (tasks.json v1, C3):
  Rama 1: motor := (btnMarcha OR motor) AND NOT btnParo   (btnParo es contacto NC)
  Rama 2: T1(IN := motor, PT := T#10S)
  Rama 3: lampara := T1.Q

Como es un PROGRAM, el harness escribe sus entradas y lee sus salidas por nombre
(PRG_Conversion.btnMarcha := ...; PRG_Conversion(); ... PRG_Conversion.motor).
Una respuesta que declare las E/S como VAR local no es utilizable desde fuera:
CODESYS rechaza escribir sus entradas ("no es ninguna entrada de PRG_Conversion",
verificado el 30-09-2026 con un doble). Se clasifica como INTERFAZ NO CONFORME,
el mismo criterio aplicado en el piloto a los FB con E/S en VAR.

Paso (btnMarcha, btnParo) duracion -> (motor, lampara)
  0 (F,F) 0.2 s -> (F,F)
  1 (T,F) 0.2 s -> (T,F)   arranque; la lampara aun no
  2 (F,F) 5.0 s -> (T,F)   enclavamiento; lampara vigilada en FALSE todo el paso
  3 (F,F) 5.5 s -> (T,T)   ~10.7 s con motor: lampara encendida
  4 (F,T) 0.2 s -> (F,F)   paro: motor y lampara (T1 se reinicia)
  5 (F,F) 0.2 s -> (F,F)
  6 (T,T) 0.2 s -> (F,F)   marcha y paro a la vez: gana el NC en serie; vigilado
  7 (T,F) 0.2 s -> (T,F)
  8 (F,F) 9.0 s -> (T,F)   T1 empezo de cero en el paso 7: lampara vigilada en FALSE
  9 (F,F) 1.5 s -> (T,T)
 10 (F,T) 0.2 s -> (F,F)
VIGILANCIA CONTINUA (enmienda 4): en los pasos 0, 2, 5, 6 y 8 la lampara no puede
valer TRUE ni un scan; en los pasos 0, 5 y 6 tampoco el motor.
Uso:  python validar_harness_C3.py
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


class FBCorrecta:
    PT = 10.0

    def __init__(self):
        self.motor = self.lampara = False
        self.T1 = TON()

    def rama1(self, m, p):
        self.motor = (m or self.motor) and not p

    def rama2(self, dt):
        self.T1(self.motor, self.PT, dt)
        self.lampara = self.T1.q

    def __call__(self, btnMarcha, btnParo, dt):
        self.rama1(btnMarcha, btnParo)
        self.rama2(dt)


FBCorrectaVarLocal = FBCorrecta


class FBParoComoNA(FBCorrecta):
    """DEFECTO: btnParo tratado como contacto NA."""
    def rama1(self, m, p):
        self.motor = (m or self.motor) and p


class FBSinEnclavamiento(FBCorrecta):
    """DEFECTO: falta el contacto de autorretencion 'motor' en paralelo."""
    def rama1(self, m, p):
        self.motor = m and not p


class FBMarchaPrioritaria(FBCorrecta):
    """DEFECTO: el paralelo queda fuera de la serie con el NC."""
    def rama1(self, m, p):
        self.motor = m or (self.motor and not p)


class FBLamparaSinTemporizar(FBCorrecta):
    """DEFECTO: la lampara sigue al motor sin el TON."""
    def rama2(self, dt):
        self.T1(self.motor, self.PT, dt)
        self.lampara = self.motor


class FBTiempoCinco(FBCorrecta):
    """DEFECTO: T1 con 5 s."""
    PT = 5.0


class FBTemporizadorRetenido(FBCorrecta):
    """DEFECTO: T1 se autoalimenta con su propia Q y no se reinicia al parar."""
    def rama2(self, dt):
        self.T1(self.motor or self.T1.q, self.PT, dt)
        self.lampara = self.T1.q


# ------------------------------------------------------------ harness (traduccion fiel del .st)
PASOS = [((0, 0), 0.2, (0, 0)), ((1, 0), 0.2, (1, 0)), ((0, 0), 5.0, (1, 0)), ((0, 0), 5.5, (1, 1)),
         ((0, 1), 0.2, (0, 0)), ((0, 0), 0.2, (0, 0)), ((1, 1), 0.2, (0, 0)), ((1, 0), 0.2, (1, 0)),
         ((0, 0), 9.0, (1, 0)), ((0, 0), 1.5, (1, 1)), ((0, 1), 0.2, (0, 0))]
ULTIMO_PASO = len(PASOS) - 1
VIG_LAMPARA = (0, 2, 5, 6, 8)
VIG_MOTOR = (0, 5, 6)


def correr_harness(fb, dt, limite_scans=2_000_000):
    paso, tPaso, pulsoReset, finalizado, violacion = 0, TON(), False, False, False
    resultado = [0] * (ULTIMO_PASO + 1)
    for _ in range(limite_scans):
        if not finalizado:
            ent, t, esp = PASOS[paso]
        qPaso = tPaso(not pulsoReset, t, dt)
        pulsoReset = False
        fb(bool(ent[0]), bool(ent[1]), dt)
        if not finalizado and ((paso in VIG_LAMPARA and fb.lampara) or (paso in VIG_MOTOR and fb.motor)):
            violacion = True
        if qPaso and not finalizado:
            resultado[paso] = 1 if ((int(fb.motor), int(fb.lampara)) == esp and not violacion) else 2
            violacion = False
            pulsoReset = True
            if paso < ULTIMO_PASO:
                paso += 1
            else:
                finalizado = True
        if finalizado:
            return (1 if all(x == 1 for x in resultado) else 2), resultado
    return 0, resultado


CASOS = [("Correcta", FBCorrecta, 1, None),
         ("ParoComoNA", FBParoComoNA, 2, 1),
         ("SinEnclavamiento", FBSinEnclavamiento, 2, 2),
         ("MarchaPrioritaria", FBMarchaPrioritaria, 2, 6),
         ("LamparaSinTemporizar", FBLamparaSinTemporizar, 2, 1),
         ("TiempoCinco", FBTiempoCinco, 2, 2),
         ("TemporizadorRetenido", FBTemporizadorRetenido, 2, 4)]


def main():
    todo_ok = True
    print("VALIDACION DEL HARNESS PRG_Test_C3")
    for nombre, cls, esp, paso in CASOS:
        vec = set()
        for dt in (0.004, 0.010, 0.020):
            v, r = correr_harness(cls(), dt)
            ok = v == esp and (paso is None or (r[paso] == 2 and 2 not in r[:paso]))
            todo_ok &= ok
            vec.add(tuple(r))
            print("%-22s %2d ms  v=%d  %s  %s" % (nombre, int(dt * 1000), v, r, "ok" if ok else "NO"))
        todo_ok &= len(vec) == 1
    print("Discrimina y es independiente del ciclo:", "SI" if todo_ok else "NO")
    return todo_ok


if __name__ == "__main__":
    main()
