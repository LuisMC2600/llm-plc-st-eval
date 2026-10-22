"""
Validacion del harness PRG_Test_I8 (FB_Compresor: permisivos de arranque) por
simulacion del ciclo de scan.

Enunciado (tasks.json v1, I8): arranque por FLANCO de btnMarcha y enclavamiento,
solo si EN ESE INSTANTE se cumplen los permisivos (pOilOk 3 s continuos, tempOk,
sinAlm); paro con btnParo o perdida de cualquier permisivo; sin rearranque
automatico; btnParo prioritario; causaBloqueo en todo momento: 1 aceite,
2 temperatura, 3 alarma, 0 ninguno; si faltan varios, el de numero menor.

Paso: entradas (pOil,temp,sinAlm,marcha,paro), duracion -> (comp, causa)
  0 (F,F,F,F,F) 0.2 s -> (F,1)   reposo, faltan todos: reporta el menor
  1 (T,T,T,F,F) 1.0 s -> (F,1)   aceite aun sin 3 s continuos
  2 (T,T,T,F,F) 2.5 s -> (F,0)   permisivos completos: NO arranca solo
  3 (T,T,T,T,F) 0.2 s -> (T,0)   flanco de marcha
  4 (T,T,T,F,F) 0.2 s -> (T,0)   enclavado
  5 (T,F,T,F,F) 0.2 s -> (F,2)   pierde temperatura
  6 (T,T,T,F,F) 0.5 s -> (F,0)   se recupera: sin rearranque automatico
  7 (T,T,T,T,T) 0.2 s -> (F,0)   marcha y paro a la vez: prioridad del paro
  8 (T,T,T,T,F) 0.2 s -> (F,0)   se suelta el paro con marcha sostenida: sin flanco no arranca
  9 (T,T,T,F,F) 0.2 s -> (F,0)
 10 (T,T,T,T,F) 0.2 s -> (T,0)
 11 (T,T,F,F,F) 0.2 s -> (F,3)   alarma
 12 (F,F,F,F,F) 0.2 s -> (F,1)   faltan todos
 13 (T,T,T,T,F) 0.5 s -> (F,1)   pulsa con el aceite aun temporizando (reiniciado)
 14 (T,T,T,T,F) 3.0 s -> (F,0)   llegan los permisivos con marcha sostenida: no arranca
 15 (T,T,T,F,F) 0.2 s -> (F,0)
 16 (T,T,T,T,F) 0.2 s -> (T,0)
 17 (F,T,T,T,F) 0.2 s -> (F,1)   perdida momentanea de aceite: se detiene
 18 (T,T,T,F,F) 0.2 s -> (F,1)   el aceite vuelve pero no lleva 3 s

VIGILANCIA CONTINUA (patron de la enmienda 4, banderas enclavadas): en los pasos
en que comp llega en FALSE y debe seguir en FALSE todo el paso (0,1,2,6,7,8,9,
12,13,14,15,18), un solo scan con comp=TRUE reprueba el paso. Sin ella, la
validacion mostro que "marcha gana al paro" pasaba inadvertido: el compresor
arrancaba UN scan en el paso 7 y se apagaba antes del muestreo.
Uso:  python validar_harness_I8.py
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
    def __init__(self):
        self.comp, self.causaBloqueo = False, 0
        self.tOil, self.prev = TON(), False

    def aceite(self, pOil, dt):
        return self.tOil(pOil, 3.0, dt)

    def causa(self, oil, temp, sinAlm):
        return 1 if not oil else 2 if not temp else 3 if not sinAlm else 0

    def __call__(self, pOil, temp, sinAlm, marcha, paro, dt):
        oil = self.aceite(pOil, dt)
        self.causaBloqueo = self.causa(oil, temp, sinAlm)
        perm = self.causaBloqueo == 0
        flanco = marcha and not self.prev
        self.prev = marcha
        self.logica(perm, flanco, marcha, paro)

    def logica(self, perm, flanco, marcha, paro):
        if paro or not perm:
            self.comp = False
        elif flanco:
            self.comp = True


class FBArrancaPorNivel(FBCorrecta):
    """DEFECTO: arranca con el nivel de btnMarcha, no con el flanco."""
    def logica(self, perm, flanco, marcha, paro):
        self.comp = (self.comp or marcha) and perm and not paro


class FBRearranqueAutomatico(FBCorrecta):
    """DEFECTO: los permisivos solo condicionan la salida; el enclavamiento sobrevive."""
    def __init__(self):
        super().__init__()
        self.lat = False

    def logica(self, perm, flanco, marcha, paro):
        self.lat = (self.lat or flanco) and not paro
        self.comp = self.lat and perm


class FBSinTemporizacionAceite(FBCorrecta):
    """DEFECTO: pOilOk se toma instantaneo, sin los 3 s continuos."""
    def aceite(self, pOil, dt):
        return pOil


class FBMarchaPrioritaria(FBCorrecta):
    """DEFECTO: el flanco de marcha gana al paro."""
    def logica(self, perm, flanco, marcha, paro):
        if flanco and perm:
            self.comp = True
        elif paro or not perm:
            self.comp = False


class FBCausaPrioridadInvertida(FBCorrecta):
    """DEFECTO: con varios permisivos ausentes reporta el de numero mayor."""
    def causa(self, oil, temp, sinAlm):
        return 3 if not sinAlm else 2 if not temp else 1 if not oil else 0


class FBAceiteNoContinuo(FBCorrecta):
    """DEFECTO: una vez cumplidos los 3 s, el permisivo de aceite queda enclavado."""
    def __init__(self):
        super().__init__()
        self.oilLat = False

    def aceite(self, pOil, dt):
        self.oilLat = self.oilLat or self.tOil(pOil, 3.0, dt)
        return self.oilLat


class FBPeticionMemorizada(FBCorrecta):
    """DEFECTO: memoriza la pulsacion hecha con permisivos ausentes y arranca al cumplirse."""
    def __init__(self):
        super().__init__()
        self.pet = False

    def logica(self, perm, flanco, marcha, paro):
        self.pet = (self.pet or flanco) and not paro
        if paro or (self.comp and not perm):
            self.comp, self.pet = False, False
        elif self.pet and perm:
            self.comp = True


# ------------------------------------------------------------ harness (traduccion fiel del .st)
PASOS = [((0, 0, 0, 0, 0), 0.2, (0, 1)), ((1, 1, 1, 0, 0), 1.0, (0, 1)), ((1, 1, 1, 0, 0), 2.5, (0, 0)),
         ((1, 1, 1, 1, 0), 0.2, (1, 0)), ((1, 1, 1, 0, 0), 0.2, (1, 0)), ((1, 0, 1, 0, 0), 0.2, (0, 2)),
         ((1, 1, 1, 0, 0), 0.5, (0, 0)), ((1, 1, 1, 1, 1), 0.2, (0, 0)), ((1, 1, 1, 1, 0), 0.2, (0, 0)),
         ((1, 1, 1, 0, 0), 0.2, (0, 0)), ((1, 1, 1, 1, 0), 0.2, (1, 0)), ((1, 1, 0, 0, 0), 0.2, (0, 3)),
         ((0, 0, 0, 0, 0), 0.2, (0, 1)), ((1, 1, 1, 1, 0), 0.5, (0, 1)), ((1, 1, 1, 1, 0), 3.0, (0, 0)),
         ((1, 1, 1, 0, 0), 0.2, (0, 0)), ((1, 1, 1, 1, 0), 0.2, (1, 0)), ((0, 1, 1, 1, 0), 0.2, (0, 1)),
         ((1, 1, 1, 0, 0), 0.2, (0, 1))]
ULTIMO_PASO = len(PASOS) - 1
VIGILADOS = (0, 1, 2, 6, 7, 8, 9, 12, 13, 14, 15, 18)


def correr_harness(fb, dt, limite_scans=2_000_000):
    paso, tPaso, pulsoReset, finalizado = 0, TON(), False, False
    resultado = [0] * (ULTIMO_PASO + 1)
    ent, t, esp = PASOS[0]
    violacion = False
    for _ in range(limite_scans):
        if not finalizado:
            ent, t, esp = PASOS[paso]
        qPaso = tPaso(not pulsoReset, t, dt)
        pulsoReset = False
        fb(*[bool(x) for x in ent], dt)
        if paso in VIGILADOS and fb.comp and not finalizado:
            violacion = True
        if qPaso and not finalizado:
            resultado[paso] = 1 if ((int(fb.comp), fb.causaBloqueo) == esp and not violacion) else 2
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
         ("SinTemporizacionAceite", FBSinTemporizacionAceite, 2, 1),
         ("RearranqueAutomatico", FBRearranqueAutomatico, 2, 6),
         ("MarchaPrioritaria", FBMarchaPrioritaria, 2, 7),
         ("ArrancaPorNivel", FBArrancaPorNivel, 2, 8),
         ("CausaPrioridadInvertida", FBCausaPrioridadInvertida, 2, 0),
         ("AceiteNoContinuo", FBAceiteNoContinuo, 2, 12),
         ("PeticionMemorizada", FBPeticionMemorizada, 2, 14)]


def main():
    todo_ok = True
    print("VALIDACION DEL HARNESS PRG_Test_I8")
    for nombre, cls, esp, paso in CASOS:
        vec = set()
        for dt in (0.004, 0.010, 0.020):
            v, r = correr_harness(cls(), dt)
            ok = v == esp and (paso is None or (r[paso] == 2 and 2 not in r[:paso]))
            todo_ok &= ok
            vec.add(tuple(r))
            print("%-24s %2d ms  v=%d  %s  %s" % (nombre, int(dt * 1000), v, r, "ok" if ok else "NO"))
        todo_ok &= len(vec) == 1
    print("Discrimina y es independiente del ciclo:", "SI" if todo_ok else "NO")
    return todo_ok


if __name__ == "__main__":
    main()
