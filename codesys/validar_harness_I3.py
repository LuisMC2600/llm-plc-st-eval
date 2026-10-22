"""
Validacion del harness PRG_Test_I3 por simulacion del ciclo de scan.

I3 (gestion de alarmas con prioridad). La regla mas delicada del enunciado es
que "el reconocimiento solo tiene efecto si la causa ya desaparecio", y
ENMIENDAS_HARNESSES.md la aprueba explicitamente en su lista de pasos:
"I3: ACK con la causa todavia presente (no debe borrar) y ACK tras retirarla
(si debe)". Aqui se comprueba si la secuencia realmente la ejercita.

Uso:  python validar_harness_I3.py
"""

from dataclasses import dataclass, field


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
    """Retencion individual; el ACK solo borra si la causa ya desaparecio;
    codigoAlm reporta la de mayor prioridad presente."""
    sirena: bool = False
    codigoAlm: int = 0
    _lat: list = field(default_factory=lambda: [False, False, False])

    def __call__(self, a1, a2, a3, k1, k2, k3, dt):
        alm, ack = [a1, a2, a3], [k1, k2, k3]
        for i in range(3):
            if alm[i]:
                self._lat[i] = True
            elif ack[i]:
                self._lat[i] = False
        self.sirena = any(self._lat)
        self.codigoAlm = next((i + 1 for i in range(3) if self._lat[i]), 0)


@dataclass
class FBAckIncondicional(FBCorrecto):
    """DEFECTO: el ACK borra la alarma AUNQUE la causa siga presente. Es la
    violacion directa de la regla del enunciado."""

    def __call__(self, a1, a2, a3, k1, k2, k3, dt):
        alm, ack = [a1, a2, a3], [k1, k2, k3]
        for i in range(3):
            if alm[i]:
                self._lat[i] = True
            if ack[i]:
                self._lat[i] = False       # borra sin comprobar la causa
        self.sirena = any(self._lat)
        self.codigoAlm = next((i + 1 for i in range(3) if self._lat[i]), 0)


@dataclass
class FBSinRetencion(FBCorrecto):
    """DEFECTO: no hay memoria de alarma; sigue a la causa."""

    def __call__(self, a1, a2, a3, k1, k2, k3, dt):
        alm = [a1, a2, a3]
        self.sirena = any(alm)
        self.codigoAlm = next((i + 1 for i in range(3) if alm[i]), 0)


@dataclass
class FBPrioridadInvertida(FBCorrecto):
    """DEFECTO: reporta la alarma de MENOR prioridad presente."""

    def __call__(self, a1, a2, a3, k1, k2, k3, dt):
        FBCorrecto.__call__(self, a1, a2, a3, k1, k2, k3, dt)
        self.codigoAlm = next((i + 1 for i in reversed(range(3)) if self._lat[i]), 0)


@dataclass
class FBSirenaSoloConCausa(FBCorrecto):
    """DEFECTO: la sirena sigue a la causa aunque la alarma siga retenida."""

    def __call__(self, a1, a2, a3, k1, k2, k3, dt):
        FBCorrecto.__call__(self, a1, a2, a3, k1, k2, k3, dt)
        self.sirena = any([a1, a2, a3])


# --------------------------------------------------------------------------
# Harness PRG_Test_I3 corregido (traduccion fiel del .st, enmienda 12)
# --------------------------------------------------------------------------
T_ASENT = 0.150
# (alm1,alm2,alm3, ack1,ack2,ack3, espSirena, espCodigo) -- None conserva
PASOS = [
    (False, False, False, True,  True,  True,  False, 0),
    (None,  None,  True,  False, False, False, True,  3),
    (None,  None,  None,  None,  None,  True,  True,  3),   # ACK CON CAUSA PRESENTE
    (None,  None,  False, None,  None,  False, True,  3),   # retencion tras retirarla
    (None,  None,  None,  None,  None,  True,  False, 0),   # ACK sin causa: si borra
    (None,  True,  True,  None,  None,  False, True,  2),
    (True,  None,  None,  None,  None,  None,  True,  1),   # prioridad alta
    (False, None,  None,  True,  None,  None,  True,  2),
    (None,  False, None,  None,  True,  None,  True,  3),
    (None,  None,  False, None,  None,  True,  False, 0),
]


def correr_harness(fb, dt: float, pasos=None, limite_scans: int = 1_000_000,
                   traza=False):
    pasos = pasos or PASOS
    ultimo = len(pasos) - 1
    a = [False, False, False]
    k = [False, False, False]
    espSirena, espCodigo = False, 0
    paso = 0
    tPaso = TON()
    pulsoReset = False
    finalizado = False
    resultado = [0] * (ultimo + 1)
    veredicto = 0

    for _ in range(limite_scans):
        tPaso(not pulsoReset, T_ASENT, dt)
        pulsoReset = False

        if not finalizado:
            v = pasos[paso]
            for i in range(3):
                if v[i] is not None:
                    a[i] = v[i]
                if v[3 + i] is not None:
                    k[i] = v[3 + i]
            espSirena, espCodigo = v[6], v[7]

        fb(a[0], a[1], a[2], k[0], k[1], k[2], dt)

        if tPaso.q and not finalizado:
            ok = (fb.sirena == espSirena) and (fb.codigoAlm == espCodigo)
            resultado[paso] = 1 if ok else 2
            if traza:
                print(f"    paso {paso}: sirena={int(fb.sirena)} codigo={fb.codigoAlm} "
                      f"(esperado {int(espSirena)} {espCodigo}) -> {resultado[paso]}")
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
        ("Defecto: ACK borra con causa presente", FBAckIncondicional, 2, 2),
        ("Defecto: sin retencion de alarma", FBSinRetencion, 2, 3),
        ("Defecto: prioridad invertida", FBPrioridadInvertida, 2, 6),
        ("Defecto: sirena solo con causa", FBSirenaSoloConCausa, 2, 3),
    ]
    ciclos = [0.004, 0.010, 0.020]

    print("VALIDACION DEL HARNESS PRG_Test_I3")
    print(f"Duracion nominal de la secuencia: {len(PASOS)*T_ASENT:.1f} s")
    print("=" * 90)
    print(f"{'implementacion':40}{'ciclo':8}{'ver.':6}{'pasos':28}{'ok'}")
    print("-" * 90)

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
            print(f"{nombre:40}{int(dt*1000):>3} ms  {v:^6}{str(r):28}{'si' if ok else 'NO'}")
        print("-" * 90)

    if fallos:
        print("\nCasos que NO discriminan:")
        for nombre, cls, dt in fallos[:1]:
            print(f"  {nombre} @ {int(dt*1000)} ms")
            correr_harness(cls(), dt, traza=True)
    print(f"\nDiscrimina correctamente en los 3 ciclos de tarea: {'SI' if todo_ok else 'NO'}")
    raise SystemExit(0 if todo_ok else 1)


if __name__ == "__main__":
    main()
