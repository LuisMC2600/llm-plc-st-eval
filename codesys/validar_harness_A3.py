"""
Validacion del harness PRG_Test_A3 (FB_Com: peticion/respuesta con reintentos)
por simulacion del ciclo de scan.

Enunciado (tasks.json v1, A3): flanco de txReq inicia un intercambio (txData=100,
ocupado, intento 1); intento correcto si dentro de 500 ms llega rxOk con
rxData = 100; si vence el plazo o llega rxOk con otro valor, falla e inicia el
siguiente con plazo nuevo; maximo 3 intentos; nIntentos = intento en curso y
conserva el ultimo; ok / error permanecen hasta el siguiente intercambio; un
flanco de txReq durante un intercambio se ignora.

rxOk se aplica SIEMPRE como pulso de UN scan al entrar en el paso: asi una
implementacion por nivel y una por flanco de rxOk se comportan igual (el
enunciado no fija cual), y ninguna gasta varios intentos con una sola respuesta.

Paso: (txReq, pulso rxOk, rxData) duracion -> (ocupado, ok, error, nIntentos, txData)   [- = no se evalua]
  0 (F,-,0)   0.20 s -> (F,F,F,-,-)  reposo
  1 (T,-,0)   0.20 s -> (T,F,F,1,100) flanco: intento 1
  2 (F,-,0)   0.20 s -> (T,F,F,1,-)   0.40 s: aun intento 1   (plazo corto)
  3 (F,-,0)   0.25 s -> (T,F,F,2,-)   0.65 s: intento 2        (plazo largo / sin reintento)
  4 (F,P,100) 0.20 s -> (F,T,F,2,-)   eco correcto: ok, conserva nIntentos=2
  5 (F,-,0)   0.30 s -> (F,T,F,2,-)   ok permanece
  6 (T,-,0)   0.10 s -> (T,F,F,1,100) nuevo intercambio: ok se borra
  7 (F,P,55)  0.10 s -> (T,F,F,2,-)   eco erroneo: falla el intento 1
  8 (T,-,0)   0.10 s -> (T,F,F,2,-)   flanco de txReq durante el intercambio: se ignora
  9 (T,-,0)   0.50 s -> (T,F,F,3,-)   vence el intento 2
 10 (T,-,0)   0.40 s -> (F,F,T,3,-)   vence el intento 3: error
 11 (F,-,0)   0.30 s -> (F,F,T,3,-)   error permanece, nIntentos se conserva
 12 (T,-,0)   0.20 s -> (T,F,F,1,100) nuevo intercambio: error se borra
 13 (T,-,0)   0.20 s -> (T,F,F,1,-)   ~0.41-0.46 s del intento 1 (segun el ciclo)
 14 (T,P,100) 0.20 s -> (F,T,F,1,-)   eco al inicio del paso: dentro del plazo (plazo demasiado corto)
NOTA: la primera version usaba 0.25 s en el paso 13 y REPROBABA a la correcta con
ciclo de 20 ms (el eco llegaba a ~0.51 s): cada cambio de paso consume un scan.
Uso:  python validar_harness_A3.py
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
    PLAZO, MAX, ECO = 0.5, 3, True

    def __init__(self):
        self.txData, self.ocupado, self.ok, self.error, self.nIntentos = 0, False, False, False, 0
        self.prev, self.t = False, 0.0

    def iniciar(self):
        self.txData, self.ocupado, self.ok, self.error, self.nIntentos, self.t = 100, True, False, False, 1, 0.0

    def fallo(self):
        if self.nIntentos < self.MAX:
            self.nIntentos += 1
            self.t = 0.0
        else:
            self.error, self.ocupado = True, False

    def __call__(self, txReq, rxOk, rxData, dt):
        flanco = txReq and not self.prev
        self.prev = txReq
        if flanco and not self.ocupado:
            self.iniciar()
            return
        if self.ocupado:
            self.t += dt
            if rxOk and (rxData == self.txData or not self.ECO):
                self.ok, self.ocupado = True, False
            elif rxOk or self.t >= self.PLAZO:
                self.fallo()


class FBPlazoLargo(FBCorrecta):
    """DEFECTO: plazo de 1 s."""
    PLAZO = 1.0


class FBPlazoCorto(FBCorrecta):
    """DEFECTO: plazo de 300 ms."""
    PLAZO = 0.3


class FBSinEco(FBCorrecta):
    """DEFECTO: acepta cualquier rxData."""
    ECO = False


class FBCuatroIntentos(FBCorrecta):
    """DEFECTO: permite 4 intentos."""
    MAX = 4


class FBReiniciaPorTxReq(FBCorrecta):
    """DEFECTO: un flanco de txReq durante el intercambio lo reinicia."""
    def __call__(self, txReq, rxOk, rxData, dt):
        if txReq and not self.prev and self.ocupado:
            self.prev = txReq
            self.iniciar()
            return
        super().__call__(txReq, rxOk, rxData, dt)


class FBPlazoNoSeReinicia(FBCorrecta):
    """DEFECTO: el temporizador del plazo no se reinicia entre intentos."""
    def fallo(self):
        t = self.t
        super().fallo()
        self.t = t


class FBOkNoSeBorra(FBCorrecta):
    """DEFECTO: ok y error no se borran al iniciar un nuevo intercambio."""
    def iniciar(self):
        ok, err = self.ok, self.error
        super().iniciar()
        self.ok, self.error = ok, err


class FBIntentosSeBorran(FBCorrecta):
    """DEFECTO: nIntentos vuelve a 0 al terminar."""
    def __call__(self, txReq, rxOk, rxData, dt):
        super().__call__(txReq, rxOk, rxData, dt)
        if not self.ocupado:
            self.nIntentos = 0


# ------------------------------------------------------------ harness (traduccion fiel del .st)
N = None
#        txReq pulso rxData  dur    ocup  ok    err   n  txData
PASOS = [(0, 0, 0, 0.20, (0, 0, 0, N, N)),
         (1, 0, 0, 0.20, (1, 0, 0, 1, 100)),
         (0, 0, 0, 0.20, (1, 0, 0, 1, N)),
         (0, 0, 0, 0.25, (1, 0, 0, 2, N)),
         (0, 1, 100, 0.20, (0, 1, 0, 2, N)),
         (0, 0, 0, 0.30, (0, 1, 0, 2, N)),
         (1, 0, 0, 0.10, (1, 0, 0, 1, 100)),
         (0, 1, 55, 0.10, (1, 0, 0, 2, N)),
         (1, 0, 0, 0.10, (1, 0, 0, 2, N)),
         (1, 0, 0, 0.50, (1, 0, 0, 3, N)),
         (1, 0, 0, 0.40, (0, 0, 1, 3, N)),
         (0, 0, 0, 0.30, (0, 0, 1, 3, N)),
         (1, 0, 0, 0.20, (1, 0, 0, 1, 100)),
         (1, 0, 0, 0.20, (1, 0, 0, 1, N)),
         (1, 1, 100, 0.20, (0, 1, 0, 1, N))]
ULTIMO_PASO = len(PASOS) - 1


def correr_harness(fb, dt, limite_scans=1_000_000):
    paso, tPaso, pulsoReset, finalizado = 0, TON(), False, False
    cargado = -1
    pendiente = False
    resultado = [0] * (ULTIMO_PASO + 1)
    for _ in range(limite_scans):
        if not finalizado:
            tx, pul, dato, t, esp = PASOS[paso]
        if paso != cargado:
            pendiente = bool(pul)
            cargado = paso
        rxOk = pendiente and not finalizado
        pendiente = False
        qPaso = tPaso(not pulsoReset, t, dt)
        pulsoReset = False
        fb(bool(tx), rxOk, dato, dt)
        if qPaso and not finalizado:
            oc, ok_, er, n, txd = esp
            bien = (fb.ocupado == bool(oc) and fb.ok == bool(ok_) and fb.error == bool(er)
                    and (n is None or fb.nIntentos == n) and (txd is None or fb.txData == txd))
            resultado[paso] = 1 if bien else 2
            pulsoReset = True
            if paso < ULTIMO_PASO:
                paso += 1
            else:
                finalizado = True
        if finalizado:
            return (1 if all(x == 1 for x in resultado) else 2), resultado
    return 0, resultado


CASOS = [("Correcta", FBCorrecta, 1, None),
         ("PlazoCorto", FBPlazoCorto, 2, 2),
         ("PlazoLargo", FBPlazoLargo, 2, 3),
         ("PlazoNoSeReinicia", FBPlazoNoSeReinicia, 2, 3),
         ("IntentosSeBorran", FBIntentosSeBorran, 2, 4),
         ("OkNoSeBorra", FBOkNoSeBorra, 2, 6),
         ("SinEco", FBSinEco, 2, 7),
         ("ReiniciaPorTxReq", FBReiniciaPorTxReq, 2, 8),
         ("CuatroIntentos", FBCuatroIntentos, 2, 10)]


def main():
    todo_ok = True
    print("VALIDACION DEL HARNESS PRG_Test_A3")
    for nombre, cls, esp, paso in CASOS:
        vec = set()
        for dt in (0.004, 0.010, 0.020):
            v, r = correr_harness(cls(), dt)
            ok = v == esp and (paso is None or (r[paso] == 2 and 2 not in r[:paso]))
            todo_ok &= ok
            vec.add(tuple(r))
            print("%-18s %2d ms  v=%d  %s  %s" % (nombre, int(dt * 1000), v, r, "ok" if ok else "NO"))
        todo_ok &= len(vec) == 1
    print("Discrimina y es independiente del ciclo:", "SI" if todo_ok else "NO")
    return todo_ok


if __name__ == "__main__":
    main()
