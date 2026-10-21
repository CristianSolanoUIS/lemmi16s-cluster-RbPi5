"""Concordancia taxonómica mononodo vs multinodo (mismas muestras, mismo nodo tipo Raspberry Pi 5).
1) Igualdad exacta del archivo de predicciones (equivale a diff -u sin diferencias).
2) Si no son idénticos: comparación por familia y género (taxones detectados y abundancia relativa).
"""
import csv, glob, os, re, hashlib
from collections import defaultdict

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))  # Libro_Proyecto_Grado
BASE = os.path.join(RAIZ, 'datos_energia', 'cluster_rpi5_mononodo')
SALIDA = os.path.join(RAIZ, 'resultados', 'comparaciones')
# LotuS3: corrida PacBio de 5 muestras (VSEARCH) en su propia subcarpeta
SUB = {'lotus3': 'pacbio_5muestras'}


def leer(f):
    filas = []
    with open(f, encoding='utf-8') as fh:
        for linea in fh:
            if linea.startswith('#') or linea.startswith('Group_ID'):
                continue
            g, size, tax = linea.rstrip('\n').split('\t')[:3]
            filas.append((float(size), tax))
    return filas


def por_rango(filas, rango):
    tot = sum(s for s, _ in filas)
    ab = defaultdict(float)
    for s, tax in filas:
        m = re.search(rango + r'__([^;]*)', tax)
        nombre = m.group(1) if m and m.group(1) not in ('', 'na') else None
        if nombre:
            ab[nombre] += s / tot
    return ab


salida = []
for p in ['kraken2', 'lotus3', 'qiime2']:
    for fm in sorted(glob.glob(os.path.join(BASE, p, SUB.get(p, ''), 'predicciones_multinodo', '*.tsv'))):
        muestra = fm.split('-')[-1].split('.')[0]
        fo = glob.glob(os.path.join(BASE, p, SUB.get(p, ''), 'predicciones', f'*-{muestra}.*predictions.tsv'))[0]
        same = hashlib.md5(open(fm, 'rb').read()).digest() == hashlib.md5(open(fo, 'rb').read()).digest()
        fila = [p, muestra, 'idéntico' if same else 'distinto']
        if not same:
            a, b = leer(fm), leer(fo)
            for r in ('f', 'g'):
                A, Bb = por_rango(a, r), por_rango(b, r)
                comunes = set(A) & set(Bb)
                solo = sorted((set(A) ^ set(Bb)))
                dif = max(abs(A.get(t, 0) - Bb.get(t, 0)) for t in set(A) | set(Bb)) * 100
                fila += [f"{'fam' if r == 'f' else 'gen'}: {len(A)} vs {len(Bb)} taxones, comunes {len(comunes)}, "
                         f"solo en uno {solo if solo else 'ninguno'}, máx dif abundancia {dif:.2f} pp"]
        salida.append(fila)
        print(' | '.join(fila))

with open(os.path.join(SALIDA, 'concordancia_mononodo_vs_multinodo.txt'), 'w', encoding='utf-8') as fh:
    for f in salida:
        fh.write(' | '.join(f) + '\n')
