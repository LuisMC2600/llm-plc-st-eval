import json, csv, glob, statistics as st
from collections import defaultdict
U="/mnt/user-data/uploads/1 Trabajo de Grado/llm-plc-st-eval/"
mapr={r['codigo']:r for r in csv.DictReader(open(U+"evaluacion_rubrica/_SELLADO_asignacion_rubrica.csv",encoding='utf-8-sig'))}
mapd={r['codigo']:r for r in csv.DictReader(open(U+"evaluacion_manual/_SELLADO_asignacion_codigos.csv",encoding='utf-8-sig'))}
K=["coherencia","claridad","mantenibilidad","funcional","iec"]
short=lambda m:{'gemini-3.1-pro-preview':'Gemini','claude-sonnet-4-6':'Claude','gpt-4o-2024-08-06':'GPT-4o','qwen2.5-coder_14b':'Qwen','qwen2.5-coder:14b':'Qwen'}.get(m,m)
def load(d):
    out={}
    for f in glob.glob(d+'/rub_*.json'):
        for x in json.load(open(f)): out[x['codigo']]=x
    return out
C=load('salida'); D=load('salida_ds')
agg=defaultdict(lambda: defaultdict(list))
for c,r in mapr.items():
    m=short(r['modelo'])
    for k in K:
        agg[(m,'Claude-eval')][k].append(C[c][k]); agg[(m,'DS-eval')][k].append(D[c][k])
    agg[(m,'Claude-eval')]['total'].append(sum(C[c][k] for k in K)); agg[(m,'DS-eval')]['total'].append(sum(D[c][k] for k in K))
print("Medias por modelo evaluado (rúbrica, 150 resp. c/u)")
print(f"{'modelo':8} {'evaluador':12} "+" ".join(f"{k[:6]:>7}" for k in K+['total']))
for m in ['Gemini','Claude','GPT-4o','Qwen']:
    for e in ['Claude-eval','DS-eval']:
        print(f"{m:8} {e:12} "+" ".join(f"{st.mean(agg[(m,e)][k]):7.2f}" for k in K+['total']))
print("\nDiferencia DS − Claude por modelo (criterios 3–5):")
for m in ['Gemini','Claude','GPT-4o','Qwen']:
    print(m, " ".join(f"{k[:6]} {st.mean(agg[(m,'DS-eval')][k])-st.mean(agg[(m,'Claude-eval')][k]):+.2f}" for k in K[:3]))
# ranking
for e in ['Claude-eval','DS-eval']:
    rk=sorted(['Gemini','Claude','GPT-4o','Qwen'],key=lambda m:-st.mean(agg[(m,e)]['total']))
    print(e,'ranking total:',rk)
# diag per model
def loadd(d):
    out={}
    for t in ['C1','C5','C6']:
        for x in json.load(open(f'{d}/diag_{t}.json')): out[x['codigo']]=x
    return out
CD=loadd('salida'); DD=loadd('salida_ds')
print("\nDiagnóstico C1/C5/C6: detecciones medias (0–4) / inventados medios por modelo")
for m in ['Gemini','Claude','GPT-4o','Qwen']:
    cs=[c for c,r in mapd.items() if short(r['modelo'])==m and c in CD]
    f=lambda S,c:sum(v=='S' for v in S[c]['det'])
    print(f"{m:8} Claude-eval det {st.mean(f(CD,c) for c in cs):.2f} inv {st.mean(CD[c]['inv'] for c in cs):.2f} | DS-eval det {st.mean(f(DD,c) for c in cs):.2f} inv {st.mean(DD[c]['inv'] for c in cs):.2f}")
