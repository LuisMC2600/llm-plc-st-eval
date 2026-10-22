# -*- coding: utf-8 -*-
"""
Prepara dos proyectos de CODESYS para las capturas del IDE (Apendice A.3 de la tesis).
Ejecutar DENTRO de CODESYS V3.5 SP22 Patch 3: Herramientas > Scripting > Ejecutar archivo de script.
IronPython 2.7 (sin f-strings).

Para cada caso: copia Plantilla_Simulacion.project (la original NO se abre ni se modifica)
a evidencias/codesys_ide/, importa la respuesta del modelo y su harness con las mismas
funciones de simular_lote_sp22.py, agrega el harness a la MainTask (10 ms), activa el
modo simulacion y guarda. No modifica el texto de ninguna respuesta ni de ningun harness.
Despues abre el caso que pasa para empezar las capturas.
"""
import os
import shutil

AQUI = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()
RAIZ = os.path.dirname(AQUI)
DESTINO = os.path.join(RAIZ, "evidencias", "codesys_ide")
PLANTILLA = os.path.join(AQUI, "Plantilla_Simulacion.project")
CODIGO = os.path.join(RAIZ, "data", "processed_definitivo")

CASOS = [  # (archivo de proyecto, modelo, tarea, estrategia, ejecucion)
    ("Captura_B1_gemini_pasa.project", "gemini-3.1-pro-preview", "B1", "zero_shot", "ejec_1"),
    ("Captura_A2_qwen_no_compila.project", "qwen2.5-coder_14b", "A2", "zero_shot", "ejec_1"),
]

# Reutiliza importar(), elegir_harness() y leer() de simular_lote_sp22.py sin ejecutar su lote.
fuente = open(os.path.join(AQUI, "simular_lote_sp22.py"), "rb").read().decode("utf-8")
fuente = fuente.replace("if EN_CODESYS:\n    principal()", "").replace("if EN_CODESYS:\r\n    principal()", "")
exec(compile(fuente, "simular_lote_sp22.py", "exec"))

if not os.path.isdir(DESTINO):
    os.makedirs(DESTINO)
creados = []
for archivo, modelo, tarea, estr, ejec in CASOS:
    destino = os.path.join(DESTINO, archivo)
    if os.path.exists(destino):
        system.write_message(Severity.Warning, "Ya existe %s; no se sobrescribe." % archivo)
        creados.append(destino)
        continue
    shutil.copyfile(PLANTILLA, destino)
    proyecto = projects.open(destino)
    try:
        app = proyecto.active_application
        app.find("MainTask", True)[0].interval = "t#10ms"
        r = {"nota": "", "pou": ""}
        texto_fb = leer(os.path.join(CODIGO, modelo, tarea, estr, ejec + ".st"))
        texto_h = elegir_harness(AQUI, HARNESS_DE.get(tarea, tarea), importar(app, texto_fb), r)
        importar(app, texto_h)
        app.find("MainTask", True)[0].pous.add("PRG_Test_%s" % HARNESS_DE.get(tarea, tarea))
        proyecto.find("Device", True)[0].set_simulation_mode(True)
        proyecto.save()
        system.write_message(Severity.Information, "Preparado %s (%s %s %s %s) %s" % (archivo, modelo, tarea, estr, ejec, r["nota"]))
        creados.append(destino)
    finally:
        proyecto.close()

projects.open(creados[0])
system.write_message(Severity.Information, "Listo. Abierto: %s" % os.path.basename(creados[0]))
