"""
Validacion del harness PRG_Test_A5 (FB_Registro: eventos en buffer circular) por
simulacion del ciclo de scan.

Enunciado (tasks.json v1, A5): tiempo acumulado = suma de 'ciclo' en cada
ejecucion; en cada flanco de nuevoEvento registra (evento, tiempo acumulado) en
buffer: ARRAY[0..19] OF ST_Evento; el primero en la posicion 0, luego
consecutivos; lleno, sobrescribe el mas antiguo; indice = posicion del ultimo
(-1 sin eventos); nEventos = posiciones validas (0..20).

TIEMPO VIRTUAL: ciclo := T#10MS fijo y pasos por NUMERO DE LLAMADAS. El banco
cuenta sus llamadas (g); para el ultimo evento registrado acepta
marca = g*10 ms o (g-1)*10 ms, porque el enunciado no fija si el tiempo se
acumula antes o despues de registrar en la misma ejecucion.
Cada evento ocupa 2 llamadas: nuevoEvento TRUE y luego FALSE.

Paso: llamadas/eventos -> (indice, nEventos, comprobacion de contenido)
  0 5 llamadas sin evento ..................... (-1, 0)
  1 evento 11 con nuevoEvento sostenido 3 llamadas (0, 1)  buffer[0]=11 + marca
  2 2 llamadas sin flanco ..................... (0, 1)
  3 19 eventos (12..30) ....................... (19, 20) buffer[19]=30 + marca; buffer[0]=11
  4 1 evento (31): sobrescribe el mas antiguo . (0, 20)  buffer[0]=31 + marca; buffer[1]=12
  5 2 eventos (32, 33) ........................ (2, 20)  buffer[2]=33 + marca; buffer[3]=14
Uso:  python validar_harness_A5.py
"""
CICLO_MS = 10


class FBCorrecta:
    ACUM_ANTES = True

    def __init__(self):
        self.buffer = [[0, 0] for _ in range(20)]
        self.indice, self.nEventos = -1, 0
        self.t, self.prev = 0, False

    def siguiente(self):
        return (self.indice + 1) % 20

    def registrar(self, evento):
        self.indice = self.siguiente()
        self.buffer[self.indice] = [evento, self.t]
        self.nEventos = min(20, self.nEventos + 1)

    def flanco(self, nuevo):
        f = nuevo and not self.prev
        self.prev = nuevo
        return f

    def __call__(self, evento, nuevoEvento, ciclo_ms):
        if self.ACUM_ANTES:
            self.t += ciclo_ms
        if self.flanco(nuevoEvento):
            self.registrar(evento)
        if not self.ACUM_ANTES:
            self.t += ciclo_ms


class FBCorrectaAcumDespues(FBCorrecta):
    """Correcta: acumula el tiempo despues de registrar (marca = (g-1)*ciclo)."""
    ACUM_ANTES = False


class FBIndiceInicialCero(FBCorrecta):
    """DEFECTO: indice vale 0 antes del primer evento."""
    def __init__(self):
        super().__init__()
        self.indice, self.vacio = 0, True

    def siguiente(self):
        if self.vacio:
            self.vacio = False
            return 0
        return (self.indice + 1) % 20


class FBCuentaPorNivel(FBCorrecta):
    """DEFECTO: registra en cada ejecucion con nuevoEvento activo."""
    def flanco(self, nuevo):
        return nuevo


class FBMarcaSinAcumular(FBCorrecta):
    """DEFECTO: la marca es 'ciclo', no el tiempo acumulado."""
    def registrar(self, evento):
        super().registrar(evento)
        self.buffer[self.indice][1] = CICLO_MS


class FBPrimeroEnPosicion1(FBCorrecta):
    """DEFECTO: incrementa antes desde 0: el primer evento cae en la posicion 1."""
    def __init__(self):
        super().__init__()
        self.indice = 0

    def __call__(self, evento, nuevoEvento, ciclo_ms):
        super().__call__(evento, nuevoEvento, ciclo_ms)


