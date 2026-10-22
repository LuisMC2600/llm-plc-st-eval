# -*- coding: utf-8 -*-
"""Sensibilidad S2 (INC-34): copia las respuestas marcadas con `caso_end_struct` en
data/results/tabla_definitivo.csv a data/processed_sens_endstruct/ quitando UNICAMENTE el
punto y coma que sigue a END_STRUCT (forma del estandar IEC que CODESYS no acepta).
No toca data/definitivo ni data/processed_definitivo. Deja un manifiesto con el cambio exacto."""
import csv, os, re, hashlib
ORIG, DEST = "data/processed_definitivo", "data/processed_sens_endstruct"
RE = re.compile(r"(?im)^([ \t]*END_STRUCT)[ \t]*;")
filas = [r for r in csv.DictReader(open("data/results/tabla_definitivo.csv", encoding="utf-8-sig")) if r["caso_end_struct"] == "1"]
man = []
for r in filas:
    rel = os.path.join(r["modelo"], r["tarea"], r["estrategia"], r["ejec"] + ".st")
    txt = open(os.path.join(ORIG, rel), encoding="utf-8").read()
    nuevo, n = RE.subn(r"\1", txt)
    assert n >= 1 and len(txt) - len(nuevo) == n, rel   # solo se elimina un caracter por coincidencia
    os.makedirs(os.path.dirname(os.path.join(DEST, rel)), exist_ok=True)
    open(os.path.join(DEST, rel), "w", encoding="utf-8", newline="").write(nuevo)
    man.append({"archivo": rel.replace(os.sep, "/"), "sustituciones": n, "caracteres_eliminados": len(txt) - len(nuevo),
                "sha256_original": hashlib.sha256(txt.encode("utf-8")).hexdigest()[:16],
                "sha256_normalizado": hashlib.sha256(nuevo.encode("utf-8")).hexdigest()[:16]})
with open(os.path.join(DEST, "manifiesto_normalizacion.csv"), "w", newline="", encoding="utf-8-sig") as fh:
    w = csv.DictWriter(fh, fieldnames=list(man[0].keys())); w.writeheader(); w.writerows(man)
print("Normalizadas: %d" % len(man))
for m in man: print(" ", m["archivo"], m["sustituciones"], m["caracteres_eliminados"])
