"""F1 de Kraken 2 y QIIME 2 (predicciones del libro, 2026-09-29) con la logica de LEMMI de compute_f1_pacbio.py,
pero con la verdad de CADA muestra; tambien la variante 'bug' (verdad de e001 para todas), como el eval.smk de LEMMI v1."""
import importlib.util, glob, sys
import numpy as np

B = '/home/zamir/proyecto_grado/lemmi16s/benchmark'
spec = importlib.util.spec_from_file_location('f', f'{B}/tmp/compute_f1_pacbio.py')
f = importlib.util.module_from_spec(spec); spec.loader.exec_module(f)

CASOS = [
    ('Kraken 2', 'HOMD_v4_GTDB_500k', 'kraken2', 'GTDB', 'yes'),
    ('QIIME 2', 'alfa_v1v2_SILVA', 'qiime2', 'SILVA', 'no'),
]
for nombre, inst, carpeta, db, gcnn in CASOS:
    gcn = f.GCN_reference(f'{B}/repository/{db}/GCN_ref.tsv')
    pred = lambda s: glob.glob(f'{B}/analysis_outputs/{carpeta}/*nativo.{inst}-{s}.lote_*.predictions.tsv')[0]
    verdad = lambda s: f'{B}/instances/{inst}/{inst}-{s}/queryTaxo.tsv'
    print(f'== {nombre} ({inst})')
    for rank in ['family', 'genus', 'species']:
        th = []
        for c in ['c001', 'c002', 'c003']:
            p = f.load_predictions(gcn, pred(c), rank, gcnn); t = f.load_truth(gcn, verdad(c), rank, gcnn)
            x, best, bt = 0, 0, -1
            while True:
                pr, rc, f1 = f.get_precision(p, t, x), f.get_recall(p, t, x), f.get_f1(p, t, x)
                if f1 > best: best, bt = f1, x
                if pr == 1 or rc == 0: break
                x += f.FILTERING_STEP
            th.append(bt)
        u = max(th)
        bien = [f.get_f1(f.load_predictions(gcn, pred(e), rank, gcnn), f.load_truth(gcn, verdad(e), rank, gcnn), u) for e in ['e001', 'e002']]
        bug = [f.get_f1(f.load_predictions(gcn, pred(e), rank, gcnn), f.load_truth(gcn, verdad('e001'), rank, gcnn), u) for e in ['e001', 'e002']]
        print(f'  {rank:8s} umbral={u:4d}  verdad propia: e001 {bien[0]:.4f} e002 {bien[1]:.4f} media {np.mean(bien):.4f}'
              f'   | con verdad de e001 (bug): media {np.mean(bug):.4f}')