class FBSinSobrescritura(FBCorrecta):
    """DEFECTO: con el arreglo lleno deja de registrar."""
    def registrar(self, evento):
        if self.nEventos < 20:
            super().registrar(evento)


class FBNEventosSinTope(FBCorrecta):
    """DEFECTO: nEventos sigue creciendo por encima de 20."""
    def registrar(self, evento):
        super().registrar(evento)
        self.nEventos = self._n = getattr(self, "_n", 0) + 1


class FBVueltaAPosicion1(FBCorrecta):
    """DEFECTO: al llegar al final vuelve a la posicion 1 en lugar de 0."""
    def siguiente(self):
        return self.indice + 1 if self.indice < 19 else 1


# ------------------------------------------------------------ harness (traduccion fiel del .st)
# (eventos, llamadas_sin_evento, sostenido, primer_codigo, indice, n, pos_marca, cod_marca, pos2, cod2)
PASOS = [(0, 5, 0, 0, -1, 0, -1, 0, -1, 0),
         (1, 0, 3, 11, 0, 1, 0, 11, -1, 0),
         (0, 2, 0, 0, 0, 1, -1, 0, -1, 0),
         (19, 0, 0, 12, 19, 20, 19, 30, 0, 11),
         (1, 0, 0, 31, 0, 20, 0, 31, 1, 12),
         (2, 0, 0, 32, 2, 20, 2, 33, 3, 14)]
ULTIMO_PASO = len(PASOS) - 1


def llamadas_del_paso(p):
    """Secuencia (evento, nuevoEvento) del paso."""
    nev, libres, sost, cod0 = p[0], p[1], p[2], p[3]
    seq = []
    if sost:
        seq += [(cod0, True)] * sost
    else:
        for j in range(nev):
            seq += [(cod0 + j, True), (cod0 + j, False)]
    seq += [(0, False)] * libres
    return seq


def correr_harness(fb, dt=None):
    resultado = [0] * (ULTIMO_PASO + 1)
    g, gUlt = 0, 0
    for paso, p in enumerate(PASOS):
        prevNuevo = False
        for ev, nuevo in llamadas_del_paso(p):
            g += 1
            fb(ev, nuevo, CICLO_MS)
            if nuevo and not prevNuevo:
                gUlt = g
            prevNuevo = nuevo
        _, _, _, _, idx, n, pm, cm, p2, c2 = p
        ok = fb.indice == idx and fb.nEventos == n
        if pm >= 0:
            ok = ok and fb.buffer[pm][0] == cm and fb.buffer[pm][1] in (gUlt * CICLO_MS, (gUlt - 1) * CICLO_MS)
        if p2 >= 0:
            ok = ok and fb.buffer[p2][0] == c2
        resultado[paso] = 1 if ok else 2
    return (1 if all(x == 1 for x in resultado) else 2), resultado


CASOS = [("Correcta", FBCorrecta, 1, None),
         ("CorrectaAcumDespues", FBCorrectaAcumDespues, 1, None),
         ("IndiceInicialCero", FBIndiceInicialCero, 2, 0),
         ("CuentaPorNivel", FBCuentaPorNivel, 2, 1),
         ("MarcaSinAcumular", FBMarcaSinAcumular, 2, 1),
         ("PrimeroEnPosicion1", FBPrimeroEnPosicion1, 2, 0),
         ("SinSobrescritura", FBSinSobrescritura, 2, 4),
         ("NEventosSinTope", FBNEventosSinTope, 2, 4),
         ("VueltaAPosicion1", FBVueltaAPosicion1, 2, 4)]


def main():
    todo_ok = True
    print("VALIDACION DEL HARNESS PRG_Test_A5 (tiempo virtual)")
    for nombre, cls, esp, paso in CASOS:
        v, r = correr_harness(cls())
        ok = v == esp and (paso is None or (r[paso] == 2 and 2 not in r[:paso]))
        todo_ok &= ok
        print("%-20s v=%d  %s  %s" % (nombre, v, r, "ok" if ok else "NO"))
    print("Discrimina:", "SI" if todo_ok else "NO")
    return todo_ok


if __name__ == "__main__":
    main()
